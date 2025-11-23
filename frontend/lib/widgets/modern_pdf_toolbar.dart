import 'package:flutter/material.dart';
import '../widgets/glass/glass_card.dart';
import '../theme/design_tokens.dart';

/// Modern floating glass toolbar for PDF viewer
/// Features auto-hide on scroll, zoom controls, and smooth animations
class ModernPdfToolbar extends StatefulWidget {
  final String fileName;
  final int currentPage;
  final int totalPages;
  final double zoomLevel;
  final VoidCallback onBack;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onSearch;
  final VoidCallback onAnnotations;
  final VoidCallback onFullscreen;
  final bool isSearching;
  final bool isFullscreen;

  const ModernPdfToolbar({
    super.key,
    required this.fileName,
    required this.currentPage,
    required this.totalPages,
    required this.zoomLevel,
    required this.onBack,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onSearch,
    required this.onAnnotations,
    required this.onFullscreen,
    this.isSearching = false,
    this.isFullscreen = false,
  });

  @override
  State<ModernPdfToolbar> createState() => _ModernPdfToolbarState();
}

class _ModernPdfToolbarState extends State<ModernPdfToolbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: DesignTokens.routeDuration,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void show() {
    if (!_isVisible) {
      setState(() => _isVisible = true);
      _animationController.forward();
    }
  }

  void hide() {
    if (_isVisible) {
      setState(() => _isVisible = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(DesignTokens.space4),
          child: AppGlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space4,
              vertical: DesignTokens.space3,
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                  tooltip: 'Back',
                ),

                const SizedBox(width: DesignTokens.space2),

                // File name and page info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.fileName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.totalPages > 0)
                        Text(
                          'Page ${widget.currentPage} of ${widget.totalPages}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: DesignTokens.space2),

                // Zoom out
                IconButton(
                  icon: const Icon(Icons.zoom_out, size: 20),
                  onPressed: widget.onZoomOut,
                  tooltip: 'Zoom out',
                ),

                // Zoom level indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space2,
                    vertical: DesignTokens.space1,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusSmall,
                    ),
                  ),
                  child: Text(
                    '${(widget.zoomLevel * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),

                // Zoom in
                IconButton(
                  icon: const Icon(Icons.zoom_in, size: 20),
                  onPressed: widget.onZoomIn,
                  tooltip: 'Zoom in',
                ),

                const SizedBox(width: DesignTokens.space2),

                // Search
                IconButton(
                  icon: Icon(
                    widget.isSearching ? Icons.close : Icons.search,
                    size: 20,
                  ),
                  onPressed: widget.onSearch,
                  tooltip: 'Search',
                ),

                // Annotations
                IconButton(
                  icon: const Icon(Icons.edit_note, size: 20),
                  onPressed: widget.onAnnotations,
                  tooltip: 'Annotations',
                ),

                // Fullscreen
                IconButton(
                  icon: Icon(
                    widget.isFullscreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                    size: 20,
                  ),
                  onPressed: widget.onFullscreen,
                  tooltip: widget.isFullscreen
                      ? 'Exit fullscreen'
                      : 'Fullscreen',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
