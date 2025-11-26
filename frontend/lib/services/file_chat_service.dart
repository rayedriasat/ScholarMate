import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/file_chat_message.dart' as model;
import '../database/database.dart';
import 'package:drift/drift.dart' as drift;

/// Service for managing file-based chat threads
class FileChatService extends ChangeNotifier {
  final AppDatabase _database;
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  RealtimeChannel? _channel;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPhotoUrl;

  FileChatService({
    required AppDatabase database,
    required SupabaseClient supabase,
  }) : _database = database,
       _supabase = supabase;

  /// Initialize chat for a specific file
  Future<void> initializeChat({
    required String fileId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
  }) async {
    _currentUserId = userId;
    _currentUserName = userName;
    _currentUserPhotoUrl = userPhotoUrl;

    // Ensure thread exists
    await _ensureThreadExists(fileId);

    // Subscribe to realtime updates
    await _subscribeToRealtimeUpdates(fileId);

    // Load initial messages
    await fetchMessages(fileId);
  }

  /// Ensure a chat thread exists for the file
  Future<String> _ensureThreadExists(String fileId) async {
    try {
      // Check if thread exists in Supabase
      final response = await _supabase
          .from('file_chat_threads')
          .select('id')
          .eq('file_id', fileId)
          .maybeSingle();

      if (response != null) {
        return response['id'] as String;
      }

      // Create new thread
      final threadId = _uuid.v4();
      await _supabase.from('file_chat_threads').insert({
        'id': threadId,
        'file_id': fileId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'message_count': 0,
      });

      return threadId;
    } catch (e) {
      debugPrint('Error ensuring thread exists: $e');
      // Fallback to local thread ID
      return 'local_$fileId';
    }
  }

