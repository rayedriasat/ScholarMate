import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tag.dart';
import '../services/tag_service.dart';
import '../services/auth_service.dart';
import '../widgets/tag_create_dialog.dart';
import '../widgets/tag_edit_dialog.dart';

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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
      appBar: AppBar(
        title: const Text('Manage Tags'),
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
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadTags, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.label_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No tags yet'),
            const SizedBox(height: 8),
            const Text(
              'Create tags to organize your documents',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createTag,
              icon: const Icon(Icons.add),
              label: const Text('Create Tag'),
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
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _parseColor(tag.color),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.label, color: Colors.white),
            ),
            title: Text(
              tag.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${tag.documentCount} document${tag.documentCount == 1 ? '' : 's'}',
            ),
            trailing: PopupMenuButton<String>(
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
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Rename'),
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
