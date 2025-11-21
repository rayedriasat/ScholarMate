import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drive_file.dart';
import '../services/drive_service.dart';

/// Dialog for selecting a PDF file from the app's file system
class PdfFilePickerDialog extends StatefulWidget {
  const PdfFilePickerDialog({super.key});

  @override
  State<PdfFilePickerDialog> createState() => _PdfFilePickerDialogState();
}

class _PdfFilePickerDialogState extends State<PdfFilePickerDialog> {
  List<DriveFile> _files = [];
  List<DriveFile> _navigationPath = [];
  bool _isLoading = true;
  String? _error;
  String? _currentFolderId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _loadFiles();
    });
    _loadFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final driveService = context.read<DriveService>();
      final files = await driveService.listFiles(_currentFolderId);

      // Filter to show only PDFs and folders, and apply search
      final filteredFiles = files.where((file) {
        final matchesMimeType =
            file.mimeType == 'application/pdf' ||
            file.mimeType == 'application/vnd.google-apps.folder';

        if (_searchQuery.isEmpty) {
          return matchesMimeType;
        }

        return matchesMimeType &&
            file.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();

      // Sort: folders first, then PDFs
      filteredFiles.sort((a, b) {
        if (a.isFolder && !b.isFolder) return -1;
        if (!a.isFolder && b.isFolder) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      setState(() {
        _files = filteredFiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToFolder(DriveFile folder) {
    setState(() {
      _currentFolderId = folder.id;
      _navigationPath.add(folder);
    });
    _loadFiles();
  }

  void _navigateBack() {
    if (_navigationPath.isNotEmpty) {
      setState(() {
        _navigationPath.removeLast();
        _currentFolderId = _navigationPath.isNotEmpty
            ? _navigationPath.last.id
            : null;
      });
      _loadFiles();
    }
  }

  void _navigateToRoot() {
    setState(() {
      _navigationPath.clear();
      _currentFolderId = null;
    });
    _loadFiles();
  }

  void _selectFile(DriveFile file) {
    Navigator.pop(context, file);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select PDF File',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Breadcrumb navigation
            if (_navigationPath.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: _navigationPath.isNotEmpty
                          ? _navigateBack
                          : null,
                      tooltip: 'Back',
                    ),
                    IconButton(
                      icon: const Icon(Icons.home, size: 20),
                      onPressed: _navigateToRoot,
                      tooltip: 'Home',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: _navigateToRoot,
                              child: const Text('Home'),
                            ),
                            for (
                              var i = 0;
                              i < _navigationPath.length;
                              i++
                            ) ...[
                              const Icon(Icons.chevron_right, size: 16),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _navigationPath.removeRange(
                                      i + 1,
                                      _navigationPath.length,
                                    );
                                    _currentFolderId = _navigationPath[i].id;
                                  });
                                  _loadFiles();
                                },
                                child: Text(_navigationPath[i].name),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search PDF files...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // File list
            Expanded(child: _buildFileList()),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading files',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadFiles,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No PDF files found'
                  : 'No files in this folder',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return ListTile(
          leading: Icon(
            file.isFolder ? Icons.folder : Icons.picture_as_pdf,
            color: file.isFolder ? Colors.amber : Colors.red,
            size: 32,
          ),
          title: Text(
            file.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: file.isFolder
              ? const Text('Folder')
              : Text(
                  file.size != null
                      ? '${(file.size! / 1024 / 1024).toStringAsFixed(2)} MB'
                      : 'Unknown size',
                ),
          trailing: file.isFolder
              ? const Icon(Icons.chevron_right)
              : const Icon(Icons.check_circle_outline),
          onTap: () {
            if (file.isFolder) {
              _navigateToFolder(file);
            } else {
              _selectFile(file);
            }
          },
        );
      },
    );
  }
}
