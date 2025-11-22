import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../models/tag.dart' as models;
import '../database/database.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';

/// Service for managing tags
class TagService extends ChangeNotifier {
  final AppDatabase _database;
  final ApiService _apiService;
  final AuthService _authService;
  final ConnectivityService _connectivityService;

  // Singleton instance
  static TagService? _instance;
  factory TagService({
    required AppDatabase database,
    required ApiService apiService,
    required AuthService authService,
    required ConnectivityService connectivityService,
  }) {
    _instance ??= TagService._internal(
      database: database,
      apiService: apiService,
      authService: authService,
      connectivityService: connectivityService,
    );
    return _instance!;
  }

  TagService._internal({
    required AppDatabase database,
    required ApiService apiService,
    required AuthService authService,
    required ConnectivityService connectivityService,
  }) : _database = database,
       _apiService = apiService,
       _authService = authService,
       _connectivityService = connectivityService;

  final _uuid = const Uuid();

  /// Get all tags for the current user
  Future<List<models.Tag>> getTags() async {
    try {
      // Try to sync from backend if online
      if (_connectivityService.isOnline) {
        await _syncTagsFromBackend();
      }

      // Get from local cache
      final tagRecords = await _database.select(_database.tags).get();

      // Get document counts
      final tags = <models.Tag>[];
      for (final record in tagRecords) {
        final count = await _getDocumentCount(record.id);
        tags.add(
          models.Tag(
            id: record.id,
            userId: record.userId,
            name: record.name,
            color: record.color,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            documentCount: count,
          ),
        );
      }

      return tags;
    } catch (e) {
      debugPrint('Error getting tags: $e');
      rethrow;
    }
  }

  /// Create a new tag
  Future<models.Tag> createTag({
    required String userId,
    required String name,
    String color = '#2196F3',
  }) async {
    try {
      models.Tag tag;

      // If online, create on backend first to get the server-generated ID
      if (_connectivityService.isOnline) {
        try {
          final backendTag = await _apiService.createTag(
            userId: userId,
            name: name,
            color: color,
          );

          // Save backend tag to local cache
          await _database
              .into(_database.tags)
              .insertOnConflictUpdate(
                TagsCompanion.insert(
                  id: backendTag.id,
                  userId: backendTag.userId,
                  name: backendTag.name,
                  color: Value(backendTag.color),
                  createdAt: backendTag.createdAt,
                  updatedAt: backendTag.updatedAt,
                  isSynced: const Value(true),
                ),
              );

          tag = backendTag;
        } catch (e) {
          debugPrint('Failed to create tag on backend: $e');
          // Fall back to offline creation
          tag = await _createTagOffline(userId, name, color);
        }
      } else {
        // Offline - create locally
        tag = await _createTagOffline(userId, name, color);
      }

      notifyListeners();
      return tag;
    } catch (e) {
      debugPrint('Error creating tag: $e');
      rethrow;
    }
  }

  /// Create tag offline (local only)
  Future<models.Tag> _createTagOffline(
    String userId,
    String name,
    String color,
  ) async {
    final tagId = _uuid.v4();
    final now = DateTime.now();

    final tag = models.Tag(
      id: tagId,
      userId: userId,
      name: name,
      color: color,
      createdAt: now,
      updatedAt: now,
      documentCount: 0,
    );

    // Save to local cache
    await _database
        .into(_database.tags)
        .insert(
          TagsCompanion.insert(
            id: tag.id,
            userId: tag.userId,
            name: tag.name,
            color: Value(tag.color),
            createdAt: tag.createdAt,
            updatedAt: tag.updatedAt,
            isSynced: const Value(false),
          ),
        );

    return tag;
  }

