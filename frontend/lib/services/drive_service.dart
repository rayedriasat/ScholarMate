import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/drive_file.dart';
import 'auth_service.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';
import 'sync_manager.dart';

/// Service for Google Drive API with automatic token refresh
///
/// Uses AuthService.getAuthenticatedClient() which handles token refresh automatically
/// via the google_sign_in_all_platforms package's internal token management.
class DriveService extends ChangeNotifier {
  static const String _baseUrl = 'https://www.googleapis.com/drive/v3';
  static const String _uploadUrl = 'https://www.googleapis.com/upload/drive/v3';
  static const String _appFolderName = 'ScholarMate';

  final AuthService _authService;
  final CacheService? _cacheService;
  final ConnectivityService? _connectivityService;
  SyncManager? _syncManager;

  String? _appFolderId;

  DriveService({
    AuthService? authService,
    CacheService? cacheService,
    ConnectivityService? connectivityService,
  }) : _authService = authService ?? AuthService(),
       _cacheService = cacheService,
       _connectivityService = connectivityService;

  void setSyncManager(SyncManager syncManager) {
    _syncManager = syncManager;
  }

  bool get isOnline => _connectivityService?.isOnline ?? true;

  /// Get authenticated HTTP client with automatic token refresh
  /// This is the key method - uses the package's built-in token management
  Future<http.Client> _getClient() async {
    final client = await _authService.getAuthenticatedClient();

    if (client == null) {
      throw Exception(
        'AUTHENTICATION_REQUIRED: Please sign in to access Google Drive.',
      );
    }

    return client;
  }

  /// Make an authenticated request using the auto-refreshing client
  Future<http.Response> _makeRequest(
    Future<http.Response> Function(http.Client client) requestFn,
  ) async {
    try {
      final client = await _getClient();
      final response = await requestFn(client);

      // If we still get 401, the session is truly expired
      if (response.statusCode == 401) {
        debugPrint('Got 401 even with authenticated client - session expired');
        throw Exception(
          'AUTHENTICATION_EXPIRED: Your session has expired. Please sign out and sign in again.',
        );
      }

      return response;
    } catch (e) {
      if (e.toString().contains('AUTHENTICATION')) {
        rethrow;
      }
      debugPrint('Request error: $e');
      rethrow;
    }
  }

