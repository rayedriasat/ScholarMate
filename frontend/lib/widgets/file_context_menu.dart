import 'package:flutter/material.dart';
import '../models/drive_file.dart';

/// Context menu for file and folder operations
class FileContextMenu extends StatelessWidget {
  final DriveFile file;
  final VoidCallback? onRename;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onManageTags;
  final VoidCallback? onReindex;

  const FileContextMenu({
    super.key,
    required this.file,
    this.onRename,
    this.onMove,
    this.onDelete,
    this.onShare,
    this.onManageTags,
    this.onReindex,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'rename':
            onRename?.call();
            break;
          case 'move':
            onMove?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
          case 'share':
            onShare?.call();
            break;
          case 'manage_tags':
            onManageTags?.call();
            break;
          case 'reindex':
            onReindex?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 18),
              const SizedBox(width: 12),
              Text('Rename ${file.isFolder ? 'folder' : 'file'}'),
            ],
          ),
        ),
        if (!file.isFolder) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'manage_tags',
            child: Row(
              children: [
                const Icon(Icons.label, size: 18),
                const SizedBox(width: 12),
                const Text('Manage Tags'),
              ],
            ),
          ),
          if (file.isPdf) ...[
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'reindex',
              child: Row(
                children: [
                  const Icon(Icons.refresh, size: 18),
                  const SizedBox(width: 12),
                  const Text('Reindex for AI'),
                ],
              ),
            ),
          ],
        ],
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(file.isFolder ? Icons.folder_shared : Icons.share, size: 18),
              const SizedBox(width: 12),
              Text('Share ${file.isFolder ? 'folder' : 'file'}'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 18, color: Colors.red),
              const SizedBox(width: 12),
              Text(
                'Delete ${file.isFolder ? 'folder' : 'file'}',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Icon(Icons.more_vert, size: 20),
      ),
    );
  }
}

/// Dialog for renaming files and folders
class RenameDialog extends StatefulWidget {
  final DriveFile file;
  final Function(String) onRename;

  const RenameDialog({super.key, required this.file, required this.onRename});

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.file.name);

    // Select filename without extension for files
    if (!widget.file.isFolder && widget.file.extension != null) {
      final nameWithoutExt = widget.file.name.substring(
        0,
        widget.file.name.lastIndexOf('.${widget.file.extension!}'),
      );
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: nameWithoutExt.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rename ${widget.file.isFolder ? 'Folder' : 'File'}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a name';
            }
            if (value.trim() == widget.file.name) {
              return 'Please enter a different name';
            }
            return null;
          },
          onFieldSubmitted: (_) => _rename(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _rename, child: const Text('Rename')),
      ],
    );
  }

  void _rename() {
    if (_formKey.currentState!.validate()) {
      widget.onRename(_controller.text.trim());
      Navigator.of(context).pop();
    }
  }
}

/// Confirmation dialog for destructive actions
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.onConfirm,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: isDestructive
              ? TextButton.styleFrom(foregroundColor: Colors.red)
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }
}