  /// Update a tag
  Future<models.Tag> updateTag({
    required String tagId,
    required String userId,
    String? name,
    String? color,
  }) async {
    try {
      final now = DateTime.now();

      // If online, update on backend first
      if (_connectivityService.isOnline) {
        try {
          final updatedTag = await _apiService.updateTag(
            tagId: tagId,
            userId: userId,
            name: name,
            color: color,
          );

          // Update local cache with backend response
          await (_database.update(
            _database.tags,
          )..where((t) => t.id.equals(tagId))).write(
            TagsCompanion(
              name: Value(updatedTag.name),
              color: Value(updatedTag.color),
              updatedAt: Value(updatedTag.updatedAt),
              isSynced: const Value(true),
            ),
          );

          final documentCount = await _getDocumentCount(tagId);
          notifyListeners();

          return models.Tag(
            id: updatedTag.id,
            userId: updatedTag.userId,
            name: updatedTag.name,
            color: updatedTag.color,
            createdAt: updatedTag.createdAt,
            updatedAt: updatedTag.updatedAt,
            documentCount: documentCount,
          );
        } catch (e) {
          debugPrint('Failed to update tag on backend: $e');
          // Fall through to offline update
        }
      }

      // Offline update or backend failed
      await (_database.update(
        _database.tags,
      )..where((t) => t.id.equals(tagId))).write(
        TagsCompanion(
          name: name != null ? Value(name) : const Value.absent(),
          color: color != null ? Value(color) : const Value.absent(),
          updatedAt: Value(now),
          isSynced: const Value(false),
        ),
      );

      // Get updated tag
      final record = await (_database.select(
        _database.tags,
      )..where((t) => t.id.equals(tagId))).getSingle();

      final documentCount = await _getDocumentCount(tagId);

      notifyListeners();
      return models.Tag(
        id: record.id,
        userId: record.userId,
        name: record.name,
        color: record.color,
        createdAt: record.createdAt,
        updatedAt: record.updatedAt,
        documentCount: documentCount,
      );
    } catch (e) {
      debugPrint('Error updating tag: $e');
      rethrow;
    }
  }

