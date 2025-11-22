import 'package:flutter/material.dart';
import '../models/drive_file.dart';
import 'auth_service.dart';
import 'sharing_service.dart';

/// Enum for file permissions
enum FilePermission { owner, editor, viewer, none }

/// Service for checking and enforcing file permissions
class PermissionService extends ChangeNotifier {
  final AuthService _authService;
  final SharingService _sharingService;

  // Cache of file permissions
  final Map<String, FilePermission> _permissionCache = {};

  PermissionService({AuthService? authService, SharingService? sharingService})
    : _authService = authService ?? AuthService(),
      _sharingService = sharingService ?? SharingService();

  /// Get permission level for a file
  Future<FilePermission> getFilePermission(DriveFile file) async {
    // Check cache first
    if (_permissionCache.containsKey(file.id)) {
      return _permissionCache[file.id]!;
    }

    final user = _authService.currentUser;
    if (user == null) {
      return FilePermission.none;
    }

    // If file is not shared, user is the owner
    if (!file.isShared) {
      _permissionCache[file.id] = FilePermission.owner;
      return FilePermission.owner;
    }

    // Check if user is in the collaborators list
    try {
      final collaborators = await _sharingService.listCollaborators(file.id);

      // Check if current user is a collaborator
      final userCollaborator = collaborators.firstWhere(
        (c) => c.email == user.email,
        orElse: () => throw Exception('Not found'),
      );

      final permission = userCollaborator.role == 'editor'
          ? FilePermission.editor
          : FilePermission.viewer;

      _permissionCache[file.id] = permission;
      return permission;
    } catch (e) {
      // If not in collaborators list, assume owner
      _permissionCache[file.id] = FilePermission.owner;
      return FilePermission.owner;
    }
  }

  /// Check if user can edit a file
  Future<bool> canEdit(DriveFile file) async {
    final permission = await getFilePermission(file);
    return permission == FilePermission.owner ||
        permission == FilePermission.editor;
  }

  /// Check if user can view a file
  Future<bool> canView(DriveFile file) async {
    final permission = await getFilePermission(file);
    return permission != FilePermission.none;
  }

  /// Check if user can share a file
  Future<bool> canShare(DriveFile file) async {
    final permission = await getFilePermission(file);
    return permission == FilePermission.owner ||
        permission == FilePermission.editor;
  }

  /// Check if user can delete a file
  Future<bool> canDelete(DriveFile file) async {
    final permission = await getFilePermission(file);
    return permission == FilePermission.owner;
  }

  /// Check if user can annotate a file
  Future<bool> canAnnotate(DriveFile file) async {
    final permission = await getFilePermission(file);
    return permission == FilePermission.owner ||
        permission == FilePermission.editor;
  }

  /// Check if user is the owner of a file
  Future<bool> isOwner(DriveFile file) async {
    final permission = await getFilePermission(file);
    return permission == FilePermission.owner;
  }

  /// Clear permission cache for a file
  void clearCache(String fileId) {
    _permissionCache.remove(fileId);
    notifyListeners();
  }

  /// Clear all permission cache
  void clearAllCache() {
    _permissionCache.clear();
    notifyListeners();
  }

  /// Get permission label for display
  String getPermissionLabel(FilePermission permission) {
    switch (permission) {
      case FilePermission.owner:
        return 'Owner';
      case FilePermission.editor:
        return 'Editor';
      case FilePermission.viewer:
        return 'Viewer';
      case FilePermission.none:
        return 'No Access';
    }
  }

  /// Get permission icon
  IconData getPermissionIcon(FilePermission permission) {
    switch (permission) {
      case FilePermission.owner:
        return Icons.admin_panel_settings;
      case FilePermission.editor:
        return Icons.edit;
      case FilePermission.viewer:
        return Icons.visibility;
      case FilePermission.none:
        return Icons.block;
    }
  }
}
