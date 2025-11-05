import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drive_file.dart';
import '../services/drive_service.dart';
import '../widgets/file_card.dart';
import '../widgets/file_card_compact.dart';
import '../widgets/breadcrumb_navigation.dart';

/// Enhanced file explorer with multiple view layouts (list, grid, compact)
class FileExplorerEnhanced extends StatefulWidget {
  final String? initialFolderId;

  const FileExplorerEnhanced({super.key, this.initialFolderId});

  @override
  State<FileExplorerEnhanced> createState() => _FileExplorerEnhancedState();
}

class _FileExplorerEnhancedState extends State<FileExplorerEnhanced> {
  List<DriveFile> _files = [];
  final Set<String> _selectedFileIds = {};
  bool _isLoading = true;
  FileSortOption _sortOption = FileSortOption.name;
  bool _sortAscending = true;
  FileViewLayout _viewLayout = FileViewLayout.grid;
  String? _currentFolderId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFolderId = widget.initialFolderId;
    _loadFiles();
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
      final files = await driveService.listFiles(
        folderId: _currentFolderId,
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      // Apply sorting
      final sortedFiles = _sortFiles(files);

      if (mounted) {
        setState(() {
          _files = sortedFiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load files: $e')));
      }
    }
  }

  List<DriveFile> _sortFiles(List<DriveFile> files) {
    final sorted = List<DriveFile>.from(files);

    switch (_sortOption) {
      case FileSortOption.name:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case FileSortOption.date:
        sorted.sort((a, b) => a.modifiedTime.compareTo(b.modifiedTime));
        break;
      case FileSortOption.size:
        sorted.sort((a, b) {
          final aSize = a.size ?? 0;
          final bSize = b.size ?? 0;
          return aSize.compareTo(bSize);
        });
        break;
      case FileSortOption.type:
        sorted.sort((a, b) {
          if (a.isFolder && !b.isFolder) return -1;
          if (!a.isFolder && b.isFolder) return 1;
          return a.mimeType.compareTo(b.mimeType);
        });
        break;
    }

    if (!_sortAscending) {
      return sorted.reversed.toList();
    }

    return sorted;
  }

  void _toggleFileSelection(String fileId) {
    setState(() {
      if (_selectedFileIds.contains(fileId)) {
        _selectedFileIds.remove(fileId);
      } else {
        _selectedFileIds.add(fileId);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedFileIds.clear());
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

  void _changeViewLayout(FileViewLayout layout) {
    setState(() => _viewLayout = layout);
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    _loadFiles();
  }

  void _navigateToFolder(String folderId) {
    setState(() {
      _currentFolderId = folderId;
      _clearSelection();
    });
    _loadFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectedFileIds.isEmpty
            ? const Text('Files')
            : Text('${_selectedFileIds.length} selected'),
        leading: _selectedFileIds.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Breadcrumb navigation
              if (_currentFolderId != null)
                BreadcrumbNavigation(
                  currentFolderId: _currentFolderId!,
                  onNavigate: _navigateToFolder,
                ),

              // Search bar and view controls
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Search bar
                    Expanded(
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
                                    _onSearch('');
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
                        onChanged: _onSearch,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // View layout toggle
                    _buildViewLayoutToggle(),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_selectedFileIds.isEmpty) ...[
            // Sort menu
            PopupMenuButton<FileSortOption>(
              icon: const Icon(Icons.sort),
              onSelected: _toggleSort,
              itemBuilder: (context) => [
                _buildSortMenuItem(FileSortOption.name, 'Name'),
                _buildSortMenuItem(FileSortOption.date, 'Date'),
                _buildSortMenuItem(FileSortOption.size, 'Size'),
                _buildSortMenuItem(FileSortOption.type, 'Type'),
              ],
            ),
          ] else ...[
            // Bulk actions
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Handle bulk delete
              },
              tooltip: 'Delete Selected',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Handle bulk share
              },
              tooltip: 'Share Selected',
            ),
          ],
        ],
      ),
      body: _buildFileList(),
    );
  }

  Widget _buildViewLayoutToggle() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLayoutButton(FileViewLayout.list, Icons.view_list, 'List View'),
          _buildLayoutButton(FileViewLayout.grid, Icons.grid_view, 'Grid View'),
          _buildLayoutButton(
            FileViewLayout.compact,
            Icons.view_agenda,
            'Compact View',
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutButton(
    FileViewLayout layout,
    IconData icon,
    String tooltip,
  ) {
    final isSelected = _viewLayout == layout;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _changeViewLayout(layout),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
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

  Widget _buildFileList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.folder_open,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No files found for "$_searchQuery"'
                  : 'No files in this folder',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearch('');
                },
                child: const Text('Clear search'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(onRefresh: _loadFiles, child: _buildLayoutView());
  }

  Widget _buildLayoutView() {
    switch (_viewLayout) {
      case FileViewLayout.grid:
        return _buildGridView();
      case FileViewLayout.compact:
        return _buildCompactView();
      case FileViewLayout.list:
      default:
        return _buildListView();
    }
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        final isSelected = _selectedFileIds.contains(file.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FileCard(
            file: file,
            isSelected: isSelected,
            onTap: () {
              if (_selectedFileIds.isNotEmpty) {
                _toggleFileSelection(file.id);
              } else if (file.isFolder) {
                _navigateToFolder(file.id);
              } else {
                // Open file
              }
            },
            onLongPress: () => _toggleFileSelection(file.id),
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        final isSelected = _selectedFileIds.contains(file.id);

        return FileCardCompact(
          file: file,
          isSelected: isSelected,
          onTap: () {
            if (_selectedFileIds.isNotEmpty) {
              _toggleFileSelection(file.id);
            } else if (file.isFolder) {
              _navigateToFolder(file.id);
            } else {
              // Open file
            }
          },
          onLongPress: () => _toggleFileSelection(file.id),
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
        final isSelected = _selectedFileIds.contains(file.id);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 2),
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isSelected
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
              '${file.formattedSize} • ${_formatDate(file.modifiedTime)}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: file.isShared
                ? Icon(Icons.people, size: 16, color: Colors.blue[600])
                : null,
            onTap: () {
              if (_selectedFileIds.isNotEmpty) {
                _toggleFileSelection(file.id);
              } else if (file.isFolder) {
                _navigateToFolder(file.id);
              } else {
                // Open file
              }
            },
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

  String _formatDate(DateTime date) {
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
}

/// Sort options for files
enum FileSortOption { name, date, size, type }

/// View layout options for files
enum FileViewLayout { list, grid, compact }