  /// Delete a tag
  Future<void> deleteTag({
    required String tagId,
    required String userId,
  }) async {
    try {
      // Delete file associations
      await (_database.delete(
        _database.fileTags,
      )..where((ft) => ft.tagId.equals(tagId))).go();

      // Delete tag
      await (_database.delete(
        _database.tags,
      )..where((t) => t.id.equals(tagId))).go();

      // Sync to backend if online
      if (_connectivityService.isOnline) {
        try {
          await _apiService.deleteTag(tagId: tagId, userId: userId);
        } catch (e) {
          debugPrint('Failed to sync tag deletion to backend: $e');
          // Continue - tag is deleted locally
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting tag: $e');
      rethrow;
    }
  }

  /// Add a tag to a file
  Future<void> addTagToFile({
    required String userId,
    required String fileId,
    required String tagId,
  }) async {
    try {
      // Check if association already exists locally
      final existing =
          await (_database.select(_database.fileTags)..where(
                (ft) => ft.fileId.equals(fileId) & ft.tagId.equals(tagId),
              ))
              .getSingleOrNull();

      if (existing != null) {
        debugPrint('Tag already associated with file');
        return;
      }

      final fileTagId = _uuid.v4();
      final now = DateTime.now();

      // Save to local cache first (optimistic update)
      await _database
          .into(_database.fileTags)
          .insert(
            FileTagsCompanion.insert(
              id: fileTagId,
              userId: userId,
              fileId: fileId,
              tagId: tagId,
              createdAt: now,
              isSynced: const Value(false),
            ),
          );

      // Sync to backend if online
      if (_connectivityService.isOnline) {
        try {
          await _apiService.addTagToFile(
            userId: userId,
            fileId: fileId,
            tagId: tagId,
          );
          await _markFileTagSynced(fileTagId);
        } catch (e) {
          debugPrint('Failed to sync file tag to backend: $e');
          // Continue - will sync later
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding tag to file: $e');
      rethrow;
    }
  }

  /// Remove a tag from a file
  Future<void> removeTagFromFile({
    required String userId,
    required String fileId,
    required String tagId,
  }) async {
    try {
      // Delete from local cache
      await (_database.delete(
        _database.fileTags,
      )..where((ft) => ft.fileId.equals(fileId) & ft.tagId.equals(tagId))).go();

      // Sync to backend if online
      if (_connectivityService.isOnline) {
        try {
          await _apiService.removeTagFromFile(
            userId: userId,
            fileId: fileId,
            tagId: tagId,
          );
        } catch (e) {
          debugPrint('Failed to sync file tag removal to backend: $e');
          // Continue - removed locally
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error removing tag from file: $e');
      rethrow;
    }
  }

  /// Get tags for a file
  Future<List<models.Tag>> getTagsForFile(String fileId) async {
    try {
      // Get file-tag associations
      final fileTagRecords = await (_database.select(
        _database.fileTags,
      )..where((ft) => ft.fileId.equals(fileId))).get();

      if (fileTagRecords.isEmpty) {
        return [];
      }

      final tagIds = fileTagRecords.map((ft) => ft.tagId).toList();

      // Get tag details
      final tagRecords = await (_database.select(
        _database.tags,
      )..where((t) => t.id.isIn(tagIds))).get();

      return tagRecords
          .map(
            (record) => models.Tag(
              id: record.id,
              userId: record.userId,
              name: record.name,
              color: record.color,
              createdAt: record.createdAt,
              updatedAt: record.updatedAt,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting tags for file: $e');
      rethrow;
    }
  }

  /// Bulk tag files
  Future<void> bulkTagFiles({
    required String userId,
    required List<String> fileIds,
    required List<String> tagIds,
  }) async {
    try {
      for (final fileId in fileIds) {
        for (final tagId in tagIds) {
          await addTagToFile(userId: userId, fileId: fileId, tagId: tagId);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error bulk tagging files: $e');
      rethrow;
    }
  }

  /// Sync tags from backend
  Future<void> _syncTagsFromBackend() async {
    try {
      // Get current user from auth service
      final user = _authService.currentUser;
      if (user == null) {
        debugPrint('No user authenticated, skipping backend sync');
        return;
      }

      final tags = await _apiService.getTags(userId: user.id);

      // Get local tag IDs to detect deletions
      final localTags = await _database.select(_database.tags).get();
      final localTagIds = localTags.map((t) => t.id).toSet();
      final backendTagIds = tags.map((t) => t.id).toSet();

      // Upsert backend tags to local cache
      for (final tag in tags) {
        await _database
            .into(_database.tags)
            .insertOnConflictUpdate(
              TagsCompanion.insert(
                id: tag.id,
                userId: tag.userId,
                name: tag.name,
                color: Value(tag.color),
                createdAt: tag.createdAt,
                updatedAt: tag.updatedAt,
                isSynced: const Value(true),
              ),
            );
      }

      // Remove local tags that don't exist on backend (deleted elsewhere)
      final deletedTagIds = localTagIds.difference(backendTagIds);
      for (final tagId in deletedTagIds) {
        await (_database.delete(
          _database.tags,
        )..where((t) => t.id.equals(tagId))).go();
      }
    } catch (e) {
      debugPrint('Error syncing tags from backend: $e');
      // Don't rethrow - continue with local cache
    }
  }

  /// Mark tag as synced
  Future<void> _markTagSynced(String tagId) async {
    await (_database.update(_database.tags)..where((t) => t.id.equals(tagId)))
        .write(const TagsCompanion(isSynced: Value(true)));
  }

  /// Mark file tag as synced
  Future<void> _markFileTagSynced(String fileTagId) async {
    await (_database.update(_database.fileTags)
          ..where((ft) => ft.id.equals(fileTagId)))
        .write(const FileTagsCompanion(isSynced: Value(true)));
  }

  /// Get document count for a tag
  Future<int> _getDocumentCount(String tagId) async {
    final count =
        await (_database.selectOnly(_database.fileTags)
              ..addColumns([_database.fileTags.id.count()])
              ..where(_database.fileTags.tagId.equals(tagId)))
            .getSingle();

    return count.read(_database.fileTags.id.count()) ?? 0;
  }

  /// Sync unsynced tags to backend (call when coming back online)
  Future<void> syncUnsyncedTags() async {
    if (!_connectivityService.isOnline) {
      return;
    }

    try {
      final user = _authService.currentUser;
      if (user == null) {
        return;
      }

      // Get unsynced tags
      final unsyncedTags = await (_database.select(
        _database.tags,
      )..where((t) => t.isSynced.equals(false))).get();

      for (final tag in unsyncedTags) {
        try {
          // Try to create on backend
          await _apiService.createTag(
            userId: user.id,
            name: tag.name,
            color: tag.color,
          );

          // Mark as synced
          await _markTagSynced(tag.id);
        } catch (e) {
          debugPrint('Failed to sync tag ${tag.id}: $e');
          // Continue with next tag
        }
      }

      // Get unsynced file tags
      final unsyncedFileTags = await (_database.select(
        _database.fileTags,
      )..where((ft) => ft.isSynced.equals(false))).get();

      for (final fileTag in unsyncedFileTags) {
        try {
          await _apiService.addTagToFile(
            userId: user.id,
            fileId: fileTag.fileId,
            tagId: fileTag.tagId,
          );

          await _markFileTagSynced(fileTag.id);
        } catch (e) {
          debugPrint('Failed to sync file tag ${fileTag.id}: $e');
          // Continue with next file tag
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing unsynced tags: $e');
    }
  }
}