  /// Subscribe to realtime updates for a file's chat
  Future<void> _subscribeToRealtimeUpdates(String fileId) async {
    try {
      // Unsubscribe from previous channel
      await _channel?.unsubscribe();

      // Subscribe to new channel
      _channel = _supabase
          .channel('file_chat_$fileId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'file_chat_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'file_id',
              value: fileId,
            ),
            callback: (payload) {
              _handleRealtimeMessage(payload.newRecord);
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error subscribing to realtime updates: $e');
    }
  }

  /// Handle incoming realtime message
  void _handleRealtimeMessage(Map<String, dynamic> record) {
    try {
      final message = model.FileChatMessage.fromJson(record);

      // Don't add our own messages again
      if (message.userId == _currentUserId) return;

      // Save to local database
      _saveMessageToLocal(message);

      notifyListeners();
    } catch (e) {
      debugPrint('Error handling realtime message: $e');
    }
  }

  /// Fetch messages for a file
  Future<List<model.FileChatMessage>> fetchMessages(String fileId) async {
    debugPrint('Fetching messages for file: $fileId');
    try {
      // Try to fetch from Supabase
      final response = await _supabase
          .from('file_chat_messages')
          .select()
          .eq('file_id', fileId)
          .order('timestamp', ascending: true);

      final messages = (response as List)
          .map((json) => model.FileChatMessage.fromJson(json))
          .toList();

      debugPrint('Fetched ${messages.length} messages from Supabase');

      // Save to local database
      for (final message in messages) {
        await _saveMessageToLocal(message);
      }

      return messages;
    } catch (e) {
      debugPrint('Error fetching messages from Supabase: $e');

      // Fallback to local database
      final localMessages = await _getLocalMessages(fileId);
      debugPrint('Fetched ${localMessages.length} messages from local DB');
      return localMessages;
    }
  }

  /// Get messages from local database
  Future<List<model.FileChatMessage>> _getLocalMessages(String fileId) async {
    final dbMessages =
        await (_database.select(_database.fileChatMessages)
              ..where((m) => m.fileId.equals(fileId))
              ..orderBy([
                (m) => drift.OrderingTerm(
                  expression: m.timestamp,
                  mode: drift.OrderingMode.asc,
                ),
              ]))
            .get();

    return dbMessages
        .map(
          (m) => model.FileChatMessage(
            id: m.id,
            threadId: m.threadId,
            fileId: m.fileId,
            userId: m.userId,
            userName: m.userName,
            userPhotoUrl: m.userPhotoUrl,
            content: m.content,
            timestamp: m.timestamp,
            isSynced: m.isSynced,
            isRead: m.isRead,
          ),
        )
        .toList();
  }

  /// Send a message
  Future<model.FileChatMessage?> sendMessage({
    required String fileId,
    required String content,
  }) async {
    if (_currentUserId == null || _currentUserName == null) {
      debugPrint('User not initialized');
      return null;
    }

    final localMessageId = 'local_${_uuid.v4()}';
    final now = DateTime.now();

    // Create local message first (optimistic update)
    final localMessage = model.FileChatMessage(
      id: localMessageId,
      threadId: 'pending',
      fileId: fileId,
      userId: _currentUserId!,
      userName: _currentUserName!,
      userPhotoUrl: _currentUserPhotoUrl,
      content: content,
      timestamp: now,
      isSynced: false,
      isRead: true, // User's own messages are always read
    );

    // Save locally first
    await _saveMessageToLocal(localMessage);
    notifyListeners();

    // Try to sync to Supabase
    try {
      // Ensure thread exists and get proper UUID
      final threadId = await _ensureThreadExists(fileId);

      // Only sync if we have a valid UUID thread (not local fallback)
      if (!threadId.startsWith('local_')) {
        // Create message with proper UUID for Supabase
        final supabaseMessageId = _uuid.v4();
        final messageData = {
          'id': supabaseMessageId,
          'thread_id': threadId,
          'file_id': fileId,
          'user_id': _currentUserId!,
          'user_name': _currentUserName!,
          'user_photo_url': _currentUserPhotoUrl,
          'content': content,
          'timestamp': now.toIso8601String(),
        };

        await _supabase.from('file_chat_messages').insert(messageData);

        // Update local message with Supabase ID and mark as synced
        await _database.transaction(() async {
          // Delete local message
          await (_database.delete(
            _database.fileChatMessages,
          )..where((m) => m.id.equals(localMessageId))).go();

          // Insert synced message with Supabase ID
          await _database
              .into(_database.fileChatMessages)
              .insert(
                FileChatMessagesCompanion.insert(
                  id: supabaseMessageId,
                  threadId: threadId,
                  fileId: fileId,
                  userId: _currentUserId!,
                  userName: _currentUserName!,
                  userPhotoUrl: drift.Value(_currentUserPhotoUrl),
                  content: content,
                  timestamp: now,
                  isSynced: const drift.Value(true),
                ),
              );
        });

        // Update thread
        await _supabase
            .from('file_chat_threads')
            .update({
              'updated_at': now.toIso8601String(),
              'message_count': await _getMessageCount(fileId),
            })
            .eq('id', threadId);

        return localMessage.copyWith(
          id: supabaseMessageId,
          threadId: threadId,
          isSynced: true,
        );
      }

      return localMessage;
    } catch (e) {
      debugPrint('Error syncing message to Supabase: $e');
      // Message remains in local database with isSynced = false
      return localMessage;
    }
  }

  /// Save message to local database
  Future<void> _saveMessageToLocal(model.FileChatMessage message) async {
    try {
      debugPrint('Saving message to local DB: ${message.id}');

      // Check if message already exists
      final existing = await (_database.select(
        _database.fileChatMessages,
      )..where((m) => m.id.equals(message.id))).getSingleOrNull();

      if (existing != null) {
        debugPrint(
          'Message ${message.id} exists, updating (preserving isRead=${existing.isRead})',
        );
        // Message exists, only update if it's not synced yet or update sync status
        // Don't overwrite isRead status
        await (_database.update(
          _database.fileChatMessages,
        )..where((m) => m.id.equals(message.id))).write(
          FileChatMessagesCompanion(
            isSynced: drift.Value(message.isSynced),
            content: drift.Value(message.content),
            timestamp: drift.Value(message.timestamp),
            // Don't update isRead to preserve local read status
          ),
        );
      } else {
        debugPrint(
          'Message ${message.id} is new, inserting with isRead=${message.isRead}',
        );
        // New message, insert it
        await _database
            .into(_database.fileChatMessages)
            .insert(
              FileChatMessagesCompanion.insert(
                id: message.id,
                threadId: message.threadId,
                fileId: message.fileId,
                userId: message.userId,
                userName: message.userName,
                userPhotoUrl: drift.Value(message.userPhotoUrl),
                content: message.content,
                timestamp: message.timestamp,
                isSynced: drift.Value(message.isSynced),
                isRead: drift.Value(message.isRead),
              ),
            );
      }
      debugPrint('Successfully saved message ${message.id}');
    } catch (e, stackTrace) {
      debugPrint('Error saving message to local DB: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Get message count for a file
  Future<int> _getMessageCount(String fileId) async {
    final count =
        await (_database.selectOnly(_database.fileChatMessages)
              ..addColumns([_database.fileChatMessages.id.count()])
              ..where(_database.fileChatMessages.fileId.equals(fileId)))
            .getSingle();

    return count.read(_database.fileChatMessages.id.count()) ?? 0;
  }

  /// Get unread message count for a file
  Future<int> getUnreadCount(String fileId, String userId) async {
    final count =
        await (_database.selectOnly(_database.fileChatMessages)
              ..addColumns([_database.fileChatMessages.id.count()])
              ..where(_database.fileChatMessages.fileId.equals(fileId))
              ..where(_database.fileChatMessages.userId.equals(userId).not())
              ..where(_database.fileChatMessages.isRead.equals(false)))
            .getSingle();

    final unreadCount = count.read(_database.fileChatMessages.id.count()) ?? 0;
    debugPrint('Unread count for file $fileId (user $userId): $unreadCount');
    return unreadCount;
  }

  /// Mark all messages as read for a file
  Future<void> markMessagesAsRead(String fileId, String userId) async {
    debugPrint('Marking messages as read for file: $fileId, user: $userId');
    final result =
        await (_database.update(_database.fileChatMessages)
              ..where((m) => m.fileId.equals(fileId))
              ..where((m) => m.userId.equals(userId).not()))
            .write(FileChatMessagesCompanion(isRead: drift.Value(true)));
    debugPrint('Marked $result messages as read');
    notifyListeners();
  }

  /// Check if user has access to file chat
  Future<bool> hasAccess(String fileId, String userId) async {
    try {
      // Check if user has access via file_shares table
      final response = await _supabase
          .from('file_shares')
          .select('id')
          .eq('file_id', fileId)
          .eq('shared_with_user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking access: $e');
      return false;
    }
  }

  /// Cleanup when leaving chat
  @override
  Future<void> dispose() async {
    await _channel?.unsubscribe();
    _currentUserId = null;
    _currentUserName = null;
    _currentUserPhotoUrl = null;
    super.dispose();
  }
}
