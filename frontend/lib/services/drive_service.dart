import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/drive_file.dart';
import 'auth_service.dart';

/// Service for interacting with Google Drive API
class DriveService extends ChangeNotifier {
  static const String _baseUrl = 'https://www.googleapis.com/drive/v3';
  static const String _uploadUrl = 'https://www.googleapis.com/upload/drive/v3';
  static const String _appFolderName = 'ScholarMate';

  final AuthService _authService;
  String? _appFolderId;

  DriveService({AuthService? authService})
    : _authService = authService ?? AuthService();

  /// Get access token with retry logic
  Future<String> _getAccessToken() async {
    // First try to get current token (uses cache if valid)
    var accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      debugPrint('No access token available, attempting to refresh...');
      accessToken = await _authService.refreshToken();

      if (accessToken == null) {
        throw Exception('No access token available. Please sign in again.');
      }
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
      debugPrint('Access token expired, refreshing...');

      final newToken = await _authService.refreshToken();
      if (newToken != null) {
        response = await requestFunction(newToken);
      } else {
        throw Exception(
          'Unable to refresh access token. Please sign in again.',
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
    final accessToken = await _getAccessToken();

    final folderMetadata = {
      'name': _appFolderName,
      'mimeType': 'application/vnd.google-apps.folder',
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/files'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(folderMetadata),
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

  /// List files and folders in the specified folder
  Future<List<DriveFile>> listFiles([String? folderId]) async {
    // Use app folder if no folder ID specified
    final targetFolderId = folderId ?? await getAppFolderId();

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

      return files;
    } else {
      throw Exception(
        'Failed to list files: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Upload a file to Google Drive
  Future<DriveFile> uploadFile(
    File file,
    String parentId, {
    String? customName,
    void Function(double progress)? onProgress,
  }) async {
    final accessToken = await _getAccessToken();

    final fileName = customName ?? file.path.split('/').last;
    final fileBytes = await file.readAsBytes();

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

    final response = await http.post(
      Uri.parse('$_uploadUrl/files?uploadType=multipart'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'multipart/related; boundary=$boundary',
        'Content-Length': totalBytes.length.toString(),
      },
      body: totalBytes,
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

  /// Create a new folder
  Future<DriveFile> createFolder(String name, String parentId) async {
    final accessToken = await _getAccessToken();

    final folderMetadata = {
      'name': name,
      'mimeType': 'application/vnd.google-apps.folder',
      'parents': [parentId],
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/files'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(folderMetadata),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DriveFile.fromJson(data);
    } else {
      throw Exception(
        'Failed to create folder: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Delete a file or folder (move to trash)
  Future<void> deleteFile(String fileId) async {
    final accessToken = await _getAccessToken();

    final response = await http.delete(
      Uri.parse('$_baseUrl/files/$fileId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete file: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Rename a file or folder
  Future<DriveFile> renameFile(String fileId, String newName) async {
    final accessToken = await _getAccessToken();

    final updateData = {'name': newName};

    final response = await http.patch(
      Uri.parse('$_baseUrl/files/$fileId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(updateData),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DriveFile.fromJson(data);
    } else {
      throw Exception(
        'Failed to rename file: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Move a file or folder to a different parent
  Future<DriveFile> moveFile(String fileId, String newParentId) async {
    final accessToken = await _getAccessToken();

    // First get current parents
    final getResponse = await http.get(
      Uri.parse('$_baseUrl/files/$fileId?fields=parents'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (getResponse.statusCode != 200) {
      throw Exception('Failed to get file info: ${getResponse.statusCode}');
    }

    final currentData = json.decode(getResponse.body);
    final currentParents = (currentData['parents'] as List).join(',');

    // Move file by removing old parents and adding new parent
    final response = await http.patch(
      Uri.parse(
        '$_baseUrl/files/$fileId?addParents=$newParentId&removeParents=$currentParents',
      ),
      headers: {'Authorization': 'Bearer $accessToken'},
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

  /// Download file content as bytes
  Future<Uint8List> downloadFile(String fileId) async {
    final accessToken = await _getAccessToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/files/$fileId?alt=media'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception(
        'Failed to download file: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Share a file with another user
  Future<void> shareFile(String fileId, String email, String role) async {
    final accessToken = await _getAccessToken();

    final permissionData = {
      'type': 'user',
      'role': role, // 'reader' or 'writer'
      'emailAddress': email,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/files/$fileId/permissions'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(permissionData),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to share file: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Create a public link for a file
  Future<String> createPublicLink(String fileId) async {
    final accessToken = await _getAccessToken();

    final permissionData = {'type': 'anyone', 'role': 'reader'};

    final response = await http.post(
      Uri.parse('$_baseUrl/files/$fileId/permissions'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(permissionData),
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
    final accessToken = await _getAccessToken();

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

    final response = await http.post(
      Uri.parse('$_uploadUrl/files?uploadType=multipart'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'multipart/related; boundary=$boundary',
        'Content-Length': totalBytes.length.toString(),
      },
      body: totalBytes,
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

  /// Clear cached app folder ID (useful for testing or when folder is deleted)
  void clearAppFolderCache() {
    _appFolderId = null;
  }
}
