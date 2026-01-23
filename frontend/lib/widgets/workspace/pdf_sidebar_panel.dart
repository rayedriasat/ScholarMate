import 'package:flutter/material.dart';
import 'pdf_tab_manager.dart';
import '../../theme/app_colors.dart';

/// Sidebar panel showing outline or thumbnails
class PdfSidebarPanel extends StatefulWidget {
  final PdfTab tab;
  final bool showOutline;
  final bool showThumbnails;
  final ValueChanged<int> onPageSelected;

  const PdfSidebarPanel({
    super.key,
    required this.tab,
    required this.showOutline,
    required this.showThumbnails,
    required this.onPageSelected,
  });

  @override
  State<PdfSidebarPanel> createState() => _PdfSidebarPanelState();
}

class _PdfSidebarPanelState extends State<PdfSidebarPanel> {
  bool _showOutline = true; // Default to outline view

  @override
  void initState() {
    super.initState();
    _showOutline = widget.showOutline;
  }

  @override
  void didUpdateWidget(PdfSidebarPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showOutline && !oldWidget.showOutline) {
      _showOutline = true;
    } else if (widget.showThumbnails && !oldWidget.showThumbnails) {
      _showOutline = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with toggle buttons
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              // Outline button
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showOutline = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _showOutline
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.list,
                          size: 16,
                          color: _showOutline
                              ? AppColors.primary
                              : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Outline',
                          style: TextStyle(
                            color: _showOutline
                                ? AppColors.primary
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: _showOutline
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Thumbnails button
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showOutline = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_showOutline
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.view_sidebar,
                          size: 16,
                          color: !_showOutline
                              ? AppColors.primary
                              : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Thumbnails',
                          style: TextStyle(
                            color: !_showOutline
                                ? AppColors.primary
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: !_showOutline
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: _showOutline ? _buildOutlinePanel() : _buildThumbnailPanel(),
        ),
      ],
    );
  }

  Widget _buildOutlinePanel() {
    final bookmarks = widget.tab.bookmarks;
    final hasBookmarks = bookmarks != null && bookmarks.count > 0;

    if (!hasBookmarks) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No table of contents',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This PDF does not contain bookmarks',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: bookmarks.count,
      itemBuilder: (context, index) {
        return _buildBookmarkItem(bookmarks[index], 0);
      },
    );
  }

  Widget _buildBookmarkItem(dynamic bookmark, int level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            // Use Syncfusion's jumpToBookmark method
            try {
              widget.tab.controller.jumpToBookmark(bookmark);
            } catch (e) {
              debugPrint('Error navigating to bookmark: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Could not navigate to: ${bookmark.title ?? "bookmark"}',
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Container(
            padding: EdgeInsets.only(
              left: 12.0 + (level * 16.0),
              right: 12,
              top: 10,
              bottom: 10,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  level == 0 ? Icons.bookmark : Icons.subdirectory_arrow_right,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bookmark.title ?? 'Untitled',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: level == 0 ? 13 : 12,
                      fontWeight: level == 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
        // Render child bookmarks recursively
        if (bookmark.count != null && bookmark.count > 0)
          ...List.generate(
            bookmark.count,
            (i) => _buildBookmarkItem(bookmark[i], level + 1),
          ),
      ],
    );
  }

  Widget _buildThumbnailPanel() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widget.tab.totalPages,
      itemBuilder: (context, index) {
        final pageNumber = index + 1;
        final isCurrentPage = pageNumber == widget.tab.currentPage;

        return InkWell(
          onTap: () => widget.onPageSelected(pageNumber),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isCurrentPage
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.2),
                width: isCurrentPage ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Page $pageNumber',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isCurrentPage
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.grey[200],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Text(
                    '$pageNumber',
                    style: TextStyle(
                      color: isCurrentPage
                          ? AppColors.primary
                          : Colors.grey[700],
                      fontSize: 11,
                      fontWeight: isCurrentPage
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
