import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tag.dart';
import '../services/tag_service.dart';
import '../services/auth_service.dart';

/// Dialog for selecting tags to apply to files
class TagSelectionDialog extends StatefulWidget {
  final List<String> fileIds;
  final List<Tag>? currentTags;

  const TagSelectionDialog({
    super.key,
    required this.fileIds,
    this.currentTags,
  });

  @override
  State<TagSelectionDialog> createState() => _TagSelectionDialogState();
}

class _TagSelectionDialogState extends State<TagSelectionDialog> {
  List<Tag> _allTags = [];
  Set<String> _selectedTagIds = {};
  bool _isLoading = true;
  String? _error;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Pre-select current tags if editing single file
    if (widget.currentTags != null) {
      _selectedTagIds = widget.currentTags!.map((t) => t.id).toSet();
    }
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
          _allTags = tags;
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

  Future<void> _applyTags() async {
    if (_selectedTagIds.isEmpty) {
      Navigator.pop(context);
      return;
    }

    try {
      final authService = context.read<AuthService>();
      final tagService = context.read<TagService>();
      final userId = authService.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Apply tags
      if (widget.fileIds.length == 1) {
        // Single file - add/remove tags individually
        final fileId = widget.fileIds.first;
        final currentTagIds =
            widget.currentTags?.map((t) => t.id).toSet() ?? {};

        // Add new tags
        for (final tagId in _selectedTagIds) {
          if (!currentTagIds.contains(tagId)) {
            await tagService.addTagToFile(
              userId: userId,
              fileId: fileId,
              tagId: tagId,
            );
          }
        }

        // Remove unselected tags
        for (final tagId in currentTagIds) {
          if (!_selectedTagIds.contains(tagId)) {
            await tagService.removeTagFromFile(
              userId: userId,
              fileId: fileId,
              tagId: tagId,
            );
          }
        }
      } else {
        // Multiple files - bulk add selected tags
        await tagService.bulkTagFiles(
          userId: userId,
          fileIds: widget.fileIds,
          tagIds: _selectedTagIds.toList(),
        );
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context, true); // Close tag selection dialog with success
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to apply tags: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.fileIds.length == 1
            ? 'Manage Tags'
            : 'Tag ${widget.fileIds.length} Files',
      ),
      content: SizedBox(width: double.maxFinite, child: _buildContent()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedTagIds.isEmpty ? null : _applyTags,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

    if (_allTags.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.label_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No tags available'),
            const SizedBox(height: 8),
            const Text(
              'Create tags in the tag management screen',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _allTags.length,
      itemBuilder: (context, index) {
        final tag = _allTags[index];
        final isSelected = _selectedTagIds.contains(tag.id);

        return CheckboxListTile(
          value: isSelected,
          onChanged: (selected) {
            setState(() {
              if (selected == true) {
                _selectedTagIds.add(tag.id);
              } else {
                _selectedTagIds.remove(tag.id);
              }
            });
          },
          title: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _parseColor(tag.color),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(tag.name)),
            ],
          ),
          subtitle: Text('${tag.documentCount} documents'),
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
