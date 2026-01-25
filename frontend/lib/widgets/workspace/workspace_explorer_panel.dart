import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/drive_file.dart';
import '../../services/drive_service.dart';
import '../../theme/app_colors.dart';

/// Explorer panel showing Google Drive files in a tree structure (Cursor-style)
class WorkspaceExplorerPanel extends StatefulWidget {
  final ValueChanged<DriveFile> onFileSelected;
  final String? selectedFileId;
  final DriveFile? selectedFile;

  const WorkspaceExplorerPanel({
    super.key,
    required this.onFileSelected,
    this.selectedFileId,
    this.selectedFile,
  });

  @override
  State<WorkspaceExplorerPanel> createState() => _WorkspaceExplorerPanelState();
}

class _WorkspaceExplorerPanelState extends State<WorkspaceExplorerPanel> {
  final Map<String, List<DriveFile>> _fileCache = {};
  final Set<String> _expandedFolders = {};
  final Set<String> _loadingFolders = {};
  final ScrollController _scrollController = ScrollController();
  
  // Track if user manually navigated into a folder
  String? _manualContextFolderId;
  String? _manualContextFolderName;
  
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  List<DriveFile> _searchResults = [];
  bool _isSearching = false;
  
  // Debounce timer for search
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    // Start loading root, but will switch to context if file arrives
    _loadRootFiles();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(WorkspaceExplorerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // INITIAL SETUP: When file first becomes available, set context
    if (oldWidget.selectedFile == null && 
        widget.selectedFile != null && 
        widget.selectedFile!.parentId != null &&
        _manualContextFolderId == null) {
      // This is the initial file load - set context to its folder
      _setInitialContext(widget.selectedFile!);
      return;
    }
    
    // Don't auto-navigate if we're in manual context mode
    // User has explicitly set their working context
    if (_manualContextFolderId != null) {
      // Just ensure the file is visible if it's in the current context
      if (widget.selectedFileId != oldWidget.selectedFileId &&
          widget.selectedFile != null) {
        // Check if the selected file is in the current context
        final currentFiles = _fileCache[_manualContextFolderId] ?? [];
        final isInCurrentContext = currentFiles.any((f) => f.id == widget.selectedFileId);
        
        if (!isInCurrentContext) {
          // File is not in current context, but don't change context
          // User can navigate manually with "../" if needed
        }
      }
      return;
    }
    
    // Only auto-expand if not in manual context mode
    if (widget.selectedFileId != oldWidget.selectedFileId &&
        widget.selectedFile != null &&
        widget.selectedFile!.parentId != null) {
      _ensureFileVisible(widget.selectedFile!);
    }
  }

  Future<void> _setInitialContext(DriveFile file) async {
    final parentId = file.parentId!;
    
    // Get parent folder name
    String parentName = 'Folder';
    if (parentId == 'root') {
      parentName = 'ScholarMate';
    } else {
      // Try to fetch the parent folder info to get its name
      try {
        final driveService = context.read<DriveService>();
        // We need to search for this folder in its parent to get the name
        // For now, load the folder and use the first file's parent reference
        final files = await driveService.listFiles(parentId);
        if (files.isNotEmpty && mounted) {
          // Check if any file has parent info we can use
          parentName = await _getFolderNameById(parentId) ?? 'Folder';
        }
      } catch (e) {
        // If we can't get the name, just use generic
        parentName = 'Folder';
      }
    }
    
    if (mounted) {
      setState(() {
        _manualContextFolderId = parentId;
        _manualContextFolderName = parentName;
        _expandedFolders.add(parentId);
      });
      
      await _loadFolderContents(parentId);
    }
  }

  Future<String?> _getFolderNameById(String folderId) async {
    // Try to find in cache first
    for (final files in _fileCache.values) {
      final folder = files.where((f) => f.id == folderId).firstOrNull;
      if (folder != null) return folder.name;
    }
    return null;
  }

  Future<void> _ensureFileVisible(DriveFile file) async {
    // Auto-expand parent folders to show the file
    if (file.parentId != null && file.parentId != 'root') {
      await _expandToFile(file.parentId!);
    }
  }

  Future<void> _expandToFile(String folderId) async {
    if (!_expandedFolders.contains(folderId)) {
      setState(() {
        _expandedFolders.add(folderId);
      });
      
      if (!_fileCache.containsKey(folderId)) {
        await _loadFolderContents(folderId);
      }
    }

    // Recursively expand parent folders
    for (final files in _fileCache.values) {
      final folder = files.where((f) => f.id == folderId).firstOrNull;
      if (folder != null && folder.parentId != null && folder.parentId != 'root') {
        await _expandToFile(folder.parentId!);
      }
    }
  }

