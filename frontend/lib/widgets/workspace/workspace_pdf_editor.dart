import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'document_tab_manager.dart';
import 'pdf_sidebar_panel.dart';
import 'pdf_toolbar.dart';
import 'workspace_split_view.dart';
import '../../theme/app_colors.dart';

// Type alias for backward compatibility
typedef PdfTab = DocumentTab;
typedef PdfTabManager = DocumentTabManager;

/// Main PDF editor area with optional sidebar
class WorkspacePdfEditor extends StatefulWidget {
  final DocumentTabManager tabManager;

  const WorkspacePdfEditor({super.key, required this.tabManager});

  @override
  State<WorkspacePdfEditor> createState() => _WorkspacePdfEditorState();
}

class _WorkspacePdfEditorState extends State<WorkspacePdfEditor> {
  bool _showSidebar = false;
  double _sidebarWidth = 250;
  PdfAnnotationMode _annotationMode = PdfAnnotationMode.none;
  Color _annotationColor = const Color(0xFFFFEB3B);
  bool _isSplitView = false;
  DocumentTab? _rightSplitTab;

  void _toggleSidebar() {
    setState(() {
      _showSidebar = !_showSidebar;
    });
  }

  void _toggleSplitView() {
    setState(() {
      _isSplitView = !_isSplitView;
      if (!_isSplitView) {
        _rightSplitTab = null;
      }
    });
  }

  Future<void> _selectRightPdf() async {
    final tabs = widget.tabManager.tabs;
    final activeTab = widget.tabManager.activeTab;

    if (tabs.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Open another PDF to use split view'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final selectedTab = await showDialog<DocumentTab>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Select PDF for Right Pane',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tabs.length,
            itemBuilder: (context, index) {
              final tab = tabs[index];
              if (tab == activeTab) return const SizedBox.shrink();

              return ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(
                  tab.file.name,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, tab),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedTab != null) {
      setState(() {
        _rightSplitTab = selectedTab;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.tabManager,
      builder: (context, _) {
        final activeTab = widget.tabManager.activeTab;

        if (activeTab == null) {
          return _buildEmptyState();
        }

        if (_isSplitView) {
          return WorkspaceSplitView(
            leftTab: activeTab,
            rightTab: _rightSplitTab,
            onCloseSplit: _toggleSplitView,
            onSelectRightPdf: _selectRightPdf,
          );
        }

        return Row(
          children: [
            // Optional sidebar (toggleable)
            if (_showSidebar) ...[
              Container(
                width: _sidebarWidth,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    right: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                  child: PdfSidebarPanel(
                    tab: activeTab,
                    onPageSelected: (page) {
                      activeTab.controller?.jumpToPage(page);
                    },
                  ),
              ),
            ],
            // Main PDF viewer
            Expanded(
              child: Column(
                children: [
                  // Toolbar
                  PdfToolbar(
                    tab: activeTab,
                    showOutlinePanel: _showSidebar,
                    annotationMode: _annotationMode,
                    annotationColor: _annotationColor,
                    isSplitView: _isSplitView,
                    onToggleOutline: _toggleSidebar,
                    onToggleSplitView: _toggleSplitView,
                    onAnnotationModeChanged: (mode) {
                      setState(() {
                        _annotationMode = mode;
                        activeTab.controller?.annotationMode = mode;
                      });
                    },
                    onAnnotationColorChanged: (color) {
                      setState(() {
                        _annotationColor = color;
                        final settings =
                            activeTab.controller?.annotationSettings;
                        if (settings != null) {
                          settings.highlight.color = color;
                          settings.underline.color = color;
                          settings.strikethrough.color = color;
                          settings.squiggly.color = color;
                        }
                      });
                    },
                  ),
                  // PDF viewer
                  Expanded(child: _buildPdfViewer(activeTab)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No PDF open',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Open a file from the explorer',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfViewer(DocumentTab tab) {
    // Show loading state
    if (tab.isLoading || tab.pdfBytes == null) {
      return Container(
        color: const Color(0xFF2A2A2A),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Loading ${tab.file.name}...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF2A2A2A),
      child: SfPdfViewer.memory(
        tab.pdfBytes!,
        key: tab.viewerKey,
        controller: tab.controller,
        onDocumentLoaded: (details) {
          setState(() {
            tab.totalPages = details.document.pages.count;
            tab.bookmarks = details.document.bookmarks;
          });

          if (tab.initialPage != null && tab.initialPage! > 0) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                tab.controller?.jumpToPage(tab.initialPage!);
              }
            });
          }

          if (tab.highlightText != null && tab.highlightText!.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                tab.controller?.searchText(tab.highlightText!);
              }
            });
          }
        },
        onPageChanged: (details) {
          setState(() {
            tab.currentPage = details.newPageNumber;
          });
        },
        onZoomLevelChanged: (details) {
          setState(() {
            tab.zoomLevel = details.newZoomLevel;
          });
        },
      ),
    );
  }
}
