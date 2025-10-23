import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drive_file.dart';
import '../services/drive_service.dart';
import '../services/auth_service.dart';
import '../widgets/file_card.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/file_upload_widget.dart';
import '../widgets/file_context_menu.dart';

/// File explorer screen for browsing Google Drive files
class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key});

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  late DriveService _driveService;
  List<DriveFile> _files = [];
  List<DriveFile> _navigationPath = [];
  bool _isLoading = true;
  String? _error;
  String? _currentFolderId;
  final Set<String> _selectedFiles = {};
  bool _showFABMenu = false;

  @override
  void initState() {
    super.initState();
    _driveService = DriveService(authService: context.read<AuthService>());
    _loadInitialFolder();
  }

  Future<void> _loadInitialFolder() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get app folder ID and create root navigation item
      final appFolderId = await _driveService.getAppFolderId();
      _currentFolderId = appFolderId;

      final rootFolder = DriveFile(
        id: appFolderId,
        name: 'ScholarMate',
        isFolder: true,
      );

      _navigationPath = [rootFolder];

      await _loadFiles();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFiles([String? folderId]) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final files = await _driveService.listFiles(folderId ?? _currentFolderId);

      setState(() {
        _files = files;
        _isLoading = false;
        _selectedFiles.clear();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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

    _currentFolderId = folder.id;
    await _loadFiles(folder.id);
  }

  Future<void> _refresh() async {
    await _loadFiles();
  }

  void _showCreateFolderDialog() {
    setState(() {
      _showFABMenu = false;
    });
    showDialog(
      context: context,
      builder: (context) => _CreateFolderDialog(onCreateFolder: _createFolder),
    );
  }

  void _showUploadDialog() {
    setState(() {
      _showFABMenu = false;
    });
    if (_currentFolderId == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Files',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Select PDF or Markdown files to upload to your ScholarMate folder.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              FileUploadWidget(
                parentFolderId: _currentFolderId!,
                driveService: _driveService,
                onUploadComplete: () {
                  _loadFiles();
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createFolder(String name) async {
    try {
      if (_currentFolderId == null) return;

      await _driveService.createFolder(name, _currentFolderId!);
      await _loadFiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder "$name" created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleFileSelection(String fileId) {
    setState(() {
      if (_selectedFiles.contains(fileId)) {
        _selectedFiles.remove(fileId);
      } else {
        _selectedFiles.add(fileId);
      }
    });
  }

  void _showRenameDialog(DriveFile file) {
    showDialog(
      context: context,
      builder: (context) => RenameDialog(
        file: file,
        onRename: (newName) => _renameFile(file, newName),
      ),
    );
  }

  Future<void> _renameFile(DriveFile file, String newName) async {
    try {
      await _driveService.renameFile(file.id, newName);
      await _loadFiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${file.isFolder ? 'Folder' : 'File'} renamed successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rename: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(DriveFile file) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete ${file.isFolder ? 'Folder' : 'File'}',
        message:
            'Are you sure you want to delete "${file.name}"? It will be moved to trash.',
        confirmText: 'Delete',
        isDestructive: true,
        onConfirm: () => _deleteFile(file),
      ),
    );
  }

  Future<void> _deleteFile(DriveFile file) async {
    try {
      await _driveService.deleteFile(file.id);
      await _loadFiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${file.isFolder ? 'Folder' : 'File'} deleted successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareFile(DriveFile file) {
    // TODO: Implement sharing (will be added in Phase 12)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File sharing will be implemented in Phase 12'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
        elevation: 0,
        actions: [
          if (_selectedFiles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDeleteSelectedConfirmation,
              tooltip: 'Delete selected',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumb navigation
          if (_navigationPath.isNotEmpty)
            BreadcrumbNavigation(
              path: _navigationPath,
              onNavigate: _navigateToFolder,
            ),

          // File list
          Expanded(child: _buildFileList()),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFileList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading files',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
          ],
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
              'No files yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload files or create folders to get started',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Responsive layout
    return RefreshIndicator(
      onRefresh: _refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Mobile: List view
          if (constraints.maxWidth < 600) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FileCard(
                    file: file,
                    isSelected: _selectedFiles.contains(file.id),
                    onTap: () => _handleFileTap(file),
                    onLongPress: () => _toggleFileSelection(file.id),
                    onRename: () => _showRenameDialog(file),
                    onDelete: () => _showDeleteConfirmation(file),
                    onShare: file.isFolder ? null : () => _shareFile(file),
                  ),
                );
              },
            );
          }

          // Desktop/Tablet: Grid view
          final crossAxisCount = constraints.maxWidth > 1200
              ? 4
              : constraints.maxWidth > 800
              ? 3
              : 2;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: _files.length,
            itemBuilder: (context, index) {
              final file = _files[index];
              return FileCard(
                file: file,
                isSelected: _selectedFiles.contains(file.id),
                onTap: () => _handleFileTap(file),
                onLongPress: () => _toggleFileSelection(file.id),
                onRename: () => _showRenameDialog(file),
                onDelete: () => _showDeleteConfirmation(file),
                onShare: file.isFolder ? null : () => _shareFile(file),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Upload FAB
        if (_showFABMenu) ...[
          FloatingActionButton(
            heroTag: "upload",
            onPressed: _showUploadDialog,
            tooltip: 'Upload files',
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "folder",
            onPressed: _showCreateFolderDialog,
            tooltip: 'Create folder',
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: const Icon(Icons.create_new_folder),
          ),
          const SizedBox(height: 16),
        ],

        // Main FAB
        FloatingActionButton(
          heroTag: "main",
          onPressed: () {
            setState(() {
              _showFABMenu = !_showFABMenu;
            });
          },
          tooltip: _showFABMenu ? 'Close menu' : 'Add',
          child: AnimatedRotation(
            turns: _showFABMenu ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(_showFABMenu ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
  }

  void _handleFileTap(DriveFile file) {
    if (_selectedFiles.isNotEmpty) {
      _toggleFileSelection(file.id);
      return;
    }

    if (file.isFolder) {
      _navigateToFolder(file);
    } else {
      // TODO: Open file (will be implemented in later phases)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File opening will be implemented in Phase 4'),
        ),
      );
    }
  }

  void _showDeleteSelectedConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Files'),
        content: Text(
          'Are you sure you want to delete ${_selectedFiles.length} file(s)? '
          'They will be moved to trash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteSelectedFiles();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedFiles() async {
    final filesToDelete = List<String>.from(_selectedFiles);
    setState(() {
      _selectedFiles.clear();
    });

    try {
      for (final fileId in filesToDelete) {
        await _driveService.deleteFile(fileId);
      }

      await _loadFiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${filesToDelete.length} file(s) deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _CreateFolderDialog extends StatefulWidget {
  final Function(String) onCreateFolder;

  const _CreateFolderDialog({required this.onCreateFolder});

  @override
  State<_CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<_CreateFolderDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Folder'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Folder name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a folder name';
            }
            return null;
          },
          onFieldSubmitted: (_) => _createFolder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _createFolder, child: const Text('Create')),
      ],
    );
  }

  void _createFolder() {
    if (_formKey.currentState!.validate()) {
      widget.onCreateFolder(_controller.text.trim());
      Navigator.of(context).pop();
    }
  }
}
