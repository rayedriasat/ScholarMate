import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drive_file.dart';
import '../services/drive_service.dart';
import '../theme/app_colors.dart';
import 'ui/glass_container.dart';
import 'ui/modern_button.dart';

/// Panel for selecting source files for AI chat with folder navigation
class SourceSelectionPanel extends StatefulWidget {
  final Set<String> selectedFileIds;
  final Function(DriveFile) onToggleFile;
  final VoidCallback onClearAll;

  const SourceSelectionPanel({
    super.key,
    required this.selectedFileIds,
    required this.onToggleFile,
    required this.onClearAll,
  });

  @override
  State<SourceSelectionPanel> createState() => _SourceSelectionPanelState();
}

class _SourceSelectionPanelState extends State<SourceSelectionPanel> {
  List<DriveFile> _files = [];
  final List<DriveFile> _navigationPath = [];
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
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final driveService = context.read<DriveService>();
      final files = await driveService.listFiles(_currentFolderId);

      // Filter and sort
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

      // Sort: folders first, then files
      filteredFiles.sort((a, b) {
        if (a.isFolder && !b.isFolder) return -1;
        if (!a.isFolder && b.isFolder) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      if (mounted) {
        setState(() {
          _files = filteredFiles;
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

  void _navigateToFolder(DriveFile folder) {
    setState(() {
      _currentFolderId = folder.id;
      _navigationPath.add(folder);
      _searchController.clear(); // Clear search on navigation
    });
    _loadFiles();
  }

  void _navigateToRoot() {
    setState(() {
      _navigationPath.clear();
      _currentFolderId = null;
      _searchController.clear();
    });
    _loadFiles();
  }

  void _navigateUp() {
    if (_navigationPath.isNotEmpty) {
      setState(() {
        _navigationPath.removeLast();
        _currentFolderId = _navigationPath.isNotEmpty
            ? _navigationPath.last.id
            : null;
        _searchController.clear();
      });
      _loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_list, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Source Selection',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (widget.selectedFileIds.isNotEmpty)
                    TextButton(
                      onPressed: widget.onClearAll,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Clear (${widget.selectedFileIds.length})',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Search Bar
              TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 13, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search files...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black38,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: isDark ? Colors.white54 : Colors.black38,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => _searchController.clear(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),

        // Breadcrumbs
        if (_navigationPath.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  InkWell(
                    onTap: _navigateToRoot,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.home, size: 16),
                    ),
                  ),
                  for (int i = 0; i < _navigationPath.length; i++) ...[
                    const Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: Colors.grey,
                    ),
                    InkWell(
                      onTap: i == _navigationPath.length - 1
                          ? null
                          : () {
                              setState(() {
                                _navigationPath.removeRange(
                                  i + 1,
                                  _navigationPath.length,
                                );
                                _currentFolderId = _navigationPath[i].id;
                                _searchController.clear();
                              });
                              _loadFiles();
                            },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 2.0,
                        ),
                        child: Text(
                          _navigationPath[i].name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: i == _navigationPath.length - 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

        // File List
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Error loading files',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ModernButton(
                        onPressed: _loadFiles,
                        icon: Icons.refresh,
                        label: 'Retry',
                        height: 36,
                      ),
                    ],
                  ),
                )
              : _files.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    return _buildFileItem(context, _files[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.folder_open,
            size: 48,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'No matching files'
                : 'This folder is empty',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontSize: 14,
            ),
          ),
          if (_searchQuery.isEmpty && _currentFolderId != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton.icon(
                onPressed: _navigateUp,
                icon: const Icon(Icons.arrow_upward, size: 16),
                label: const Text('Go Up'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, DriveFile file) {
    final theme = Theme.of(context);
    final isSelected = widget.selectedFileIds.contains(file.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(8),
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.5)
              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
        child: InkWell(
          onTap: () {
            if (file.isFolder) {
              _navigateToFolder(file);
            } else {
              widget.onToggleFile(file);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                if (file.isFolder)
                  Icon(Icons.folder, color: Colors.amber.shade300, size: 24)
                else
                  // Checkbox for files
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => widget.onToggleFile(file),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: file.isFolder || isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!file.isFolder)
                        Row(
                          children: [
                            Text(
                              file.formattedSize,
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            // Indexed/Included indicator
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    size: 8,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    isSelected ? 'Included' : 'Available',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                if (file.isFolder)
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
