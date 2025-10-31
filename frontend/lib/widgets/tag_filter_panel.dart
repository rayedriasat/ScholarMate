import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tag.dart';
import '../services/tag_service.dart';

/// Filter mode for tag filtering
enum TagFilterMode {
  any, // OR logic - show files with any selected tag
  all, // AND logic - show files with all selected tags
}

/// Panel for filtering files by tags with search
class TagFilterPanel extends StatefulWidget {
  final Set<String> selectedTagIds;
  final TagFilterMode filterMode;
  final String searchQuery;
  final Function(Set<String> tagIds, TagFilterMode mode, String searchQuery)
  onFilterChanged;
  final VoidCallback? onClose;

  const TagFilterPanel({
    super.key,
    required this.selectedTagIds,
    required this.filterMode,
    required this.searchQuery,
    required this.onFilterChanged,
    this.onClose,
  });

  @override
  State<TagFilterPanel> createState() => _TagFilterPanelState();
}

class _TagFilterPanelState extends State<TagFilterPanel>
    with SingleTickerProviderStateMixin {
  List<Tag> _tags = [];
  List<Tag> _filteredTags = [];
  bool _isLoading = true;
  late Set<String> _selectedTagIds;
  late TagFilterMode _filterMode;
  late String _searchQuery;
  bool _initialized = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTagIds = Set.from(widget.selectedTagIds);
    _filterMode = widget.filterMode;
    _searchQuery = widget.searchQuery;

    _searchController.addListener(_filterTags);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadTags();
    }
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);

    try {
      final tagService = context.read<TagService>();
      final tags = await tagService.getTags();

      if (mounted) {
        setState(() {
          _tags = tags;
          _filteredTags = tags;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterTags() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTags = _tags;
      } else {
        _filteredTags = _tags
            .where((tag) => tag.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });
    widget.onFilterChanged(_selectedTagIds, _filterMode, _searchQuery);
  }

  void _clearFilters() {
    setState(() {
      _selectedTagIds.clear();
      _searchController.clear();
    });
    widget.onFilterChanged(_selectedTagIds, _filterMode, _searchQuery);
  }

  void _toggleFilterMode() {
    setState(() {
      _filterMode = _filterMode == TagFilterMode.any
          ? TagFilterMode.all
          : TagFilterMode.any;
    });
    if (_selectedTagIds.isNotEmpty) {
      widget.onFilterChanged(_selectedTagIds, _filterMode, _searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Make panel responsive - 90% width on mobile, fixed width on desktop
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final panelWidth = isMobile ? screenWidth * 0.9 : 320.0;
    final theme = Theme.of(context);

    return Container(
      width: panelWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(left: BorderSide(color: theme.dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildModernHeader(theme),
          Expanded(child: _buildTagFilterContent(theme)),
          if (screenWidth < 600 && widget.onClose != null)
            _buildMobileDoneButton(theme),
        ],
      ),
    );
  }

  Widget _buildModernHeader(ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.tune, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters & Search',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                if (_selectedTagIds.isNotEmpty)
                  Text(
                    '${_selectedTagIds.length} tag${_selectedTagIds.length == 1 ? '' : 's'} selected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedTagIds.isNotEmpty)
            IconButton(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear all filters',
              iconSize: 20,
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surface.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
          if (isMobile && widget.onClose != null)
            IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close),
              tooltip: 'Close filters',
              iconSize: 20,
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surface.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagFilterContent(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter by tags',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_selectedTagIds.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _filterMode == TagFilterMode.any ? 'ANY' : 'ALL',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: _toggleFilterMode,
                            child: Icon(
                              Icons.swap_horiz,
                              size: 16,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search tags...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildTagList(theme)),
      ],
    );
  }

  Widget _buildTagList(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final tagsToShow = _filteredTags.isEmpty ? _tags : _filteredTags;

    if (tagsToShow.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.label_outline,
                size: 48,
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isNotEmpty
                    ? 'No tags found'
                    : 'No tags available',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      itemCount: tagsToShow.length,
      itemBuilder: (context, index) {
        final tag = tagsToShow[index];
        final isSelected = _selectedTagIds.contains(tag.id);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: isSelected ? 2 : 0,
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (_) => _toggleTag(tag.id),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            visualDensity: VisualDensity.compact,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _parseColor(tag.color),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _parseColor(tag.color).withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tag.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                '${tag.documentCount} doc${tag.documentCount == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileDoneButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                if (_selectedTagIds.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedTagIds.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.blue;
    }
  }
}
