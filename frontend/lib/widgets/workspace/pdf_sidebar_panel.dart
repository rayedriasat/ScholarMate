import 'package:flutter/material.dart';
import 'pdf_tab_manager.dart';
import '../../theme/app_colors.dart';

/// Sidebar panel showing document outline
class PdfSidebarPanel extends StatelessWidget {
  final PdfTab tab;
  final ValueChanged<int> onPageSelected;

  const PdfSidebarPanel({
    super.key,
    required this.tab,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
              Icon(Icons.list, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Outline',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(child: _buildOutlinePanel(context)),
      ],
    );
  }

  Widget _buildOutlinePanel(BuildContext context) {
    final bookmarks = tab.bookmarks;
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
        return _buildBookmarkItem(context, bookmarks[index], 0);
      },
    );
  }

  Widget _buildBookmarkItem(BuildContext context, dynamic bookmark, int level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            // Use Syncfusion's jumpToBookmark method
            try {
              tab.controller.jumpToBookmark(bookmark);
            } catch (e) {
              debugPrint('Error navigating to bookmark: $e');
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
            (i) => _buildBookmarkItem(context, bookmark[i], level + 1),
          ),
      ],
    );
  }
}
