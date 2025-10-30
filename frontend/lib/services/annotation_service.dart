import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf;
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../models/annotation.dart';
import '../database/database.dart';
import 'cache_service.dart';
import 'annotation_sync_service.dart';
import 'connectivity_service.dart';

/// Service for managing PDF annotations
class AnnotationService extends ChangeNotifier {
  final AppDatabase _database;
  final CacheService _cacheService;
  final AnnotationSyncService? _syncService;
  final ConnectivityService? _connectivityService;
  final _uuid = const Uuid();

  AnnotationService({
    required AppDatabase database,
    required CacheService cacheService,
    AnnotationSyncService? syncService,
    ConnectivityService? connectivityService,
  }) : _database = database,
       _cacheService = cacheService,
       _syncService = syncService,
       _connectivityService = connectivityService;

  /// Get all annotations for a file
  Future<List<PdfAnnotation>> getAnnotations(String fileId) async {
    final dbAnnotations = await _database.getAnnotations(fileId);
    return dbAnnotations.map((a) => _annotationFromDb(a)).toList();
  }

  /// Get annotations for a specific page
  Future<List<PdfAnnotation>> getAnnotationsForPage(
    String fileId,
    int pageNumber,
  ) async {
    final allAnnotations = await getAnnotations(fileId);
    return allAnnotations.where((a) => a.pageNumber == pageNumber).toList();
  }

  /// Create a new annotation and embed it in the PDF
  Future<PdfAnnotation?> createAnnotation({
    required String fileId,
    required int pageNumber,
    required AnnotationType type,
    required Rect boundingBox,
    required Color color,
    String? content,
    String? authorId,
    String? authorName,
  }) async {
    try {
      final annotationId = _uuid.v4();
      final now = DateTime.now();

      // Check if online
      final isOnline = _connectivityService?.isOnline ?? false;

      if (isOnline && _syncService != null) {
        // Create annotation online (immediate sync)
        final annotation = await _syncService.createAnnotationOnline(
          fileId: fileId,
          pageNumber: pageNumber,
          type: type,
          boundingBox: boundingBox,
          color: color,
          content: content,
        );

        if (annotation != null) {
          // Embed annotation in PDF
          await _embedAnnotationInPdf(fileId, annotation);
          notifyListeners();
          return annotation;
        }
      }

      // Offline mode or sync failed - create locally
      final annotation = PdfAnnotation(
        id: annotationId,
        fileId: fileId,
        pageNumber: pageNumber,
        type: type,
        content: content,
        boundingBox: boundingBox,
        color: color,
        createdAt: now,
        modifiedAt: now,
        isSynced: false,
        authorId: authorId,
        authorName: authorName,
      );

      // Save to database
      await _database.insertAnnotation(
        AnnotationsCompanion.insert(
          id: annotation.id,
          fileId: annotation.fileId,
          pageNumber: annotation.pageNumber,
          annotationType: annotation.type.toString(),
          content: Value(annotation.content),
          position: Value(
            annotation.boundingBox != null
                ? '${annotation.boundingBox!.left},${annotation.boundingBox!.top},${annotation.boundingBox!.right},${annotation.boundingBox!.bottom}'
                : null,
          ),
          color: Value('0x${annotation.color.value.toRadixString(16)}'),
          createdAt: annotation.createdAt,
          modifiedAt: annotation.modifiedAt,
          isSynced: Value(annotation.isSynced),
          authorId: Value(annotation.authorId),
          authorName: Value(annotation.authorName),
        ),
      );

      // Embed annotation in PDF
      await _embedAnnotationInPdf(fileId, annotation);

      notifyListeners();
      return annotation;
    } catch (e) {
      debugPrint('Error creating annotation: $e');
      return null;
    }
  }

