import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'document_tab_manager.dart';
import 'workspace_resize_handle.dart';
import '../../theme/app_colors.dart';

// Type alias for backward compatibility
typedef PdfTab = DocumentTab;

/// Split view for comparing two PDFs side by side
class WorkspaceSplitView extends StatefulWidget {
  final DocumentTab leftTab;
  final DocumentTab? rightTab;
  final VoidCallback onCloseSplit;
  final VoidCallback onSelectRightPdf;

  const WorkspaceSplitView({
    super.key,
    required this.leftTab,
    this.rightTab,
    required this.onCloseSplit,
    required this.onSelectRightPdf,
  });

  @override
  State<WorkspaceSplitView> createState() => _WorkspaceSplitViewState();
}

class _WorkspaceSplitViewState extends State<WorkspaceSplitView> {
  double _dividerPosition = 0.5;
  bool _syncPageNavigation = false;
  bool _syncZoom = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSplitToolbar(),
        Expanded(
          child: Row(
            children: [
              // Left pane
              Expanded(
                flex: (_dividerPosition * 1000).round(),
                child: _buildPdfPane(
                  tab: widget.leftTab,
                  title: 'Left: ${widget.leftTab.file.name}',
                  isLeft: true,
                ),
              ),
              // Divider
              WorkspaceResizeHandle(
                onDrag: (delta) {
                  setState(() {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final newPosition =
                        _dividerPosition + (delta / screenWidth);
                    _dividerPosition = newPosition.clamp(0.2, 0.8);
                  });
                },
                isVertical: true,
              ),
              // Right pane
              Expanded(
                flex: ((1 - _dividerPosition) * 1000).round(),
                child: widget.rightTab != null
                    ? _buildPdfPane(
                        tab: widget.rightTab!,
                        title: 'Right: ${widget.rightTab!.file.name}',
                        isLeft: false,
                      )
                    : _buildEmptyRightPane(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSplitToolbar() {
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
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: widget.onCloseSplit,
            tooltip: 'Exit Split View',
          ),
          const VerticalDivider(),
          const Text(
            'Split View',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Sync options
          IconButton(
            icon: Icon(
              _syncPageNavigation ? Icons.link : Icons.link_off,
              color: _syncPageNavigation ? AppColors.primary : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _syncPageNavigation = !_syncPageNavigation;
              });
            },
            tooltip: 'Sync Page Navigation',
          ),
          IconButton(
            icon: Icon(
              _syncZoom ? Icons.zoom_in : Icons.zoom_out_map,
              color: _syncZoom ? AppColors.primary : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _syncZoom = !_syncZoom;
              });
            },
            tooltip: 'Sync Zoom',
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPane({
    required PdfTab tab,
    required String title,
    required bool isLeft,
  }) {
    return Column(
      children: [
        // Pane header
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Page ${tab.currentPage} / ${tab.totalPages}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        // PDF viewer
        Expanded(
          child: tab.pdfBytes != null
              ? Container(
                  color: const Color(0xFF2A2A2A),
                  child: SfPdfViewer.memory(
                    tab.pdfBytes!,
                    key: tab.viewerKey,
                    controller: tab.controller,
                    onDocumentLoaded: (details) {
                      setState(() {
                        tab.totalPages = details.document.pages.count;
                      });
                    },
                    onPageChanged: (details) {
                      setState(() {
                        tab.currentPage = details.newPageNumber;
                      });

                      if (_syncPageNavigation && widget.rightTab != null) {
                        if (isLeft &&
                            details.newPageNumber <=
                                widget.rightTab!.totalPages) {
                          widget.rightTab!.controller?.jumpToPage(
                            details.newPageNumber,
                          );
                        } else if (!isLeft &&
                            details.newPageNumber <=
                                widget.leftTab.totalPages) {
                          widget.leftTab.controller?.jumpToPage(
                            details.newPageNumber,
                          );
                        }
                      }
                    },
                    onZoomLevelChanged: (details) {
                      setState(() {
                        tab.zoomLevel = details.newZoomLevel;
                      });

                      if (_syncZoom && widget.rightTab != null) {
                        if (isLeft) {
                          final rightController = widget.rightTab!.controller;
                          if (rightController != null) {
                            rightController.zoomLevel = details.newZoomLevel;
                          }
                        } else {
                          final leftController = widget.leftTab.controller;
                          if (leftController != null) {
                            leftController.zoomLevel = details.newZoomLevel;
                          }
                        }
                      }
                    },
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
        ),
        // Pane controls
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: tab.currentPage > 1 ? Colors.white : Colors.white24,
                ),
                onPressed: tab.currentPage > 1
                    ? () => tab.controller?.previousPage()
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out, size: 20, color: Colors.white),
                onPressed: () {
                  final controller = tab.controller;
                  if (controller != null) {
                    controller.zoomLevel = (controller.zoomLevel - 0.25)
                        .clamp(0.5, 3.0);
                  }
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.fit_screen,
                  size: 20,
                  color: Colors.white,
                ),
                onPressed: () {
                  final controller = tab.controller;
                  if (controller != null) {
                    controller.zoomLevel = 1.0;
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, size: 20, color: Colors.white),
                onPressed: () {
                  final controller = tab.controller;
                  if (controller != null) {
                    controller.zoomLevel = (controller.zoomLevel + 0.25)
                        .clamp(0.5, 3.0);
                  }
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: tab.currentPage < tab.totalPages
                      ? Colors.white
                      : Colors.white24,
                ),
                onPressed: tab.currentPage < tab.totalPages
                    ? () => tab.controller?.nextPage()
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyRightPane() {
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
              'No second PDF selected',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onSelectRightPdf,
              icon: const Icon(Icons.add),
              label: const Text('Select PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
