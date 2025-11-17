import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../services/notebook_service.dart';
import '../services/drive_service.dart';

class NotebookFilesTab extends StatefulWidget {
  final String folderId;

  const NotebookFilesTab({super.key, required this.folderId});

  @override
  State<NotebookFilesTab> createState() => _NotebookFilesTabState();
}

class _NotebookFilesTabState extends State<NotebookFilesTab> {
  List<NotebookFile> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<NotebookService>();
      final files = await service.getFiles(widget.folderId);
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading files: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createNote() async {
    final nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Note'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Note Name',
            hintText: 'e.g., Meeting Notes',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        final service = context.read<NotebookService>();
        await service.addFile(
          folderId: widget.folderId,
          name: nameController.text,
          fileType: 'markdown',
          content: '',
        );
        await _loadFiles();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creating note: $e')));
        }
      }
    }
  }

  Future<void> _addFromDrive() async {
    try {
      final driveService = context.read<DriveService>();
      final service = context.read<NotebookService>();

      // Get all files from Drive
      final driveFiles = await driveService.listFiles();

      if (!mounted) return;

      // Show file selection dialog
      final selectedFiles = await showDialog<List<DriveFile>>(
        context: context,
        builder: (context) => _FileSelectionDialog(files: driveFiles),
      );

      if (selectedFiles != null && selectedFiles.isNotEmpty) {
        for (final file in selectedFiles) {
          final fileType = _getFileTypeFromMime(file.mimeType ?? '');
          await service.addFile(
            folderId: widget.folderId,
            name: file.name,
            fileType: fileType,
            driveFileId: file.id,
            size: file.size,
          );
        }
        await _loadFiles();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Added ${selectedFiles.length} file(s) to workspace',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding files: $e')));
      }
    }
  }

  String _getFileTypeFromMime(String mimeType) {
    if (mimeType.contains('pdf')) return 'pdf';
    if (mimeType.contains('markdown') || mimeType.contains('text')) {
      return 'markdown';
    }
    if (mimeType.contains('image')) return 'image';
    return 'other';
  }

  Future<void> _deleteFile(NotebookFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = context.read<NotebookService>();
        await service.deleteFile(file.id);
        await _loadFiles();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting file: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_files.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _createNote,
                  icon: const Icon(Icons.note_add),
                  label: const Text('New Note'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addFromDrive,
                  icon: const Icon(Icons.add_to_drive),
                  label: const Text('Add from Drive'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _files.length,
            itemBuilder: (context, index) {
              final file = _files[index];
              return _FileListTile(
                file: file,
                onTap: () => _openFile(file),
                onDelete: () => _deleteFile(file),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No files yet'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _createNote,
            icon: const Icon(Icons.note_add),
            label: const Text('Create Note'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addFromDrive,
            icon: const Icon(Icons.add_to_drive),
            label: const Text('Add from Drive'),
          ),
        ],
      ),
    );
  }

  void _openFile(NotebookFile file) {
    // TODO: Open file viewer/editor based on file type
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Opening ${file.name}...')));
  }
}

class _FileListTile extends StatelessWidget {
  final NotebookFile file;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FileListTile({
    required this.file,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_getFileIcon(file.fileType)),
      title: Text(file.name),
      subtitle: Text(_formatDate(file.updatedAt)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'markdown':
        return Icons.description;
      case 'image':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Dialog for selecting files from Drive
class _FileSelectionDialog extends StatefulWidget {
  final List<DriveFile> files;

  const _FileSelectionDialog({required this.files});

  @override
  State<_FileSelectionDialog> createState() => _FileSelectionDialogState();
}

class _FileSelectionDialogState extends State<_FileSelectionDialog> {
  final Set<String> _selectedFileIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Files from Drive'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: widget.files.isEmpty
            ? const Center(child: Text('No files available'))
            : ListView.builder(
                itemCount: widget.files.length,
                itemBuilder: (context, index) {
                  final file = widget.files[index];
                  if (file.isFolder) return const SizedBox.shrink();

                  final isSelected = _selectedFileIds.contains(file.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedFileIds.add(file.id);
                        } else {
                          _selectedFileIds.remove(file.id);
                        }
                      });
                    },
                    title: Text(file.name),
                    subtitle: Text(_getFileTypeLabel(file.mimeType ?? '')),
                    secondary: Icon(_getFileIcon(file.mimeType ?? '')),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedFileIds.isEmpty
              ? null
              : () {
                  final selectedFiles = widget.files
                      .where((f) => _selectedFileIds.contains(f.id))
                      .toList();
                  Navigator.pop(context, selectedFiles);
                },
          child: Text('Add ${_selectedFileIds.length} file(s)'),
        ),
      ],
    );
  }

  String _getFileTypeLabel(String mimeType) {
    if (mimeType.contains('pdf')) return 'PDF Document';
    if (mimeType.contains('markdown')) return 'Markdown';
    if (mimeType.contains('text')) return 'Text Document';
    if (mimeType.contains('image')) return 'Image';
    return 'File';
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('markdown')) return Icons.description;
    if (mimeType.contains('text')) return Icons.description;
    if (mimeType.contains('image')) return Icons.image;
    return Icons.insert_drive_file;
  }
}
