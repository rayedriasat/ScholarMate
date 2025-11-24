import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tag.dart';
import '../services/tag_service.dart';
import '../services/auth_service.dart';
import '../widgets/tag_create_dialog.dart';
import '../widgets/tag_edit_dialog.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../theme/app_colors.dart';

/// Screen for managing tags
class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({super.key});

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  List<Tag> _tags = [];
  bool _isLoading = true;
  String? _error;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadTags();
    }
  }

  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tagService = context.read<TagService>();
      final tags = await tagService.getTags();

      if (mounted) {
        setState(() {
          _tags = tags;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createTag() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const TagCreateDialog(),
    );

    if (result != null && mounted) {
      try {
        final authService = context.read<AuthService>();
        final tagService = context.read<TagService>();
        final userId = authService.currentUser?.id;

        if (userId == null) {
          throw Exception('User not authenticated');
        }

        await tagService.createTag(
          userId: userId,
          name: result['name']!,
          color: result['color']!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tag "${result['name']}" created')),
          );
          _loadTags();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to create tag: $e')));
        }
      }
    }
  }

  Future<void> _editTag(Tag tag) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => TagEditDialog(tag: tag),
    );

    if (result != null && mounted) {
      try {
        final authService = context.read<AuthService>();
        final tagService = context.read<TagService>();
        final userId = authService.currentUser?.id;

        if (userId == null) {
          throw Exception('User not authenticated');
        }

        await tagService.updateTag(
          tagId: tag.id,
          userId: userId,
          name: result['name'],
          color: result['color'],
        );

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Tag updated')));
          _loadTags();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to update tag: $e')));
        }
      }
    }
  }

  Future<void> _deleteTag(Tag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Tag', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${tag.name}"?\n\n'
          'This will remove the tag from ${tag.documentCount} document(s).',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ModernButton(
            onPressed: () => Navigator.pop(context, true),
            label: 'Delete',
            backgroundColor: Colors.red,
            width: 80,
            height: 36,
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final authService = context.read<AuthService>();
        final tagService = context.read<TagService>();
        final userId = authService.currentUser?.id;

        if (userId == null) {
          throw Exception('User not authenticated');
        }

        await tagService.deleteTag(tagId: tag.id, userId: userId);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Tag "${tag.name}" deleted')));
          _loadTags();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete tag: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Tags', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTags,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTag,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ModernButton(onPressed: _loadTags, label: 'Retry'),
          ],
        ),
      );
    }

    if (_tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.label_outline, size: 48, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No tags yet',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create tags to organize your documents',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ModernButton(
              onPressed: _createTag,
              icon: Icons.add,
              label: 'Create Tag',
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tags.length,
      itemBuilder: (context, index) {
        final tag = _tags[index];
        return GlassContainer(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _parseColor(tag.color),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _parseColor(tag.color).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.label, color: Colors.white, size: 20),
            ),
            title: Text(
              tag.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              '${tag.documentCount} document${tag.documentCount == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: AppColors.surface,
              onSelected: (value) {
                if (value == 'edit') {
                  _editTag(tag);
                } else if (value == 'delete') {
                  _deleteTag(tag);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Rename', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.blue;
    }
  }
}
