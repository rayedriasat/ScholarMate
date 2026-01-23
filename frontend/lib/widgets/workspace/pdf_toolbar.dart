import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'pdf_tab_manager.dart';
import '../../theme/app_colors.dart';

/// Toolbar for PDF viewer controls
class PdfToolbar extends StatefulWidget {
  final PdfTab tab;
  final bool showOutlinePanel;
  final PdfAnnotationMode annotationMode;
  final Color annotationColor;
  final bool isSplitView;
  final VoidCallback onToggleOutline;
  final VoidCallback onToggleSplitView;
  final ValueChanged<PdfAnnotationMode> onAnnotationModeChanged;
  final ValueChanged<Color> onAnnotationColorChanged;

  const PdfToolbar({
    super.key,
    required this.tab,
    required this.showOutlinePanel,
    required this.annotationMode,
    required this.annotationColor,
    required this.isSplitView,
    required this.onToggleOutline,
    required this.onToggleSplitView,
    required this.onAnnotationModeChanged,
    required this.onAnnotationColorChanged,
  });

  @override
  State<PdfToolbar> createState() => _PdfToolbarState();
}

class _PdfToolbarState extends State<PdfToolbar> {
  final TextEditingController _pageController = TextEditingController();
  bool _isEditingPage = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _jumpToPage() {
    final pageNumber = int.tryParse(_pageController.text);
    if (pageNumber != null &&
        pageNumber > 0 &&
        pageNumber <= widget.tab.totalPages) {
      widget.tab.controller.jumpToPage(pageNumber);
      setState(() {
        _isEditingPage = false;
      });
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enter a valid page number (1-${widget.tab.totalPages})',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Sidebar toggle button (compact)
          IconButton(
            icon: Icon(
              Icons.menu,
              size: 20,
              color: widget.showOutlinePanel ? AppColors.primary : Colors.white,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: widget.onToggleOutline,
            tooltip: 'Outline',
          ),
          Container(
            height: 24,
            width: 1,
            color: Colors.white.withValues(alpha: 0.1),
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          // Navigation (compact)
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20, color: Colors.white),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: widget.tab.currentPage > 1
                ? () => widget.tab.controller.previousPage()
                : null,
            tooltip: 'Previous',
          ),
          // Editable page number field
          InkWell(
            onTap: () {
              setState(() {
                _isEditingPage = true;
                _pageController.text = widget.tab.currentPage.toString();
              });
              Future.delayed(const Duration(milliseconds: 100), () {
                _pageController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _pageController.text.length,
                );
              });
            },
            child: Container(
              constraints: const BoxConstraints(minWidth: 60, maxWidth: 80),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: _isEditingPage
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _isEditingPage
                      ? AppColors.primary
                      : Colors.transparent,
                ),
              ),
              child: _isEditingPage
                  ? TextField(
                      controller: _pageController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _jumpToPage(),
                      onTapOutside: (_) {
                        setState(() {
                          _isEditingPage = false;
                        });
                      },
                    )
                  : Text(
                      '${widget.tab.currentPage}/${widget.tab.totalPages}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: widget.tab.currentPage < widget.tab.totalPages
                ? () => widget.tab.controller.nextPage()
                : null,
            tooltip: 'Next',
          ),
          Container(
            height: 24,
            width: 1,
            color: Colors.white.withValues(alpha: 0.1),
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          // Zoom controls (compact)
          IconButton(
            icon: const Icon(Icons.remove, size: 18, color: Colors.white),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              widget.tab.controller.zoomLevel =
                  (widget.tab.controller.zoomLevel - 0.25).clamp(0.5, 3.0);
            },
            tooltip: 'Zoom Out',
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            child: Text(
              '${(widget.tab.zoomLevel * 100).toInt()}%',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              widget.tab.controller.zoomLevel =
                  (widget.tab.controller.zoomLevel + 0.25).clamp(0.5, 3.0);
            },
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen, size: 18, color: Colors.white),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              widget.tab.controller.zoomLevel = 1.0;
            },
            tooltip: 'Fit',
          ),
          Container(
            height: 24,
            width: 1,
            color: Colors.white.withValues(alpha: 0.1),
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          // Split view toggle (compact)
          IconButton(
            icon: Icon(
              Icons.view_column,
              size: 20,
              color: widget.isSplitView ? AppColors.primary : Colors.white,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: widget.onToggleSplitView,
            tooltip: 'Split',
          ),
          Container(
            height: 24,
            width: 1,
            color: Colors.white.withValues(alpha: 0.1),
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          // Annotation tools (compact)
          PopupMenuButton<PdfAnnotationMode>(
            icon: Icon(
              Icons.edit,
              size: 20,
              color: widget.annotationMode != PdfAnnotationMode.none
                  ? AppColors.primary
                  : Colors.white,
            ),
            padding: const EdgeInsets.all(8),
            tooltip: 'Annotate',
            color: AppColors.surface,
            onSelected: widget.onAnnotationModeChanged,
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
          // Color picker (compact)
          if (widget.annotationMode != PdfAnnotationMode.none)
            PopupMenuButton<Color>(
              icon: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: widget.annotationColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              padding: const EdgeInsets.all(8),
              tooltip: 'Color',
              color: AppColors.surface,
              onSelected: widget.onAnnotationColorChanged,
              itemBuilder: (context) => _buildColorMenuItems(),
            ),
          const Spacer(),
          // Search (compact)
          IconButton(
            icon: const Icon(Icons.search, size: 20, color: Colors.white),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.annotationColor == color
                  ? Colors.white
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
      );
    }).toList();
  }
}
