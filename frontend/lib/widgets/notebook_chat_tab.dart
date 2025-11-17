import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../database/database.dart';
import '../services/notebook_service.dart';
import '../services/ai_chat_service.dart';
import '../services/auth_service.dart';

/// Chat tab for notebook folder
class NotebookChatTab extends StatefulWidget {
  final String folderId;

  const NotebookChatTab({super.key, required this.folderId});

  @override
  State<NotebookChatTab> createState() => _NotebookChatTabState();
}

class _NotebookChatTabState extends State<NotebookChatTab> {
  NotebookChat? _currentChat;
  List<NotebookChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIChatService _chatService = AIChatService();
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadOrCreateChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOrCreateChat() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<NotebookService>();
      final chats = await service.getChats(widget.folderId);

      if (chats.isEmpty) {
        // Create default chat
        final chat = await service.createChat(
          folderId: widget.folderId,
          title: 'Chat',
        );
        setState(() => _currentChat = chat);
      } else {
        setState(() => _currentChat = chats.first);
      }

      await _loadMessages();
    } catch (e) {
      debugPrint('Error loading chat: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_currentChat == null) return;

    try {
      final service = context.read<NotebookService>();
      final messages = await service.getMessages(_currentChat!.id);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentChat == null) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    try {
      final service = context.read<NotebookService>();

      // Add user message
      await service.addMessage(
        chatId: _currentChat!.id,
        content: userMessage,
        isUser: true,
      );

      await _loadMessages();

      // Get AI response using RAG (same as AI Chat screen)
      final authService = context.read<AuthService>();
      final userId = authService.currentUser?.id ?? '';

      // Get folder files for context
      final files = await service.getFiles(widget.folderId);
      final fileIds = files
          .where((f) => f.driveFileId != null)
          .map((f) => f.driveFileId!)
          .toList();

      if (fileIds.isEmpty) {
        // No files to query
        await service.addMessage(
          chatId: _currentChat!.id,
          content:
              'Please add files to this workspace first. I need documents to answer your questions.',
          isUser: false,
        );
        await _loadMessages();
        return;
      }

      String aiResponse;
      String? citationsJson;

      try {
        // Use the same AI chat service as the main AI Chat screen
        final response = await _chatService.sendMessage(
          question: userMessage,
          userId: userId,
          selectedFileIds: fileIds,
          topK: 5,
        );

        aiResponse = response.content;

        // Format citations if available
        if (response.citations != null && response.citations!.isNotEmpty) {
          citationsJson = jsonEncode(
            response.citations!.map((c) => c.toJson()).toList(),
          );
        }
      } catch (e) {
        debugPrint('Error getting AI response: $e');
        aiResponse =
            'Sorry, I encountered an error: ${e.toString()}. Please check your API key configuration and try again.';
      }

      // Add AI response
      await service.addMessage(
        chatId: _currentChat!.id,
        content: aiResponse,
        isUser: false,
        citations: citationsJson,
      );

      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _MessageBubble(message: message);
                  },
                ),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Start a conversation'),
          const SizedBox(height: 8),
          Text(
            'Ask questions about your files',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              enabled: !_isSending,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _isSending ? null : _sendMessage,
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final NotebookChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    List<dynamic>? citations;

    // Parse citations if available
    if (!isUser && message.citations != null) {
      try {
        citations = jsonDecode(message.citations!) as List<dynamic>;
      } catch (e) {
        debugPrint('Error parsing citations: $e');
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: theme.primaryColor,
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? theme.primaryColor : theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : theme.textTheme.bodyLarge?.color,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(message.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                // Citations
                if (citations != null && citations.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: citations.map((citation) {
                        return _buildCitationChip(context, citation);
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[700], size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCitationChip(
    BuildContext context,
    Map<String, dynamic> citation,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fileName = citation['file_name'] ?? 'Unknown';
    final pageNumber = citation['page_number'] ?? 0;

    final backgroundColor = colorScheme.primaryContainer;
    final textColor = colorScheme.onPrimaryContainer;
    final borderColor = colorScheme.outline.withOpacity(0.5);

    return Tooltip(
      message: 'Source: $fileName, Page $pageNumber',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf, size: 14, color: textColor),
            const SizedBox(width: 4),
            Text(
              '$fileName (p. $pageNumber)',
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
