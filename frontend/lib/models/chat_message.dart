/// Model for chat messages
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<Citation>? citations;
  final bool isTyping;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.citations,
    this.isTyping = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['is_user'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      citations: json['citations'] != null
          ? (json['citations'] as List)
              .map((c) => Citation.fromJson(c))
              .toList()
          : null,
      isTyping: json['is_typing'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'citations': citations?.map((c) => c.toJson()).toList(),
      'is_typing': isTyping,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    List<Citation>? citations,
    bool? isTyping,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      citations: citations ?? this.citations,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

/// Model for citation references
class Citation {
  final String fileId;
  final String fileName;
  final int pageNumber;
  final String snippet;

  Citation({
    required this.fileId,
    required this.fileName,
    required this.pageNumber,
    this.snippet = '',
  });

  factory Citation.fromJson(Map<String, dynamic> json) {
    return Citation(
      fileId: json['file_id'] as String,
      fileName: json['file_name'] as String,
      pageNumber: json['page_number'] as int,
      snippet: json['snippet'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_id': fileId,
      'file_name': fileName,
      'page_number': pageNumber,
      'snippet': snippet,
    };
  }
}
