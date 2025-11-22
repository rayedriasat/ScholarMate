/// Realtime service for annotation synchronization and collaboration
library;

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/annotation.dart' show PdfAnnotation;

/// Event types for realtime updates
enum RealtimeEventType {
  annotationCreated,
  annotationUpdated,
  annotationDeleted,
  fileOperation,
  presenceUpdate,
  typingStarted,
  typingStopped,
}

/// Realtime event wrapper
class RealtimeEvent {
  final RealtimeEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  RealtimeEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Realtime service for managing Supabase Realtime connections
class RealtimeService {
  final SupabaseClient _supabase;

  // Active channels
  final Map<String, RealtimeChannel> _channels = {};

  // Event stream controller
  final _eventStreamController = StreamController<RealtimeEvent>.broadcast();

  Stream<RealtimeEvent> get eventStream => _eventStreamController.stream;

  RealtimeService(this._supabase);

  /// Connect to Supabase Realtime
  Future<void> connect() async {
    // Supabase client is already connected when initialized
    // This method is here for API consistency
  }

  /// Subscribe to file-specific channel for annotations
  Future<void> subscribeToFile(String fileId) async {
    final channelName = 'file:$fileId';

    // Don't subscribe if already subscribed
    if (_channels.containsKey(channelName)) {
      return;
    }

    // Create channel for this file
    final channel = _supabase.channel(channelName);

    // Listen to annotation changes
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'annotations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'file_id',
            value: fileId,
          ),
          callback: (payload) {
            _handleAnnotationInsert(payload);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'annotations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'file_id',
            value: fileId,
          ),
          callback: (payload) {
            _handleAnnotationUpdate(payload);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'annotations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'file_id',
            value: fileId,
          ),
          callback: (payload) {
            _handleAnnotationDelete(payload);
          },
        );

    // Listen to typing indicators
    _listenToTypingIndicators(channel);

    // Subscribe to channel
    channel.subscribe();

    _channels[channelName] = channel;
  }

  /// Subscribe to folder-specific channel for file operations
  Future<void> subscribeToFolder(String folderId) async {
    final channelName = 'folder:$folderId';

    // Don't subscribe if already subscribed
    if (_channels.containsKey(channelName)) {
      return;
    }

    // Create channel for this folder
    final channel = _supabase.channel(channelName);

    // Listen to file changes in this folder
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'files',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'parent_drive_id',
            value: folderId,
          ),
          callback: (payload) {
            _handleFileOperation(payload);
          },
        )
        .subscribe();

    _channels[channelName] = channel;
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribe(String channelName) async {
    final channel = _channels[channelName];
    if (channel != null) {
      await _supabase.removeChannel(channel);
      _channels.remove(channelName);
    }
  }

  /// Unsubscribe from all channels
  Future<void> unsubscribeAll() async {
    for (final channel in _channels.values) {
      await _supabase.removeChannel(channel);
    }
    _channels.clear();
  }

  /// Broadcast annotation event
  Future<void> broadcastAnnotation(
    PdfAnnotation annotation,
    String action,
  ) async {
    // The annotation is already saved to Supabase via the annotation sync API
    // The Postgres changes will trigger the realtime events automatically
    // This method is here for explicit broadcasting if needed
  }

  /// Broadcast file operation event
  Future<void> broadcastFileOperation(
    String operation,
    Map<String, dynamic> fileData,
  ) async {
    // File operations are saved to Supabase via the files API
    // The Postgres changes will trigger the realtime events automatically
  }

  /// Broadcast presence data
  Future<void> broadcastPresence(
    String fileId,
    Map<String, dynamic> presenceData,
  ) async {
    final channelName = 'file:$fileId';
    final channel = _channels[channelName];

    if (channel != null) {
      await channel.track(presenceData);
    }
  }

  /// Broadcast typing indicator
  Future<void> broadcastTyping({
    required String fileId,
    required String userId,
    required String userName,
    required bool isTyping,
    int? pageNumber,
  }) async {
    final channelName = 'file:$fileId';
    final channel = _channels[channelName];

    if (channel != null) {
      final event = RealtimeEvent(
        type: isTyping ? RealtimeEventType.typingStarted : RealtimeEventType.typingStopped,
        data: {
          'user_id': userId,
          'user_name': userName,
          'page_number': pageNumber,
          'file_id': fileId,
        },
      );

      // Broadcast to channel
      await channel.sendBroadcastMessage(
        event: isTyping ? 'typing_started' : 'typing_stopped',
        payload: event.data,
      );

      // Also emit locally
      _eventStreamController.add(event);
    }
  }

  /// Listen to typing indicators on a channel
  void _listenToTypingIndicators(RealtimeChannel channel) {
    channel
        .onBroadcast(
          event: 'typing_started',
          callback: (payload) {
            final event = RealtimeEvent(
              type: RealtimeEventType.typingStarted,
              data: payload,
            );
            _eventStreamController.add(event);
          },
        )
        .onBroadcast(
          event: 'typing_stopped',
          callback: (payload) {
            final event = RealtimeEvent(
              type: RealtimeEventType.typingStopped,
              data: payload,
            );
            _eventStreamController.add(event);
          },
        );
  }

  /// Handle annotation insert event
  void _handleAnnotationInsert(PostgresChangePayload payload) {
    final event = RealtimeEvent(
      type: RealtimeEventType.annotationCreated,
      data: payload.newRecord,
    );
    _eventStreamController.add(event);
  }

  /// Handle annotation update event
  void _handleAnnotationUpdate(PostgresChangePayload payload) {
    final event = RealtimeEvent(
      type: RealtimeEventType.annotationUpdated,
      data: payload.newRecord,
    );
    _eventStreamController.add(event);
  }

  /// Handle annotation delete event
  void _handleAnnotationDelete(PostgresChangePayload payload) {
    final event = RealtimeEvent(
      type: RealtimeEventType.annotationDeleted,
      data: payload.oldRecord,
    );
    _eventStreamController.add(event);
  }

  /// Handle file operation event
  void _handleFileOperation(PostgresChangePayload payload) {
    final event = RealtimeEvent(
      type: RealtimeEventType.fileOperation,
      data: {
        'event': payload.eventType.name,
        'old': payload.oldRecord,
        'new': payload.newRecord,
      },
    );
    _eventStreamController.add(event);
  }

  /// Dispose resources
  void dispose() {
    unsubscribeAll();
    _eventStreamController.close();
  }
}
