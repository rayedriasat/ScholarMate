import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/markdown_note.dart';

/// Service for storing and managing markdown notes
/// Uses SharedPreferences for local storage with offline-first approach
class MarkdownStorageService {
  static const String _notesKey = 'markdown_notes';
  static const String _lastSyncKey = 'markdown_notes_last_sync';

  /// Load all markdown notes from local storage
  Future<List<MarkdownNote>> loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey);

      if (notesJson == null) return [];

      final notesList = jsonDecode(notesJson) as List<dynamic>;
      return notesList
          .map((json) => MarkdownNote.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      throw Exception('Failed to load markdown notes: $e');
    }
  }

  /// Save a single markdown note
  Future<void> saveNote(MarkdownNote note) async {
    try {
      final notes = await loadNotes();
      final existingIndex = notes.indexWhere((n) => n.id == note.id);

      if (existingIndex >= 0) {
        notes[existingIndex] = note;
      } else {
        notes.add(note);
      }

      await _saveAllNotes(notes);
    } catch (e) {
      throw Exception('Failed to save markdown note: $e');
    }
  }

  /// Delete a markdown note
  Future<void> deleteNote(String noteId) async {
    try {
      final notes = await loadNotes();
      notes.removeWhere((note) => note.id == noteId);
      await _saveAllNotes(notes);
    } catch (e) {
      throw Exception('Failed to delete markdown note: $e');
    }
  }

  /// Get a specific note by ID
  Future<MarkdownNote?> getNote(String noteId) async {
    try {
      final notes = await loadNotes();
      return notes.where((note) => note.id == noteId).firstOrNull;
    } catch (e) {
      throw Exception('Failed to get markdown note: $e');
    }
  }

  /// Search notes by title or content
  Future<List<MarkdownNote>> searchNotes(String query) async {
    try {
      if (query.isEmpty) return loadNotes();

      final notes = await loadNotes();
      final lowercaseQuery = query.toLowerCase();

      return notes.where((note) {
        return note.title.toLowerCase().contains(lowercaseQuery) ||
            note.content.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search markdown notes: $e');
    }
  }

  /// Get notes by tags
  Future<List<MarkdownNote>> getNotesByTags(List<String> tags) async {
    try {
      if (tags.isEmpty) return loadNotes();

      final notes = await loadNotes();
      return notes.where((note) {
        return tags.any((tag) => note.tags.contains(tag));
      }).toList();
    } catch (e) {
      throw Exception('Failed to get notes by tags: $e');
    }
  }

  /// Get all unique tags from all notes
  Future<List<String>> getAllTags() async {
    try {
      final notes = await loadNotes();
      final allTags = <String>{};

      for (final note in notes) {
        allTags.addAll(note.tags);
      }

      return allTags.toList()..sort();
    } catch (e) {
      throw Exception('Failed to get all tags: $e');
    }
  }

  /// Export note as markdown file content
  String exportNoteAsMarkdown(MarkdownNote note) {
    final buffer = StringBuffer();

    // Add title as H1
    buffer.writeln('# ${note.title}');
    buffer.writeln();

    // Add metadata
    buffer.writeln('---');
    buffer.writeln('Created: ${note.createdAt.toIso8601String()}');
    buffer.writeln('Updated: ${note.updatedAt.toIso8601String()}');
    if (note.tags.isNotEmpty) {
      buffer.writeln('Tags: ${note.tags.join(', ')}');
    }
    buffer.writeln('---');
    buffer.writeln();

    // Add content
    buffer.write(note.content);

    return buffer.toString();
  }

  /// Import note from markdown content
  MarkdownNote importNoteFromMarkdown(String content, {String? title}) {
    // Extract title from content if not provided
    String noteTitle = title ?? 'Untitled Note';
    String noteContent = content;

    // Try to extract title from first H1 heading
    final lines = content.split('\n');
    if (lines.isNotEmpty && lines.first.startsWith('# ')) {
      noteTitle = lines.first.substring(2).trim();
      // Remove the title line from content
      noteContent = lines.skip(1).join('\n').trim();
    }

    return MarkdownNote.create(title: noteTitle, content: noteContent);
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final notes = await loadNotes();
      final totalWords = notes.fold<int>(
        0,
        (sum, note) => sum + note.wordCount,
      );
      final totalCharacters = notes.fold<int>(
        0,
        (sum, note) => sum + note.characterCount,
      );

      return {
        'noteCount': notes.length,
        'totalWords': totalWords,
        'totalCharacters': totalCharacters,
        'averageWordsPerNote': notes.isEmpty
            ? 0
            : (totalWords / notes.length).round(),
      };
    } catch (e) {
      throw Exception('Failed to get storage stats: $e');
    }
  }

  /// Clear all notes (for testing or reset)
  Future<void> clearAllNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notesKey);
      await prefs.remove(_lastSyncKey);
    } catch (e) {
      throw Exception('Failed to clear all notes: $e');
    }
  }

  /// Private method to save all notes to storage
  Future<void> _saveAllNotes(List<MarkdownNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = jsonEncode(notes.map((note) => note.toJson()).toList());
    await prefs.setString(_notesKey, notesJson);
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(_lastSyncKey);
      return lastSyncString != null ? DateTime.parse(lastSyncString) : null;
    } catch (e) {
      return null;
    }
  }
}
