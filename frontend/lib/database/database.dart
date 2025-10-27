import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'database.g.dart';

/// Main database class for ScholarMate
/// Supports all platforms including web using Drift
@DriftDatabase(tables: [Files, CachedPdfs, Annotations, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Constructor for testing with custom executor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Migration from version 1 to 2
          // Add any schema changes here if needed
        }
        if (from < 3) {
          // Migration from version 2 to 3: Add author fields to annotations
          await m.addColumn(annotations, annotations.authorId);
          await m.addColumn(annotations, annotations.authorName);
        }
      },
    );
  }

  // File operations
  Future<List<File>> getFiles([String? parentId]) {
    if (parentId != null) {
      return (select(files)
            ..where((f) => f.parentId.equals(parentId))
            ..orderBy([
              (f) =>
                  OrderingTerm(expression: f.isFolder, mode: OrderingMode.desc),
              (f) => OrderingTerm(expression: f.name),
            ]))
          .get();
    } else {
      return (select(files)
            ..where((f) => f.parentId.isNull())
            ..orderBy([
              (f) =>
                  OrderingTerm(expression: f.isFolder, mode: OrderingMode.desc),
              (f) => OrderingTerm(expression: f.name),
            ]))
          .get();
    }
  }

  Future<File?> getFile(String fileId) {
    return (select(files)..where((f) => f.id.equals(fileId))).getSingleOrNull();
  }

  Future<int> insertFile(FilesCompanion file) {
    return into(files).insert(file, mode: InsertMode.insertOrReplace);
  }

  Future<void> insertFiles(List<FilesCompanion> fileList) async {
    await batch((batch) {
      batch.insertAll(files, fileList, mode: InsertMode.insertOrReplace);
    });
  }

  Future<int> updateFile(FilesCompanion file) {
    return (update(
      files,
    )..where((f) => f.id.equals(file.id.value))).write(file);
  }

  Future<int> deleteFile(String fileId) {
    return (delete(files)..where((f) => f.id.equals(fileId))).go();
  }

  // Cached PDF operations
  Future<CachedPdf?> getCachedPdf(String fileId) {
    return (select(
      cachedPdfs,
    )..where((p) => p.fileId.equals(fileId))).getSingleOrNull();
  }

  Future<int> insertCachedPdf(CachedPdfsCompanion pdf) {
    return into(cachedPdfs).insert(pdf, mode: InsertMode.insertOrReplace);
  }

  Future<bool> isPdfCached(String fileId) async {
    final result =
        await (select(cachedPdfs)
              ..where((p) => p.fileId.equals(fileId))
              ..limit(1))
            .getSingleOrNull();
    return result != null;
  }

  Future<int> deleteCachedPdf(String fileId) {
    return (delete(cachedPdfs)..where((p) => p.fileId.equals(fileId))).go();
  }

  // Annotation operations
  Future<List<Annotation>> getAnnotations(String fileId) {
    return (select(annotations)
          ..where((a) => a.fileId.equals(fileId))
          ..orderBy([
            (a) => OrderingTerm(expression: a.pageNumber),
            (a) => OrderingTerm(expression: a.createdAt),
          ]))
        .get();
  }

  Future<List<Annotation>> getUnsyncedAnnotations() {
    return (select(annotations)..where((a) => a.isSynced.equals(false))).get();
  }

  Future<int> insertAnnotation(AnnotationsCompanion annotation) {
    return into(
      annotations,
    ).insert(annotation, mode: InsertMode.insertOrReplace);
  }

  Future<int> updateAnnotation(AnnotationsCompanion annotation) {
    return (update(
      annotations,
    )..where((a) => a.id.equals(annotation.id.value))).write(annotation);
  }

  Future<int> markAnnotationSynced(String annotationId) {
    return (update(annotations)..where((a) => a.id.equals(annotationId))).write(
      const AnnotationsCompanion(isSynced: Value(true)),
    );
  }

  Future<int> deleteAnnotation(String annotationId) {
    return (delete(annotations)..where((a) => a.id.equals(annotationId))).go();
  }

  // Sync queue operations
  Future<List<SyncQueueData>> getPendingSyncOperations() {
    return (select(syncQueue)..where((s) => s.status.equals('pending'))).get();
  }

  Future<int> insertSyncOperation(SyncQueueCompanion operation) {
    return into(syncQueue).insert(operation);
  }

  Future<int> updateSyncOperation(SyncQueueCompanion operation) {
    return (update(
      syncQueue,
    )..where((s) => s.id.equals(operation.id.value))).write(operation);
  }

  Future<int> deleteSyncOperation(int operationId) {
    return (delete(syncQueue)..where((s) => s.id.equals(operationId))).go();
  }

  // Cache statistics
  Future<Map<String, int>> getCacheStats() async {
    final fileCount = await (selectOnly(files)..addColumns([files.id.count()]))
        .getSingle()
        .then((row) => row.read(files.id.count()) ?? 0);

    final cachedPdfCount =
        await (selectOnly(cachedPdfs)..addColumns([cachedPdfs.fileId.count()]))
            .getSingle()
            .then((row) => row.read(cachedPdfs.fileId.count()) ?? 0);

    final annotationCount =
        await (selectOnly(annotations)..addColumns([annotations.id.count()]))
            .getSingle()
            .then((row) => row.read(annotations.id.count()) ?? 0);

    final totalSize =
        await (selectOnly(cachedPdfs)..addColumns([cachedPdfs.fileSize.sum()]))
            .getSingle()
            .then((row) => row.read(cachedPdfs.fileSize.sum()) ?? 0);

    return {
      'file_count': fileCount,
      'cached_pdf_count': cachedPdfCount,
      'annotation_count': annotationCount,
      'total_cache_size': totalSize,
    };
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    await delete(cachedPdfs).go();
    await delete(annotations).go();
    await delete(files).go();
    await delete(syncQueue).go();
  }
}

/// Open database connection with platform-specific implementation
QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'scholarmate_cache',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.dart.js'),
    ),
  );
}
