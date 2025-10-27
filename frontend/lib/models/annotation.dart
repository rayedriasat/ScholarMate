import 'package:flutter/material.dart';

/// Model representing a PDF annotation
class PdfAnnotation {
  final String id;
  final String fileId;
  final int pageNumber;
  final AnnotationType type;
  final String? content;
  final Rect? boundingBox;
  final Color color;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isSynced;
  final String? authorId;
  final String? authorName;

  PdfAnnotation({
    required this.id,
    required this.fileId,
    required this.pageNumber,
    required this.type,
    this.content,
    this.boundingBox,
    required this.color,
    required this.createdAt,
    required this.modifiedAt,
    this.isSynced = false,
    this.authorId,
    this.authorName,
  });

  /// Create from database row
  factory PdfAnnotation.fromDatabase(Map<String, dynamic> row) {
    return PdfAnnotation(
      id: row['id'] as String,
      fileId: row['file_id'] as String,
      pageNumber: row['page_number'] as int,
      type: AnnotationType.fromString(row['annotation_type'] as String),
      content: row['content'] as String?,
      boundingBox: row['position'] != null
          ? _parseRect(row['position'] as String)
          : null,
      color: Color(int.parse(row['color'] as String? ?? '0xFFFFFF00')),
      createdAt: DateTime.parse(row['created_at'] as String),
      modifiedAt: DateTime.parse(row['modified_at'] as String),
      isSynced: (row['is_synced'] as int? ?? 0) == 1,
      authorId: row['author_id'] as String?,
      authorName: row['author_name'] as String?,
    );
  }

  /// Convert to database format
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'file_id': fileId,
      'page_number': pageNumber,
      'annotation_type': type.toString(),
      'content': content,
      'position': boundingBox != null ? _rectToString(boundingBox!) : null,
      'color': '0x${color.value.toRadixString(16).padLeft(8, '0')}',
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'author_id': authorId,
      'author_name': authorName,
    };
  }

  /// Create a copy with updated fields
  PdfAnnotation copyWith({
    String? id,
    String? fileId,
    int? pageNumber,
    AnnotationType? type,
    String? content,
    Rect? boundingBox,
    Color? color,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isSynced,
    String? authorId,
    String? authorName,
  }) {
    return PdfAnnotation(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      pageNumber: pageNumber ?? this.pageNumber,
      type: type ?? this.type,
      content: content ?? this.content,
      boundingBox: boundingBox ?? this.boundingBox,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isSynced: isSynced ?? this.isSynced,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
    );
  }

  static Rect? _parseRect(String rectString) {
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

  static String _rectToString(Rect rect) {
    return '${rect.left},${rect.top},${rect.right},${rect.bottom}';
  }
}

/// Annotation types supported
enum AnnotationType {
  highlight,
  underline,
  strikethrough,
  squiggly,
  note;

  @override
  String toString() {
    switch (this) {
      case AnnotationType.highlight:
        return 'highlight';
      case AnnotationType.underline:
        return 'underline';
      case AnnotationType.strikethrough:
        return 'strikethrough';
      case AnnotationType.squiggly:
        return 'squiggly';
      case AnnotationType.note:
        return 'note';
    }
  }

  static AnnotationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'highlight':
        return AnnotationType.highlight;
      case 'underline':
        return AnnotationType.underline;
      case 'strikethrough':
        return AnnotationType.strikethrough;
      case 'squiggly':
        return AnnotationType.squiggly;
      case 'note':
        return AnnotationType.note;
      default:
        return AnnotationType.highlight;
    }
  }

  IconData get icon {
    switch (this) {
      case AnnotationType.highlight:
        return Icons.highlight;
      case AnnotationType.underline:
        return Icons.format_underlined;
      case AnnotationType.strikethrough:
        return Icons.format_strikethrough;
      case AnnotationType.squiggly:
        return Icons.waves;
      case AnnotationType.note:
        return Icons.note;
    }
  }
}
