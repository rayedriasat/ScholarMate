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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surface : null,
        title: const Text('Delete Tag'),
        content: Text(
          'Are you sure you want to delete "${tag.name}"?\n\n'
          'This will remove the tag from ${tag.documentCount} document(s).',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.background : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Tags'),
        backgroundColor: isDark ? AppColors.surface : null,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
            Icon(Icons.error_outline, size: 48, color: Colors.red.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
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
            Icon(
              Icons.label_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No tags yet',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create tags to organize your documents',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return GlassContainer(
          borderRadius: BorderRadius.circular(16),
          color: isDark 
              ? AppColors.surface 
              : Colors.white.withValues(alpha: 0.7),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              '${tag.documentCount} document${tag.documentCount == 1 ? '' : 's'}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surface
                  : Colors.white,
              onSelected: (value) {
                if (value == 'edit') {
                  _editTag(tag);
                } else if (value == 'delete') {
                  _deleteTag(tag);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      const Text('Rename'),
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