  /// Get the ScholarMate app folder ID
  Future<String> getAppFolderId() async {
    if (_appFolderId != null) return _appFolderId!;

    final searchUrl =
        '$_baseUrl/files?q=name=\'$_appFolderName\' and mimeType=\'application/vnd.google-apps.folder\' and trashed=false';

    final response = await _makeRequest(
      (client) => client.get(
        Uri.parse(searchUrl),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final files = data['files'] as List;

      if (files.isNotEmpty) {
        _appFolderId = files.first['id'] as String;
        return _appFolderId!;
      }
    }

    return await createAppFolder();
  }

  /// Create the ScholarMate app folder
  Future<String> createAppFolder() async {
    final folderMetadata = {
      'name': _appFolderName,
      'mimeType': 'application/vnd.google-apps.folder',
    };

    final response = await _makeRequest(
      (client) => client.post(
        Uri.parse('$_baseUrl/files'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(folderMetadata),
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _appFolderId = data['id'] as String;
      debugPrint('Created ScholarMate folder: $_appFolderId');
      return _appFolderId!;
    } else {
      throw Exception('Failed to create app folder: ${response.statusCode}');
    }
  }

  /// List files in a folder
  Future<List<DriveFile>> listFiles([String? folderId]) async {
    final targetFolderId = folderId ?? await getAppFolderId();

    if (!isOnline && _cacheService != null) {
      debugPrint('Offline: Loading from cache');
      return await _cacheService.getCachedFiles(targetFolderId);
    }

    try {
      final query = '\'$targetFolderId\' in parents and trashed=false';
      final fields =
          'files(id,name,mimeType,size,parents,modifiedTime,createdTime,thumbnailLink,shared)';
      final url =
          '$_baseUrl/files?q=${Uri.encodeComponent(query)}&fields=$fields&orderBy=folder,name';

      final response = await _makeRequest(
        (client) => client.get(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final files = (data['files'] as List)
            .map((f) => DriveFile.fromJson(f as Map<String, dynamic>))
            .toList();

        files.sort((a, b) {
          if (a.isFolder && !b.isFolder) return -1;
          if (!a.isFolder && b.isFolder) return 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        if (_cacheService != null) {
          await _cacheService.cacheFileMetadataList(files);
        }

        return files;
      } else {
        throw Exception('Failed to list files: ${response.statusCode}');
      }
    } catch (e) {
      if (_cacheService != null) {
        debugPrint('Error fetching files, using cache: $e');
        return await _cacheService.getCachedFiles(targetFolderId);
      }
      rethrow;
    }
  }

  /// Upload a file
  Future<DriveFile> uploadFile(
    File file,
    String parentId, {
    String? customName,
    void Function(double progress)? onProgress,
  }) async {
    final fileName = customName ?? file.path.split('/').last;
    final fileBytes = await file.readAsBytes();

    if (!isOnline && _syncManager != null) {
      debugPrint('Offline: Queuing upload');
      await _syncManager!.queueAction(
        operationType: 'upload',
        resourceType: 'file',
        payload: {
          'file_bytes': fileBytes,
          'file_name': fileName,
          'parent_id': parentId,
        },
      );

      final tempFile = DriveFile(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: fileName,
        parentId: parentId,
        size: fileBytes.length,
        createdTime: DateTime.now(),
        modifiedTime: DateTime.now(),
        syncStatus: 'pending',
      );

      if (_cacheService != null) {
        await _cacheService.cacheFileMetadata(tempFile);
      }

      return tempFile;
    }

    return await uploadFileFromBytes(
      fileBytes,
      fileName,
      parentId,
      onProgress: onProgress,
    );
  }

  /// Upload file from bytes
  Future<DriveFile> uploadFileFromBytes(
    Uint8List fileBytes,
    String fileName,
    String parentId, {
    void Function(double progress)? onProgress,
  }) async {
    String mimeType = 'application/octet-stream';
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        mimeType = 'application/pdf';
        break;
      case 'md':
      case 'markdown':
        mimeType = 'text/markdown';
        break;
      case 'txt':
        mimeType = 'text/plain';
        break;
    }

    final boundary = 'dart-boundary-${DateTime.now().millisecondsSinceEpoch}';
    final metadata = {
      'name': fileName,
      'parents': [parentId],
    };

    final metadataPart =
        '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${json.encode(metadata)}\r\n';
    final filePart = '--$boundary\r\nContent-Type: $mimeType\r\n\r\n';
    final endBoundary = '\r\n--$boundary--';

    final totalBytes = Uint8List.fromList([
      ...utf8.encode(metadataPart),
      ...utf8.encode(filePart),
      ...fileBytes,
      ...utf8.encode(endBoundary),
    ]);

    final response = await _makeRequest(
      (client) => client.post(
        Uri.parse('$_uploadUrl/files?uploadType=multipart'),
        headers: {
          'Content-Type': 'multipart/related; boundary=$boundary',
          'Content-Length': totalBytes.length.toString(),
        },
        body: totalBytes,
      ),
    );

    if (response.statusCode == 200) {
      return DriveFile.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to upload: ${response.statusCode}');
    }
  }

  /// Create a folder
  Future<DriveFile> createFolder(String name, String parentId) async {
    if (!isOnline && _syncManager != null) {
      debugPrint('Offline: Queuing folder creation');
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final tempFolder = DriveFile(
        id: tempId,
        name: name,
        parentId: parentId,
        isFolder: true,
        createdTime: DateTime.now(),
        modifiedTime: DateTime.now(),
        syncStatus: 'pending',
      );

      await _syncManager!.queueAction(
        operationType: 'create',
        resourceType: 'folder',
        resourceId: tempId,
        payload: {'name': name, 'parent_id': parentId},
      );

      if (_cacheService != null) {
        await _cacheService.cacheFileMetadata(tempFolder);
      }

      return tempFolder;
    }

    final folderMetadata = {
      'name': name,
      'mimeType': 'application/vnd.google-apps.folder',
      'parents': [parentId],
    };

    final response = await _makeRequest(
      (client) => client.post(
        Uri.parse('$_baseUrl/files'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(folderMetadata),
      ),
    );

    if (response.statusCode == 200) {
      final folder = DriveFile.fromJson(json.decode(response.body));
      if (_cacheService != null) {
        await _cacheService.cacheFileMetadata(folder);
      }
      return folder;
    } else {
      throw Exception('Failed to create folder: ${response.statusCode}');
    }
  }

  /// Delete a file or folder
  Future<void> deleteFile(String fileId) async {
    if (!isOnline && _syncManager != null) {
      debugPrint('Offline: Queuing deletion');
      await _syncManager!.queueAction(
        operationType: 'delete',
        resourceType: 'file',
        resourceId: fileId,
        payload: {},
      );
      if (_cacheService != null) {
        await _cacheService.deleteCachedFile(fileId);
      }
      return;
    }

    final response = await _makeRequest(
      (client) => client.delete(Uri.parse('$_baseUrl/files/$fileId')),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete: ${response.statusCode}');
    }
  }

  /// Rename a file or folder
  Future<DriveFile> renameFile(String fileId, String newName) async {
    if (!isOnline && _syncManager != null) {
      debugPrint('Offline: Queuing rename');
      await _syncManager!.queueAction(
        operationType: 'rename',
        resourceType: 'file',
        resourceId: fileId,
        payload: {'new_name': newName},
      );

      if (_cacheService != null) {
        final cached = await _cacheService.getCachedFile(fileId);
        if (cached != null) {
          final updated = cached.copyWith(name: newName);
          await _cacheService.cacheFileMetadata(updated);
          return updated;
        }
      }

      return DriveFile(id: fileId, name: newName, modifiedTime: DateTime.now());
    }

    final response = await _makeRequest(
      (client) => client.patch(
        Uri.parse('$_baseUrl/files/$fileId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': newName}),
      ),
    );

    if (response.statusCode == 200) {
      final file = DriveFile.fromJson(json.decode(response.body));
      if (_cacheService != null) {
        await _cacheService.cacheFileMetadata(file);
      }
      return file;
    } else {
      throw Exception('Failed to rename: ${response.statusCode}');
    }
  }

  /// Move a file to a different folder
  Future<DriveFile> moveFile(String fileId, String newParentId) async {
    if (!isOnline && _syncManager != null) {
      debugPrint('Offline: Queuing move');
      await _syncManager!.queueAction(
        operationType: 'move',
        resourceType: 'file',
        resourceId: fileId,
        payload: {'new_parent_id': newParentId},
      );

      if (_cacheService != null) {
        final cached = await _cacheService.getCachedFile(fileId);
        if (cached != null) {
          final updated = cached.copyWith(parentId: newParentId);
          await _cacheService.cacheFileMetadata(updated);
          return updated;
        }
      }

      return DriveFile(
        id: fileId,
        parentId: newParentId,
        name: 'moved',
        modifiedTime: DateTime.now(),
      );
    }

    // Get current parents
    final getResponse = await _makeRequest(
      (client) =>
          client.get(Uri.parse('$_baseUrl/files/$fileId?fields=parents')),
    );

    if (getResponse.statusCode != 200) {
      throw Exception('Failed to get file info: ${getResponse.statusCode}');
    }

    final currentParents = (json.decode(getResponse.body)['parents'] as List)
        .join(',');

    final response = await _makeRequest(
      (client) => client.patch(
        Uri.parse(
          '$_baseUrl/files/$fileId?addParents=$newParentId&removeParents=$currentParents',
        ),
      ),
    );

    if (response.statusCode == 200) {
      return DriveFile.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to move: ${response.statusCode}');
    }
  }

  /// Download file content
  Future<Uint8List?> downloadFile(
    String fileId, {
    void Function(double progress)? onProgress,
    bool forceRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh && _cacheService != null) {
      final cached = await _cacheService.getCachedPdf(fileId);
      if (cached != null) {
        debugPrint('Loading from cache: $fileId');
        onProgress?.call(1.0);
        return cached;
      }
    }

    if (!isOnline) {
      throw Exception(
        'File not available offline. Please connect to download.',
      );
    }

    final response = await _makeRequest(
      (client) => client.get(Uri.parse('$_baseUrl/files/$fileId?alt=media')),
    );

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      onProgress?.call(1.0);

      if (_cacheService != null) {
        final file = await _cacheService.getCachedFile(fileId);
        if (file?.isPdf == true) {
          await _cacheService.cachePdfBytes(fileId, bytes);
        }
      }

      return bytes;
    } else {
      throw Exception('Failed to download: ${response.statusCode}');
    }
  }

  /// Download file as string
  Future<String> downloadFileAsString(String fileId) async {
    final bytes = await downloadFile(fileId);
    if (bytes == null) throw Exception('Failed to download file');
    return utf8.decode(bytes);
  }

  /// Update file content
  Future<DriveFile> updateFile(
    String fileId,
    Uint8List fileBytes,
    String fileName, {
    void Function(double progress)? onProgress,
  }) async {
    String mimeType = 'application/octet-stream';
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        mimeType = 'application/pdf';
        break;
      case 'md':
      case 'markdown':
        mimeType = 'text/markdown';
        break;
      case 'txt':
        mimeType = 'text/plain';
        break;
    }

    final response = await _makeRequest(
      (client) => client.patch(
        Uri.parse('$_uploadUrl/files/$fileId?uploadType=media'),
        headers: {
          'Content-Type': mimeType,
          'Content-Length': fileBytes.length.toString(),
        },
        body: fileBytes,
      ),
    );

    if (response.statusCode == 200) {
      return DriveFile.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update: ${response.statusCode}');
    }
  }

  /// Update file content (text)
  Future<void> updateFileContent(
    String fileId,
    String content, {
    String? newName,
  }) async {
    if (!isOnline) {
      throw Exception('Cannot update file while offline');
    }

    final boundary = 'boundary_${DateTime.now().millisecondsSinceEpoch}';
    final requestBody = StringBuffer();

    requestBody.write('--$boundary\r\n');
    requestBody.write('Content-Type: application/json; charset=UTF-8\r\n\r\n');

    final metadata = <String, dynamic>{};
    if (newName != null) metadata['name'] = newName;
    requestBody.write(jsonEncode(metadata));
    requestBody.write('\r\n');

    requestBody.write('--$boundary\r\n');
    requestBody.write('Content-Type: text/markdown\r\n\r\n');
    requestBody.write(content);
    requestBody.write('\r\n--$boundary--\r\n');

    final response = await _makeRequest(
      (client) => client.patch(
        Uri.parse('$_uploadUrl/files/$fileId?uploadType=multipart'),
        headers: {'Content-Type': 'multipart/related; boundary=$boundary'},
        body: requestBody.toString(),
      ),
    );

    if (response.statusCode == 200) {
      debugPrint('File updated: $fileId');
      if (_cacheService != null) {
        await _cacheService.deleteCachedFile(fileId);
      }
      notifyListeners();
    } else {
      throw Exception('Failed to update: ${response.statusCode}');
    }
  }

  /// Share a file
  Future<String> shareFile(String fileId, String email, String role) async {
    final driveRole = role == 'editor' ? 'writer' : 'reader';

    final response = await _makeRequest(
      (client) => client.post(
        Uri.parse(
          '$_baseUrl/files/$fileId/permissions?sendNotificationEmail=true',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'type': 'user',
          'role': driveRole,
          'emailAddress': email,
        }),
      ),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['id'] as String;
    } else {
      throw Exception('Failed to share: ${response.statusCode}');
    }
  }

  /// List file permissions
  Future<List<Map<String, dynamic>>> listFilePermissions(String fileId) async {
    final response = await _makeRequest(
      (client) => client.get(
        Uri.parse(
          '$_baseUrl/files/$fileId/permissions?fields=permissions(id,emailAddress,role,type,displayName,photoLink)',
        ),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(
        json.decode(response.body)['permissions'] ?? [],
      );
    } else {
      throw Exception('Failed to list permissions: ${response.statusCode}');
    }
  }

  /// Remove file permission
  Future<void> removeFilePermission(String fileId, String permissionId) async {
    final response = await _makeRequest(
      (client) => client.delete(
        Uri.parse('$_baseUrl/files/$fileId/permissions/$permissionId'),
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove permission: ${response.statusCode}');
    }
  }

  /// Create public link
  Future<String> createPublicLink(String fileId) async {
    final response = await _makeRequest(
      (client) => client.post(
        Uri.parse('$_baseUrl/files/$fileId/permissions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'type': 'anyone', 'role': 'reader'}),
      ),
    );

    if (response.statusCode == 200) {
      return 'https://drive.google.com/file/d/$fileId/view';
    } else {
      throw Exception('Failed to create public link: ${response.statusCode}');
    }
  }

  /// Get cached file name
  Future<String?> getCachedFileName(String fileId) async {
    try {
      return (await _cacheService?.getCachedFile(fileId))?.name;
    } catch (e) {
      return null;
    }
  }

  /// List all files recursively
  Future<List<DriveFile>> listAllFiles() async {
    final allFiles = <DriveFile>[];
    final appFolderId = await getAppFolderId();
    await _listFilesRecursive(appFolderId, allFiles);
    return allFiles;
  }

  Future<void> _listFilesRecursive(String folderId, List<DriveFile> acc) async {
    try {
      final files = await listFiles(folderId);
      for (final file in files) {
        if (file.isFolder) {
          await _listFilesRecursive(file.id, acc);
        } else {
          acc.add(file);
        }
      }
    } catch (e) {
      debugPrint('Error listing folder $folderId: $e');
    }
  }

  void clearAppFolderCache() {
    _appFolderId = null;
  }
}
