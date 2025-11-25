import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/file_chat_service.dart';
import '../models/file_chat_message.dart' as model;

/// Floating chat head with popup chat window for PDF notes
class FileChatPanel extends StatefulWidget {
  final String fileId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;

  const FileChatPanel({
    super.key,
    required this.fileId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
  });

  @override
  State<FileChatPanel> createState() => _FileChatPanelState();
}

class _FileChatPanelState extends State<FileChatPanel> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isOpen = false;
  bool _isLoading = true;
  List<model.FileChatMessage> _messages = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final chatService = context.read<FileChatService>();

      await chatService.initializeChat(
        fileId: widget.fileId,
        userId: widget.userId,
        userName: widget.userName,
        userPhotoUrl: widget.userPhotoUrl,
      );

      final messages = await chatService.fetchMessages(widget.fileId);

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }

      chatService.addListener(_onMessagesUpdated);
    } catch (e) {
      debugPrint('FileChatPanel init error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onMessagesUpdated() async {
    try {
      final chatService = context.read<FileChatService>();
      final messages = await chatService.fetchMessages(widget.fileId);

      if (mounted) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    try {
      final chatService = context.read<FileChatService>();
      await chatService.sendMessage(fileId: widget.fileId, content: content);

      final messages = await chatService.fetchMessages(widget.fileId);
      if (mounted) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
    });
    if (_isOpen) {
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    try {
      context.read<FileChatService>().removeListener(_onMessagesUpdated);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Just show the chat head when closed
    if (!_isOpen) {
      return _buildChatHead(isDark);
    }

    // Show popup + chat head when open
    return SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildChatPopup(isDark),
          const SizedBox(height: 8),
          _buildChatHead(isDark),
        ],
      ),
    );
  }

  Widget _buildChatHead(bool isDark) {
    return GestureDetector(
      onTap: _toggleChat,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isOpen
                ? [Colors.grey[600]!, Colors.grey[700]!]
                : [const Color(0xFF10B981), const Color(0xFF059669)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isOpen ? Colors.grey : const Color(0xFF10B981))
                  .withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                _isOpen ? Icons.close : Icons.forum_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            if (!_isOpen && _messages.isNotEmpty)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1F2937) : Colors.white,
                      width: 2,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    _messages.length > 9 ? '9+' : '${_messages.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPopup(bool isDark) {
    return Container(
      width: 280,
      height: 320,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildPopupHeader(isDark),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _messages.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildMessageList(isDark),
            ),
            _buildInputArea(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.sticky_note_2, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Notes',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_messages.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 32,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No notes yet',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start a discussion',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isCurrentUser = message.userId == widget.userId;
        return _buildMessageBubble(message, isCurrentUser, isDark);
      },
    );
  }

  Widget _buildMessageBubble(
    model.FileChatMessage message,
    bool isCurrentUser,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            _buildSmallAvatar(message),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? const Color(0xFF10B981)
                    : isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isCurrentUser ? 12 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        message.userName.split(' ').first,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: isCurrentUser
                          ? Colors.white
                          : isDark
                          ? Colors.grey[200]
                          : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 9,
                      color: isCurrentUser
                          ? Colors.white.withOpacity(0.7)
                          : isDark
                          ? Colors.grey[600]
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 6),
            _buildSmallAvatar(message),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallAvatar(model.FileChatMessage message) {
    if (message.userPhotoUrl != null) {
      return CircleAvatar(
        radius: 12,
        backgroundImage: NetworkImage(message.userPhotoUrl!),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          message.userName.isNotEmpty ? message.userName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Add note...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
                maxLines: 2,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${timestamp.day}/${timestamp.month}';
  }
}