  Future<void> _loadRootFiles() async {
    if (_fileCache.containsKey('root')) {
      setState(() {}); // Just refresh UI
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final driveService = context.read<DriveService>();
      final files = await driveService.listFiles();

      if (mounted) {
        setState(() {
          _fileCache['root'] = files;
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

  Future<void> _loadFolderContents(String folderId) async {
    if (_fileCache.containsKey(folderId)) {
      return;
    }

    setState(() {
      _loadingFolders.add(folderId);
    });

    try {
      final driveService = context.read<DriveService>();
      final files = await driveService.listFiles(folderId);

      if (mounted) {
        setState(() {
          _fileCache[folderId] = files;
          _loadingFolders.remove(folderId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingFolders.remove(folderId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleFolder(DriveFile folder) {
    if (_expandedFolders.contains(folder.id)) {
      setState(() {
        _expandedFolders.remove(folder.id);
      });
    } else {
      setState(() {
        _expandedFolders.add(folder.id);
      });
      _loadFolderContents(folder.id);
    }
  }

  // Manual deep navigation - sets context mode
  void _navigateIntoFolder(DriveFile folder) {
    setState(() {
      _manualContextFolderId = folder.id;
      _manualContextFolderName = folder.name;
      _expandedFolders.clear();
      _expandedFolders.add(folder.id);
    });
    _loadFolderContents(folder.id);
  }

  // Exit context mode - back to full tree
  Future<void> _exitContextMode() async {
    if (_manualContextFolderId == null) return;
    
    // Find parent of current context folder
    final currentFolderId = _manualContextFolderId!;
    String? parentId;
    String parentName = 'ScholarMate';
    
    // Search cache for the current folder to find its parent
    for (final files in _fileCache.values) {
      final folder = files.where((f) => f.id == currentFolderId).firstOrNull;
      if (folder != null && folder.parentId != null) {
        parentId = folder.parentId;
        if (parentId != 'root') {
          parentName = await _getFolderNameById(parentId!) ?? 'Folder';
        }
        break;
      }
    }
    
    // If we found a parent, navigate to it; otherwise go to root tree view
    if (parentId != null && parentId != 'root') {
      setState(() {
        _manualContextFolderId = parentId;
        _manualContextFolderName = parentName;
        _expandedFolders.clear();
        _expandedFolders.add(parentId!);
      });
      await _loadFolderContents(parentId);
    } else {
      // Go back to full root tree view
      setState(() {
        _manualContextFolderId = null;
        _manualContextFolderName = null;
      });
      await _loadRootFiles();
    }
  }

  List<DriveFile> _getFilteredFiles(List<DriveFile> files) {
    if (_searchQuery.isEmpty) {
      return files.where((f) => f.isFolder || f.isPdf || f.isMarkdown).toList();
    }

    final query = _searchQuery.toLowerCase();
    return files.where((file) {
      return (file.isFolder || file.isPdf || file.isMarkdown) &&
          file.name.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _performGlobalSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final driveService = context.read<DriveService>();
      // Use the new searchFiles method
      final results = await driveService.searchFiles(query);
      
      if (mounted) {
        setState(() {
          _searchResults = results
              .where((f) => f.isFolder || f.isPdf || f.isMarkdown)
              .toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isContextMode = _manualContextFolderId != null;
    
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // Header
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isContextMode 
                        ? _manualContextFolderName!.toUpperCase()
                        : 'EXPLORER',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    _fileCache.clear();
                    _expandedFolders.clear();
                    _loadRootFiles();
                  },
                  tooltip: 'Refresh',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                
                // Debounce search
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                  _performGlobalSearch(value);
                });
              },
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search all files...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchResults = [];
                            _isSearching = false;
                          });
                          _searchDebounce?.cancel();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
            ),
          ),
          // File tree
          Expanded(child: _buildFileTree()),
        ],
      ),
    );
  }

  Widget _buildFileTree() {
    // Show search results if searching
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading files',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _loadRootFiles, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final rootFolderId = _manualContextFolderId ?? 'root';
    final rootFiles = _fileCache[rootFolderId] ?? [];
    final filteredFiles = _getFilteredFiles(rootFiles);

    if (filteredFiles.isEmpty && _manualContextFolderId == null) {
      return Center(
        child: Text(
          'No files',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      children: [
        // Show "go back" button only if in context mode AND not at root level
        if (_manualContextFolderId != null && _shouldShowGoBackButton())
          _buildGoBackItem(),
        ..._buildFileList(filteredFiles, 0),
      ],
    );
  }

  bool _shouldShowGoBackButton() {
    if (_manualContextFolderId == null) return false;
    
    // If context is root, don't show button
    if (_manualContextFolderId == 'root') return false;
    
    // Check if current context folder has a parent (is not at root level)
    for (final files in _fileCache.values) {
      final folder = files.where((f) => f.id == _manualContextFolderId).firstOrNull;
      if (folder != null) {
        // If folder has a parent (even if parent is root), show button
        return folder.parentId != null;
      }
    }
    
    // Default to showing button if we can't determine (better safe than sorry)
    return true;
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Searching...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No results found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search term',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final file = _searchResults[index];
        return _buildSearchResultItem(file);
      },
    );
  }

  Widget _buildSearchResultItem(DriveFile file) {
    final isSelected = widget.selectedFileId == file.id;

    return InkWell(
      key: ValueKey(file.id),
      onTap: () {
        if (file.isFolder) {
          // Clear search and navigate to folder
          setState(() {
            _searchQuery = '';
            _searchResults = [];
            _isSearching = false;
          });
          _navigateIntoFolder(file);
        } else if (file.isPdf || file.isMarkdown) {
          widget.onFileSelected(file);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          border: isSelected
              ? Border(
                  left: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                )
              : Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // File icon
            _getFileIcon(file, isSelected, false),
            const SizedBox(width: 12),
            // File name
            Expanded(
              child: Text(
                file.name,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Show location hint for files
            if (!file.isFolder)
              Icon(
                Icons.folder_outlined,
                size: 14,
                color: Colors.white.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFileList(List<DriveFile> files, int level) {
    final widgets = <Widget>[];

    for (final file in files) {
      widgets.add(_buildFileItem(file, level));

      // If folder is expanded, show its contents
      if (file.isFolder && _expandedFolders.contains(file.id)) {
        if (_loadingFolders.contains(file.id)) {
          widgets.add(_buildLoadingIndicator(level + 1));
        } else {
          final children = _fileCache[file.id] ?? [];
          final filteredChildren = _getFilteredFiles(children);
          if (filteredChildren.isEmpty) {
            widgets.add(_buildEmptyFolderIndicator(level + 1));
          } else {
            widgets.addAll(_buildFileList(filteredChildren, level + 1));
          }
        }
      }
    }

    return widgets;
  }

  Widget _buildGoBackItem() {
    // Check if we can go up further or if we're at root
    bool hasParent = false;
    if (_manualContextFolderId != null) {
      for (final files in _fileCache.values) {
        final folder = files.where((f) => f.id == _manualContextFolderId).firstOrNull;
        if (folder != null && folder.parentId != null) {
          hasParent = true;
          break;
        }
      }
    }
    
    return InkWell(
      onTap: _exitContextMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.arrow_upward,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              '../',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              hasParent ? '(Go up one level)' : '(Back to root)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(int level) {
    final indentation = level * 16.0;
    return Container(
      padding: EdgeInsets.only(
        left: 12 + indentation,
        right: 12,
        top: 6,
        bottom: 6,
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFolderIndicator(int level) {
    final indentation = level * 16.0;
    return Container(
      padding: EdgeInsets.only(
        left: 12 + indentation,
        right: 12,
        top: 6,
        bottom: 6,
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.folder_open,
            size: 14,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 8),
          Text(
            'Empty folder',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(DriveFile file, int level) {
    final isExpanded = _expandedFolders.contains(file.id);
    final isSelected = widget.selectedFileId == file.id;
    final indentation = level * 16.0;
    final isLoading = _loadingFolders.contains(file.id);

    return InkWell(
      key: ValueKey(file.id),
      onTap: () {
        if (file.isFolder) {
          _toggleFolder(file);
        } else if (file.isPdf || file.isMarkdown) {
          widget.onFileSelected(file);
        }
      },
      onDoubleTap: () {
        // Double-click folder to enter context mode
        if (file.isFolder) {
          _navigateIntoFolder(file);
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          left: 12 + indentation,
          right: 12,
          top: 6,
          bottom: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          border: isSelected
              ? Border(
                  left: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Expand/collapse icon for folders
            if (file.isFolder)
              SizedBox(
                width: 16,
                height: 16,
                child: isLoading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
              )
            else
              const SizedBox(width: 16),
            const SizedBox(width: 8),
            // File icon
            _getFileIcon(file, isSelected, isExpanded),
            const SizedBox(width: 8),
            // File name
            Expanded(
              child: Text(
                file.name,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getFileIcon(DriveFile file, bool isSelected, [bool isExpanded = false]) {
    final alphaModifier = isSelected ? 1.0 : 0.8;
    
    if (file.isFolder) {
      return Icon(
        isExpanded ? Icons.folder_open : Icons.folder,
        size: 16,
        color: Colors.amber.withValues(alpha: alphaModifier),
      );
    } else if (file.isPdf) {
      return Icon(
        Icons.picture_as_pdf,
        size: 16,
        color: Colors.red.withValues(alpha: isSelected ? 0.9 : 0.7),
      );
    } else if (file.isMarkdown) {
      return Icon(
        Icons.description,
        size: 16,
        color: Colors.blue.withValues(alpha: isSelected ? 0.9 : 0.7),
      );
    }
    return Icon(
      Icons.insert_drive_file,
      size: 16,
      color: Colors.white.withValues(alpha: isSelected ? 0.7 : 0.5),
    );
  }
}
