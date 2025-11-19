/// Collaboration models for real-time PDF sessions
import 'package:flutter/material.dart';

/// User cursor position in PDF
class CursorPosition {
  final double x; // 0-1 normalized
  final double y; // 0-1 normalized
  final int pageNumber;

  CursorPosition({
    required this.x,
    required this.y,
    required this.pageNumber,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'page_number': pageNumber,
      };

  factory CursorPosition.fromJson(Map<String, dynamic> json) => CursorPosition(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        pageNumber: json['page_number'] as int,
      );
}

/// Session role
enum SessionRole {
  owner,
  editor,
  viewer;

  String toJson() => name;

  static SessionRole fromJson(String value) {
    return SessionRole.values.firstWhere((e) => e.name == value);
  }
}

/// Session participant
class SessionParticipant {
  final String userId;
  final String userName;
  final String userEmail;
  final Color userColor;
  final SessionRole role;
  final CursorPosition? cursorPosition;
  final DateTime lastSeen;

  SessionParticipant({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userColor,
    required this.role,
    this.cursorPosition,
    required this.lastSeen,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'user_color': '#${userColor.value.toRadixString(16).substring(2)}',
        'role': role.toJson(),
        'cursor_position': cursorPosition?.toJson(),
        'last_seen': lastSeen.toIso8601String(),
      };

  factory SessionParticipant.fromJson(Map<String, dynamic> json) {
    final colorHex = json['user_color'] as String;
    final color = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);

    return SessionParticipant(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userEmail: json['user_email'] as String,
      userColor: color,
      role: SessionRole.fromJson(json['role'] as String),
      cursorPosition: json['cursor_position'] != null
          ? CursorPosition.fromJson(json['cursor_position'] as Map<String, dynamic>)
          : null,
      lastSeen: DateTime.parse(json['last_seen'] as String),
    );
  }

  SessionParticipant copyWith({
    CursorPosition? cursorPosition,
    DateTime? lastSeen,
  }) {
    return SessionParticipant(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userColor: userColor,
      role: role,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

/// Collaboration session
class CollaborationSession {
  final String sessionId;
  final String fileId;
  final String fileName;
  final String ownerId;
  final String shareLink;
  final List<SessionParticipant> participants;
  final DateTime createdAt;
  final DateTime? expiresAt;

  CollaborationSession({
    required this.sessionId,
    required this.fileId,
    required this.fileName,
    required this.ownerId,
    required this.shareLink,
    required this.participants,
    required this.createdAt,
    this.expiresAt,
  });

  factory CollaborationSession.fromJson(Map<String, dynamic> json) {
    return CollaborationSession(
      sessionId: json['session_id'] as String,
      fileId: json['file_id'] as String,
      fileName: json['file_name'] as String,
      ownerId: json['owner_id'] as String,
      shareLink: json['share_link'] as String,
      participants: (json['participants'] as List)
          .map((p) => SessionParticipant.fromJson(p as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
    );
  }

  CollaborationSession copyWith({
    List<SessionParticipant>? participants,
  }) {
    return CollaborationSession(
      sessionId: sessionId,
      fileId: fileId,
      fileName: fileName,
      ownerId: ownerId,
      shareLink: shareLink,
      participants: participants ?? this.participants,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }
}

/// Real-time annotation update
class CollaborationAnnotation {
  final String? id;
  final String userId;
  final String userName;
  final Color userColor;
  final String annotationType;
  final int pageNumber;
  final Map<String, dynamic> positionData;
  final String? content;
  final String? color;
  final DateTime createdAt;

  CollaborationAnnotation({
    this.id,
    required this.userId,
    required this.userName,
    required this.userColor,
    required this.annotationType,
    required this.pageNumber,
    required this.positionData,
    this.content,
    this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'user_name': userName,
        'user_color': '#${userColor.value.toRadixString(16).substring(2)}',
        'annotation_type': annotationType,
        'page_number': pageNumber,
        'position_data': positionData,
        if (content != null) 'content': content,
        if (color != null) 'color': color,
        'created_at': createdAt.toIso8601String(),
      };

  factory CollaborationAnnotation.fromJson(Map<String, dynamic> json) {
    final colorHex = json['user_color'] as String;
    final userColor = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);

    return CollaborationAnnotation(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userColor: userColor,
      annotationType: json['annotation_type'] as String,
      pageNumber: json['page_number'] as int,
      positionData: json['position_data'] as Map<String, dynamic>,
      content: json['content'] as String?,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
