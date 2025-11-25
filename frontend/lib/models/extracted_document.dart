import 'package:flutter/foundation.dart';

/// Represents a document that has been scanned and had its data extracted via OCR + AI
class ExtractedDocument {
  final String id;
  final String userId;
  final String
  documentType; // Hospital, Appointment, ID Card, Bill, Prescription, etc.
  final Map<String, dynamic>
  extractedData; // Key-value pairs of extracted fields
  final String summary; // 1-2 line AI-generated summary
  final String? imagePath; // Local path or cloud URL to original image
  final List<String> tags; // Auto-generated tags
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExtractedDocument({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.extractedData,
    required this.summary,
    this.imagePath,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new extracted document (for local creation before upload)
  factory ExtractedDocument.create({
    required String userId,
    required String documentType,
    required Map<String, dynamic> extractedData,
    required String summary,
    String? imagePath,
    List<String>? tags,
  }) {
    final now = DateTime.now();
    return ExtractedDocument(
      id: '', // Will be assigned by backend
      userId: userId,
      documentType: documentType,
      extractedData: extractedData,
      summary: summary,
      imagePath: imagePath,
      tags: tags ?? [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create from JSON (from API response)
  factory ExtractedDocument.fromJson(Map<String, dynamic> json) {
    return ExtractedDocument(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      documentType: json['document_type'] as String,
      extractedData: Map<String, dynamic>.from(json['extracted_data'] as Map),
      summary: json['summary'] as String,
      imagePath: json['image_url'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON (for API request)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'document_type': documentType,
      'extracted_data': extractedData,
      'summary': summary,
      'image_url': imagePath,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  ExtractedDocument copyWith({
    String? id,
    String? userId,
    String? documentType,
    Map<String, dynamic>? extractedData,
    String? summary,
    String? imagePath,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExtractedDocument(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      documentType: documentType ?? this.documentType,
      extractedData: extractedData ?? this.extractedData,
      summary: summary ?? this.summary,
      imagePath: imagePath ?? this.imagePath,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Get icon for document type
  String get typeIcon {
    switch (documentType.toLowerCase()) {
      case 'hospital':
      case 'medical':
        return '🏥';
      case 'appointment':
        return '📅';
      case 'id card':
      case 'identification':
        return '🪪';
      case 'bill':
      case 'invoice':
        return '💰';
      case 'prescription':
        return '💊';
      case 'receipt':
        return '🧾';
      default:
        return '📄';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExtractedDocument &&
        other.id == id &&
        other.userId == userId &&
        other.documentType == documentType &&
        mapEquals(other.extractedData, extractedData) &&
        other.summary == summary &&
        other.imagePath == imagePath &&
        listEquals(other.tags, tags) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      documentType,
      extractedData,
      summary,
      imagePath,
      tags,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'ExtractedDocument(id: $id, type: $documentType, summary: $summary)';
  }
}
