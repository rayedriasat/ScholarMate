import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drive_file.dart';
import '../services/auth_service.dart';
import '../services/drive_service.dart';
import '../services/tag_service.dart';
import '../services/sharing_service.dart';
import '../services/indexing_service.dart';
import '../widgets/file_card.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/file_upload_widget.dart';
import '../widgets/file_context_menu.dart';
import '../widgets/tag_filter_panel.dart';
import '../widgets/tag_selection_dialog.dart';
import '../widgets/sharing_dialog.dart';
import '../widgets/indexing_progress_panel.dart';
import '../widgets/connectivity_indicator.dart';
import 'pdf_viewer_screen.dart';
import 'markdown_viewer_screen.dart';
import 'document_scanner_screen.dart';
import 'tag_management_screen.dart';
import 'shared_files_screen.dart';
import 'ai_chat_screen.dart';

/// File explorer screen for browsing Google Drive files
class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key});

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

/// Public class to handle back navigation from parent widgets
class FileExplorerNavigationHandler {
  static _FileExplorerScreenState? _instance;

  static void _setInstance(_FileExplorerScreenState? instance) {
    _instance = instance;
  }

  static Future<bool> handleBackNavigation() async {
    if (_instance != null) {
      return await _instance!.handleBackNavigation();
    }
    return true; // Allow exit if no instance
  }
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  DriveService? _driveService;
  List<DriveFile> _files = [];
  List<DriveFile> _navigationPath = [];
  bool _isLoading = true;
  String? _error;
  String? _currentFolderId;
  final Set<String> _selectedFiles = {};
  bool _showFABMenu = false;
  bool _showTagFilter = false;
  Set<String> _selectedTagIds = {};
  TagFilterMode _filterMode = TagFilterMode.any;
  String _searchQuery = '';
  FileSortOption _sortOption = FileSortOption.name;
  bool _sortAscending = true;
  FileViewLayout _viewLayout =
      FileViewLayout.list; // Default to list view for Android
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    FileExplorerNavigationHandler._setInstance(this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _loadFiles();
    });
    _loadInitialFolder();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get DriveService from Provider
    _driveService = context.read<DriveService>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    FileExplorerNavigationHandler._setInstance(null);
    super.dispose();
  }

  Future<void> _loadInitialFolder() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Ensure DriveService is available
      _driveService ??= context.read<DriveService>();

      // Get app folder ID and create root navigation item
      final appFolderId = await _driveService!.getAppFolderId();
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

      var files = await _driveService!.listFiles(folderId ?? _currentFolderId);

      // Apply search query filtering
      if (_searchQuery.isNotEmpty) {
        files = files
            .where(
              (file) =>
                  file.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();
      }

      // Apply tag filtering if tags are selected
      if (_selectedTagIds.isNotEmpty) {
        files = await _filterFilesByTags(files);
      }

      // Apply sorting
      files = _sortFiles(files);

      setState(() {
        _files = files;
        _isLoading = false;
        _selectedFiles.clear();
      });
    } catch (e) {
      final errorMsg = e.toString();
      setState(() {
        _error = errorMsg;
        _isLoading = false;
      });
      
      // Check if this is an authentication error that requires re-login
      if (errorMsg.contains('AUTHENTICATION_EXPIRED') || 
          errorMsg.contains('UNAUTHENTICATED') ||
          errorMsg.contains('sign out and sign in again')) {
        // Show a dialog prompting user to sign out and sign back in
        if (mounted) {
          _showAuthenticationExpiredDialog();
        }
      }
    }
  }

  Future<List<DriveFile>> _filterFilesByTags(List<DriveFile> files) async {
    try {
      final tagService = context.read<TagService>();
      final filteredFiles = <DriveFile>[];

      for (final file in files) {
        if (file.isFolder) {
          filteredFiles.add(file); // Always show folders
          continue;
        }

        final fileTags = await tagService.getTagsForFile(file.id);
        final fileTagIds = fileTags.map((t) => t.id).toSet();

        final matches = _filterMode == TagFilterMode.all
            ? _selectedTagIds.every((id) => fileTagIds.contains(id))
            : _selectedTagIds.any((id) => fileTagIds.contains(id));

        if (matches) {
          filteredFiles.add(file);
        }
      }

      return filteredFiles;
    } catch (e) {
      return files; // Return unfiltered on error
    }
  }

  List<DriveFile> _sortFiles(List<DriveFile> files) {
    final sorted = List<DriveFile>.from(files);

    switch (_sortOption) {
      case FileSortOption.name:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case FileSortOption.date:
        sorted.sort((a, b) {
          final aTime = a.modifiedTime ?? DateTime(1970);
          final bTime = b.modifiedTime ?? DateTime(1970);
          return aTime.compareTo(bTime);
        });
        break;
      case FileSortOption.size:
        sorted.sort((a, b) {
          final aSize = a.size ?? 0;
          final bSize = b.size ?? 0;
          return aSize.compareTo(bSize);
        });
        break;
      case FileSortOption.tag:
        // Sort by number of tags (requires async, simplified here)
        break;
    }

    if (!_sortAscending) {
      return sorted.reversed.toList();
    }

    return sorted;
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

  /// Navigate back one folder level
  Future<void> _navigateBack() async {
    if (_navigationPath.length > 1) {
      // Remove current folder from path
      _navigationPath.removeLast();
      final parentFolder = _navigationPath.last;
      _currentFolderId = parentFolder.id;
      await _loadFiles(parentFolder.id);
    }
  }

  /// Check if we can navigate back (not at root)
  bool get _canNavigateBack => _navigationPath.length > 1;

  /// Handle back button press - only handles folder navigation, not app exit
  /// Returns true if at root level and parent should handle exit
  Future<bool> handleBackNavigation() async {
    // Close FAB menu if open
    if (_showFABMenu) {
      setState(() {
        _showFABMenu = false;
      });
      return false;
    }

    // Clear selection if any files are selected
    if (_selectedFiles.isNotEmpty) {
      setState(() {
        _selectedFiles.clear();
      });
      return false;
    }

    // Navigate back if not at root
    if (_canNavigateBack) {
      await _navigateBack();
      return false;
    }

    // At root level - let parent handle exit logic
    return true;
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

  void _showScanDocument() async {
    setState(() {
      _showFABMenu = false;
    });
    if (_currentFolderId == null) return;

    final result = await Navigator.push<DriveFile>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DocumentScannerScreen(parentFolderId: _currentFolderId),
      ),
    );

    if (result != null) {
      // Refresh file list
      await _loadFiles(_currentFolderId);
    }
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
                driveService: _driveService!,
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

      await _driveService!.createFolder(name, _currentFolderId!);
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
      await _driveService!.renameFile(file.id, newName);
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
      await _driveService!.deleteFile(file.id);
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

  Future<void> _shareFile(DriveFile file) async {
    try {
      // Load current collaborators
      final sharingService = context.read<SharingService>();
      final collaborators = await sharingService.listCollaborators(file.id);

      if (!mounted) return;

      // Show sharing dialog
      await showDialog(
        context: context,
        builder: (context) => SharingDialog(
          fileName: file.name,
          fileId: file.id,
          isFolder: file.isFolder,
          currentCollaborators: collaborators,
          onShare: (email, role) async {
            // Share on Google Drive
            await _driveService!.shareFile(file.id, email, role);

            // Store metadata in Supabase
            await sharingService.shareFile(
              driveFileId: file.id,
              fileName: file.name,
              mimeType: file.mimeType ?? 'application/octet-stream',
              sharedWithEmail: email,
              permission: role,
              isFolder: file.isFolder,
              sizeBytes: file.size,
            );
          },
          onRemoveCollaborator: (email) async {
            // Get permissions from Drive to find the permission ID
            final permissions = await _driveService!.listFilePermissions(
              file.id,
            );
            final permission = permissions.firstWhere(
              (p) => p['emailAddress'] == email,
              orElse: () => throw Exception('Permission not found'),
            );

            // Remove from Google Drive
            await _driveService!.removeFilePermission(
              file.id,
              permission['id'],
            );

            // Remove from Supabase
            await sharingService.removeShare(
              driveFileId: file.id,
              sharedWithEmail: email,
            );
          },
        ),
      );

      // Refresh file list to update shared status
      await _loadFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reindexFile(DriveFile file) async {
    try {
      final indexingService = context.read<IndexingService>();
      await indexingService.reindexFile(fileId: file.id, fileName: file.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reindexing "${file.name}" started')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reindex: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _chatWithFolder() async {
    // Get all non-folder files (PDFs and Markdown) from current folder
    final filesInFolder = _files.where((f) => !f.isFolder).toList();

    if (filesInFolder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No files in this folder to chat with'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get file IDs
    final fileIds = filesInFolder.map((f) => f.id).toList();

    // Get current folder name
    final folderName = _navigationPath.isNotEmpty
        ? _navigationPath.last.name
        : 'ScholarMate';

    // Navigate to AI chat with all files preselected
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AIChatScreen(preselectedFileIds: fileIds, folderName: folderName),
      ),
    );
  }

  void _showIndexingProgressPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => const IndexingProgressPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
        elevation: 0,
        toolbarHeight: isSmallScreen ? 48 : null, // Reduce height on mobile
        bottom: isSmallScreen
            ? PreferredSize(
                preferredSize: const Size.fromHeight(0),
                child: Container(), // Remove bottom spacing on mobile
              )
            : null,
        leading: _canNavigateBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _navigateBack,
                tooltip: 'Back',
              )
            : null,
        actions: [
          if (_selectedFiles.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.label),
              onPressed: _bulkTagFiles,
              tooltip: 'Tag selected files',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDeleteSelectedConfirmation,
              tooltip: 'Delete selected',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
              tooltip: 'Refresh',
            ),
            // Connectivity and sync status indicator
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: ConnectivityIndicator(),
            ),
            // Indexing progress button
            Consumer<IndexingService>(
              builder: (context, indexingService, child) {
                final activeCount = indexingService.activeJobCount;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.analytics),
                      onPressed: _showIndexingProgressPanel,
                      tooltip: 'Indexing Progress',
                    ),
                    if (activeCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$activeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            // Settings menu
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'manage_tags') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TagManagementScreen(),
                    ),
                  ).then((_) => _loadFiles());
                } else if (value == 'shared_with_me') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SharedFilesScreen(),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'shared_with_me',
                  child: Row(
                    children: [
                      Icon(Icons.folder_shared, size: 20),
                      SizedBox(width: 8),
                      Text('Shared with Me'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'manage_tags',
                  child: Row(
                    children: [
                      Icon(Icons.label, size: 20),
                      SizedBox(width: 8),
                      Text('Manage Tags'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildResponsiveBody(theme),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildResponsiveBody(ThemeData theme) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    if (isSmallScreen) {
      // Mobile layout: Stack for overlay
      return Stack(
        children: [
          // Main content
          Column(
            children: [
              // Breadcrumb navigation
              if (_navigationPath.isNotEmpty)
                Transform.translate(
                  offset: isSmallScreen ? const Offset(0, -4) : Offset.zero,
                  child: BreadcrumbNavigation(
                    path: _navigationPath,
                    onNavigate: _navigateToFolder,
                  ),
                ),

              // Modern toolbar with search, sort, and filter
              _buildModernToolbar(theme),

              // File list
              Expanded(child: _buildFileList()),
            ],
          ),

          // Tag filter panel overlay
          if (_showTagFilter)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showTagFilter = false;
                  });
                },
                child: Container(color: Colors.black.withValues(alpha: 0.3)),
              ),
            ),
          if (_showTagFilter)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent:
                            ModalRoute.of(context)?.animation ??
                            const AlwaysStoppedAnimation(1.0),
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: TagFilterPanel(
                  selectedTagIds: _selectedTagIds,
                  filterMode: _filterMode,
                  searchQuery: _searchQuery,
                  onFilterChanged: (tagIds, mode, searchQuery) {
                    setState(() {
                      _selectedTagIds = tagIds;
                      _filterMode = mode;
                      _searchQuery = searchQuery;
                    });
                    _loadFiles();
                  },
                  onClose: () {
                    setState(() {
                      _showTagFilter = false;
                    });
                  },
                ),
              ),
            ),
        ],
      );
    } else {
      // Desktop layout: Row for side panel
      return Row(
        children: [
          Expanded(
            child: Column(
              children: [
                // Breadcrumb navigation
                if (_navigationPath.isNotEmpty)
                  Transform.translate(
                    offset: isSmallScreen ? const Offset(0, -4) : Offset.zero,
                    child: BreadcrumbNavigation(
                      path: _navigationPath,
                      onNavigate: _navigateToFolder,
                    ),
                  ),

                // Modern toolbar with search, sort, and filter
                _buildModernToolbar(theme),

                // File list
                Expanded(child: _buildFileList()),
              ],
            ),
          ),

          // Tag filter panel
          if (_showTagFilter)
            TagFilterPanel(
              selectedTagIds: _selectedTagIds,
              filterMode: _filterMode,
              searchQuery: _searchQuery,
              onFilterChanged: (tagIds, mode, searchQuery) {
                setState(() {
                  _selectedTagIds = tagIds;
                  _filterMode = mode;
                  _searchQuery = searchQuery;
                });
                _loadFiles();
              },
              onClose: () {
                setState(() {
                  _showTagFilter = false;
                });
              },
            ),
        ],
      );
    }
  }

  Widget _buildViewLayoutToggle(ThemeData theme, bool isSmallScreen) {
    // On Android, only show list and compact views (no grid)
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    return Container(
      height: isSmallScreen ? 38 : 43,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLayoutButton(
            FileViewLayout.list,
            Icons.view_list,
            'List View',
            theme,
            isSmallScreen,
          ),
          if (!isAndroid) // Hide grid view on Android
            _buildLayoutButton(
              FileViewLayout.grid,
              Icons.grid_view,
              'Grid View',
              theme,
              isSmallScreen,
            ),
          _buildLayoutButton(
            FileViewLayout.compact,
            Icons.view_agenda,
            'Compact View',
            theme,
            isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutButton(
    FileViewLayout layout,
    IconData icon,
    String tooltip,
    ThemeData theme,
    bool isSmallScreen,
  ) {
    final isSelected = _viewLayout == layout;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _viewLayout = layout),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: isSmallScreen ? 16 : 18,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildModernToolbar(ThemeData theme) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isSmallScreen ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: Container(
              height: isSmallScreen ? 38 : 43,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _searchQuery.isNotEmpty
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                  width: _searchQuery.isNotEmpty ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search files...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                          tooltip: 'Clear search',
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),

          // Sort button
          Container(
            height: isSmallScreen ? 38 : 43,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: PopupMenuButton<FileSortOption>(
              icon: Icon(Icons.sort, color: theme.colorScheme.primary),
              tooltip: 'Sort files',
              onSelected: _toggleSort,
              constraints: BoxConstraints(
                minHeight: isSmallScreen ? 38 : 43,
                minWidth: isSmallScreen ? 38 : 43,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                _buildSortMenuItem(FileSortOption.name, 'Name'),
                _buildSortMenuItem(FileSortOption.date, 'Date'),
                _buildSortMenuItem(FileSortOption.size, 'Size'),
                _buildSortMenuItem(FileSortOption.tag, 'Tag'),
              ],
            ),
          ),
          SizedBox(width: isSmallScreen ? 6 : 8),

          // View layout toggle
          _buildViewLayoutToggle(theme, isSmallScreen),
          SizedBox(width: isSmallScreen ? 6 : 8),

          // Filter button
          Container(
            height: isSmallScreen ? 38 : 43,
            decoration: BoxDecoration(
              color: _showTagFilter || _selectedTagIds.isNotEmpty
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showTagFilter || _selectedTagIds.isNotEmpty
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
                width: _showTagFilter || _selectedTagIds.isNotEmpty ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                IconButton(
                  icon: Icon(
                    _showTagFilter ? Icons.filter_list_off : Icons.filter_list,
                    color: _showTagFilter || _selectedTagIds.isNotEmpty
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    setState(() => _showTagFilter = !_showTagFilter);
                  },
                  tooltip: 'Filter by tags',
                  constraints: BoxConstraints(
                    minHeight: isSmallScreen ? 38 : 43,
                    minWidth: isSmallScreen ? 38 : 43,
                  ),
                ),
                if (_selectedTagIds.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_selectedTagIds.length}',
                        style: TextStyle(
                          color: theme.colorScheme.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
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

    // Layout-based view
    return RefreshIndicator(onRefresh: _refresh, child: _buildLayoutView());
  }

  Widget _buildLayoutView() {
    switch (_viewLayout) {
      case FileViewLayout.grid:
        return _buildGridView();
      case FileViewLayout.compact:
        return _buildCompactView();
      case FileViewLayout.list:
        return _buildListView();
    }
  }

  Widget _buildListView() {
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
            onShare: () => _shareFile(file),
            onReindex: file.isPdf ? () => _reindexFile(file) : null,
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
            ? 3
            : constraints.maxWidth > 600
            ? 2
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
              onShare: () => _shareFile(file),
              onReindex: file.isPdf ? () => _reindexFile(file) : null,
            );
          },
        );
      },
    );
  }

  Widget _buildCompactView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 2),
          elevation: _selectedFiles.contains(file.id) ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: _selectedFiles.contains(file.id)
                ? BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : BorderSide.none,
          ),
          child: ListTile(
            leading: _buildCompactIcon(file),
            title: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${file.formattedSize} • ${_formatCompactDate(file.modifiedTime)}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (file.isShared)
                  Icon(Icons.people, size: 16, color: Colors.blue[600]),
                FileContextMenu(
                  file: file,
                  onRename: () => _showRenameDialog(file),
                  onMove: null,
                  onDelete: () => _showDeleteConfirmation(file),
                  onShare: () => _shareFile(file),
                  onManageTags: file.isFolder
                      ? null
                      : () => _showTagDialog(file),
                  onReindex: file.isPdf ? () => _reindexFile(file) : null,
                ),
              ],
            ),
            onTap: () => _handleFileTap(file),
            onLongPress: () => _toggleFileSelection(file.id),
          ),
        );
      },
    );
  }

  Widget _buildCompactIcon(DriveFile file) {
    if (file.isFolder) {
      return Icon(Icons.folder, color: Colors.blue[700]);
    }

    Color iconColor;
    IconData iconData;

    if (file.isPdf) {
      iconColor = Colors.red[700]!;
      iconData = Icons.picture_as_pdf;
    } else if (file.isMarkdown) {
      iconColor = Colors.green[700]!;
      iconData = Icons.description;
    } else {
      iconColor = Colors.grey[700]!;
      iconData = Icons.insert_drive_file;
    }

    return Icon(iconData, color: iconColor);
  }

  String _formatCompactDate(DateTime? date) {
    if (date == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _showTagDialog(DriveFile file) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TagSelectionDialog(fileIds: [file.id]),
    );

    if (result == true) {
      _loadFiles();
    }
  }

  Widget _buildFAB() {
    final theme = Theme.of(context);
    final hasFiles = _files.where((f) => !f.isFolder).isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Chat with Folder button - show when there are files in current folder
        if (hasFiles) ...[
          FloatingActionButton(
            heroTag: "chat_folder",
            onPressed: _chatWithFolder,
            tooltip: 'Chat with this folder',
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            child: const Icon(Icons.forum),
          ),
          const SizedBox(height: 16),
        ],

        // Upload FAB
        if (_showFABMenu) ...[
          FloatingActionButton(
            heroTag: "scan",
            onPressed: _showScanDocument,
            tooltip: 'Scan document',
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: const Icon(Icons.document_scanner),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "upload",
            onPressed: _showUploadDialog,
            tooltip: 'Upload files',
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            child: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "folder",
            onPressed: _showCreateFolderDialog,
            tooltip: 'Create folder',
            backgroundColor: theme.colorScheme.tertiaryContainer,
            foregroundColor: theme.colorScheme.onTertiaryContainer,
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
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
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
    } else if (file.isPdf) {
      // Open PDF in viewer
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => PdfViewerScreen(file: file)),
      );
    } else if (file.isMarkdown) {
      // Open Markdown in viewer
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MarkdownViewerScreen(file: file),
        ),
      );
    } else {
      // TODO: Open other file types (will be implemented in later phases)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Opening ${file.extension?.toUpperCase() ?? 'this'} files is not yet supported',
          ),
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
        await _driveService!.deleteFile(fileId);
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

  Future<void> _bulkTagFiles() async {
    if (_selectedFiles.isEmpty) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          TagSelectionDialog(fileIds: _selectedFiles.toList()),
    );

    if (result == true) {
      setState(() => _selectedFiles.clear());
      _loadFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tagged ${_selectedFiles.length} files')),
        );
      }
    }
  }

  void _toggleSort(FileSortOption option) {
    setState(() {
      if (_sortOption == option) {
        _sortAscending = !_sortAscending;
      } else {
        _sortOption = option;
        _sortAscending = true;
      }
    });
    _loadFiles();
  }

  PopupMenuItem<FileSortOption> _buildSortMenuItem(
    FileSortOption option,
    String label,
  ) {
    final isSelected = _sortOption == option;
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Icon(
            isSelected
                ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.sort,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
          if (isSelected) const Spacer(),
          if (isSelected) const Icon(Icons.check, size: 20),
        ],
      ),
    );
  }

  void _showAuthenticationExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Session Expired'),
          ],
        ),
        content: const Text(
          'Your Google authentication session has expired or been revoked. '
          'Please sign out and sign back in to continue using ScholarMate.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authService = context.read<AuthService>();
              try {
                await authService.signOut();
                // Navigation to login screen will be handled automatically
                // by the auth state listener in main.dart
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sign out failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

/// Sort options for files
enum FileSortOption { name, date, size, tag }

/// View layout options for files
enum FileViewLayout { list, grid, compact }

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
