import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';
import 'drive_service.dart';

/// Sync status for UI updates
enum SyncStatus { idle, syncing, error }

/// Service for managing offline action queue and synchronization
class SyncManager extends ChangeNotifier {
  final CacheService _cacheService;
  final ConnectivityService _connectivityService;
  final DriveService _driveService;

  SyncStatus _syncStatus = SyncStatus.idle;
  SyncStatus get syncStatus => _syncStatus;

  int _pendingActionCount = 0;
  int get pendingActionCount => _pendingActionCount;

  String? _lastError;
  String? get lastError => _lastError;

  bool _isSyncing = false;
  StreamSubscription<bool>? _connectivitySubscription;

  /// Stream of sync status updates
  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  SyncManager({
    required CacheService cacheService,
    required ConnectivityService connectivityService,
    required DriveService driveService,
  }) : _cacheService = cacheService,
       _connectivityService = connectivityService,
       _driveService = driveService {
    _init();
  }

  /// Initialize sync manager
  Future<void> _init() async {
    // Load pending action count
    await _updatePendingCount();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.connectivityStream.listen((
      isOnline,
    ) {
      if (isOnline && _pendingActionCount > 0) {
        debugPrint('Connection restored, starting sync...');
        processSyncQueue();
      }
    });

    // Auto-sync if online and has pending actions
    if (_connectivityService.isOnline && _pendingActionCount > 0) {
      processSyncQueue();
    }
  }

  /// Queue an offline action
  Future<void> queueAction({
    required String operationType,
    required String resourceType,
    String? resourceId,
    required Map<String, dynamic> payload,
  }) async {
    final db = _cacheService.database;

    await db.insertSyncOperation(
      SyncQueueCompanion(
        operationType: drift.Value(operationType),
        resourceType: drift.Value(resourceType),
        resourceId: drift.Value(resourceId),
        payload: drift.Value(json.encode(payload)),
        createdAt: drift.Value(DateTime.now()),
        retryCount: const drift.Value(0),
        status: const drift.Value('pending'),
      ),
    );

    await _updatePendingCount();
    notifyListeners();

    debugPrint(
      'Queued action: $operationType $resourceType (${resourceId ?? 'new'})',
    );

    // Try to sync immediately if online
    if (_connectivityService.isOnline) {
      processSyncQueue();
    }
  }

