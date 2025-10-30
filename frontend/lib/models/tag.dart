/// Tag model for organizing files
class Tag {
  final String id;
  final String userId;
  final String name;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int documentCount;

  Tag({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.documentCount = 0,
  });

  /// Create Tag from JSON
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#2196F3',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      documentCount: json['document_count'] as int? ?? 0,
    );
  }

  /// Convert Tag to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'document_count': documentCount,
    };
  }

  /// Create a copy with updated fields
  Tag copyWith({
    String? id,
    String? userId,
    String? name,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? documentCount,
  }) {
    return Tag(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      documentCount: documentCount ?? this.documentCount,
    );
  }

  @override
  String toString() => 'Tag(id: $id, name: $name, color: $color)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// File-tag relationship model
class FileTag {
  final String id;
  final String userId;
  final String fileId;
  final String tagId;
  final DateTime createdAt;

  FileTag({
    required this.id,
    required this.userId,
    required this.fileId,
    required this.tagId,
    required this.createdAt,
  });

  /// Create FileTag from JSON
  factory FileTag.fromJson(Map<String, dynamic> json) {
    return FileTag(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fileId: json['file_id'] as String,
      tagId: json['tag_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert FileTag to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'file_id': fileId,
      'tag_id': tagId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'FileTag(id: $id, fileId: $fileId, tagId: $tagId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileTag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
