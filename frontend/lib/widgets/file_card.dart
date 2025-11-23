import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drive_file.dart';
import '../models/tag.dart';
import '../services/cache_service.dart';
import '../services/tag_service.dart';

import 'ui/glass_container.dart';
import 'file_context_menu.dart';
import 'tag_chip.dart';
import 'tag_selection_dialog.dart';
import 'indexing_status_badge.dart';

/// A modern glassmorphism card displaying file or folder information
class FileCard extends StatefulWidget {
  final DriveFile file;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRename;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onReindex;
  final bool isSelected;

  const FileCard({
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
  });

  @override
  State<FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<FileCard>
    with SingleTickerProviderStateMixin {
  List<Tag> _tags = [];
  bool _isLoadingTags = false;
  bool _initialized = false;
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && !widget.file.isFolder) {
      _initialized = true;
      _loadTags();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            blur: 10,
            opacity: widget.isSelected ? 0.15 : (_isHovered ? 0.1 : 0.05),
            color: widget.isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                : (_isHovered
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.08)
                      : Theme.of(context).cardColor.withValues(alpha: 0.5)),
            border: Border.all(
              color: widget.isSelected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.1),
              width: 1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and name row
                Row(
                  children: [
                    Stack(
                      children: [
                        _buildFileIcon(),
                        if (widget.file.isPdf)
                          FutureBuilder<bool>(
                            future: context.read<CacheService>().isPdfCached(
                              widget.file.id,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.data == true) {
                                return Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.file.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!widget.file.isFolder) ...[
                            const SizedBox(height: 4),
                            Text(
                              _getFileTypeLabel(),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.file.isShared)
                      Icon(
                        Icons.people,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    const SizedBox(width: 8),
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
                ),

                const SizedBox(height: 12),

                // Tags section (only for files, not folders)
                if (!widget.file.isFolder) ...[
                  if (_isLoadingTags)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_tags.isNotEmpty) ...[
                    TagChipList(
                      tags: _tags,
                      small: true,
                      maxTags: 3,
                      onTagTap: (tag) {
                        // Optional: Navigate to filtered view with this tag
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ],

                // Metadata row
                Row(
                  children: [
                    if (!widget.file.isFolder && widget.file.size != null) ...[
                      Icon(
                        Icons.storage,
                        size: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.54),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.file.formattedSize,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.54),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.54),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _formatDate(widget.file.modifiedTime),
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.54),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                // Sync status indicator
                if (widget.file.syncStatus != 'synced') ...[
                  const SizedBox(height: 8),
                  _buildSyncStatusBadge(),
                ],

                // Indexing status badge (only for PDFs)
                if (widget.file.isPdf) ...[
                  const SizedBox(height: 8),
                  IndexingStatusBadge(fileId: widget.file.id),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    if (widget.file.isFolder) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[400]!, Colors.blue[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.folder, color: Colors.white, size: 24),
      );
    }

    Color iconColor;
    IconData iconData;
    List<Color> gradientColors;

    if (widget.file.isPdf) {
      iconColor = Colors.red;
      iconData = Icons.picture_as_pdf;
      gradientColors = [Colors.red[400]!, Colors.red[700]!];
    } else if (widget.file.isMarkdown) {
      iconColor = Colors.green;
      iconData = Icons.description;
      gradientColors = [Colors.green[400]!, Colors.green[700]!];
    } else {
      iconColor = Colors.grey;
      iconData = Icons.insert_drive_file;
      gradientColors = [Colors.grey[400]!, Colors.grey[600]!];
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(iconData, color: Colors.white, size: 24),
    );
  }

  String _getFileTypeLabel() {
    if (widget.file.isPdf) return 'PDF Document';
    if (widget.file.isMarkdown) return 'Markdown File';
    if (widget.file.extension != null) {
      return '${widget.file.extension!.toUpperCase()} File';
    }
    return 'File';
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

  Widget _buildSyncStatusBadge() {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (widget.file.syncStatus) {
      case 'pending':
        badgeColor = Colors.orange;
        badgeIcon = Icons.cloud_upload;
        badgeText = 'Pending upload';
        break;
      case 'failed':
        badgeColor = Colors.red;
        badgeIcon = Icons.error_outline;
        badgeText = 'Upload failed';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
