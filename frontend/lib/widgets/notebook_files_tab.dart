import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../services/notebook_service.dart';
import '../models/drive_file.dart';
import 'source_selection_panel.dart';

class NotebookFilesTab extends StatefulWidget {
  final String folderId;

  const NotebookFilesTab({super.key, required this.folderId});

  @override
  State<NotebookFilesTab> createState() => _NotebookFilesTabState();
}

class _NotebookFilesTabState extends State<NotebookFilesTab> {
  Set<String> _selectedFileIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final service = context.read<NotebookService>();
      final files = await service.getFiles(widget.folderId);

      if (!mounted) return;
      setState(() {
        _selectedFileIds = files
            .where((f) => f.driveFileId != null)
            .map((f) => f.driveFileId!)
            .toSet();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading files: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFileToggle(DriveFile file) async {
    // Optimistic update
    setState(() {
      if (_selectedFileIds.contains(file.id)) {
        _selectedFileIds.remove(file.id);
      } else {
        _selectedFileIds.add(file.id);
      }
    });

    try {
      final service = context.read<NotebookService>();

      // We need to re-fetch the list to find the ID to delete,
      // or to verify we're not adding a duplicate if race condition.
      // But since we are toggling, we can infer action.
      // However to delete, we strictly need the NotebookFile.id (int/string).

      // Fetch current files to get the mapping
      final currentFiles = await service.getFiles(widget.folderId);
      final existingFile = currentFiles
          .where((f) => f.driveFileId == file.id)
          .firstOrNull;

      if (existingFile != null) {
        // If it exists, we are removing it
        await service.deleteFile(existingFile.id);
      } else {
        // If it doesn't exist, we are adding it
        await service.addFile(
          folderId: widget.folderId,
          name: file.name,
          fileType: _getFileTypeFromMime(file.mimeType ?? ''),
          driveFileId: file.id,
          size: file.size,
        );
      }

      // Reload to ensure state is consistent
      await _loadFiles();
    } catch (e) {
      debugPrint('Error toggling file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating file selection: $e')),
        );
        // Revert on error
        _loadFiles();
      }
    }
  }

  Future<void> _handleClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Files'),
        content: const Text(
          'Are you sure you want to remove all files from this workspace?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _selectedFileIds.clear();
    });

    try {
      final service = context.read<NotebookService>();
      final files = await service.getFiles(widget.folderId);

      for (final file in files) {
        await service.deleteFile(file.id);
      }

      await _loadFiles();
    } catch (e) {
      debugPrint('Error clearing files: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error clearing files: $e')));
        _loadFiles();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SourceSelectionPanel(
      selectedFileIds: _selectedFileIds,
      onToggleFile: _handleFileToggle,
      onClearAll: _handleClearAll,
    );
  }
}

extension ListExtensions<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
