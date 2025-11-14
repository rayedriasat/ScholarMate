import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../models/drive_file.dart';

/// Service for managing local Drift cache (cross-platform including web)
class CacheService extends ChangeNotifier {
  late final AppDatabase _database;

  CacheService() {
    try {
      debugPrint('Initializing database...');
      _database = AppDatabase();
      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('ERROR: Failed to initialize database: $e');
      rethrow;
    }
  }

  /// Get database instance
  AppDatabase get database => _database;

  /// Cache file metadata
  Future<void> cacheFileMetadata(DriveFile file) async {
    await _database.insertFile(
      FilesCompanion(
        id: drift.Value(file.id),
        name: drift.Value(file.name),
        mimeType: drift.Value(file.mimeType),
        size: drift.Value(file.size),
        parentId: drift.Value(file.parentId),
        modifiedTime: drift.Value(file.modifiedTime),
        createdTime: drift.Value(file.createdTime),
        thumbnailLink: drift.Value(file.thumbnailLink),
        isFolder: drift.Value(file.isFolder),
        isShared: drift.Value(file.isShared),
        isCached: const drift.Value(false),
        lastSynced: drift.Value(DateTime.now()),
        syncStatus: drift.Value(file.syncStatus),
      ),
    );

    notifyListeners();
  }

  /// Cache multiple file metadata entries
  Future<void> cacheFileMetadataList(List<DriveFile> files) async {
    final fileCompanions = files.map((file) {
      return FilesCompanion(
        id: drift.Value(file.id),
        name: drift.Value(file.name),
        mimeType: drift.Value(file.mimeType),
        size: drift.Value(file.size),
        parentId: drift.Value(file.parentId),
        modifiedTime: drift.Value(file.modifiedTime),
        createdTime: drift.Value(file.createdTime),
        thumbnailLink: drift.Value(file.thumbnailLink),
        isFolder: drift.Value(file.isFolder),
        isShared: drift.Value(file.isShared),
        isCached: const drift.Value(false),
        lastSynced: drift.Value(DateTime.now()),
        syncStatus: drift.Value(file.syncStatus),
      );
    }).toList();

    await _database.insertFiles(fileCompanions);
    notifyListeners();
  }

  /// Get cached files for a specific folder
  Future<List<DriveFile>> getCachedFiles([String? parentId]) async {
    final files = await _database.getFiles(parentId);
    return files.map((file) => _driveFileFromDrift(file)).toList();
  }

  /// Get a specific cached file by ID
  Future<DriveFile?> getCachedFile(String fileId) async {
    final file = await _database.getFile(fileId);
    if (file == null) return null;
    return _driveFileFromDrift(file);
  }

  /// Cache PDF file bytes
  Future<void> cachePdfBytes(String fileId, Uint8List pdfBytes) async {
    await _database.insertCachedPdf(
      CachedPdfsCompanion(
        fileId: drift.Value(fileId),
        pdfBytes: drift.Value(pdfBytes),
        cachedAt: drift.Value(DateTime.now()),
        fileSize: drift.Value(pdfBytes.length),
      ),
    );

    // Update file metadata to mark as cached
    await _database.updateFile(
      FilesCompanion(
        id: drift.Value(fileId),
        isCached: const drift.Value(true),
      ),
    );

    notifyListeners();
  }

  /// Get cached PDF bytes
  Future<Uint8List?> getCachedPdf(String fileId) async {
    final cachedPdf = await _database.getCachedPdf(fileId);
    return cachedPdf?.pdfBytes;
  }

  /// Check if a PDF is cached
  Future<bool> isPdfCached(String fileId) async {
    return await _database.isPdfCached(fileId);
  }

  /// Cache annotation
  Future<void> cacheAnnotation(Map<String, dynamic> annotation) async {
    await _database.insertAnnotation(
      AnnotationsCompanion(
        id: drift.Value(annotation['id'] as String),
        fileId: drift.Value(annotation['file_id'] as String),
        pageNumber: drift.Value(annotation['page_number'] as int),
        annotationType: drift.Value(annotation['annotation_type'] as String),
        content: drift.Value(annotation['content'] as String?),
        position: drift.Value(
          annotation['position'] != null
              ? json.encode(annotation['position'])
              : null,
        ),
        color: drift.Value(annotation['color'] as String?),
        createdAt: drift.Value(
          annotation['created_at'] is String
              ? DateTime.parse(annotation['created_at'] as String)
              : annotation['created_at'] as DateTime,
        ),
        modifiedAt: drift.Value(
          annotation['modified_at'] is String
              ? DateTime.parse(annotation['modified_at'] as String)
              : annotation['modified_at'] as DateTime,
        ),
        isSynced: drift.Value(
          (annotation['is_synced'] as int? ?? 0) == 1 ? true : false,
        ),
      ),
    );

    notifyListeners();
  }

  /// Get cached annotations for a file
  Future<List<Map<String, dynamic>>> getCachedAnnotations(String fileId) async {
    final annotations = await _database.getAnnotations(fileId);

    return annotations.map((annotation) {
      return {
        'id': annotation.id,
        'file_id': annotation.fileId,
        'page_number': annotation.pageNumber,
        'annotation_type': annotation.annotationType,
        'content': annotation.content,
        'position': annotation.position != null
            ? json.decode(annotation.position!)
            : null,
        'color': annotation.color,
        'created_at': annotation.createdAt.toIso8601String(),
        'modified_at': annotation.modifiedAt.toIso8601String(),
        'is_synced': annotation.isSynced ? 1 : 0,
      };
    }).toList();
  }

  /// Get unsynced annotations
  Future<List<Map<String, dynamic>>> getUnsyncedAnnotations() async {
    final annotations = await _database.getUnsyncedAnnotations();

    return annotations.map((annotation) {
      return {
        'id': annotation.id,
        'file_id': annotation.fileId,
        'page_number': annotation.pageNumber,
        'annotation_type': annotation.annotationType,
        'content': annotation.content,
        'position': annotation.position != null
            ? json.decode(annotation.position!)
            : null,
        'color': annotation.color,
        'created_at': annotation.createdAt.toIso8601String(),
        'modified_at': annotation.modifiedAt.toIso8601String(),
        'is_synced': annotation.isSynced ? 1 : 0,
      };
    }).toList();
  }

  /// Mark annotation as synced
  Future<void> markAnnotationSynced(String annotationId) async {
    await _database.markAnnotationSynced(annotationId);
    notifyListeners();
  }

  /// Delete cached file and related data
  Future<void> deleteCachedFile(String fileId) async {
    // Delete related data first
    await _database.deleteCachedPdf(fileId);

    // Get and delete annotations
    final annotations = await _database.getAnnotations(fileId);
    for (final annotation in annotations) {
      await _database.deleteAnnotation(annotation.id);
    }

    // Delete file metadata
    await _database.deleteFile(fileId);

    notifyListeners();
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    await _database.clearAllCache();
    notifyListeners();
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final stats = await _database.getCacheStats();
    return stats;
  }

  /// Convert Drift File to DriveFile
  DriveFile _driveFileFromDrift(File file) {
    return DriveFile(
      id: file.id,
      name: file.name,
      mimeType: file.mimeType,
      size: file.size,
      parentId: file.parentId,
      modifiedTime: file.modifiedTime,
      createdTime: file.createdTime,
      thumbnailLink: file.thumbnailLink,
      isFolder: file.isFolder,
      isShared: file.isShared,
      syncStatus: file.syncStatus,
    );
  }

  /// Close database connection
  Future<void> close() async {
    await _database.close();
  }
}
