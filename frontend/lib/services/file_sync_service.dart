import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/drive_file.dart';
import 'auth_service.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';

/// Service for syncing file changes from Google Drive
/// Periodically checks for updates and refreshes cached files
class FileSyncService extends ChangeNotifier {
  static const String _baseUrl = 'https://www.googleapis.com/drive/v3';

  final AuthService _authService;
  final CacheService _cacheService;
  final ConnectivityService _connectivityService;

  Timer? _syncTimer;
  final Map<String, DateTime> _lastChecked = {};
  final Map<String, StreamController<DriveFile>> _fileUpdateControllers = {};

  // Sync interval (default: 30 seconds)
  Duration syncInterval = const Duration(seconds: 30);

  // Files currently being watched
  final Set<String> _watchedFiles = {};

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  FileSyncService({
    required AuthService authService,
    required CacheService cacheService,
    required ConnectivityService connectivityService,
  }) : _authService = authService,
       _cacheService = cacheService,
       _connectivityService = connectivityService;

  /// Start watching a file for changes
  void watchFile(String fileId) {
    if (!_watchedFiles.contains(fileId)) {
      _watchedFiles.add(fileId);
      debugPrint('Started watching file: $fileId');

      // Immediately check for updates
      _checkFileForUpdates(fileId);

      // Start periodic sync if not already running
      _startPeriodicSync();
    }
  }

  /// Stop watching a file
  void unwatchFile(String fileId) {
    _watchedFiles.remove(fileId);
    _lastChecked.remove(fileId);
    _fileUpdateControllers[fileId]?.close();
    _fileUpdateControllers.remove(fileId);
    debugPrint('Stopped watching file: $fileId');

    // Stop periodic sync if no files are being watched
    if (_watchedFiles.isEmpty) {
      _stopPeriodicSync();
    }
  }

  /// Get stream of updates for a specific file
  Stream<DriveFile> getFileUpdateStream(String fileId) {
    if (!_fileUpdateControllers.containsKey(fileId)) {
      _fileUpdateControllers[fileId] = StreamController<DriveFile>.broadcast();
    }
    return _fileUpdateControllers[fileId]!.stream;
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    if (_syncTimer != null && _syncTimer!.isActive) return;

    _syncTimer = Timer.periodic(syncInterval, (timer) {
      if (_connectivityService.isOnline) {
        _syncWatchedFiles();
      }
    });

    debugPrint(
      'Started periodic file sync (interval: ${syncInterval.inSeconds}s)',
    );
  }

  /// Stop periodic sync timer
  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('Stopped periodic file sync');
  }

  /// Sync all watched files
  Future<void> _syncWatchedFiles() async {
    if (_isSyncing || !_connectivityService.isOnline) return;

    _isSyncing = true;
    notifyListeners();

    try {
      for (final fileId in _watchedFiles.toList()) {
        await _checkFileForUpdates(fileId);
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Check if a specific file has been updated on Drive
  Future<void> _checkFileForUpdates(String fileId) async {
    if (!_connectivityService.isOnline) return;

    try {
      // Get cached file metadata
      final cachedFile = await _cacheService.getCachedFile(fileId);
      if (cachedFile == null) {
        debugPrint('File not in cache, skipping sync check: $fileId');
        return;
      }

      // Get current file metadata from Drive
      final driveFile = await _getFileMetadata(fileId);
      if (driveFile == null) {
        debugPrint('File not found on Drive: $fileId');
        return;
      }

      // Compare modification times
      final cachedModified = cachedFile.modifiedTime;
      final driveModified = driveFile.modifiedTime;

      if (driveModified != null && cachedModified != null) {
        if (driveModified.isAfter(cachedModified)) {
          debugPrint('File updated on Drive, refreshing cache: $fileId');
          debugPrint('  Cached: $cachedModified');
          debugPrint('  Drive:  $driveModified');

          // File has been updated, refresh the cache
          await _refreshFileCache(fileId, driveFile);

          // Notify listeners via stream
          _fileUpdateControllers[fileId]?.add(driveFile);
        } else {
          debugPrint('File up to date: $fileId');
        }
      }

      _lastChecked[fileId] = DateTime.now();
    } catch (e) {
      debugPrint('Error checking file for updates: $e');
    }
  }

  /// Get file metadata from Google Drive
  Future<DriveFile?> _getFileMetadata(String fileId) async {
    try {
      final accessToken = await _authService.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final fields =
          'id,name,mimeType,size,parents,modifiedTime,createdTime,thumbnailLink,shared';
      final url = '$_baseUrl/files/$fileId?fields=$fields';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DriveFile.fromJson(data);
      } else if (response.statusCode == 404) {
        debugPrint('File not found: $fileId');
        return null;
      } else {
        throw Exception('Failed to get file metadata: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting file metadata: $e');
      return null;
    }
  }

  /// Refresh cached file content
  Future<void> _refreshFileCache(
    String fileId,
    DriveFile updatedMetadata,
  ) async {
    try {
      // Update metadata in cache
      await _cacheService.cacheFileMetadata(updatedMetadata);

      // If it's a PDF, refresh the PDF bytes
      if (updatedMetadata.isPdf) {
        final accessToken = await _authService.getAccessToken();
        if (accessToken == null) {
          throw Exception('No access token available');
        }

        debugPrint('Downloading updated PDF: $fileId');

        final response = await http.get(
          Uri.parse('$_baseUrl/files/$fileId?alt=media'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          await _cacheService.cachePdfBytes(fileId, bytes);
          debugPrint('Updated PDF cached: $fileId (${bytes.length} bytes)');
        } else {
          throw Exception(
            'Failed to download updated file: ${response.statusCode}',
          );
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing file cache: $e');
      rethrow;
    }
  }

  /// Manually trigger sync for a specific file
  Future<bool> syncFile(String fileId) async {
    if (!_connectivityService.isOnline) {
      debugPrint('Cannot sync file: offline');
      return false;
    }

    try {
      await _checkFileForUpdates(fileId);
      return true;
    } catch (e) {
      debugPrint('Error syncing file: $e');
      return false;
    }
  }

  /// Manually trigger sync for all watched files
  Future<void> syncAllWatchedFiles() async {
    await _syncWatchedFiles();
  }

  /// Check if a file needs syncing (based on last check time)
  bool needsSync(String fileId) {
    final lastCheck = _lastChecked[fileId];
    if (lastCheck == null) return true;

    final timeSinceLastCheck = DateTime.now().difference(lastCheck);
    return timeSinceLastCheck > syncInterval;
  }

  /// Get last sync time for a file
  DateTime? getLastSyncTime(String fileId) {
    return _lastChecked[fileId];
  }

  /// Clear all watched files and stop syncing
  void clearAll() {
    for (final fileId in _watchedFiles.toList()) {
      unwatchFile(fileId);
    }
    _stopPeriodicSync();
  }

  @override
  void dispose() {
    clearAll();
    for (final controller in _fileUpdateControllers.values) {
      controller.close();
    }
    _fileUpdateControllers.clear();
    super.dispose();
  }
}
