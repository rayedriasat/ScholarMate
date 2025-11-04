import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import 'package:intl/intl.dart';

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
    final theme = Theme.of(context);

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
              child: const Icon(Icons.smart_toy, color: Colors.white),
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
                        color: Colors.black.withValues(alpha: 0.05),
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

                // Timestamp and actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTimestamp(message.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                    // Save as Note button for AI messages
                    if (!isUser && onSaveAsNote != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onSaveAsNote,
                        borderRadius: BorderRadius.circular(12),
                        child: Tooltip(
                          message: 'Save as Note',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.save_alt,
                                  size: 14,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Citations
                if (message.citations != null && message.citations!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: message.citations!.map((citation) {
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
              child: Icon(Icons.person, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCitationChip(BuildContext context, Citation citation) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use theme-aware colors for better contrast in both light and dark modes
    final backgroundColor = colorScheme.primaryContainer;
    final textColor = colorScheme.onPrimaryContainer;
    final borderColor = colorScheme.outline.withValues(alpha: 0.5);

    return Tooltip(
      message:
          'Click to open ${citation.fileName} at page ${citation.pageNumber}',
      child: InkWell(
        onTap: () => onCitationTapped?.call(citation),
        borderRadius: BorderRadius.circular(16),
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
              Flexible(
                child: Text(
                  '${citation.fileName} (p. ${citation.pageNumber})',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.open_in_new, size: 12, color: textColor),
            ],
          ),
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
