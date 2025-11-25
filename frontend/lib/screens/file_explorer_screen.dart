import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drive_file.dart';
// import '../services/auth_service.dart';
import '../services/drive_service.dart';
import '../services/tag_service.dart';
import '../services/sharing_service.dart';
import '../services/indexing_service.dart';
import '../theme/app_colors.dart';

import '../widgets/breadcrumb_navigation.dart';
import '../widgets/file_upload_widget.dart';
import '../widgets/file_card.dart';
// import '../widgets/tag_selection_dialog.dart';
import '../widgets/sharing_dialog.dart';
import '../widgets/indexing_progress_panel.dart';
// import '../widgets/connectivity_indicator.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../widgets/ui/modern_text_field.dart';
import 'pdf_viewer_screen.dart';
import 'markdown_viewer_screen.dart';
import 'document_scanner_screen.dart';
import 'tag_management_screen.dart';
import 'shared_files_screen.dart';
import 'ai_chat_screen.dart';
import 'analytics_screen.dart';
import 'advanced_search_screen.dart';
import '../widgets/tag_selection_dialog.dart';
import 'enhanced_drawing_canvas_screen.dart';
import 'markdown_editor_screen.dart';

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
  // bool _showTagFilter = false; // Unused
  Set<String> _selectedTagIds = {};
  TagFilterMode _filterMode = TagFilterMode.any;
  String _searchQuery = '';
  FileSortOption _sortOption = FileSortOption.name;
  bool _sortAscending = true;
  FileViewLayout _viewLayout = FileViewLayout.list;
  final TextEditingController _searchController = TextEditingController();

  // Chat panel state
  bool _showChatPanel = false;
  double _chatPanelWidth = 400;
  bool _chatPanelFullscreen = false;
  static const double _minChatWidth = 300;
  static const double _maxChatWidthPercent = 0.7;
  String? _chatFolderName;
  List<String> _chatFileIds = [];

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

      _driveService ??= context.read<DriveService>();

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

      if (_searchQuery.isNotEmpty) {
        files = files
            .where(
              (file) =>
                  file.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();
      }

      if (_selectedTagIds.isNotEmpty) {
        files = await _filterFilesByTags(files);
      }

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
    }
  }

  Future<List<DriveFile>> _filterFilesByTags(List<DriveFile> files) async {
    try {
      final tagService = context.read<TagService>();
      final filteredFiles = <DriveFile>[];

      for (final file in files) {
        if (file.isFolder) {
          filteredFiles.add(file);
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
      return files;
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
        break;
    }

    if (!_sortAscending) {
      return sorted.reversed.toList();
    }

    return sorted;
  }

  Future<void> _navigateToFolder(DriveFile folder) async {
    if (!folder.isFolder) return;

    final existingIndex = _navigationPath.indexWhere((f) => f.id == folder.id);
    if (existingIndex != -1) {
      _navigationPath = _navigationPath.sublist(0, existingIndex + 1);
    } else {
      _navigationPath.add(folder);
    }

    _currentFolderId = folder.id;
    await _loadFiles(folder.id);
  }

  Future<void> _navigateBack() async {
    if (_navigationPath.length > 1) {
      _navigationPath.removeLast();
      final parentFolder = _navigationPath.last;
      _currentFolderId = parentFolder.id;
      await _loadFiles(parentFolder.id);
    }
  }

  bool get _canNavigateBack => _navigationPath.length > 1;

  Future<bool> handleBackNavigation() async {
    if (_showFABMenu) {
      setState(() {
        _showFABMenu = false;
      });
      return false;
    }

    if (_selectedFiles.isNotEmpty) {
      setState(() {
        _selectedFiles.clear();
      });
      return false;
    }

    if (_canNavigateBack) {
      await _navigateBack();
      return false;
    }

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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Files',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select PDF or Markdown files to upload to your ScholarMate folder.',
                style: TextStyle(color: Colors.grey[400]),
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
      final sharingService = context.read<SharingService>();
      final collaborators = await sharingService.listCollaborators(file.id);

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => SharingDialog(
          fileName: file.name,
          fileId: file.id,
          isFolder: file.isFolder,
          currentCollaborators: collaborators,
          onShare: (email, role) async {
            await _driveService!.shareFile(file.id, email, role);
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
            final permissions = await _driveService!.listFilePermissions(
              file.id,
            );
            final permission = permissions.firstWhere(
              (p) => p['emailAddress'] == email,
              orElse: () => throw Exception('Permission not found'),
            );

            await _driveService!.removeFilePermission(
              file.id,
              permission['id'],
            );

            await sharingService.removeShare(
              driveFileId: file.id,
              sharedWithEmail: email,
            );
          },
        ),
      );

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

    final fileIds = filesInFolder.map((f) => f.id).toList();

    final folderName = _navigationPath.isNotEmpty
        ? _navigationPath.last.name
        : 'ScholarMate';

    if (mounted) {
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth >= 900) {
        setState(() {
          _chatFileIds = fileIds;
          _chatFolderName = folderName;
          _showChatPanel = true;
          _chatPanelFullscreen = false;
        });
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AIChatScreen(
              preselectedFileIds: fileIds,
              folderName: folderName,
            ),
          ),
        );
      }
    }
  }

  Future<void> _chatWithSpecificFolder(DriveFile folder) async {
    try {
      // Fetch files in the folder
      final files = await _driveService!.listFiles(folder.id);
      final filesInFolder = files.where((f) => !f.isFolder).toList();

      if (filesInFolder.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No files in this folder to chat with'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      final fileIds = filesInFolder.map((f) => f.id).toList();

      if (mounted) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (screenWidth >= 900) {
          setState(() {
            _chatFileIds = fileIds;
            _chatFolderName = folder.name;
            _showChatPanel = true;
            _chatPanelFullscreen = false;
          });
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AIChatScreen(
                preselectedFileIds: fileIds,
                folderName: folder.name,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error preparing chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showIndexingProgressPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const IndexingProgressPanel(),
    );
  }

  Widget _buildChatPanel(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * _maxChatWidthPercent;
    final effectiveWidth = _chatPanelFullscreen
        ? screenWidth
        : _chatPanelWidth.clamp(_minChatWidth, maxWidth);

    return Row(
      children: [
        // Resize handle
        if (!_chatPanelFullscreen)
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _chatPanelWidth = (_chatPanelWidth - details.delta.dx).clamp(
                    _minChatWidth,
                    maxWidth,
                  );
                });
              },
              child: Container(
                width: 8,
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    width: 2,
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        // Chat panel
        Container(
          width: effectiveWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surface
                : Colors.white,
            border: Border(
              left: BorderSide(color: Theme.of(context).dividerColor, width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Chat content
              Expanded(
                child: AIChatScreen(
                  preselectedFileIds: _chatFileIds,
                  folderName: _chatFolderName,
                  isEmbedded: true,
                  onClose: () {
                    setState(() {
                      _showChatPanel = false;
                    });
                  },
                  onToggleFullscreen: () {
                    setState(() {
                      _chatPanelFullscreen = !_chatPanelFullscreen;
                    });
                  },
                  isFullscreen: _chatPanelFullscreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Placeholder for missing methods
  // void _bulkTagFiles() {} // Unused
  // void _showDeleteSelectedConfirmation() {} // Unused

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Top safe area padding
                    if (isAndroid) SizedBox(height: padding.top),

                    // Custom Toolbar
                    _buildToolbar(isSmallScreen),

                    // Breadcrumbs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: BreadcrumbNavigation(
                        path: _navigationPath,
                        onNavigate: _navigateToFolder,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // File List
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: isAndroid ? padding.bottom + 80 : 0,
                        ),
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              )
                            : _error != null
                            ? Center(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                            : _files.isEmpty
                            ? _buildEmptyState()
                            : _buildFileListView(),
                      ),
                    ),
                  ],
                ),

                // Floating Action Button
                Positioned(
                  bottom: isAndroid ? padding.bottom + 90 : 32,
                  right: 32,
                  child: _buildFAB(),
                ),
              ],
            ),
          ),
          if (_showChatPanel && MediaQuery.of(context).size.width >= 900)
            _buildChatPanel(context),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isSmallScreen) {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          if (_canNavigateBack)
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: _navigateBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (_canNavigateBack) const SizedBox(width: 4),
          Text(
            'Library',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          // Search Bar
          if (screenWidth > 600)
            Container(
              width: screenWidth > 800 ? 300 : 200,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          if (screenWidth > 600) const SizedBox(width: 8),

          // View layout toggle
          if (kIsWeb || isAndroid)
            IconButton(
              icon: Icon(
                _viewLayout == FileViewLayout.list
                    ? Icons.grid_view
                    : Icons.view_list,
                color: Theme.of(context).iconTheme.color,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _viewLayout = _viewLayout == FileViewLayout.list
                      ? FileViewLayout.glassCard
                      : FileViewLayout.list;
                });
              },
              tooltip: _viewLayout == FileViewLayout.list
                  ? 'Card View'
                  : 'List View',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

          if (!isSmallScreen)
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: Theme.of(context).iconTheme.color,
                size: 20,
              ),
              onPressed: _refresh,
              tooltip: 'Refresh',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (!isSmallScreen)
            IconButton(
              icon: Icon(
                Icons.analytics_outlined,
                color: Theme.of(context).iconTheme.color,
                size: 20,
              ),
              onPressed: _showIndexingProgressPanel,
              tooltip: 'Indexing Progress',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).iconTheme.color,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surface
                : Colors.white,
            onSelected: (value) {
              if (value == 'refresh') {
                _refresh();
              } else if (value == 'indexing') {
                _showIndexingProgressPanel();
              } else if (value == 'manage_tags') {
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
              } else if (value == 'advanced_search') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdvancedSearchScreen(),
                  ),
                );
              } else if (value == 'analytics') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalyticsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              if (isSmallScreen) ...[
                const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
                const PopupMenuItem(
                  value: 'indexing',
                  child: Text('Indexing Progress'),
                ),
              ],
              const PopupMenuItem(
                value: 'advanced_search',
                child: Text('Advanced Search'),
              ),
              const PopupMenuItem(
                value: 'shared_with_me',
                child: Text('Shared with Me'),
              ),
              const PopupMenuItem(
                value: 'manage_tags',
                child: Text('Manage Tags'),
              ),
              const PopupMenuItem(value: 'analytics', child: Text('Analytics')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No files found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          ModernButton(
            label: 'Upload File',
            icon: Icons.upload_file,
            onPressed: _showUploadDialog,
            variant: ModernButtonVariant.outline,
          ),
        ],
      ),
    );
  }

  Widget _buildFileListView() {
    final isAndroid = !kIsWeb && Platform.isAndroid;

    // Android uses card-based list view (old style) or glassy cards
    if (isAndroid) {
      if (_viewLayout == FileViewLayout.glassCard) {
        return _buildGlassCardGrid();
      }
      return _buildAndroidCardList();
    }

    // Web uses table view or glassy cards
    if (_viewLayout == FileViewLayout.glassCard) {
      return _buildGlassCardGrid();
    }
    return _buildFileTable();
  }

  Widget _buildAndroidCardList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FileCard(
            file: file,
            isSelected: _selectedFiles.contains(file.id),
            onTap: () {
              if (_selectedFiles.isNotEmpty) {
                _toggleFileSelection(file.id);
              } else if (file.isFolder) {
                _navigateToFolder(file);
              } else {
                if (file.isPdf) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen(file: file),
                    ),
                  );
                } else if (file.isMarkdown) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarkdownViewerScreen(file: file),
                    ),
                  );
                }
              }
            },
            onLongPress: () => _toggleFileSelection(file.id),
            onRename: () => _showRenameDialog(file),
            onDelete: () => _showDeleteConfirmation(file),
            onShare: () => _shareFile(file),
            onReindex: () => _reindexFile(file),
          ),
        );
      },
    );
  }

  Widget _buildGlassCardGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth > 1200) {
      crossAxisCount = 4;
      childAspectRatio = 0.55;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
      childAspectRatio = 0.55;
    } else if (screenWidth > 500) {
      crossAxisCount = 2;
      childAspectRatio = 0.55;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 0.5;
    }

    return GridView.builder(
      padding: EdgeInsets.all(screenWidth < 600 ? 12 : 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: screenWidth < 600 ? 12 : 20,
        mainAxisSpacing: screenWidth < 600 ? 12 : 20,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return _buildGlassCard(file);
      },
    );
  }

  Widget _buildGlassCard(DriveFile file) {
    final isSelected = _selectedFiles.contains(file.id);

    return GestureDetector(
      onTap: () {
        if (_selectedFiles.isNotEmpty) {
          _toggleFileSelection(file.id);
        } else if (file.isFolder) {
          _navigateToFolder(file);
        } else {
          if (file.isPdf) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfViewerScreen(file: file),
              ),
            );
          } else if (file.isMarkdown) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MarkdownViewerScreen(file: file),
              ),
            );
          }
        }
      },
      onLongPress: () => _toggleFileSelection(file.id),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        blur: 20,
        opacity: 0.05,
        color: isSelected
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : Theme.of(context).cardColor.withValues(alpha: 0.3),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.4)
              : Theme.of(context).dividerColor.withValues(alpha: 0.15),
          width: 1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail/Preview area with status indicators
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: file.isFolder
                          ? Colors.blue.withValues(alpha: 0.1)
                          : (file.isPdf
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        file.isFolder
                            ? Icons.folder
                            : (file.isPdf
                                  ? Icons.picture_as_pdf
                                  : Icons.description),
                        size: 48,
                        color: file.isFolder
                            ? Colors.blue
                            : (file.isPdf ? Colors.red : Colors.green),
                      ),
                    ),
                  ),
                  // Status badges
                  if (file.isShared)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.people,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // File info with metadata
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File name
                  Text(
                    file.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Metadata row
                  Row(
                    children: [
                      if (!file.isFolder) ...[
                        Icon(
                          Icons.insert_drive_file,
                          size: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          file.isPdf ? 'PDF' : 'MD',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (!file.isFolder && file.size != null) ...[
                        Icon(
                          Icons.storage,
                          size: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            file.formattedSize,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 16,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        padding: EdgeInsets.zero,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.surface
                            : Colors.white,
                        onSelected: (value) {
                          if (value == 'rename') _showRenameDialog(file);
                          if (value == 'delete') _showDeleteConfirmation(file);
                          if (value == 'share') _shareFile(file);
                          if (value == 'reindex') _reindexFile(file);
                          if (value == 'manage_tags') {
                            showDialog(
                              context: context,
                              builder: (context) => TagSelectionDialog(
                                fileIds: [file.id],
                                currentTags: [],
                              ),
                            );
                          }
                          if (value == 'chat_with_folder') {
                            _chatWithSpecificFolder(file);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Text('Rename'),
                          ),
                          const PopupMenuItem(
                            value: 'share',
                            child: Text('Share'),
                          ),
                          if (file.isPdf)
                            const PopupMenuItem(
                              value: 'reindex',
                              child: Text('Reindex'),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          if (file.isFolder)
                            const PopupMenuItem(
                              value: 'chat_with_folder',
                              child: Text('Chat with Folder'),
                            ),
                          const PopupMenuItem(
                            value: 'manage_tags',
                            child: Text('Manage Tags'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Date
                  if (file.modifiedTime != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(file.modifiedTime),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTable() {
    final screenWidth = MediaQuery.of(context).size.width;

    return ListView.builder(
      padding: EdgeInsets.all(screenWidth < 600 ? 12 : 20),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        final isSelected = _selectedFiles.contains(file.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              if (_selectedFiles.isNotEmpty) {
                _toggleFileSelection(file.id);
              } else if (file.isFolder) {
                _navigateToFolder(file);
              } else {
                if (file.isPdf) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen(file: file),
                    ),
                  );
                } else if (file.isMarkdown) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarkdownViewerScreen(file: file),
                    ),
                  );
                }
              }
            },
            onLongPress: () => _toggleFileSelection(file.id),
            child: GlassContainer(
              padding: EdgeInsets.all(screenWidth < 600 ? 12 : 16),
              blur: 20,
              opacity: 0.05,
              color: isSelected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                  : Theme.of(context).cardColor.withValues(alpha: 0.3),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.4)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.15),
                width: 1,
              ),
              child: Row(
                children: [
                  // Icon with gradient background
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: file.isFolder
                            ? [Colors.blue[400]!, Colors.blue[600]!]
                            : (file.isPdf
                                  ? [Colors.red[400]!, Colors.red[700]!]
                                  : [Colors.green[400]!, Colors.green[700]!]),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      file.isFolder
                          ? Icons.folder
                          : (file.isPdf
                                ? Icons.picture_as_pdf
                                : Icons.description),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // File info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name with type badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                file.name,
                                style: TextStyle(
                                  fontSize: screenWidth < 600 ? 13 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!file.isFolder) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (file.isPdf ? Colors.red : Colors.green)
                                          .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  file.isPdf ? 'PDF' : 'MD',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: file.isPdf
                                        ? Colors.red[300]
                                        : Colors.green[300],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Metadata row
                        Row(
                          children: [
                            if (!file.isFolder && file.size != null) ...[
                              Icon(
                                Icons.storage,
                                size: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                file.formattedSize,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            if (file.modifiedTime != null) ...[
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(file.modifiedTime),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                            const Spacer(),
                            // Status indicators
                            if (file.isShared)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.people,
                                  size: 14,
                                  color: Colors.blue[300],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Actions
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    padding: EdgeInsets.zero,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.surface
                        : Colors.white,
                    onSelected: (value) {
                      if (value == 'rename') _showRenameDialog(file);
                      if (value == 'delete') _showDeleteConfirmation(file);
                      if (value == 'share') _shareFile(file);
                      if (value == 'reindex') _reindexFile(file);
                      if (value == 'manage_tags') {
                        showDialog(
                          context: context,
                          builder: (context) => TagSelectionDialog(
                            fileIds: [file.id],
                            currentTags: [],
                          ),
                        );
                      }
                      if (value == 'chat_with_folder') {
                        _chatWithSpecificFolder(file);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text('Rename'),
                      ),
                      const PopupMenuItem(value: 'share', child: Text('Share')),
                      if (file.isPdf)
                        const PopupMenuItem(
                          value: 'reindex',
                          child: Text('Reindex'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      if (file.isFolder)
                        const PopupMenuItem(
                          value: 'chat_with_folder',
                          child: Text('Chat with Folder'),
                        ),
                      const PopupMenuItem(
                        value: 'manage_tags',
                        child: Text('Manage Tags'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleSort(FileSortOption option) {
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

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateMarkdownNote() {
    setState(() => _showFABMenu = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MarkdownEditorScreen()),
    ).then((_) => _loadFiles());
  }

  void _showCreateDrawingNote() {
    setState(() => _showFABMenu = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedDrawingCanvasScreen(),
      ),
    ).then((_) => _loadFiles());
  }

  Widget _buildFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_showFABMenu) ...[
          _buildFABItem(
            icon: Icons.create_new_folder,
            label: 'New Folder',
            onTap: _showCreateFolderDialog,
          ),
          const SizedBox(height: 16),
          _buildFABItem(
            icon: Icons.edit_note,
            label: 'New Markdown Note',
            onTap: _showCreateMarkdownNote,
          ),
          const SizedBox(height: 16),
          _buildFABItem(
            icon: Icons.brush,
            label: 'New Drawing Note',
            onTap: _showCreateDrawingNote,
          ),
          const SizedBox(height: 16),
          _buildFABItem(
            icon: Icons.upload_file,
            label: 'Upload File',
            onTap: _showUploadDialog,
          ),
          const SizedBox(height: 16),
          _buildFABItem(
            icon: Icons.document_scanner,
            label: 'Scan Document',
            onTap: _showScanDocument,
          ),
          const SizedBox(height: 16),
          _buildFABItem(
            icon: Icons.chat,
            label: 'Chat with Folder',
            onTap: _chatWithFolder,
          ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _showFABMenu = !_showFABMenu;
            });
          },
          backgroundColor: AppColors.primary,
          child: Icon(_showFABMenu ? Icons.close : Icons.add),
        ),
      ],
    );
  }

  Widget _buildFABItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          borderRadius: BorderRadius.circular(8),
          color: Colors.black.withValues(alpha: 0.6),
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 12),
        FloatingActionButton(
          onPressed: onTap,
          mini: true,
          backgroundColor: AppColors.secondary,
          child: Icon(icon, size: 20),
        ),
      ],
    );
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('New Folder', style: TextStyle(color: Colors.white)),
      content: ModernTextField(
        controller: _controller,
        hintText: 'Folder Name',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onCreateFolder(_controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

enum FileSortOption { name, date, size, tag }

enum FileViewLayout { list, glassCard }

enum TagFilterMode { any, all }

class RenameDialog extends StatefulWidget {
  final DriveFile file;
  final Function(String) onRename;

  const RenameDialog({super.key, required this.file, required this.onRename});

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.file.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Rename', style: TextStyle(color: Colors.white)),
      content: ModernTextField(controller: _controller, hintText: 'New Name'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.isNotEmpty &&
                _controller.text != widget.file.name) {
              widget.onRename(_controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Rename'),
        ),
      ],
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final bool isDestructive;
  final VoidCallback onConfirm;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.isDestructive,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Text(message, style: TextStyle(color: Colors.grey[400])),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            foregroundColor: isDestructive ? Colors.red : AppColors.primary,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
