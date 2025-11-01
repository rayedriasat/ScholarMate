import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/drive_file.dart';
import '../widgets/sharing_dialog.dart';
import 'auth_service.dart';
import 'config_service.dart';

/// Service for managing file sharing and collaboration
class SharingService extends ChangeNotifier {
  final AuthService _authService;
  final ConfigService _configService = ConfigService();

  String get _baseUrl => _configService.apiBaseUrl;

  SharingService({AuthService? authService})
    : _authService = authService ?? AuthService();

  /// Share a file or folder with another user
  Future<void> shareFile({
    required String driveFileId,
    required String fileName,
    required String mimeType,
    required String sharedWithEmail,
    required String permission,
    required bool isFolder,
    int? sizeBytes,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final requestBody = {
      'user_id': user.id,
      'drive_file_id': driveFileId,
      'file_name': fileName,
      'mime_type': mimeType,
      'shared_with_email': sharedWithEmail,
      'permission': permission,
      'is_folder': isFolder,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/api/sharing/share'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to share file');
    }

    debugPrint('File shared successfully with $sharedWithEmail');
  }

  /// Remove a share (revoke access)
  Future<void> removeShare({
    required String driveFileId,
    required String sharedWithEmail,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final requestBody = {
      'user_id': user.id,
      'drive_file_id': driveFileId,
      'shared_with_email': sharedWithEmail,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/api/sharing/remove'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to remove share');
    }

    debugPrint('Share removed for $sharedWithEmail');
  }

  /// List all collaborators for a file
  Future<List<Collaborator>> listCollaborators(String driveFileId) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/api/sharing/list/${user.id}/$driveFileId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to list collaborators');
    }

    final data = json.decode(response.body);
    final collaborators = <Collaborator>[];

    for (final item in data['collaborators']) {
      collaborators.add(
        Collaborator(
          email: item['email'],
          role: item['permission'],
          name: item['name'],
          pictureUrl: item['picture_url'],
          sharedAt: DateTime.parse(item['shared_at']),
        ),
      );
    }

    return collaborators;
  }

  /// List all files shared with the current user
  Future<List<SharedFileInfo>> listSharedWithMe() async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/api/sharing/shared-with-me/${user.id}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to list shared files');
    }

    final data = json.decode(response.body);
    final sharedFiles = <SharedFileInfo>[];

    for (final item in data['shared_files']) {
      sharedFiles.add(
        SharedFileInfo(
          driveFileId: item['drive_file_id'],
          name: item['name'],
          mimeType: item['mime_type'],
          sizeBytes: item['size_bytes'],
          isFolder: item['is_folder'] ?? false,
          permission: item['permission'],
          ownerName: item['owner_name'],
          ownerEmail: item['owner_email'],
          sharedAt: DateTime.parse(item['shared_at']),
        ),
      );
    }

    return sharedFiles;
  }
}

/// Model representing a file shared with the user
class SharedFileInfo {
  final String driveFileId;
  final String name;
  final String mimeType;
  final int? sizeBytes;
  final bool isFolder;
  final String permission;
  final String? ownerName;
  final String? ownerEmail;
  final DateTime sharedAt;

  SharedFileInfo({
    required this.driveFileId,
    required this.name,
    required this.mimeType,
    this.sizeBytes,
    required this.isFolder,
    required this.permission,
    this.ownerName,
    this.ownerEmail,
    required this.sharedAt,
  });

  /// Convert to DriveFile for display
  DriveFile toDriveFile() {
    return DriveFile(
      id: driveFileId,
      name: name,
      mimeType: mimeType,
      size: sizeBytes,
      isFolder: isFolder,
      isShared: true,
      modifiedTime: sharedAt,
    );
  }
}