  /// Process sync queue
  Future<void> processSyncQueue() async {
    if (_isSyncing) {
      debugPrint('Sync already in progress, skipping...');
      return;
    }

    if (!_connectivityService.isOnline) {
      debugPrint('Offline, cannot sync');
      return;
    }

    _isSyncing = true;
    _updateSyncStatus(SyncStatus.syncing);

    try {
      final db = _cacheService.database;

      // Get pending actions
      final allActions = await db.getPendingSyncOperations();

      if (allActions.isEmpty) {
        debugPrint('No pending actions to sync');
        _updateSyncStatus(SyncStatus.idle);
        _isSyncing = false;
        return;
      }

      // Sort actions: folders first, then files
      // This ensures parent folders are created before files are uploaded to them
      var actions = _sortActionsByDependency(allActions);

      debugPrint('Processing ${actions.length} pending actions...');

      int successCount = 0;
      int failCount = 0;
      int processedCount = 0;

      while (processedCount < actions.length) {
        final action = actions[processedCount];
        final actionId = action.id;
        final operationType = action.operationType;
        final resourceType = action.resourceType;
        final resourceId = action.resourceId;
        final payload = json.decode(action.payload) as Map<String, dynamic>;
        final retryCount = action.retryCount;

        try {
          // Process the action based on type
          await _processAction(
            operationType: operationType,
            resourceType: resourceType,
            resourceId: resourceId,
            payload: payload,
          );

          // Remove successful action from queue
          await db.deleteSyncOperation(actionId);

          // Clean up temporary file for uploads
          if (operationType == 'upload' && resourceType == 'file') {
            try {
              // Find and delete the temporary file in cache
              final fileName = payload['file_name'] as String;
              final parentId = payload['parent_id'] as String;
              final cachedFiles = await _cacheService.getCachedFiles(parentId);

              // Find temp file with matching name
              final tempFiles = cachedFiles
                  .where((f) => f.name == fileName && f.id.startsWith('temp_'))
                  .toList();

              // Delete all matching temp files
              for (final tempFile in tempFiles) {
                await _cacheService.deleteCachedFile(tempFile.id);
                debugPrint('Cleaned up temp file: ${tempFile.id}');
              }
            } catch (e) {
              // Non-critical error, just log it
              debugPrint('Warning: Could not clean up temp file: $e');
            }
          }

          successCount++;
          debugPrint('✓ Synced: $operationType $resourceType');

          // If we just created a folder, reload the queue to get updated parent_ids
          if (operationType == 'create' && resourceType == 'folder') {
            final remainingActions = await db.getPendingSyncOperations();
            actions = _sortActionsByDependency(remainingActions);
            processedCount = 0; // Reset to reprocess with updated IDs
            continue;
          }
        } catch (e) {
          failCount++;
          final newRetryCount = retryCount + 1;
          const maxRetries = 5;

          debugPrint('✗ Failed to sync: $operationType $resourceType - $e');

          if (newRetryCount >= maxRetries) {
            // Mark as failed after max retries
            await db.updateSyncOperation(
              SyncQueueCompanion(
                id: drift.Value(actionId),
                status: const drift.Value('failed'),
                lastError: drift.Value(e.toString()),
                retryCount: drift.Value(newRetryCount),
              ),
            );
            debugPrint('Action marked as failed after $maxRetries retries');
          } else {
            // Increment retry count with exponential backoff
            await db.updateSyncOperation(
              SyncQueueCompanion(
                id: drift.Value(actionId),
                retryCount: drift.Value(newRetryCount),
                lastError: drift.Value(e.toString()),
              ),
            );

            // Wait before next retry (exponential backoff)
            final backoffSeconds = (2 << (newRetryCount - 1)).clamp(1, 60);
            await Future.delayed(Duration(seconds: backoffSeconds));
          }
        }

        processedCount++;
      }

      debugPrint('Sync complete: $successCount succeeded, $failCount failed');

      await _updatePendingCount();

      if (failCount > 0) {
        _lastError = 'Some actions failed to sync';
        _updateSyncStatus(SyncStatus.error);
      } else {
        _lastError = null;
        _updateSyncStatus(SyncStatus.idle);
      }
    } catch (e) {
      debugPrint('Error processing sync queue: $e');
      _lastError = e.toString();
      _updateSyncStatus(SyncStatus.error);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Process a single action
  Future<void> _processAction({
    required String operationType,
    required String resourceType,
    String? resourceId,
    required Map<String, dynamic> payload,
  }) async {
    switch (resourceType) {
      case 'file':
        await _processFileAction(operationType, resourceId, payload);
        break;
      case 'folder':
        await _processFolderAction(operationType, resourceId, payload);
        break;
      case 'annotation':
        await _processAnnotationAction(operationType, resourceId, payload);
        break;
      default:
        throw Exception('Unknown resource type: $resourceType');
    }
  }

  /// Process file actions
  Future<void> _processFileAction(
    String operationType,
    String? resourceId,
    Map<String, dynamic> payload,
  ) async {
    switch (operationType) {
      case 'upload':
        // Upload file from cached bytes
        // Convert List<dynamic> from JSON to List<int>
        final fileBytesRaw = payload['file_bytes'] as List<dynamic>;
        final fileBytes = fileBytesRaw.map((e) => e as int).toList();
        final fileName = payload['file_name'] as String;
        final parentId = payload['parent_id'] as String;

        // Check if parent is still a temp ID (shouldn't happen if folder sync worked)
        if (parentId.startsWith('temp_')) {
          throw Exception(
            'Cannot upload file to temporary folder ID: $parentId. '
            'Parent folder may not have synced yet.',
          );
        }

        await _driveService.uploadFileFromBytes(
          Uint8List.fromList(fileBytes),
          fileName,
          parentId,
        );
        break;

      case 'delete':
        if (resourceId != null) {
          // Skip delete if it's a temp file (doesn't exist in Drive)
          if (resourceId.startsWith('temp_')) {
            debugPrint('Skipping delete of temp file: $resourceId');
            return;
          }
          await _driveService.deleteFile(resourceId);
        }
        break;

      case 'rename':
        if (resourceId != null) {
          // Skip rename if it's a temp file (doesn't exist in Drive)
          if (resourceId.startsWith('temp_')) {
            debugPrint('Skipping rename of temp file: $resourceId');
            return;
          }
          final newName = payload['new_name'] as String;
          await _driveService.renameFile(resourceId, newName);
        }
        break;

      case 'move':
        if (resourceId != null) {
          // Skip move if it's a temp file (doesn't exist in Drive)
          if (resourceId.startsWith('temp_')) {
            debugPrint('Skipping move of temp file: $resourceId');
            return;
          }
          final newParentId = payload['new_parent_id'] as String;
          await _driveService.moveFile(resourceId, newParentId);
        }
        break;

      default:
        throw Exception('Unknown file operation: $operationType');
    }
  }

  /// Process folder actions
  Future<void> _processFolderAction(
    String operationType,
    String? resourceId,
    Map<String, dynamic> payload,
  ) async {
    switch (operationType) {
      case 'create':
        final name = payload['name'] as String;
        final parentId = payload['parent_id'] as String;

        // Check if parent is still a temp ID (nested temp folders)
        if (parentId.startsWith('temp_')) {
          throw Exception(
            'Cannot create folder in temporary parent folder ID: $parentId. '
            'Parent folder may not have synced yet.',
          );
        }

        final createdFolder = await _driveService.createFolder(name, parentId);

        // If this was a temp folder, update any pending operations that reference it
        if (resourceId != null && resourceId.startsWith('temp_')) {
          await _updatePendingOperationsParentId(resourceId, createdFolder.id);
        }
        break;

      case 'delete':
        if (resourceId != null) {
          // Skip delete if it's a temp file (doesn't exist in Drive)
          if (resourceId.startsWith('temp_')) {
            debugPrint('Skipping delete of temp file: $resourceId');
            return;
          }
          await _driveService.deleteFile(resourceId);
        }
        break;

      case 'rename':
        if (resourceId != null) {
          // Skip rename if it's a temp file (doesn't exist in Drive)
          if (resourceId.startsWith('temp_')) {
            debugPrint('Skipping rename of temp file: $resourceId');
            return;
          }
          final newName = payload['new_name'] as String;
          await _driveService.renameFile(resourceId, newName);
        }
        break;

      default:
        throw Exception('Unknown folder operation: $operationType');
    }
  }

  /// Update parent_id in pending operations when a temp folder gets a real ID
  Future<void> _updatePendingOperationsParentId(
    String oldParentId,
    String newParentId,
  ) async {
    final db = _cacheService.database;
    final pendingActions = await db.getPendingSyncOperations();

    for (final action in pendingActions) {
      try {
        final payload = json.decode(action.payload) as Map<String, dynamic>;
        bool needsUpdate = false;

        // Check if this action references the old parent ID
        if (payload['parent_id'] == oldParentId) {
          payload['parent_id'] = newParentId;
          needsUpdate = true;
        }

        if (needsUpdate) {
          await db.updateSyncOperation(
            SyncQueueCompanion(
              id: drift.Value(action.id),
              payload: drift.Value(json.encode(payload)),
            ),
          );
          debugPrint(
            'Updated parent_id in pending operation ${action.id}: $oldParentId -> $newParentId',
          );
        }
      } catch (e) {
        debugPrint('Error updating pending operation ${action.id}: $e');
      }
    }
  }

  /// Process annotation actions
  Future<void> _processAnnotationAction(
    String operationType,
    String? resourceId,
    Map<String, dynamic> payload,
  ) async {
    // TODO: Implement annotation sync when backend API is ready
    debugPrint('Annotation sync not yet implemented');
  }

  /// Update pending action count
  Future<void> _updatePendingCount() async {
    final db = _cacheService.database;
    final pendingActions = await db.getPendingSyncOperations();
    _pendingActionCount = pendingActions.length;
    notifyListeners();
  }

  /// Update sync status
  void _updateSyncStatus(SyncStatus status) {
    _syncStatus = status;
    _syncStatusController.add(status);
    notifyListeners();
  }

  /// Manually trigger sync
  Future<void> manualSync() async {
    if (!_connectivityService.isOnline) {
      throw Exception('Cannot sync while offline');
    }

    await processSyncQueue();
  }

  /// Clear failed actions
  Future<void> clearFailedActions() async {
    final db = _cacheService.database;
    final allActions = await (db.select(
      db.syncQueue,
    )..where((s) => s.status.equals('failed'))).get();

    for (final action in allActions) {
      await db.deleteSyncOperation(action.id);
    }

    await _updatePendingCount();
    notifyListeners();
  }

  /// Get failed actions for debugging
  Future<List<SyncQueueData>> getFailedActions() async {
    final db = _cacheService.database;
    return await (db.select(
      db.syncQueue,
    )..where((s) => s.status.equals('failed'))).get();
  }

  /// Sort actions by dependency order
  /// Priority: 1. Folder creates, 2. File uploads, 3. Everything else
  List<SyncQueueData> _sortActionsByDependency(List<SyncQueueData> actions) {
    final folderCreates = <SyncQueueData>[];
    final fileUploads = <SyncQueueData>[];
    final others = <SyncQueueData>[];

    for (final action in actions) {
      if (action.resourceType == 'folder' && action.operationType == 'create') {
        folderCreates.add(action);
      } else if (action.resourceType == 'file' &&
          action.operationType == 'upload') {
        fileUploads.add(action);
      } else {
        others.add(action);
      }
    }

    // Sort folder creates by creation time to handle nested folders
    // (parent folders should be created before child folders)
    folderCreates.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Combine in order: folders first, then file uploads, then everything else
    return [...folderCreates, ...fileUploads, ...others];
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
    super.dispose();
  }
}
