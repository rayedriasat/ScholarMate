import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/drawing_note.dart';
import '../models/drive_file.dart';
import 'drive_service.dart';

/// Service for persisting drawing notes locally and to Google Drive
class DrawingStorageService extends ChangeNotifier {
  static const String _notesKey = 'drawing_notes';

  final DriveService _driveService;
  String? _notesFolderId;

  DrawingStorageService({DriveService? driveService})
    : _driveService = driveService ?? DriveService();

  /// Get or create the Notes folder in Google Drive
  Future<String> _getNotesFolderId() async {
    if (_notesFolderId != null) return _notesFolderId!;

    try {
      final appFolderId = await _driveService.getAppFolderId();
      final files = await _driveService.listFiles(appFolderId);

      // Look for existing Notes folder
      final notesFolder = files.firstWhere(
        (file) => file.isFolder && file.name == 'Notes',
        orElse: () => DriveFile(id: '', name: ''),
      );

      if (notesFolder.id.isNotEmpty) {
        _notesFolderId = notesFolder.id;
      } else {
        // Create Notes folder
        final newFolder = await _driveService.createFolder(
          'Notes',
          appFolderId,
        );
        _notesFolderId = newFolder.id;
      }

      return _notesFolderId!;
    } catch (e) {
      debugPrint('Error getting notes folder: $e');
      rethrow;
    }
  }

  /// Save all notes to local storage
  Future<void> saveNotes(List<DrawingNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = notes.map((note) => note.toJson()).toList();
    await prefs.setString(_notesKey, jsonEncode(notesJson));
  }

  /// Load all notes from local storage
  Future<List<DrawingNote>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesString = prefs.getString(_notesKey);

    if (notesString == null) {
      return [];
    }

