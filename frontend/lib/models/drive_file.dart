/// Model representing a file or folder in Google Drive
class DriveFile {
  final String id;
  final String name;
  final String? mimeType;
  final int? size;
  final String? parentId;
  final DateTime? modifiedTime;
  final DateTime? createdTime;
  final String? thumbnailLink;
  final bool isFolder;
  final bool isShared;
  final List<String>? parents;

  DriveFile({
    required this.id,
    required this.name,
    this.mimeType,
    this.size,
    this.parentId,
    this.modifiedTime,
    this.createdTime,
    this.thumbnailLink,
    this.isFolder = false,
    this.isShared = false,
    this.parents,
  });

  /// Create DriveFile from Google Drive API response
  factory DriveFile.fromJson(Map<String, dynamic> json) {
    final mimeType = json['mimeType'] as String?;
    final isFolder = mimeType == 'application/vnd.google-apps.folder';

    return DriveFile(
      id: json['id'] as String,
      name: json['name'] as String,
      mimeType: mimeType,
      size: json['size'] != null ? int.tryParse(json['size'].toString()) : null,
      parentId: (json['parents'] as List?)?.isNotEmpty == true
          ? json['parents'][0] as String
          : null,
      modifiedTime: json['modifiedTime'] != null
          ? DateTime.tryParse(json['modifiedTime'] as String)
          : null,
      createdTime: json['createdTime'] != null
          ? DateTime.tryParse(json['createdTime'] as String)
          : null,
      thumbnailLink: json['thumbnailLink'] as String?,
      isFolder: isFolder,
      isShared: json['shared'] as bool? ?? false,
      parents: (json['parents'] as List?)?.cast<String>(),
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mimeType': mimeType,
      'size': size,
      'parentId': parentId,
      'modifiedTime': modifiedTime?.toIso8601String(),
      'createdTime': createdTime?.toIso8601String(),
      'thumbnailLink': thumbnailLink,
      'isFolder': isFolder,
      'isShared': isShared,
      'parents': parents,
    };
  }

  /// Create a copy with updated fields
  DriveFile copyWith({
    String? id,
    String? name,
    String? mimeType,
    int? size,
    String? parentId,
    DateTime? modifiedTime,
    DateTime? createdTime,
    String? thumbnailLink,
    bool? isFolder,
    bool? isShared,
    List<String>? parents,
  }) {
    return DriveFile(
      id: id ?? this.id,
      name: name ?? this.name,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      parentId: parentId ?? this.parentId,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      createdTime: createdTime ?? this.createdTime,
      thumbnailLink: thumbnailLink ?? this.thumbnailLink,
      isFolder: isFolder ?? this.isFolder,
      isShared: isShared ?? this.isShared,
      parents: parents ?? this.parents,
    );
  }

  /// Get file extension from name
  String? get extension {
    if (isFolder) return null;
    final lastDot = name.lastIndexOf('.');
    if (lastDot == -1) return null;
    return name.substring(lastDot + 1).toLowerCase();
  }

  /// Check if file is a PDF
  bool get isPdf => extension == 'pdf' || mimeType == 'application/pdf';

  /// Check if file is a Markdown file
  bool get isMarkdown =>
      extension == 'md' ||
      extension == 'markdown' ||
      mimeType == 'text/markdown' ||
      mimeType == 'text/x-markdown';

  /// Get human-readable file size
  String get formattedSize {
    if (size == null) return '';

    const units = ['B', 'KB', 'MB', 'GB'];
    double fileSize = size!.toDouble();
    int unitIndex = 0;

    while (fileSize >= 1024 && unitIndex < units.length - 1) {
      fileSize /= 1024;
      unitIndex++;
    }

    return '${fileSize.toStringAsFixed(fileSize < 10 ? 1 : 0)} ${units[unitIndex]}';
  }

  @override
  String toString() {
    return 'DriveFile(id: $id, name: $name, isFolder: $isFolder)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriveFile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
