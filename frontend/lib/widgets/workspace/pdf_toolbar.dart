import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'pdf_tab_manager.dart';
import '../../theme/app_colors.dart';

/// Toolbar for PDF viewer controls
class PdfToolbar extends StatelessWidget {
  final PdfTab tab;
  final bool showOutlinePanel;
  final bool showThumbnailPanel;
  final PdfAnnotationMode annotationMode;
  final Color annotationColor;
  final bool isSplitView;
  final VoidCallback onToggleOutline;
  final VoidCallback onToggleThumbnails;
  final VoidCallback onToggleSplitView;
  final ValueChanged<PdfAnnotationMode> onAnnotationModeChanged;
  final ValueChanged<Color> onAnnotationColorChanged;

  const PdfToolbar({
    super.key,
    required this.tab,
    required this.showOutlinePanel,
    required this.showThumbnailPanel,
    required this.annotationMode,
    required this.annotationColor,
    required this.isSplitView,
    required this.onToggleOutline,
    required this.onToggleThumbnails,
    required this.onToggleSplitView,
    required this.onAnnotationModeChanged,
    required this.onAnnotationColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Sidebar toggle button
          IconButton(
            icon: Icon(
              Icons.view_sidebar,
              color: showOutlinePanel ? AppColors.primary : Colors.white,
            ),
            onPressed: onToggleOutline,
            tooltip: 'Toggle Sidebar',
          ),
          const VerticalDivider(),
          // Navigation
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: tab.currentPage > 1
                ? () => tab.controller.previousPage()
                : null,
            tooltip: 'Previous Page',
          ),
          Text(
            '${tab.currentPage} / ${tab.totalPages}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: tab.currentPage < tab.totalPages
                ? () => tab.controller.nextPage()
                : null,
            tooltip: 'Next Page',
          ),
          const VerticalDivider(),
          // Zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.white),
            onPressed: () {
              tab.controller.zoomLevel = (tab.controller.zoomLevel - 0.25)
                  .clamp(0.5, 3.0);
            },
            tooltip: 'Zoom Out',
          ),
          Text(
            '${(tab.zoomLevel * 100).toInt()}%',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.white),
            onPressed: () {
              tab.controller.zoomLevel = (tab.controller.zoomLevel + 0.25)
                  .clamp(0.5, 3.0);
            },
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen, color: Colors.white),
            onPressed: () {
              tab.controller.zoomLevel = 1.0;
            },
            tooltip: 'Fit to Width',
          ),
          const VerticalDivider(),
          // Split view toggle
          IconButton(
            icon: Icon(
              Icons.view_column,
              color: isSplitView ? AppColors.primary : Colors.white,
            ),
            onPressed: onToggleSplitView,
            tooltip: 'Split View',
          ),
          const VerticalDivider(),
          // Annotation tools
          PopupMenuButton<PdfAnnotationMode>(
            icon: Icon(
              Icons.edit,
              color: annotationMode != PdfAnnotationMode.none
                  ? AppColors.primary
                  : Colors.white,
            ),
            tooltip: 'Annotations',
            color: AppColors.surface,
            onSelected: onAnnotationModeChanged,
            itemBuilder: (context) => [
              _buildAnnotationMenuItem(
                PdfAnnotationMode.none,
                Icons.close,
                'None',
              ),
              _buildAnnotationMenuItem(
                PdfAnnotationMode.highlight,
                Icons.highlight,
                'Highlight',
              ),
              _buildAnnotationMenuItem(
                PdfAnnotationMode.underline,
                Icons.format_underlined,
                'Underline',
              ),
              _buildAnnotationMenuItem(
                PdfAnnotationMode.strikethrough,
                Icons.format_strikethrough,
                'Strikethrough',
              ),
              _buildAnnotationMenuItem(
                PdfAnnotationMode.squiggly,
                Icons.waves,
                'Squiggly',
              ),
            ],
          ),
          // Color picker
          if (annotationMode != PdfAnnotationMode.none)
            PopupMenuButton<Color>(
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: annotationColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              tooltip: 'Annotation Color',
              color: AppColors.surface,
              onSelected: onAnnotationColorChanged,
              itemBuilder: (context) => _buildColorMenuItems(),
            ),
          const Spacer(),
          // Search
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implement search
            },
            tooltip: 'Search',
          ),
        ],
      ),
    );
  }

  PopupMenuItem<PdfAnnotationMode> _buildAnnotationMenuItem(
    PdfAnnotationMode mode,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  List<PopupMenuItem<Color>> _buildColorMenuItems() {
    final colors = [
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFFFF9800), // Orange
      const Color(0xFFF44336), // Red
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF2196F3), // Blue
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF009688), // Teal
      const Color(0xFF4CAF50), // Green
    ];

    return colors.map((color) {
      return PopupMenuItem(
        value: color,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: annotationColor == color
                  ? Colors.white
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
      );
    }).toList();
  }
}
