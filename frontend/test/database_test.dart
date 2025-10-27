import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/database/database.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // Use in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Files Table', () {
    test('Insert and retrieve file', () async {
      // Insert a file
      await database.insertFile(
        FilesCompanion(
          id: const Value('file-1'),
          name: const Value('Test File.pdf'),
          mimeType: const Value('application/pdf'),
          size: const Value(1024),
          parentId: const Value(null),
          isFolder: const Value(false),
          isShared: const Value(false),
          isCached: const Value(false),
        ),
      );

      // Retrieve the file
      final file = await database.getFile('file-1');

      expect(file, isNotNull);
      expect(file!.name, 'Test File.pdf');
      expect(file.mimeType, 'application/pdf');
      expect(file.size, 1024);
      expect(file.isFolder, false);
    });

    test('Get files by parent', () async {
      // Insert parent folder
      await database.insertFile(
        FilesCompanion(
          id: const Value('folder-1'),
          name: const Value('My Folder'),
          isFolder: const Value(true),
          isShared: const Value(false),
          isCached: const Value(false),
        ),
      );

      // Insert child files
      await database.insertFiles([
        const FilesCompanion(
          id: Value('file-1'),
          name: Value('File 1.pdf'),
          parentId: Value('folder-1'),
          isFolder: Value(false),
          isShared: Value(false),
        ),
        const FilesCompanion(
          id: Value('file-2'),
          name: Value('File 2.pdf'),
          parentId: Value('folder-1'),
          isFolder: Value(false),
          isShared: Value(false),
        ),
      ]);

      // Get files in folder
      final files = await database.getFiles('folder-1');

      expect(files.length, 2);
      expect(files[0].name, 'File 1.pdf');
      expect(files[1].name, 'File 2.pdf');
    });
  });

  group('Cached PDFs', () {
    test('Cache and retrieve PDF bytes', () async {
      final pdfBytes = Uint8List.fromList(List<int>.generate(100, (i) => i));

      // Cache PDF
      await database.insertCachedPdf(
        CachedPdfsCompanion(
          fileId: const Value('file-1'),
          pdfBytes: Value(pdfBytes),
          cachedAt: Value(DateTime.now()),
          fileSize: Value(pdfBytes.length),
        ),
      );

      // Check if cached
      final isCached = await database.isPdfCached('file-1');
      expect(isCached, true);

      // Retrieve PDF
      final cachedPdf = await database.getCachedPdf('file-1');
      expect(cachedPdf, isNotNull);
      expect(cachedPdf!.pdfBytes, pdfBytes);
      expect(cachedPdf.fileSize, 100);
    });
  });

  group('Annotations', () {
    test('Insert and retrieve annotations', () async {
      // Insert annotations
      await database.insertAnnotation(
        AnnotationsCompanion(
          id: const Value('ann-1'),
          fileId: const Value('file-1'),
          pageNumber: const Value(1),
          annotationType: const Value('highlight'),
          content: const Value('Important text'),
          color: const Value('#FFFF00'),
          createdAt: Value(DateTime.now()),
          modifiedAt: Value(DateTime.now()),
          isSynced: const Value(false),
        ),
      );

      // Get annotations
      final annotations = await database.getAnnotations('file-1');
      expect(annotations.length, 1);
      expect(annotations[0].annotationType, 'highlight');
      expect(annotations[0].content, 'Important text');

      // Get unsynced annotations
      final unsynced = await database.getUnsyncedAnnotations();
      expect(unsynced.length, 1);

      // Mark as synced
      await database.markAnnotationSynced('ann-1');

      final unsyncedAfter = await database.getUnsyncedAnnotations();
      expect(unsyncedAfter.length, 0);
    });
  });

  group('Cache Statistics', () {
    test('Get cache stats', () async {
      // Insert test data
      await database.insertFile(
        const FilesCompanion(
          id: Value('file-1'),
          name: Value('Test.pdf'),
          isFolder: Value(false),
          isShared: Value(false),
        ),
      );

      await database.insertCachedPdf(
        CachedPdfsCompanion(
          fileId: const Value('file-1'),
          pdfBytes: Value(Uint8List.fromList(List<int>.filled(1000, 0))),
          cachedAt: Value(DateTime.now()),
          fileSize: const Value(1000),
        ),
      );

      await database.insertAnnotation(
        AnnotationsCompanion(
          id: const Value('ann-1'),
          fileId: const Value('file-1'),
          pageNumber: const Value(1),
          annotationType: const Value('highlight'),
          createdAt: Value(DateTime.now()),
          modifiedAt: Value(DateTime.now()),
        ),
      );

      // Get stats
      final stats = await database.getCacheStats();

      expect(stats['file_count'], 1);
      expect(stats['cached_pdf_count'], 1);
      expect(stats['annotation_count'], 1);
      expect(stats['total_cache_size'], 1000);
    });
  });

  group('Clear Cache', () {
    test('Clear all cache data', () async {
      // Insert test data
      await database.insertFile(
        const FilesCompanion(
          id: Value('file-1'),
          name: Value('Test.pdf'),
          isFolder: Value(false),
          isShared: Value(false),
        ),
      );

      // Clear cache
      await database.clearAllCache();

      // Verify empty
      final files = await database.getFiles();
      expect(files.length, 0);
    });
  });
}
