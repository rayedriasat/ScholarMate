import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sharing_service.dart';
import '../services/drive_service.dart';
import '../models/drive_file.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../theme/app_colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PopScope(
      canPop: !_canNavigateBack,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _canNavigateBack) {
          await _navigateBack();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.background : Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            _currentFolderId != null
                ? _navigationPath.isNotEmpty
                      ? _navigationPath.last.name
                      : 'Folder'
                : 'Shared with Me',
          ),
          backgroundColor: isDark ? AppColors.surface : null,
          elevation: 0,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: BreadcrumbNavigation(
                  path: _navigationPath,
                  onNavigate: _navigateToFolder,
                ),
              ),
            Expanded(child: _buildBody()),
          ],
        ),
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
            Icon(Icons.error_outline, size: 64, color: Colors.red.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              'Error loading files',
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ModernButton(
              onPressed: _refresh,
              icon: Icons.refresh,
              label: 'Retry',
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No shared files',
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Files shared with you will appear here',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sharedFiles.length,
        itemBuilder: (context, index) {
          final fileInfo = _sharedFiles[index];
          final file = fileInfo.toDriveFile();
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
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Icon(
                  file.isFolder
                      ? Icons.folder
                      : file.isPdf
                      ? Icons.picture_as_pdf
                      : file.isMarkdown
                      ? Icons.description
                      : Icons.insert_drive_file,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                file.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fileInfo.permission == 'editor' ? 'Editor' : 'Viewer',
                        style: const TextStyle(
                          color: AppColors.primary,
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
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (file.size != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      file.formattedSize,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Empty folder',
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This folder contains no files',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _currentFolderFiles.length,
        itemBuilder: (context, index) {
          final file = _currentFolderFiles[index];
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
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Icon(
                  file.isFolder
                      ? Icons.folder
                      : file.isPdf
                      ? Icons.picture_as_pdf
                      : file.isMarkdown
                      ? Icons.description
                      : Icons.insert_drive_file,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                file.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  if (file.size != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      file.formattedSize,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
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
