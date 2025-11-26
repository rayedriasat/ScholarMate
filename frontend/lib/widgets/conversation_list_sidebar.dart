import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../theme/app_colors.dart';
import 'ui/glass_container.dart';
import 'ui/modern_button.dart';
import 'ui/modern_text_field.dart';

/// Sidebar widget for displaying chat conversation history
class ConversationListSidebar extends StatelessWidget {
  final List<ChatConversation> conversations;
  final String? currentConversationId;
  final Function(String conversationId) onConversationSelected;
  final Function() onNewConversation;
  final Function(String conversationId) onDeleteConversation;
  final Function(String conversationId, String newTitle) onRenameConversation;
  final bool isLoading;
  final double width;

  const ConversationListSidebar({
    super.key,
    required this.conversations,
    this.currentConversationId,
    required this.onConversationSelected,
    required this.onNewConversation,
    required this.onDeleteConversation,
    required this.onRenameConversation,
    this.isLoading = false,
    this.width = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with new conversation button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ModernButton(
                onPressed: onNewConversation,
                icon: Icons.add,
                label: 'New Chat',
                height: 40,
              ),
            ),
          ),

          // Conversation list
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : conversations.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final isSelected =
                          conversation.id == currentConversationId;

                      return _ConversationListItem(
                        conversation: conversation,
                        isSelected: isSelected,
                        onTap: () => onConversationSelected(conversation.id),
                        onDelete: () => onDeleteConversation(conversation.id),
                        onRename: (newTitle) =>
                            onRenameConversation(conversation.id, newTitle),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new chat to begin',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationListItem extends StatelessWidget {
  final ChatConversation conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(String newTitle) onRename;

  const _ConversationListItem({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');
    final now = DateTime.now();
    final isToday =
        conversation.updatedAt.year == now.year &&
        conversation.updatedAt.month == now.month &&
        conversation.updatedAt.day == now.day;

    final dateText = isToday
        ? timeFormat.format(conversation.updatedAt)
        : dateFormat.format(conversation.updatedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Theme.of(context).cardColor,
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.5)
              : Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateText,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  color: Theme.of(context).cardColor,
                  onSelected: (value) {
                    if (value == 'rename') {
                      _showRenameDialog(context);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Rename',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: conversation.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Rename Conversation',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: ModernTextField(controller: controller, hintText: 'Title'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                onRename(newTitle);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Delete Conversation',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
