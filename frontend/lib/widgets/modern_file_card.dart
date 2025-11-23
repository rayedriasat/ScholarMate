import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drive_file.dart';
import '../models/tag.dart';
import '../services/cache_service.dart';
import '../services/tag_service.dart';
import '../theme/design_tokens.dart';
import 'glass/glass_card.dart';
import 'file_context_menu.dart';
import 'tag_selection_dialog.dart';
import 'indexing_status_badge.dart';

/// Modern file card with glassmorphism design
/// Displays file information with glass styling, rounded corners, and hover effects
class ModernFileCard extends StatefulWidget {
  final DriveFile file;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRename;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onReindex;
  final bool isSelected;
  final bool isGridView;

  const ModernFileCard({
    super.key,
    required this.file,
    this.onTap,
    this.onLongPress,
    this.onRename,
    this.onMove,
    this.onDelete,
    this.onShare,
    this.onReindex,
    this.isSelected = false,
    this.isGridView = false,
  });

  @override
  State<ModernFileCard> createState() => _ModernFileCardState();
}

class _ModernFileCardState extends State<ModernFileCard> {
  List<Tag> _tags = [];
  bool _isLoadingTags = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && !widget.file.isFolder) {
      _initialized = true;
      _loadTags();
    }
  }

  Future<void> _loadTags() async {
    setState(() => _isLoadingTags = true);

    try {
      final tagService = context.read<TagService>();
      final tags = await tagService.getTagsForFile(widget.file.id);

      if (mounted) {
        setState(() {
          _tags = tags;
          _isLoadingTags = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTags = false);
      }
    }
  }

  Future<void> _manageTags() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          TagSelectionDialog(fileIds: [widget.file.id], currentTags: _tags),
    );

    if (result == true) {
      _loadTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppGlassCard(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
      child: InkWell(
        onLongPress: widget.onLongPress,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        child: Container(
          decoration: widget.isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: widget.isGridView
                ? _buildGridContent()
                : _buildListContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildGridContent() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail with rounded corners and shadow
        _buildThumbnail(),
        const SizedBox(height: DesignTokens.space3),

        // File name
        Text(
          widget.file.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: DesignTokens.semiBold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: DesignTokens.space2),

        // Tags (pill-shaped chips with accent colors)
        if (!widget.file.isFolder && _tags.isNotEmpty) ...[
          _buildTagChips(),
          const SizedBox(height: DesignTokens.space2),
        ],

        const Spacer(),

        // Metadata row with icons
        _buildMetadataRow(),

        // Indexing status for PDFs
        if (widget.file.isPdf) ...[
          const SizedBox(height: DesignTokens.space2),
          IndexingStatusBadge(fileId: widget.file.id),
        ],
      ],
    );
  }

  Widget _buildListContent() {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Thumbnail
        _buildThumbnail(size: 56),
        const SizedBox(width: DesignTokens.space4),

        // File info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File name
              Text(
                widget.file.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.semiBold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: DesignTokens.space1),

              // Tags
              if (!widget.file.isFolder && _tags.isNotEmpty) ...[
                _buildTagChips(),
                const SizedBox(height: DesignTokens.space1),
              ],

              // Metadata
              _buildMetadataRow(),

              // Indexing status for PDFs
              if (widget.file.isPdf) ...[
                const SizedBox(height: DesignTokens.space1),
                IndexingStatusBadge(fileId: widget.file.id),
              ],
            ],
          ),
        ),

        // Context menu
        FileContextMenu(
          file: widget.file,
          onRename: widget.onRename,
          onMove: widget.onMove,
          onDelete: widget.onDelete,
          onShare: widget.onShare,
          onManageTags: widget.file.isFolder ? null : _manageTags,
          onReindex: widget.file.isPdf ? widget.onReindex : null,
        ),
      ],
    );
  }

  Widget _buildThumbnail({double size = 80}) {
    final theme = Theme.of(context);

    Widget thumbnail;
    Color backgroundColor;
    Color iconColor;
    IconData iconData;

    if (widget.file.isFolder) {
      backgroundColor = theme.colorScheme.primaryContainer;
      iconColor = theme.colorScheme.primary;
      iconData = Icons.folder;
    } else if (widget.file.isPdf) {
      backgroundColor = DesignTokens.error[100]!;
      iconColor = DesignTokens.error[700]!;
      iconData = Icons.picture_as_pdf;
    } else if (widget.file.isMarkdown) {
      backgroundColor = DesignTokens.success[100]!;
      iconColor = DesignTokens.success[700]!;
      iconData = Icons.description;
    } else {
      backgroundColor = DesignTokens.neutral[100]!;
      iconColor = DesignTokens.neutral[700]!;
      iconData = Icons.insert_drive_file;
    }

    thumbnail = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(iconData, color: iconColor, size: size * 0.5),
    );

    // Add cached indicator for PDFs
    if (widget.file.isPdf) {
      return Stack(
        children: [
          thumbnail,
          FutureBuilder<bool>(
            future: context.read<CacheService>().isPdfCached(widget.file.id),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: DesignTokens.success[500],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      );
    }

    // Add shared indicator
    if (widget.file.isShared) {
      return Stack(
        children: [
          thumbnail,
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.people, size: 12, color: Colors.white),
            ),
          ),
        ],
      );
    }

    return thumbnail;
  }

  Widget _buildTagChips() {
    final theme = Theme.of(context);

    if (_isLoadingTags) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      );
    }

    return Wrap(
      spacing: DesignTokens.space1,
      runSpacing: DesignTokens.space1,
      children: _tags.take(3).map((tag) {
        final tagColor = Color(int.parse(tag.color));
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space2,
            vertical: DesignTokens.space1,
          ),
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            border: Border.all(color: tagColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            tag.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: DesignTokens.medium,
              color: tagColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetadataRow() {
    final theme = Theme.of(context);
    final metadataStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Row(
      children: [
        // Size icon and text
        if (!widget.file.isFolder && widget.file.size != null) ...[
          Icon(
            Icons.storage,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.space1),
          Text(widget.file.formattedSize, style: metadataStyle),
          const SizedBox(width: DesignTokens.space3),
        ],

        // Date icon and text
        Icon(
          Icons.access_time,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: DesignTokens.space1),
        Expanded(
          child: Text(
            _formatDate(widget.file.modifiedTime),
            style: metadataStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
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
}
