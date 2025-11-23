import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

/// Widget for displaying a chat message bubble
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(Citation)? onCitationTapped;
  final VoidCallback? onSaveAsNote;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onCitationTapped,
    this.onSaveAsNote,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment:
            CrossAxisAlignment.end, // Align to bottom for modern look
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary
                        : isDark
                        ? const Color(0xFF2C2C2C)
                        : Colors.white,
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isUser
                              ? Colors.white
                              : isDark
                              ? Colors.white
                              : const Color(0xFF2D3748),
                          fontSize: 14.5,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (message.citations != null &&
                          message.citations!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: message.citations!.map((citation) {
                              return _buildCitationChip(
                                context,
                                citation,
                                isUser,
                                isDark,
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTimestamp(message.timestamp),
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!isUser && onSaveAsNote != null) ...[
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: onSaveAsNote,
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bookmark_border,
                              size: 14,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3A3A3A) : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: isDark ? Colors.white70 : Colors.grey[600],
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCitationChip(
    BuildContext context,
    Citation citation,
    bool isUser,
    bool isDark,
  ) {
    final textColor = isUser
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.primary;
    final backgroundColor = isUser
        ? Colors.white.withValues(alpha: 0.2)
        : AppColors.primary.withValues(alpha: 0.1);

    return InkWell(
      onTap: () => onCitationTapped?.call(citation),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isUser
                ? Colors.white.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 14, color: textColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${citation.fileName} (p. ${citation.pageNumber})',
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
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

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return DateFormat('h:mm a').format(timestamp);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE h:mm a').format(timestamp);
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }
}
