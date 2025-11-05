import 'package:uuid/uuid.dart';

/// Model for markdown notes
class MarkdownNote {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;

  MarkdownNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  /// Create a new markdown note
  factory MarkdownNote.create({
    required String title,
    String content = '',
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    return MarkdownNote(
      id: const Uuid().v4(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      tags: tags,
    );
  }

  /// Create from JSON
  factory MarkdownNote.fromJson(Map<String, dynamic> json) {
    return MarkdownNote(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
    };
  }

  /// Create a copy with updated fields
  MarkdownNote copyWith({String? title, String? content, List<String>? tags}) {
    return MarkdownNote(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      tags: tags ?? this.tags,
    );
  }

  /// Get word count
  int get wordCount {
    if (content.isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  /// Get character count
  int get characterCount => content.length;

  /// Get reading time estimate (average 200 words per minute)
  int get readingTimeMinutes {
    final words = wordCount;
    return (words / 200).ceil();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarkdownNote && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MarkdownNote(id: $id, title: $title, wordCount: $wordCount)';
  }
}
