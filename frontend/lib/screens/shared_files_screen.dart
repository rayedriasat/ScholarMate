import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sharing_service.dart';
import '../services/drive_service.dart';
import '../models/drive_file.dart';
import '../widgets/breadcrumb_navigation.dart';
import 'pdf_viewer_screen.dart';
import 'markdown_viewer_screen.dart';

/// Screen displaying files shared with the current user
class SharedFilesScreen extends StatefulWidget {
  const SharedFilesScreen({super.key});

  @override
  State<SharedFilesScreen> createState() => _SharedFilesScreenState();
}

class _SharedFilesScreenState extends State<SharedFilesScreen> {
  List<SharedFileInfo> _sharedFiles = [];
  List<DriveFile> _currentFolderFiles = [];
  List<DriveFile> _navigationPath = [];
  bool _isLoading = true;
  String? _error;
  String? _currentFolderId;

  @override
  void initState() {
    super.initState();
    _loadSharedFiles();
  }

  Future<void> _loadSharedFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sharingService = context.read<SharingService>();
      final sharedFiles = await sharingService.listSharedWithMe();

      if (mounted) {
        setState(() {
          _sharedFiles = sharedFiles;
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

  Future<void> _refresh() async {
    if (_currentFolderId != null) {
      await _loadFolderContents(_currentFolderId!);
    } else {
      await _loadSharedFiles();
    }
  }

  Future<void> _loadFolderContents(String folderId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final driveService = context.read<DriveService>();
      final files = await driveService.listFiles(folderId);

      if (mounted) {
        setState(() {
          _currentFolderFiles = files;
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

  void _openFile(SharedFileInfo fileInfo) {
    final file = fileInfo.toDriveFile();

    if (file.isPdf) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PdfViewerScreen(file: file)),
      );
    } else if (file.isFolder) {
      _navigateToSharedFolder(fileInfo);
    } else if (file.isMarkdown) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkdownViewerScreen(file: file),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open ${file.extension ?? 'this'} files yet'),
        ),
      );
    }
  }

  void _openFileFromFolder(DriveFile file) {
    if (file.isPdf) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PdfViewerScreen(file: file)),
      );
    } else if (file.isFolder) {
      _navigateToFolder(file);
    } else if (file.isMarkdown) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkdownViewerScreen(file: file),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open ${file.extension ?? 'this'} files yet'),
        ),
      );
    }
  }

  Future<void> _navigateToSharedFolder(SharedFileInfo sharedFolder) async {
    final file = sharedFolder.toDriveFile();

    setState(() {
      _currentFolderId = file.id;
      _navigationPath = [file];
    });

    await _loadFolderContents(file.id);
  }

  Future<void> _navigateToFolder(DriveFile folder) async {
    if (!folder.isFolder) return;

    // Update navigation path
    final existingIndex = _navigationPath.indexWhere((f) => f.id == folder.id);
    if (existingIndex != -1) {
      // Navigate back to existing folder in path
      _navigationPath = _navigationPath.sublist(0, existingIndex + 1);
    } else {
      // Navigate forward to new folder
      _navigationPath.add(folder);
    }

    setState(() {
      _currentFolderId = folder.id;
    });

    await _loadFolderContents(folder.id);
  }

  Future<void> _navigateBack() async {
    if (_navigationPath.length > 1) {
      // Remove current folder from path
      _navigationPath.removeLast();
      final parentFolder = _navigationPath.last;

      setState(() {
        _currentFolderId = parentFolder.id;
      });

      await _loadFolderContents(parentFolder.id);
    } else {
      // Back to shared files list
      setState(() {
        _currentFolderId = null;
        _navigationPath = [];
      });
      await _loadSharedFiles();
    }
  }

  bool get _canNavigateBack => _currentFolderId != null;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_canNavigateBack) {
          await _navigateBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _currentFolderId != null
                ? _navigationPath.isNotEmpty
                      ? _navigationPath.last.name
                      : 'Folder'
                : 'Shared with Me',
          ),
          leading: _canNavigateBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _navigateBack,
                  tooltip: 'Back',
                )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Column(
          children: [
            // Breadcrumb navigation when inside a folder
            if (_navigationPath.isNotEmpty)
              BreadcrumbNavigation(
                path: _navigationPath,
                onNavigate: _navigateToFolder,
              ),
            Expanded(child: _buildBody()),
          ],
        ),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading files',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show folder contents if navigated into a folder
    if (_currentFolderId != null) {
      return _buildFolderContents();
    }

    // Show shared files list
    if (_sharedFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_shared_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No shared files',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Files shared with you will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sharedFiles.length,
        itemBuilder: (context, index) {
          final fileInfo = _sharedFiles[index];
          final file = fileInfo.toDriveFile();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  file.isFolder
                      ? Icons.folder
                      : file.isPdf
                      ? Icons.picture_as_pdf
                      : file.isMarkdown
                      ? Icons.description
                      : Icons.insert_drive_file,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                file.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        fileInfo.permission == 'editor'
                            ? Icons.edit_outlined
                            : Icons.visibility_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fileInfo.permission == 'editor' ? 'Editor' : 'Viewer',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Shared by ${fileInfo.ownerName ?? fileInfo.ownerEmail ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (file.size != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      file.formattedSize,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openFile(fileInfo),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFolderContents() {
    if (_currentFolderFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Empty folder',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This folder contains no files',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _currentFolderFiles.length,
        itemBuilder: (context, index) {
          final file = _currentFolderFiles[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  file.isFolder
                      ? Icons.folder
                      : file.isPdf
                      ? Icons.picture_as_pdf
                      : file.isMarkdown
                      ? Icons.description
                      : Icons.insert_drive_file,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                file.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (file.modifiedTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Modified ${_formatDate(file.modifiedTime!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                  if (file.size != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      file.formattedSize,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openFileFromFolder(file),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
