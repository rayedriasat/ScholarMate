import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/drive_file.dart';
import 'auth_service.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';
import 'sync_manager.dart';

/// Service for interacting with Google Drive API with offline support
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

  /// Set sync manager (must be called after initialization)
  void setSyncManager(SyncManager syncManager) {
    _syncManager = syncManager;
  }

  /// Check if currently online
  bool get isOnline => _connectivityService?.isOnline ?? true;

  /// Get access token with retry logic
  Future<String> _getAccessToken() async {
    // First try to get current token (automatically refreshes if expired)
    var accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      debugPrint(
        'No access token available from AuthService, attempting silent sign-in...',
      );

      // Try silent sign-in to restore session
      final user = await _authService.silentSignIn();
      accessToken = user?.accessToken;

      if (accessToken == null) {
        debugPrint('Silent sign-in also failed to provide access token');
        throw Exception('No access token available. Please sign in again.');
      }

      debugPrint('Access token obtained from silent sign-in');
    }

    return accessToken;
  }

  /// Make HTTP request with automatic token refresh on 401 errors
  Future<http.Response> _makeAuthenticatedRequest(
    Future<http.Response> Function(String token) requestFunction,
  ) async {
    String accessToken = await _getAccessToken();

    // Make the request
    http.Response response = await requestFunction(accessToken);

    // If unauthorized, try to refresh token and retry once
    if (response.statusCode == 401) {
      debugPrint(
        'Received 401 Unauthorized from Google Drive API, attempting to refresh token...',
      );

      // Try to get a fresh token (forcing refresh)
      final freshToken = await _authService.getAccessToken(forceRefresh: true);

      if (freshToken != null && freshToken != accessToken) {
        debugPrint('Got fresh token, retrying request...');
        response = await requestFunction(freshToken);
      } else {
        debugPrint('Unable to get fresh token or token unchanged.');
      }

      // Check if retry was successful
      if (response.statusCode == 401) {
        debugPrint('Request still failed after token refresh');
        debugPrint(
          'This indicates the OAuth session may be revoked or invalid',
        );
        throw Exception(
          'AUTHENTICATION_EXPIRED: Your session has expired. Please sign out and sign in again to continue.',
        );
      }
    }

    return response;
  }

  /// Get the ScholarMate app folder ID, creating it if necessary
  Future<String> getAppFolderId() async {
    if (_appFolderId != null) return _appFolderId!;

    // Search for existing ScholarMate folder
    final searchUrl =
        '$_baseUrl/files?q=name=\'$_appFolderName\' and mimeType=\'application/vnd.google-apps.folder\' and trashed=false';

    final response = await _makeAuthenticatedRequest(
      (token) => http.get(
        Uri.parse(searchUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
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

    // Create the ScholarMate folder if it doesn't exist
    return await createAppFolder();
  }

  /// Create the ScholarMate app folder in Drive root
  Future<String> createAppFolder() async {
    final folderMetadata = {
      'name': _appFolderName,
      'mimeType': 'application/vnd.google-apps.folder',
    };

    final response = await _makeAuthenticatedRequest(
      (token) => http.post(
        Uri.parse('$_baseUrl/files'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(folderMetadata),
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _appFolderId = data['id'] as String;
      debugPrint('Created ScholarMate folder with ID: $_appFolderId');
      return _appFolderId!;
    } else {
      throw Exception(
        'Failed to create app folder: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// List files and folders in the specified folder (with offline support)
  Future<List<DriveFile>> listFiles([String? folderId]) async {
    // Use app folder if no folder ID specified
    final targetFolderId = folderId ?? await getAppFolderId();

    // If offline, return cached files
    if (!isOnline && _cacheService != null) {
      debugPrint(
        'Offline: Loading files from cache for folder $targetFolderId',
      );
      return await _cacheService.getCachedFiles(targetFolderId);
    }

    // Online: Fetch from Drive API
    try {
      // Query for files in the specified folder
      final query = '\'$targetFolderId\' in parents and trashed=false';
      final fields =
          'files(id,name,mimeType,size,parents,modifiedTime,createdTime,thumbnailLink,shared)';

      final url =
          '$_baseUrl/files?q=${Uri.encodeComponent(query)}&fields=$fields&orderBy=folder,name';

      final response = await _makeAuthenticatedRequest(
        (token) => http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final files = (data['files'] as List)
            .map((file) => DriveFile.fromJson(file as Map<String, dynamic>))
            .toList();

        // Sort folders first, then files
        files.sort((a, b) {
          if (a.isFolder && !b.isFolder) return -1;
          if (!a.isFolder && b.isFolder) return 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        // Cache the files if cache service is available
        if (_cacheService != null) {
          await _cacheService.cacheFileMetadataList(files);
        }

        return files;
      } else {
        throw Exception(
          'Failed to list files: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      // If online request fails and we have cache, fall back to cache
      if (_cacheService != null) {
        debugPrint('Error fetching files, falling back to cache: $e');
        return await _cacheService.getCachedFiles(targetFolderId);
      }
      rethrow;
    }
  }

  /// Upload a file to Google Drive (with offline queue support)
  Future<DriveFile> uploadFile(
    File file,
    String parentId, {
    String? customName,
    void Function(double progress)? onProgress,
  }) async {
    final fileName = customName ?? file.path.split('/').last;
    final fileBytes = await file.readAsBytes();

    // If offline, queue the upload
    if (!isOnline && _syncManager != null) {
      debugPrint('Offline: Queuing file upload for $fileName');

      await _syncManager!.queueAction(
        operationType: 'upload',
        resourceType: 'file',
        payload: {
          'file_bytes': fileBytes,
          'file_name': fileName,
          'parent_id': parentId,
        },
      );

      // Create a temporary DriveFile object with pending status
      final tempFile = DriveFile(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: fileName,
        parentId: parentId,
        size: fileBytes.length,
        createdTime: DateTime.now(),
        modifiedTime: DateTime.now(),
        syncStatus: 'pending',
      );

      // Cache the temporary file so it appears in the UI
      if (_cacheService != null) {
        await _cacheService.cacheFileMetadata(tempFile);
      }

      return tempFile;
    }

    // Online: Upload immediately
    // Determine MIME type based on file extension
    String mimeType = 'application/octet-stream';
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
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

    // Create multipart upload
    final boundary = 'dart-boundary-${DateTime.now().millisecondsSinceEpoch}';

    final metadata = {
      'name': fileName,
      'parents': [parentId],
    };

    final metadataPart =
        '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '${json.encode(metadata)}\r\n';

    final filePart =
        '--$boundary\r\n'
        'Content-Type: $mimeType\r\n\r\n';

    final endBoundary = '\r\n--$boundary--';

    // Combine all parts
    final metadataBytes = utf8.encode(metadataPart);
    final filePartBytes = utf8.encode(filePart);
    final endBoundaryBytes = utf8.encode(endBoundary);

    final totalBytes = Uint8List.fromList([
      ...metadataBytes,
      ...filePartBytes,
      ...fileBytes,
      ...endBoundaryBytes,
    ]);

    final response = await _makeAuthenticatedRequest(
      (token) => http.post(
        Uri.parse('$_uploadUrl/files?uploadType=multipart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/related; boundary=$boundary',
          'Content-Length': totalBytes.length.toString(),
        },
        body: totalBytes,
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DriveFile.fromJson(data);
    } else {
      throw Exception(
        'Failed to upload file: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Create a new folder (with offline queue support)
  Future<DriveFile> createFolder(String name, String parentId) async {
    // If offline, queue the folder creation
    if (!isOnline && _syncManager != null) {
      debugPrint('Offline: Queuing folder creation for $name');

      // Create a temporary DriveFile object
      final tempFolderId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final tempFolder = DriveFile(
        id: tempFolderId,
        name: name,
        parentId: parentId,
        isFolder: true,
        createdTime: DateTime.now(),
        modifiedTime: DateTime.now(),
        syncStatus: 'pending',
      );

      // Queue with the temp ID as resourceId so we can update references later
      await _syncManager!.queueAction(
        operationType: 'create',
        resourceType: 'folder',
        resourceId: tempFolderId,
        payload: {'name': name, 'parent_id': parentId},
      );

      // Cache the temporary folder
      if (_cacheService != null) {
        await _cacheService.cacheFileMetadata(tempFolder);
      }

      return tempFolder;
    }

    // Online: Create immediately
    final folderMetadata = {
      'name': name,
      'mimeType': 'application/vnd.google-apps.folder',
      'parents': [parentId],
    };

    final response = await _makeAuthenticatedRequest(
      (token) => http.post(
        Uri.parse('$_baseUrl/files'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(folderMetadata),
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final folder = DriveFile.fromJson(data);

      // Cache the folder
      if (_cacheService != null) {
        await _cacheService.cacheFileMetadata(folder);
      }

      return folder;
    } else {
      throw Exception(
        'Failed to create folder: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Delete a file or folder (with offline queue support)
  Future<void> deleteFile(String fileId) async {
    // If offline, queue the deletion
    if (!isOnline && _syncManager != null) {
      debugPrint('Offline: Queuing file deletion for $fileId');

      await _syncManager!.queueAction(
        operationType: 'delete',
        resourceType: 'file',
        resourceId: fileId,
        payload: {},
      );

      // Remove from cache
      if (_cacheService != null) {
        await _cacheService.deleteCachedFile(fileId);
      }

      return;
    }

    // Online: Delete immediately
    final response = await _makeAuthenticatedRequest(
      (token) => http.delete(
        Uri.parse('$_baseUrl/files/$fileId'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete file: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Rename a file or folder (with offline queue support)
  Future<DriveFile> renameFile(String fileId, String newName) async {
    // If offline, queue the rename
    if (!isOnline && _syncManager != null) {
      debugPrint('Offline: Queuing file rename for $fileId');

      await _syncManager!.queueAction(
        operationType: 'rename',
        resourceType: 'file',
        resourceId: fileId,
        payload: {'new_name': newName},
      );

      // Update cache
      if (_cacheService != null) {
        final cachedFile = await _cacheService.getCachedFile(fileId);
        if (cachedFile != null) {
          final updatedFile = cachedFile.copyWith(name: newName);
          await _cacheService.cacheFileMetadata(updatedFile);
          return updatedFile;
        }
      }

      // Return a temporary updated file
      return DriveFile(id: fileId, name: newName, modifiedTime: DateTime.now());
    }

    // Online: Rename immediately
    final updateData = {'name': newName};

    final response = await _makeAuthenticatedRequest(
      (token) => http.patch(
        Uri.parse('$_baseUrl/files/$fileId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final renamedFile = DriveFile.fromJson(data);

      // Update cache
      if (_cacheService != null) {
        await _cacheService.cacheFileMetadata(renamedFile);
      }

      return renamedFile;
    } else {
      throw Exception(
        'Failed to rename file: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Move a file or folder to a different parent (with offline queue support)
  Future<DriveFile> moveFile(String fileId, String newParentId) async {
    // If offline, queue the move
    if (!isOnline && _syncManager != null) {
      debugPrint('Offline: Queuing file move for $fileId');

      await _syncManager!.queueAction(
        operationType: 'move',
        resourceType: 'file',
        resourceId: fileId,
        payload: {'new_parent_id': newParentId},
      );

      // Update cache
      if (_cacheService != null) {
        final cachedFile = await _cacheService.getCachedFile(fileId);
        if (cachedFile != null) {
          final updatedFile = cachedFile.copyWith(parentId: newParentId);
          await _cacheService.cacheFileMetadata(updatedFile);
          return updatedFile;
        }
      }

      // Return a temporary updated file
      return DriveFile(
        id: fileId,
        parentId: newParentId,
        name: 'moved_file',
        modifiedTime: DateTime.now(),
      );
    }

    // Online: Move immediately
    // First get current parents
    final getResponse = await _makeAuthenticatedRequest(
      (token) => http.get(
        Uri.parse('$_baseUrl/files/$fileId?fields=parents'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (getResponse.statusCode != 200) {
      throw Exception('Failed to get file info: ${getResponse.statusCode}');
    }

    final currentData = json.decode(getResponse.body);
    final currentParents = (currentData['parents'] as List).join(',');

    // Move file by removing old parents and adding new parent
    final response = await _makeAuthenticatedRequest(
      (token) => http.patch(
        Uri.parse(
          '$_baseUrl/files/$fileId?addParents=$newParentId&removeParents=$currentParents',
        ),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DriveFile.fromJson(data);
    } else {
      throw Exception(
        'Failed to move file: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Download file content as bytes (with cache support and progress callback)
  /// If online, checks for updates before returning cached version
  Future<Uint8List?> downloadFile(
    String fileId, {
    void Function(double progress)? onProgress,
    bool forceRefresh = false,
  }) async {
    // If online, check if file has been updated on Drive
    if (isOnline && _cacheService != null && !forceRefresh) {
      try {
        final cachedFile = await _cacheService.getCachedFile(fileId);
        if (cachedFile != null) {
          // Get current file metadata from Drive
          final driveMetadata = await _getFileMetadata(fileId);

          if (driveMetadata != null &&
              driveMetadata.modifiedTime != null &&
              cachedFile.modifiedTime != null) {
            // Check if Drive version is newer
            if (driveMetadata.modifiedTime!.isAfter(cachedFile.modifiedTime!)) {
              debugPrint(
                'File updated on Drive, downloading fresh copy: $fileId',
              );
              forceRefresh = true;
            }
          }
        }
      } catch (e) {
        debugPrint('Error checking for file updates: $e');
        // Continue with normal flow
      }
    }

    // Check cache first (unless force refresh)
    if (!forceRefresh && _cacheService != null) {
      final cachedPdf = await _cacheService.getCachedPdf(fileId);
      if (cachedPdf != null) {
        debugPrint('Loading PDF from cache: $fileId');
        onProgress?.call(1.0);
        return cachedPdf;
      }
    }

    // If offline and not cached, throw error
    if (!isOnline) {
      throw Exception(
        'File not available offline. Please connect to download.',
      );
    }

    // Online: Download from Drive
    final response = await _makeAuthenticatedRequest(
      (token) => http.get(
        Uri.parse('$_baseUrl/files/$fileId?alt=media'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      onProgress?.call(1.0);

      // Cache the PDF if it's a PDF file
      if (_cacheService != null) {
        final file = await _cacheService.getCachedFile(fileId);
        if (file?.isPdf == true) {
          await _cacheService.cachePdfBytes(fileId, bytes);
          debugPrint('Cached PDF: $fileId (${bytes.length} bytes)');
        }
      }

      return bytes;
    } else {
      throw Exception(
        'Failed to download file: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Get file metadata from Google Drive
  Future<DriveFile?> _getFileMetadata(String fileId) async {
    try {
      final fields =
          'id,name,mimeType,size,parents,modifiedTime,createdTime,thumbnailLink,shared';
      final url = '$_baseUrl/files/$fileId?fields=$fields';

      final response = await _makeAuthenticatedRequest(
        (token) => http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DriveFile.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get file metadata: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting file metadata: $e');
      return null;
    }
  }

  /// Get cached file name by ID (for UI display)
  /// Returns null if file not found in cache
  /// This is async but can be called from build methods using FutureBuilder
  Future<String?> getCachedFileName(String fileId) async {
    try {
      final cachedFile = await _cacheService?.getCachedFile(fileId);
      return cachedFile?.name;
    } catch (e) {
      debugPrint('Error getting cached file name: $e');
      return null;
    }
  }

  /// Share a file with another user
  /// Returns the permission ID for the created permission
  Future<String> shareFile(String fileId, String email, String role) async {
    // Map our role names to Google Drive roles
    final driveRole = role == 'editor' ? 'writer' : 'reader';

    final permissionData = {
      'type': 'user',
      'role': driveRole,
      'emailAddress': email,
    };

    final response = await _makeAuthenticatedRequest(
      (token) => http.post(
        Uri.parse(
          '$_baseUrl/files/$fileId/permissions?sendNotificationEmail=true',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(permissionData),
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id'] as String;
    } else {
      throw Exception(
        'Failed to share file: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// List all permissions for a file
  Future<List<Map<String, dynamic>>> listFilePermissions(String fileId) async {
    final response = await _makeAuthenticatedRequest(
      (token) => http.get(
        Uri.parse(
          '$_baseUrl/files/$fileId/permissions?fields=permissions(id,emailAddress,role,type,displayName,photoLink)',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['permissions'] ?? []);
    } else {
      throw Exception(
        'Failed to list permissions: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Remove a permission from a file
  Future<void> removeFilePermission(String fileId, String permissionId) async {
    final response = await _makeAuthenticatedRequest(
      (token) => http.delete(
        Uri.parse('$_baseUrl/files/$fileId/permissions/$permissionId'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to remove permission: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Create a public link for a file
  Future<String> createPublicLink(String fileId) async {
    final permissionData = {'type': 'anyone', 'role': 'reader'};

    final response = await _makeAuthenticatedRequest(
      (token) => http.post(
        Uri.parse('$_baseUrl/files/$fileId/permissions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(permissionData),
      ),
    );

    if (response.statusCode == 200) {
      return 'https://drive.google.com/file/d/$fileId/view';
    } else {
      throw Exception(
        'Failed to create public link: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Upload file from bytes (for web compatibility)
  Future<DriveFile> uploadFileFromBytes(
    Uint8List fileBytes,
    String fileName,
    String parentId, {
    void Function(double progress)? onProgress,
  }) async {
    // Determine MIME type based on file extension
    String mimeType = 'application/octet-stream';
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
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

    // Create multipart upload
    final boundary = 'dart-boundary-${DateTime.now().millisecondsSinceEpoch}';

    final metadata = {
      'name': fileName,
      'parents': [parentId],
    };

    final metadataPart =
        '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '${json.encode(metadata)}\r\n';

    final filePart =
        '--$boundary\r\n'
        'Content-Type: $mimeType\r\n\r\n';

    final endBoundary = '\r\n--$boundary--';

    // Combine all parts
    final metadataBytes = utf8.encode(metadataPart);
    final filePartBytes = utf8.encode(filePart);
    final endBoundaryBytes = utf8.encode(endBoundary);

    final totalBytes = Uint8List.fromList([
      ...metadataBytes,
      ...filePartBytes,
      ...fileBytes,
      ...endBoundaryBytes,
    ]);

    final response = await _makeAuthenticatedRequest(
      (token) => http.post(
        Uri.parse('$_uploadUrl/files?uploadType=multipart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/related; boundary=$boundary',
          'Content-Length': totalBytes.length.toString(),
        },
        body: totalBytes,
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DriveFile.fromJson(data);
    } else {
      throw Exception(
        'Failed to upload file: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Update an existing file in Google Drive with new content
  Future<DriveFile> updateFile(
    String fileId,
    Uint8List fileBytes,
    String fileName, {
    void Function(double progress)? onProgress,
  }) async {
    // Determine MIME type based on file extension
    String mimeType = 'application/octet-stream';
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
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

    // Update file content using PATCH with uploadType=media
    final response = await _makeAuthenticatedRequest(
      (token) => http.patch(
        Uri.parse('$_uploadUrl/files/$fileId?uploadType=media'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': mimeType,
          'Content-Length': fileBytes.length.toString(),
        },
        body: fileBytes,
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DriveFile.fromJson(data);
    } else {
      throw Exception(
        'Failed to update file: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Clear cached app folder ID (useful for testing or when folder is deleted)
  void clearAppFolderCache() {
    _appFolderId = null;
  }

  /// List all files recursively from the app folder
  Future<List<DriveFile>> listAllFiles() async {
    final allFiles = <DriveFile>[];
    final appFolderId = await getAppFolderId();

    await _listFilesRecursive(appFolderId, allFiles);

    return allFiles;
  }

  /// Helper method to recursively list files
  Future<void> _listFilesRecursive(
    String folderId,
    List<DriveFile> accumulator,
  ) async {
    try {
      final files = await listFiles(folderId);

      for (final file in files) {
        if (file.isFolder) {
          // Recursively list files in subfolder
          await _listFilesRecursive(file.id, accumulator);
        } else {
          // Add file to accumulator
          accumulator.add(file);
        }
      }
    } catch (e) {
      debugPrint('Error listing files in folder $folderId: $e');
    }
  }

  /// Download file content as string (for text files like markdown)
  Future<String> downloadFileAsString(String fileId) async {
    final bytes = await downloadFile(fileId);
    if (bytes == null) {
      throw Exception('Failed to download file content');
    }
    return utf8.decode(bytes);
  }

  /// Update file content on Google Drive (for text files)
  Future<void> updateFileContent(
    String fileId,
    String content, {
    String? newName,
  }) async {
    if (!isOnline) {
      throw Exception('Cannot update file while offline');
    }

    try {
      // Prepare the request body
      final boundary = 'boundary_${DateTime.now().millisecondsSinceEpoch}';

      // Build multipart request
      final requestBody = StringBuffer();

      // Metadata part
      requestBody.write('--$boundary\r\n');
      requestBody.write(
        'Content-Type: application/json; charset=UTF-8\r\n\r\n',
      );

      final metadata = <String, dynamic>{};
      if (newName != null) {
        metadata['name'] = newName;
      }

      requestBody.write(jsonEncode(metadata));
      requestBody.write('\r\n');

      // Content part
      requestBody.write('--$boundary\r\n');
      requestBody.write('Content-Type: text/markdown\r\n\r\n');
      requestBody.write(content);
      requestBody.write('\r\n--$boundary--\r\n');

      final url = '$_uploadUrl/files/$fileId?uploadType=multipart';

      final response = await _makeAuthenticatedRequest(
        (token) => http.patch(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/related; boundary=$boundary',
          },
          body: requestBody.toString(),
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('File updated successfully: $fileId');

        // Clear cache for this file to force refresh
        if (_cacheService != null) {
          await _cacheService.deleteCachedFile(fileId);
        }

        notifyListeners();
      } else {
        throw Exception(
          'Failed to update file: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error updating file content: $e');
      rethrow;
    }
  }
}
