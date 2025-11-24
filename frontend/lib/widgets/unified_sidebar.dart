import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/drive_file.dart';
import '../services/metadata_service.dart';
import '../services/tts_service.dart';
import 'annotation_list_panel.dart';
import 'file_metadata_sidebar.dart';
import 'tts_controls.dart';

/// Unified sidebar with tabs for all PDF features
class UnifiedSidebar extends StatefulWidget {
  final List<Annotation> annotations;
  final Function(Annotation) onAnnotationTap;
  final Function(Annotation) onAnnotationDelete;
  final DriveFile file;
  final MetadataService metadataService;
  final TtsService? ttsService;
  final String currentPageText;
  final VoidCallback onSpeakCurrentPage;
  final VoidCallback onTtsNextPage;
  final VoidCallback onTtsPreviousPage;
  final VoidCallback? onClose;

  const UnifiedSidebar({
    super.key,
    required this.annotations,
    required this.onAnnotationTap,
    required this.onAnnotationDelete,
    required this.file,
    required this.metadataService,
    this.ttsService,
    required this.currentPageText,
    required this.onSpeakCurrentPage,
    required this.onTtsNextPage,
    required this.onTtsPreviousPage,
    this.onClose,
  });

  @override
  State<UnifiedSidebar> createState() => _UnifiedSidebarState();
}

class _UnifiedSidebarState extends State<UnifiedSidebar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E).withValues(alpha: 0.95)
            : const Color(0xFFF5F5F5).withValues(alpha: 0.95),
        border: Border(
          left: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.dashboard_outlined,
                  color: Theme.of(context).iconTheme.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'PDF Tools',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (widget.onClose != null)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: widget.onClose,
                    tooltip: 'Close',
                    iconSize: 20,
                  ),
              ],
            ),
          ),

          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).primaryColor,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
              tabs: [
                Tab(
                  icon: const Icon(Icons.bookmark, size: 18),
                  text: 'Annotations',
                  height: 60,
                ),
                Tab(
                  icon: const Icon(Icons.info_outline, size: 18),
                  text: 'Metadata',
                  height: 60,
                ),
                Tab(
                  icon: const Icon(Icons.volume_up, size: 18),
                  text: 'Read Aloud',
                  height: 60,
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Annotations tab
                AnnotationListPanel(
                  annotations: widget.annotations,
                  onAnnotationTap: widget.onAnnotationTap,
                  onAnnotationDelete: widget.onAnnotationDelete,
                ),

                // Metadata tab
                FileMetadataSidebar(
                  file: widget.file,
                  metadataService: widget.metadataService,
                  onClose: null, // Don't show close button in tab
                ),

                // TTS tab
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Text-to-Speech',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Listen to the current page being read aloud.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (widget.ttsService != null)
                        TtsControls(
                          onPlay: widget.onSpeakCurrentPage,
                          onNextPage: widget.onTtsNextPage,
                          onPreviousPage: widget.onTtsPreviousPage,
                          canGoNext: true,
                          canGoPrevious: true,
                        )
                      else
                        Center(
                          child: Text(
                            'TTS service not available',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
