/// Model for file chat messages
class FileChatMessage {
  final String id;
  final String threadId;
  final String fileId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String content;
  final DateTime timestamp;
  final bool isSynced;

  FileChatMessage({
    required this.id,
    required this.threadId,
    required this.fileId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.content,
    required this.timestamp,
    this.isSynced = false,
  });

  /// Create from JSON (Supabase response)
  factory FileChatMessage.fromJson(Map<String, dynamic> json) {
    return FileChatMessage(
      id: json['id'] as String,
      threadId: json['thread_id'] as String,
      fileId: json['file_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userPhotoUrl: json['user_photo_url'] as String?,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSynced: true,
    );
  }

  /// Convert to JSON (for Supabase insert)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'thread_id': threadId,
      'file_id': fileId,
      'user_id': userId,
      'user_name': userName,
      'user_photo_url': userPhotoUrl,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  FileChatMessage copyWith({
    String? id,
    String? threadId,
    String? fileId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? content,
    DateTime? timestamp,
    bool? isSynced,
  }) {
    return FileChatMessage(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      fileId: fileId ?? this.fileId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
