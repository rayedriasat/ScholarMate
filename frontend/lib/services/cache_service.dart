import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/drive_file.dart';

/// Service for managing local SQLite cache
class CacheService extends ChangeNotifier {
  static const String _databaseName = 'scholarmate_cache.db';
  static const int _databaseVersion = 2;

  Database? _database;

  /// Get database instance, initializing if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize SQLite database with schema
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Files table - stores file/folder metadata
    await db.execute('''
      CREATE TABLE files (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        mime_type TEXT,
        size INTEGER,
        parent_id TEXT,
        modified_time TEXT,
        created_time TEXT,
        thumbnail_link TEXT,
        is_folder INTEGER NOT NULL,
        is_shared INTEGER NOT NULL,
        is_cached INTEGER DEFAULT 0,
        last_synced TEXT
      )
    ''');

    // Cached PDFs table - stores actual PDF file bytes
    await db.execute('''
      CREATE TABLE cached_pdfs (
        file_id TEXT PRIMARY KEY,
        pdf_bytes BLOB NOT NULL,
        cached_at TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        FOREIGN KEY (file_id) REFERENCES files (id) ON DELETE CASCADE
      )
    ''');

    // Annotations table - stores PDF annotations
    await db.execute('''
      CREATE TABLE annotations (
        id TEXT PRIMARY KEY,
        file_id TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        annotation_type TEXT NOT NULL,
        content TEXT,
        position TEXT,
        color TEXT,
        created_at TEXT NOT NULL,
        modified_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (file_id) REFERENCES files (id) ON DELETE CASCADE
      )
    ''');

    // Sync queue table - stores offline operations
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL,
        resource_type TEXT NOT NULL,
        resource_id TEXT,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT,
        status TEXT DEFAULT 'pending'
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_files_parent ON files(parent_id)');
    await db.execute(
      'CREATE INDEX idx_annotations_file ON annotations(file_id)',
    );
    await db.execute(
      'CREATE INDEX idx_sync_queue_status ON sync_queue(status)',
    );
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 2: Remove parents column (redundant with parent_id)
      // SQLite doesn't support DROP COLUMN, so we need to recreate the table
      await db.execute('ALTER TABLE files RENAME TO files_old');

      await db.execute('''
        CREATE TABLE files (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          mime_type TEXT,
          size INTEGER,
          parent_id TEXT,
          modified_time TEXT,
          created_time TEXT,
          thumbnail_link TEXT,
          is_folder INTEGER NOT NULL,
          is_shared INTEGER NOT NULL,
          is_cached INTEGER DEFAULT 0,
          last_synced TEXT
        )
      ''');

      await db.execute('''
        INSERT INTO files (id, name, mime_type, size, parent_id, modified_time, 
                          created_time, thumbnail_link, is_folder, is_shared, 
                          is_cached, last_synced)
        SELECT id, name, mime_type, size, parent_id, modified_time, 
               created_time, thumbnail_link, is_folder, is_shared, 
               is_cached, last_synced
        FROM files_old
      ''');

