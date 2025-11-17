import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notebook_service.dart';
import '../services/drive_service.dart';
import '../models/drive_file.dart';

/// Files tab with source selection (like AI Chat)
class NotebookFilesTabV2 extends StatefulWidget {
  final String folderId;

  const NotebookFilesTabV2({super.key, required this.folderId});

  @override
  State<NotebookFilesTabV2> createState() => _NotebookFilesTabV2State();
}

class _NotebookFilesTabV2State extends State<NotebookFilesTabV2> {
  List<DriveFile> _availableFiles = [];
  Set<String> _selectedFileIds = {};
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFiles();
    _loadSelectedFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final driveService = context.read<DriveService>();
      final files = await driveService.listFiles();

      // Filter to only show non-folder files
      final nonFolderFiles = files.where((f) => !f.isFolder).toList();

      setState(() {
        _availableFiles = nonFolderFiles;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading files: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSelectedFiles() async {
    try {
      final service = context.read<NotebookService>();
      final workspaceFiles = await service.getFiles(widget.folderId);

      setState(() {
        _selectedFileIds = workspaceFiles
            .where((f) => f.driveFileId != null)
            .map((f) => f.driveFileId!)
            .toSet();
      });
    } catch (e) {
      debugPrint('Error loading selected files: $e');
    }
  }

  Future<void> _toggleFile(String fileId) async {
    final service = context.read<NotebookService>();

    if (_selectedFileIds.contains(fileId)) {
      // Remove file
      setState(() => _selectedFileIds.remove(fileId));

      // Find and delete from database
      final workspaceFiles = await service.getFiles(widget.folderId);
      final fileToRemove = workspaceFiles.where((f) => f.driveFileId == fileId);
      for (final file in fileToRemove) {
        await service.deleteFile(file.id);
      }
    } else {
      // Add file
      setState(() => _selectedFileIds.add(fileId));

      // Find file details
      final file = _availableFiles.firstWhere((f) => f.id == fileId);

      // Add to database
      await service.addFile(
        folderId: widget.folderId,
        name: file.name,
        fileType: _getFileTypeFromMime(file.mimeType ?? ''),
        driveFileId: file.id,
        size: file.size,
      );
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

  void _selectAll() async {
    setState(() {
      _selectedFileIds = _availableFiles.map((f) => f.id).toSet();
    });
    await _saveSelection();
  }

  void _clearAll() async {
    setState(() {
      _selectedFileIds.clear();
    });
    await _saveSelection();
  }

  Future<void> _saveSelection() async {
    final service = context.read<NotebookService>();

    // Get current workspace files
    final currentFiles = await service.getFiles(widget.folderId);

    // Remove files not in selection
    for (final file in currentFiles) {
      if (file.driveFileId != null &&
          !_selectedFileIds.contains(file.driveFileId)) {
        await service.deleteFile(file.id);
      }
    }

    // Add files in selection that aren't in workspace
    final currentDriveIds = currentFiles
        .map((f) => f.driveFileId)
        .whereType<String>()
        .toSet();

    for (final fileId in _selectedFileIds) {
      if (!currentDriveIds.contains(fileId)) {
        final file = _availableFiles.firstWhere((f) => f.id == fileId);
        await service.addFile(
          folderId: widget.folderId,
          name: file.name,
          fileType: _getFileTypeFromMime(file.mimeType ?? ''),
          driveFileId: file.id,
          size: file.size,
        );
      }
    }
  }

  List<DriveFile> get _filteredFiles {
    if (_searchQuery.isEmpty) return _availableFiles;

    return _availableFiles.where((file) {
      return file.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchBar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildFileList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Source Selection',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadFiles,
                tooltip: 'Refresh files',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_selectedFileIds.length} of ${_availableFiles.length} selected',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectAll,
                  icon: const Icon(Icons.check_box, size: 18),
                  label: const Text('Select All'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear All'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search files...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildFileList() {
    final files = _filteredFiles;

    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No files available' : 'No files found',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              const Text('Upload files in the main Files screen'),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final isSelected = _selectedFileIds.contains(file.id);

        return CheckboxListTile(
          value: isSelected,
          onChanged: (_) => _toggleFile(file.id),
          title: Text(file.name),
          subtitle: Text(_getFileTypeLabel(file.mimeType ?? '')),
          secondary: Icon(_getFileIcon(file.mimeType ?? '')),
          activeColor: Theme.of(context).primaryColor,
        );
      },
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