    final notesList = jsonDecode(notesString) as List;
    return notesList.map((json) => DrawingNote.fromJson(json)).toList();
  }

  /// Save a single note (locally and to Drive)
  Future<void> saveNote(DrawingNote note) async {
    try {
      // Validate note data before serialization
      if (note.id.isEmpty) {
        throw Exception('Note ID cannot be empty');
      }

      if (note.pages.isEmpty) {
        throw Exception('Note must have at least one page');
      }

      // Test serialization to catch any data issues early
      final testJson = note.toJson();
      final testJsonString = jsonEncode(testJson);
      debugPrint(
        'Note serialization test passed: ${testJsonString.length} characters',
      );

      // Save locally first
      final notes = await loadNotes();
      final index = notes.indexWhere((n) => n.id == note.id);

      if (index >= 0) {
        notes[index] = note;
      } else {
        notes.add(note);
      }

      await saveNotes(notes);
      debugPrint('Note saved locally: ${note.title}');

      // Note: JSON is only saved locally now. PDF export handles Drive storage.
      debugPrint('Note saved locally only: ${note.title}');
    } catch (e, stackTrace) {
      debugPrint('Error in saveNote: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }

    notifyListeners();
  }

  /// Export note as PDF from canvas images and save to Google Drive
  Future<DriveFile?> exportNoteToPDFFromImages(
    String noteTitle,
    List<Uint8List> pageImages,
  ) async {
    try {
      final pdf = pw.Document();

      // Add each page image to PDF
      for (int i = 0; i < pageImages.length; i++) {
        final imageBytes = pageImages[i];

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Center(
              child: pw.Image(
                pw.MemoryImage(imageBytes),
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
        );

        debugPrint('Added page ${i + 1} to PDF (${imageBytes.length} bytes)');
      }

      final pdfBytes = await pdf.save();
      final fileName = '${noteTitle.replaceAll(RegExp(r'[^\w\s-]'), '')}.pdf';

      final folderId = await _getNotesFolderId();
      final driveFile = await _driveService.uploadFileFromBytes(
        pdfBytes,
        fileName,
        folderId,
      );

      debugPrint(
        'Note exported as PDF: $noteTitle (${pageImages.length} pages)',
      );
      return driveFile;
    } catch (e) {
      debugPrint('Error exporting note to PDF from images: $e');
      return null;
    }
  }

  /// Export note as PDF and save to Google Drive (legacy method - kept for compatibility)
  Future<DriveFile?> exportNoteToPDF(DrawingNote note) async {
    try {
      final pdf = pw.Document();

      // Add each page to PDF
      for (int i = 0; i < note.pages.length; i++) {
        final page = note.pages[i];

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Container(
              color: PdfColor.fromInt(page.backgroundColor.value),
              child: pw.Stack(
                children: [
                  // Add stroke indicators (simplified - full stroke rendering would need custom implementation)
                  if (page.strokes.isNotEmpty)
                    pw.Positioned(
                      left: 20,
                      top: 20,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'Drawing contains ${page.strokes.length} stroke(s)',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ),
                    ),

                  // Add text notes
                  ...page.textNotes.map(
                    (textNote) => pw.Positioned(
                      left: textNote.position.dx,
                      top: textNote.position.dy,
                      child: pw.Text(
                        textNote.text,
                        style: pw.TextStyle(
                          fontSize: textNote.fontSize,
                          color: PdfColor.fromInt(textNote.color.value),
                        ),
                      ),
                    ),
                  ),

                  // Add images
                  ...page.images.map(
                    (image) => pw.Positioned(
                      left: image.position.dx,
                      top: image.position.dy,
                      child: pw.Image(
                        pw.MemoryImage(image.imageBytes),
                        width: image.width * image.scale,
                        height: image.height * image.scale,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final pdfBytes = await pdf.save();
      final fileName = '${note.title.replaceAll(RegExp(r'[^\w\s-]'), '')}.pdf';

      final folderId = await _getNotesFolderId();
      final driveFile = await _driveService.uploadFileFromBytes(
        pdfBytes,
        fileName,
        folderId,
      );

      debugPrint('Note exported as PDF: ${note.title}');
      return driveFile;
    } catch (e) {
      debugPrint('Error exporting note to PDF: $e');
      return null;
    }
  }

  /// Delete a note (locally and from Drive)
  Future<void> deleteNote(String noteId) async {
    // Delete locally
    final notes = await loadNotes();
    notes.removeWhere((note) => note.id == noteId);
    await saveNotes(notes);

    // Try to delete from Drive (best effort)
    try {
      final folderId = await _getNotesFolderId();
      final files = await _driveService.listFiles(folderId);

      // Find and delete the note file
      for (final file in files) {
        if (file.name.contains(noteId) || file.name.endsWith('.note.json')) {
          // Would need to check file content to match ID
          // For now, skip Drive deletion to avoid accidental deletions
        }
      }
    } catch (e) {
      debugPrint('Error deleting note from Drive: $e');
    }

    notifyListeners();
  }

  /// Clear all notes
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notesKey);
    notifyListeners();
  }

  /// Load notes from Google Drive and sync with local storage
  Future<void> syncNotesFromDrive() async {
    try {
      final folderId = await _getNotesFolderId();
      final files = await _driveService.listFiles(folderId);

      final noteFiles = files.where((file) => file.name.endsWith('.note.json'));
      final syncedNotes = <DrawingNote>[];

      for (final file in noteFiles) {
        try {
          final fileBytes = await _driveService.downloadFile(file.id);
          if (fileBytes != null) {
            final jsonString = utf8.decode(fileBytes);
            final noteJson = jsonDecode(jsonString);
            final note = DrawingNote.fromJson(noteJson);
            syncedNotes.add(note);
          }
        } catch (e) {
          debugPrint('Error loading note ${file.name}: $e');
        }
      }

      // Merge with local notes (Drive takes precedence)
      final localNotes = await loadNotes();
      final mergedNotes = <String, DrawingNote>{};

      // Add local notes first
      for (final note in localNotes) {
        mergedNotes[note.id] = note;
      }

      // Override with Drive notes
      for (final note in syncedNotes) {
        mergedNotes[note.id] = note;
      }

      await saveNotes(mergedNotes.values.toList());
      notifyListeners();

      debugPrint('Synced ${syncedNotes.length} notes from Drive');
    } catch (e) {
      debugPrint('Error syncing notes from Drive: $e');
    }
  }
}
