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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isEditingPage = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
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

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final searchResult = widget.tab.controller.searchText(query);
    setState(() {
      widget.tab.searchResult = searchResult;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    widget.tab.controller.clearSelection();
    setState(() {
      widget.tab.searchResult = null;
      _isSearching = false;
    });
  }

  void _nextSearchResult() {
    widget.tab.searchResult?.nextInstance();
  }

  void _previousSearchResult() {
    widget.tab.searchResult?.previousInstance();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main toolbar
        Container(
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
                  color: widget.showOutlinePanel
                      ? AppColors.primary
                      : Colors.white,
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
                icon: const Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: Colors.white,
                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
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
              if (!isSmallScreen) ...[
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
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () {
                    widget.tab.controller.zoomLevel =
                        (widget.tab.controller.zoomLevel - 0.25).clamp(
                          0.5,
                          3.0,
                        );
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
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () {
                    widget.tab.controller.zoomLevel =
                        (widget.tab.controller.zoomLevel + 0.25).clamp(
                          0.5,
                          3.0,
                        );
                  },
                  tooltip: 'Zoom In',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.fit_screen,
                    size: 18,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () {
                    widget.tab.controller.zoomLevel = 1.0;
                  },
                  tooltip: 'Fit',
                ),
              ],
              Container(
                height: 24,
                width: 1,
                color: Colors.white.withValues(alpha: 0.1),
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              // Split view toggle (compact)
              if (!isSmallScreen)
                IconButton(
                  icon: Icon(
                    Icons.view_column,
                    size: 20,
                    color: widget.isSplitView
                        ? AppColors.primary
                        : Colors.white,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: widget.onToggleSplitView,
                  tooltip: 'Split',
                ),
              if (!isSmallScreen)
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
                icon: Icon(
                  Icons.search,
                  size: 20,
                  color: _isSearching ? AppColors.primary : Colors.white,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _clearSearch();
                    } else {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _searchFocusNode.requestFocus();
                      });
                    }
                  });
                },
                tooltip: 'Search',
              ),
            ],
          ),
        ),
        // Search bar (expandable)
        if (_isSearching)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.95),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search in PDF...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                size: 18,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _clearSearch();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _performSearch(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                // Search button
                IconButton(
                  icon: const Icon(Icons.search, size: 20, color: Colors.white),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: _performSearch,
                  tooltip: 'Search',
                ),
                // Previous result
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_up,
                    size: 20,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: widget.tab.searchResult != null
                      ? _previousSearchResult
                      : null,
                  tooltip: 'Previous',
                ),
                // Next result
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: widget.tab.searchResult != null
                      ? _nextSearchResult
                      : null,
                  tooltip: 'Next',
                ),
                // Result count
                if (widget.tab.searchResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ListenableBuilder(
                      listenable: widget.tab.searchResult!,
                      builder: (context, _) {
                        final result = widget.tab.searchResult!;
                        final currentIndex = result.currentInstanceIndex;
                        final totalCount = result.totalInstanceCount;

                        // Handle case where search is complete but no results
                        if (totalCount == 0) {
                          return const Text(
                            '0/0',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          );
                        }

                        // currentInstanceIndex is 1-based
                        final displayIndex = totalCount > 0 ? currentIndex : 0;

                        return Text(
                          '$displayIndex/$totalCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
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