  /// Sync annotations when connectivity is restored
  Future<void> syncAnnotationsOnReconnect(String fileId) async {
    if (_syncService == null || _connectivityService == null) return;

    final isOnline = _connectivityService.isOnline;
    if (!isOnline) return;

    try {
      // Sync offline annotations
      await _syncService.syncOfflineAnnotations(fileId);

      // Fetch latest annotations from server
      await _syncService.fetchAnnotations(fileId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing annotations on reconnect: $e');
    }
  }

  /// Fetch latest annotations from server on file open
  Future<void> fetchLatestAnnotations(String fileId) async {
    if (_syncService == null || _connectivityService == null) return;

    final isOnline = _connectivityService.isOnline;
    if (!isOnline) return;

    try {
      await _syncService.fetchAnnotations(fileId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching latest annotations: $e');
    }
  }

  /// Update an existing annotation
  Future<bool> updateAnnotation(PdfAnnotation annotation) async {
    try {
      final updatedAnnotation = annotation.copyWith(
        modifiedAt: DateTime.now(),
        isSynced: false,
      );

      await _database.updateAnnotation(
        AnnotationsCompanion.insert(
          id: updatedAnnotation.id,
          fileId: updatedAnnotation.fileId,
          pageNumber: updatedAnnotation.pageNumber,
          annotationType: updatedAnnotation.type.toString(),
          content: Value(updatedAnnotation.content),
          position: Value(
            updatedAnnotation.boundingBox != null
                ? '${updatedAnnotation.boundingBox!.left},${updatedAnnotation.boundingBox!.top},${updatedAnnotation.boundingBox!.right},${updatedAnnotation.boundingBox!.bottom}'
                : null,
          ),
          color: Value('0x${updatedAnnotation.color.value.toRadixString(16)}'),
          createdAt: updatedAnnotation.createdAt,
          modifiedAt: updatedAnnotation.modifiedAt,
          isSynced: Value(updatedAnnotation.isSynced),
        ),
      );

      // Re-embed annotation in PDF
      await _embedAnnotationInPdf(updatedAnnotation.fileId, updatedAnnotation);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating annotation: $e');
      return false;
    }
  }

  /// Delete an annotation
  Future<bool> deleteAnnotation(String annotationId, String fileId) async {
    try {
      await _database.deleteAnnotation(annotationId);

      // Rebuild PDF without this annotation
      await _rebuildPdfAnnotations(fileId);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting annotation: $e');
      return false;
    }
  }

  /// Embed annotation in PDF bytes
  Future<void> _embedAnnotationInPdf(
    String fileId,
    PdfAnnotation annotation,
  ) async {
    try {
      // Get cached PDF bytes
      final cachedPdf = await _cacheService.getCachedPdf(fileId);
      if (cachedPdf == null) {
        debugPrint('No cached PDF found for embedding annotation');
        return;
      }

      // Load PDF document
      final document = pdf.PdfDocument(inputBytes: cachedPdf);

      if (annotation.pageNumber > document.pages.count) {
        debugPrint('Invalid page number for annotation');
        document.dispose();
        return;
      }

      // Get the page
      final page = document.pages[annotation.pageNumber - 1];

      // Create annotation based on type
      switch (annotation.type) {
        case AnnotationType.highlight:
          _addHighlightAnnotation(page, annotation);
          break;
        case AnnotationType.underline:
          _addUnderlineAnnotation(page, annotation);
          break;
        case AnnotationType.strikethrough:
          _addStrikethroughAnnotation(page, annotation);
          break;
        case AnnotationType.squiggly:
          _addSquigglyAnnotation(page, annotation);
          break;
        case AnnotationType.note:
          _addNoteAnnotation(page, annotation);
          break;
      }

      // Save modified PDF
      final List<int> modifiedBytesList = await document.save();
      document.dispose();

      // Update cache with modified PDF
      final modifiedBytes = Uint8List.fromList(modifiedBytesList);
      await _cacheService.cachePdfBytes(fileId, modifiedBytes);
    } catch (e) {
      debugPrint('Error embedding annotation in PDF: $e');
    }
  }

  /// Rebuild PDF with all annotations
  Future<void> _rebuildPdfAnnotations(String fileId) async {
    try {
      // Get original PDF (without annotations)
      // For now, we'll just clear and re-add all annotations
      final annotations = await getAnnotations(fileId);

      // Get cached PDF
      final cachedPdf = await _cacheService.getCachedPdf(fileId);
      if (cachedPdf == null) return;

      final document = pdf.PdfDocument(inputBytes: cachedPdf);

      // Clear all annotations from document
      for (var i = 0; i < document.pages.count; i++) {
        // Remove all annotations from page
        final annotations = document.pages[i].annotations;
        while (annotations.count > 0) {
          annotations.remove(annotations[0]);
        }
      }

      // Re-add all annotations
      for (final annotation in annotations) {
        if (annotation.pageNumber <= document.pages.count) {
          final page = document.pages[annotation.pageNumber - 1];

          switch (annotation.type) {
            case AnnotationType.highlight:
              _addHighlightAnnotation(page, annotation);
              break;
            case AnnotationType.underline:
              _addUnderlineAnnotation(page, annotation);
              break;
            case AnnotationType.strikethrough:
              _addStrikethroughAnnotation(page, annotation);
              break;
            case AnnotationType.squiggly:
              _addSquigglyAnnotation(page, annotation);
              break;
            case AnnotationType.note:
              _addNoteAnnotation(page, annotation);
              break;
          }
        }
      }

      // Save and update cache
      final List<int> modifiedBytesList = await document.save();
      document.dispose();
      final modifiedBytes = Uint8List.fromList(modifiedBytesList);
      await _cacheService.cachePdfBytes(fileId, modifiedBytes);
    } catch (e) {
      debugPrint('Error rebuilding PDF annotations: $e');
    }
  }

  void _addHighlightAnnotation(pdf.PdfPage page, PdfAnnotation annotation) {
    if (annotation.boundingBox == null) return;

    final highlight = pdf.PdfTextMarkupAnnotation(
      annotation.boundingBox!,
      'Highlight',
      pdf.PdfColor(
        (annotation.color.r * 255).round(),
        (annotation.color.g * 255).round(),
        (annotation.color.b * 255).round(),
      ),
      textMarkupAnnotationType: pdf.PdfTextMarkupAnnotationType.highlight,
    );

    if (annotation.content != null) {
      highlight.text = annotation.content!;
    }

    page.annotations.add(highlight);
  }

  void _addUnderlineAnnotation(pdf.PdfPage page, PdfAnnotation annotation) {
    if (annotation.boundingBox == null) return;

    final underline = pdf.PdfTextMarkupAnnotation(
      annotation.boundingBox!,
      'Underline',
      pdf.PdfColor(
        (annotation.color.r * 255).round(),
        (annotation.color.g * 255).round(),
        (annotation.color.b * 255).round(),
      ),
      textMarkupAnnotationType: pdf.PdfTextMarkupAnnotationType.underline,
    );

    if (annotation.content != null) {
      underline.text = annotation.content!;
    }

    page.annotations.add(underline);
  }

  void _addStrikethroughAnnotation(pdf.PdfPage page, PdfAnnotation annotation) {
    if (annotation.boundingBox == null) return;

    final strikethrough = pdf.PdfTextMarkupAnnotation(
      annotation.boundingBox!,
      'Strikethrough',
      pdf.PdfColor(
        (annotation.color.r * 255).round(),
        (annotation.color.g * 255).round(),
        (annotation.color.b * 255).round(),
      ),
      textMarkupAnnotationType: pdf.PdfTextMarkupAnnotationType.strikethrough,
    );

    if (annotation.content != null) {
      strikethrough.text = annotation.content!;
    }

    page.annotations.add(strikethrough);
  }

  void _addSquigglyAnnotation(pdf.PdfPage page, PdfAnnotation annotation) {
    if (annotation.boundingBox == null) return;

    final squiggly = pdf.PdfTextMarkupAnnotation(
      annotation.boundingBox!,
      'Squiggly',
      pdf.PdfColor(
        (annotation.color.r * 255).round(),
        (annotation.color.g * 255).round(),
        (annotation.color.b * 255).round(),
      ),
      textMarkupAnnotationType: pdf.PdfTextMarkupAnnotationType.squiggly,
    );

    if (annotation.content != null) {
      squiggly.text = annotation.content!;
    }

    page.annotations.add(squiggly);
  }

  void _addNoteAnnotation(pdf.PdfPage page, PdfAnnotation annotation) {
    if (annotation.boundingBox == null) return;

    final note = pdf.PdfPopupAnnotation(
      annotation.boundingBox!,
      annotation.content ?? '',
    );

    note.color = pdf.PdfColor(
      (annotation.color.r * 255).round(),
      (annotation.color.g * 255).round(),
      (annotation.color.b * 255).round(),
    );

    page.annotations.add(note);
  }

  PdfAnnotation _annotationFromDb(Annotation dbAnnotation) {
    return PdfAnnotation(
      id: dbAnnotation.id,
      fileId: dbAnnotation.fileId,
      pageNumber: dbAnnotation.pageNumber,
      type: AnnotationType.fromString(dbAnnotation.annotationType),
      content: dbAnnotation.content,
      boundingBox: dbAnnotation.position != null
          ? _parseRect(dbAnnotation.position!)
          : null,
      color: Color(int.parse(dbAnnotation.color ?? '0xFFFFFF00')),
      createdAt: dbAnnotation.createdAt,
      modifiedAt: dbAnnotation.modifiedAt,
      isSynced: dbAnnotation.isSynced,
    );
  }

  Rect? _parseRect(String rectString) {
    try {
      final parts = rectString.split(',');
      if (parts.length == 4) {
        return Rect.fromLTRB(
          double.parse(parts[0]),
          double.parse(parts[1]),
          double.parse(parts[2]),
          double.parse(parts[3]),
        );
      }
    } catch (e) {
      // Invalid format
    }
    return null;
  }
}
