import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drive_file.dart';
import '../services/drive_service.dart';
import '../services/tag_service.dart';
import '../services/sharing_service.dart';
import '../services/indexing_service.dart';
import '../services/metadata_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/modern_file_grid_view.dart';
import '../widgets/modern_file_list_view.dart';
import '../widgets/empty_state.dart';
import '../widgets/multi_select_toolbar.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/file_upload_widget.dart';
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
import 'citation_generator_screen.dart';
import 'analytics_screen.dart';
import 'join_collaboration_screen.dart';

/// Modern file explorer screen with glassmorphism design
/// Features glass cards, modern grid/list views, and empty states
class ModernFileExplorerScreen extends StatefulWidget {
  const ModernFileExplorerScreen({super.key});

  @override
  State<ModernFileExplorerScreen> createState() =>
      _ModernFileExplorerScreenState();
}

class _ModernFileExplorerScreenState extends State<ModernFileExplorerScreen> {
  DriveService? _driveService;
  List<DriveFile> _files = [];
  List<DriveFile> _navigationPath = [];
  bool _isLoading = true;
  String? _error;
  String? _currentFolderId;
  final Set<String> _selectedFiles = {};
  bool _showFABMenu = false;
  bool _showTagFilter = false;
  final Set<String> _selectedTagIds = {};
  final TagFilterMode _filterMode = TagFilterMode.any;
  String _searchQuery = '';
  FileSortOption _sortOption = FileSortOption.name;
  bool _sortAscending = true;
  FileViewLayout _viewLayout =
      FileViewLayout.grid; // Default to grid for modern UI
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
      setState(() {
        _error = e.toString();
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

  Future<void> _refresh() async {
    await _loadFiles();
  }

  void _handleFileTap(DriveFile file) {
    if (_selectedFiles.isNotEmpty) {
      _toggleFileSelection(file.id);
      return;
    }

    if (file.isFolder) {
      _navigateToFolder(file);
    } else if (file.isPdf) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => PdfViewerScreen(file: file)),
      );
    } else if (file.isMarkdown) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MarkdownViewerScreen(file: file),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Opening ${file.extension?.toUpperCase() ?? 'this'} files is not yet supported',
          ),
        ),
      );
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
      builder: (context) => _RenameDialog(
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
      builder: (context) => AlertDialog(
        title: Text('Delete ${file.isFolder ? 'Folder' : 'File'}'),
        content: Text(
          'Are you sure you want to delete "${file.name}"? It will be moved to trash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteFile(file);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen =
        MediaQuery.of(context).size.width < DesignTokens.mobileBreakpoint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
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
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ConnectivityIndicator(),
          ),
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
          _buildSettingsMenu(),
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

          // Multi-select toolbar
          if (_selectedFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: MultiSelectToolbar(
                selectedCount: _selectedFiles.length,
                onClearSelection: () => setState(() => _selectedFiles.clear()),
                onBulkTag: _bulkTagFiles,
                onBulkDelete: _showDeleteSelectedConfirmation,
              ),
            ),

          // Modern toolbar
          _buildModernToolbar(theme, isSmallScreen),

          // File list
          Expanded(child: _buildFileList()),
        ],
      ),
      floatingActionButton: _buildFAB(theme),
    );
  }

  Widget _buildSettingsMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'join_collaboration') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const JoinCollaborationScreen(),
            ),
          );
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
            MaterialPageRoute(builder: (context) => const SharedFilesScreen()),
          );
        } else if (value == 'citations') {
          final metadataService = context.read<MetadataService>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CitationGeneratorScreen(metadataService: metadataService),
            ),
          );
        } else if (value == 'analytics') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'join_collaboration',
          child: Row(
            children: [
              Icon(Icons.people, size: 20, color: Colors.purple),
              SizedBox(width: 8),
              Text('Join Collaboration'),
            ],
          ),
        ),
        const PopupMenuDivider(),
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
          value: 'analytics',
          child: Row(
            children: [
              Icon(Icons.insights, size: 20),
              SizedBox(width: 8),
              Text('Analytics & Insights'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'citations',
          child: Row(
            children: [
              Icon(Icons.format_quote, size: 20),
              SizedBox(width: 8),
              Text('Citations'),
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
    );
  }

  Widget _buildModernToolbar(ThemeData theme, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: isSmallScreen ? DesignTokens.space2 : DesignTokens.space3,
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
                borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
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
                    horizontal: DesignTokens.space4,
                    vertical: isSmallScreen
                        ? DesignTokens.space2
                        : DesignTokens.space3,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: isSmallScreen ? DesignTokens.space2 : DesignTokens.space3,
          ),

          // Sort button
          _buildToolbarButton(
            theme,
            Icons.sort,
            'Sort',
            onTap: () => _showSortMenu(theme),
          ),
          SizedBox(
            width: isSmallScreen ? DesignTokens.space1 : DesignTokens.space2,
          ),

          // View layout toggle
          _buildToolbarButton(
            theme,
            _viewLayout == FileViewLayout.grid
                ? Icons.grid_view
                : Icons.view_list,
            'View',
            onTap: _toggleViewLayout,
          ),
          SizedBox(
            width: isSmallScreen ? DesignTokens.space1 : DesignTokens.space2,
          ),

          // Filter button
          _buildToolbarButton(
            theme,
            _showTagFilter ? Icons.filter_list_off : Icons.filter_list,
            'Filter',
            onTap: () => setState(() => _showTagFilter = !_showTagFilter),
            isActive: _showTagFilter || _selectedTagIds.isNotEmpty,
            badge: _selectedTagIds.isNotEmpty ? _selectedTagIds.length : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(
    ThemeData theme,
    IconData icon,
    String tooltip, {
    VoidCallback? onTap,
    bool isActive = false,
    int? badge,
  }) {
    return Stack(
      children: [
        Container(
          height: 43,
          width: 43,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
            border: Border.all(
              color: isActive ? theme.colorScheme.primary : theme.dividerColor,
              width: isActive ? 2 : 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: onTap,
            tooltip: tooltip,
          ),
        ),
        if (badge != null)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$badge',
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
    );
  }

  void _toggleViewLayout() {
    setState(() {
      _viewLayout = _viewLayout == FileViewLayout.grid
          ? FileViewLayout.list
          : FileViewLayout.grid;
    });
  }

  void _showSortMenu(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sort by', style: theme.textTheme.titleLarge),
            const SizedBox(height: DesignTokens.space4),
            _buildSortOption(FileSortOption.name, 'Name'),
            _buildSortOption(FileSortOption.date, 'Date'),
            _buildSortOption(FileSortOption.size, 'Size'),
            _buildSortOption(FileSortOption.tag, 'Tag'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(FileSortOption option, String label) {
    final isSelected = _sortOption == option;
    return ListTile(
      leading: Icon(
        isSelected
            ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
            : Icons.sort,
      ),
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check) : null,
      onTap: () {
        setState(() {
          if (_sortOption == option) {
            _sortAscending = !_sortAscending;
          } else {
            _sortOption = option;
            _sortAscending = true;
          }
        });
        _loadFiles();
        Navigator.pop(context);
      },
    );
  }

  Widget _buildFileList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return EmptyState.error(
        errorMessage: _error!,
        action: ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
      );
    }

    if (_files.isEmpty) {
      return EmptyState.emptyFolder(
        action: ElevatedButton.icon(
          onPressed: () => setState(() => _showFABMenu = true),
          icon: const Icon(Icons.add),
          label: const Text('Add Files'),
        ),
      );
    }

    // Display files in grid or list view
    if (_viewLayout == FileViewLayout.grid) {
      return ModernFileGridView(
        files: _files,
        selectedFiles: _selectedFiles,
        onFileTap: _handleFileTap,
        onFileLongPress: _toggleFileSelection,
        onRename: _showRenameDialog,
        onDelete: _showDeleteConfirmation,
        onShare: _shareFile,
        onReindex: _reindexFile,
        onRefresh: _refresh,
      );
    } else {
      return ModernFileListView(
        files: _files,
        selectedFiles: _selectedFiles,
        onFileTap: _handleFileTap,
        onFileLongPress: _toggleFileSelection,
        onRename: _showRenameDialog,
        onDelete: _showDeleteConfirmation,
        onShare: _shareFile,
        onReindex: _reindexFile,
        onRefresh: _refresh,
      );
    }
  }

  Widget _buildFAB(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showFABMenu) ...[
          FloatingActionButton(
            heroTag: "scan",
            onPressed: _showScanDocument,
            tooltip: 'Scan document',
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: const Icon(Icons.document_scanner),
          ),
          const SizedBox(height: DesignTokens.space4),
          FloatingActionButton(
            heroTag: "upload",
            onPressed: _showUploadDialog,
            tooltip: 'Upload files',
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            child: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: DesignTokens.space4),
          FloatingActionButton(
            heroTag: "folder",
            onPressed: _showCreateFolderDialog,
            tooltip: 'Create folder',
            backgroundColor: theme.colorScheme.tertiaryContainer,
            foregroundColor: theme.colorScheme.onTertiaryContainer,
            child: const Icon(Icons.create_new_folder),
          ),
          const SizedBox(height: DesignTokens.space4),
        ],
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
            duration: DesignTokens.hoverDuration,
            child: Icon(_showFABMenu ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
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
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.space6),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Files',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: DesignTokens.space4),
              Text(
                'Select PDF or Markdown files to upload to your ScholarMate folder.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: DesignTokens.space6),
              FileUploadWidget(
                parentFolderId: _currentFolderId!,
                driveService: _driveService!,
                onUploadComplete: () {
                  _loadFiles();
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: DesignTokens.space4),
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
}

/// Sort options for files
enum FileSortOption { name, date, size, tag }

/// View layout options for files
enum FileViewLayout { list, grid }

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

class _RenameDialog extends StatefulWidget {
  final DriveFile file;
  final Function(String) onRename;

  const _RenameDialog({required this.file, required this.onRename});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

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
      title: Text('Rename ${widget.file.isFolder ? 'Folder' : 'File'}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'New name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a name';
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