      await db.execute('DROP TABLE files_old');
      await db.execute('CREATE INDEX idx_files_parent ON files(parent_id)');
    }
  }

  /// Cache file metadata
  Future<void> cacheFileMetadata(DriveFile file) async {
    final db = await database;

    await db.insert('files', {
      'id': file.id,
      'name': file.name,
      'mime_type': file.mimeType,
      'size': file.size,
      'parent_id': file.parentId,
      'modified_time': file.modifiedTime?.toIso8601String(),
      'created_time': file.createdTime?.toIso8601String(),
      'thumbnail_link': file.thumbnailLink,
      'is_folder': file.isFolder ? 1 : 0,
      'is_shared': file.isShared ? 1 : 0,
      'is_cached': 0,
      'last_synced': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    notifyListeners();
  }

  /// Cache multiple file metadata entries
  Future<void> cacheFileMetadataList(List<DriveFile> files) async {
    final db = await database;
    final batch = db.batch();

    for (final file in files) {
      batch.insert('files', {
        'id': file.id,
        'name': file.name,
        'mime_type': file.mimeType,
        'size': file.size,
        'parent_id': file.parentId,
        'modified_time': file.modifiedTime?.toIso8601String(),
        'created_time': file.createdTime?.toIso8601String(),
        'thumbnail_link': file.thumbnailLink,
        'is_folder': file.isFolder ? 1 : 0,
        'is_shared': file.isShared ? 1 : 0,
        'is_cached': 0,
        'last_synced': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
    notifyListeners();
  }

  /// Get cached files for a specific folder
  Future<List<DriveFile>> getCachedFiles([String? parentId]) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'files',
      where: parentId != null ? 'parent_id = ?' : 'parent_id IS NULL',
      whereArgs: parentId != null ? [parentId] : null,
      orderBy: 'is_folder DESC, name ASC',
    );

    return maps.map((map) => _driveFileFromMap(map)).toList();
  }

  /// Get a specific cached file by ID
  Future<DriveFile?> getCachedFile(String fileId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'files',
      where: 'id = ?',
      whereArgs: [fileId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _driveFileFromMap(maps.first);
  }

  /// Cache PDF file bytes
  Future<void> cachePdfBytes(String fileId, Uint8List pdfBytes) async {
    final db = await database;

    await db.insert('cached_pdfs', {
      'file_id': fileId,
      'pdf_bytes': pdfBytes,
      'cached_at': DateTime.now().toIso8601String(),
      'file_size': pdfBytes.length,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Update file metadata to mark as cached
    await db.update(
      'files',
      {'is_cached': 1},
      where: 'id = ?',
      whereArgs: [fileId],
    );

    notifyListeners();
  }

  /// Get cached PDF bytes
  Future<Uint8List?> getCachedPdf(String fileId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'cached_pdfs',
      where: 'file_id = ?',
      whereArgs: [fileId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first['pdf_bytes'] as Uint8List;
  }

  /// Check if a PDF is cached
  Future<bool> isPdfCached(String fileId) async {
    final db = await database;

    final result = await db.query(
      'cached_pdfs',
      where: 'file_id = ?',
      whereArgs: [fileId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Cache annotation
  Future<void> cacheAnnotation(Map<String, dynamic> annotation) async {
    final db = await database;

    await db.insert('annotations', {
      'id': annotation['id'],
      'file_id': annotation['file_id'],
      'page_number': annotation['page_number'],
      'annotation_type': annotation['annotation_type'],
      'content': annotation['content'],
      'position': json.encode(annotation['position']),
      'color': annotation['color'],
      'created_at': annotation['created_at'],
      'modified_at': annotation['modified_at'],
      'is_synced': annotation['is_synced'] ?? 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    notifyListeners();
  }

  /// Get cached annotations for a file
  Future<List<Map<String, dynamic>>> getCachedAnnotations(String fileId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'annotations',
      where: 'file_id = ?',
      whereArgs: [fileId],
      orderBy: 'page_number ASC, created_at ASC',
    );

    return maps.map((map) {
      return {
        'id': map['id'],
        'file_id': map['file_id'],
        'page_number': map['page_number'],
        'annotation_type': map['annotation_type'],
        'content': map['content'],
        'position': json.decode(map['position'] as String),
        'color': map['color'],
        'created_at': map['created_at'],
        'modified_at': map['modified_at'],
        'is_synced': map['is_synced'],
      };
    }).toList();
  }

  /// Get unsynced annotations
  Future<List<Map<String, dynamic>>> getUnsyncedAnnotations() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'annotations',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return maps;
  }

  /// Mark annotation as synced
  Future<void> markAnnotationSynced(String annotationId) async {
    final db = await database;

    await db.update(
      'annotations',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [annotationId],
    );

    notifyListeners();
  }

  /// Delete cached file and related data
  Future<void> deleteCachedFile(String fileId) async {
    final db = await database;

    // Delete file metadata (cascades to cached_pdfs and annotations)
    await db.delete('files', where: 'id = ?', whereArgs: [fileId]);

    notifyListeners();
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    final db = await database;

    await db.delete('cached_pdfs');
    await db.delete('annotations');
    await db.delete('files');
    await db.delete('sync_queue');

    notifyListeners();
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final db = await database;

    final fileCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM files'),
        ) ??
        0;

    final cachedPdfCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM cached_pdfs'),
        ) ??
        0;

    final annotationCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM annotations'),
        ) ??
        0;

    final totalSize =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT SUM(file_size) FROM cached_pdfs'),
        ) ??
        0;

    return {
      'file_count': fileCount,
      'cached_pdf_count': cachedPdfCount,
      'annotation_count': annotationCount,
      'total_cache_size': totalSize,
    };
  }

  /// Convert database map to DriveFile
  DriveFile _driveFileFromMap(Map<String, dynamic> map) {
    return DriveFile(
      id: map['id'] as String,
      name: map['name'] as String,
      mimeType: map['mime_type'] as String?,
      size: map['size'] as int?,
      parentId: map['parent_id'] as String?,
      modifiedTime: map['modified_time'] != null
          ? DateTime.parse(map['modified_time'] as String)
          : null,
      createdTime: map['created_time'] != null
          ? DateTime.parse(map['created_time'] as String)
          : null,
      thumbnailLink: map['thumbnail_link'] as String?,
      isFolder: (map['is_folder'] as int) == 1,
      isShared: (map['is_shared'] as int) == 1,
    );
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
