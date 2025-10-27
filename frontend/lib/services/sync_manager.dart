import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
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
    final db = await _cacheService.database;

    await db.insert('sync_queue', {
      'operation_type': operationType,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'payload': json.encode(payload),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
      'status': 'pending',
    });

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
      final db = await _cacheService.database;

      // Get pending actions
      final actions = await db.query(
        'sync_queue',
        where: 'status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at ASC',
      );

      if (actions.isEmpty) {
        debugPrint('No pending actions to sync');
        _updateSyncStatus(SyncStatus.idle);
        _isSyncing = false;
        return;
      }

      debugPrint('Processing ${actions.length} pending actions...');

      int successCount = 0;
      int failCount = 0;

      for (final action in actions) {
        final actionId = action['id'] as int;
        final operationType = action['operation_type'] as String;
        final resourceType = action['resource_type'] as String;
        final resourceId = action['resource_id'] as String?;
        final payload = json.decode(action['payload'] as String);
        final retryCount = action['retry_count'] as int;

        try {
          // Process the action based on type
          await _processAction(
            operationType: operationType,
            resourceType: resourceType,
            resourceId: resourceId,
            payload: payload,
          );

          // Remove successful action from queue
          await db.delete('sync_queue', where: 'id = ?', whereArgs: [actionId]);

          successCount++;
          debugPrint('✓ Synced: $operationType $resourceType');
        } catch (e) {
          failCount++;
          final newRetryCount = retryCount + 1;
          final maxRetries = 5;

          debugPrint('✗ Failed to sync: $operationType $resourceType - $e');

          if (newRetryCount >= maxRetries) {
            // Mark as failed after max retries
            await db.update(
              'sync_queue',
              {
                'status': 'failed',
                'last_error': e.toString(),
                'retry_count': newRetryCount,
              },
              where: 'id = ?',
              whereArgs: [actionId],
            );
            debugPrint('Action marked as failed after $maxRetries retries');
          } else {
            // Increment retry count with exponential backoff
            await db.update(
              'sync_queue',
              {'retry_count': newRetryCount, 'last_error': e.toString()},
              where: 'id = ?',
              whereArgs: [actionId],
            );

            // Wait before next retry (exponential backoff)
            final backoffSeconds = (2 << (newRetryCount - 1)).clamp(1, 60);
            await Future.delayed(Duration(seconds: backoffSeconds));
          }
        }
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
        final fileBytes = payload['file_bytes'] as List<int>;
        final fileName = payload['file_name'] as String;
        final parentId = payload['parent_id'] as String;

        await _driveService.uploadFileFromBytes(
          Uint8List.fromList(fileBytes),
          fileName,
          parentId,
        );
        break;

      case 'delete':
        if (resourceId != null) {
          await _driveService.deleteFile(resourceId);
        }
        break;

      case 'rename':
        if (resourceId != null) {
          final newName = payload['new_name'] as String;
          await _driveService.renameFile(resourceId, newName);
        }
        break;

      case 'move':
        if (resourceId != null) {
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
        await _driveService.createFolder(name, parentId);
        break;

      case 'delete':
        if (resourceId != null) {
          await _driveService.deleteFile(resourceId);
        }
        break;

      case 'rename':
        if (resourceId != null) {
          final newName = payload['new_name'] as String;
          await _driveService.renameFile(resourceId, newName);
        }
        break;

      default:
        throw Exception('Unknown folder operation: $operationType');
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
    final db = await _cacheService.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE status = ?',
      ['pending'],
    );

    _pendingActionCount = Sqflite.firstIntValue(result) ?? 0;
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
    final db = await _cacheService.database;

    await db.delete('sync_queue', where: 'status = ?', whereArgs: ['failed']);

    await _updatePendingCount();
    notifyListeners();
  }

  /// Get failed actions for debugging
  Future<List<Map<String, dynamic>>> getFailedActions() async {
    final db = await _cacheService.database;

    return await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['failed'],
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
    super.dispose();
  }
}
