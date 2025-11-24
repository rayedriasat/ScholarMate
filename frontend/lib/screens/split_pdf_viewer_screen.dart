import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/drive_file.dart';
import '../services/pdf_viewer_manager.dart';
import '../widgets/connectivity_indicator.dart';
import '../widgets/pdf_file_picker_dialog.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../theme/app_colors.dart';

/// Split-screen PDF viewer for comparing two PDFs side-by-side (Web only)
class SplitPdfViewerScreen extends StatefulWidget {
  final DriveFile? leftFile;
  final String? leftFileId;
  final String? leftFileName;

  const SplitPdfViewerScreen({
    super.key,
    this.leftFile,
    this.leftFileId,
    this.leftFileName,
  }) : assert(
         leftFile != null || (leftFileId != null && leftFileName != null),
         'Either leftFile or both leftFileId and leftFileName must be provided',
       );

  @override
  State<SplitPdfViewerScreen> createState() => _SplitPdfViewerScreenState();
}

class _SplitPdfViewerScreenState extends State<SplitPdfViewerScreen> {
  // Left pane controllers
  final PdfViewerController _leftController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _leftViewerKey = GlobalKey();
  int _leftCurrentPage = 1;
  int _leftTotalPages = 0;
  Uint8List? _leftPdfBytes;
  bool _leftLoading = false;
  String? _leftError;

  // Right pane controllers
  final PdfViewerController _rightController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _rightViewerKey = GlobalKey();
  int _rightCurrentPage = 1;
  int _rightTotalPages = 0;
  Uint8List? _rightPdfBytes;
  bool _rightLoading = false;
  String? _rightError;
  String? _rightFileName;

  // Layout state
  double _dividerPosition = 0.5; // 50% split
  bool _isDraggingDivider = false;
  bool _syncScroll = false;
  bool _syncZoom = false;
  bool _syncPageNavigation = false;

  @override
  void initState() {
    super.initState();
    _loadLeftPdf();
    _loadLayoutPreferences();
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    _saveLayoutPreferences();
    super.dispose();
  }

  Future<void> _loadLayoutPreferences() async {
    // TODO: Load from shared preferences
    // For now, use defaults
  }

  Future<void> _saveLayoutPreferences() async {
    // TODO: Save to shared preferences
  }

  Future<void> _loadLeftPdf() async {
    setState(() {
      _leftLoading = true;
      _leftError = null;
    });

    try {
      final pdfManager = context.read<PdfViewerManager>();

      if (widget.leftFile != null) {
        await pdfManager.loadPdf(widget.leftFile!);
      } else if (widget.leftFileId != null) {
        final driveFile = DriveFile(
          id: widget.leftFileId!,
          name: widget.leftFileName!,
          mimeType: 'application/pdf',
        );
        await pdfManager.loadPdf(driveFile);
      }

      if (pdfManager.currentPdfBytes != null) {
        setState(() {
          _leftPdfBytes = pdfManager.currentPdfBytes;
          _leftLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _leftError = e.toString();
        _leftLoading = false;
      });
    }
  }

  Future<void> _loadRightPdfFromDrive() async {
    try {
      // Show file picker dialog
      final selectedFile = await showDialog<DriveFile>(
        context: context,
        builder: (context) => const PdfFilePickerDialog(),
      );

      if (selectedFile != null) {
        setState(() {
          _rightLoading = true;
          _rightError = null;
        });

        // Load the PDF using PdfViewerManager
        final pdfManager = context.read<PdfViewerManager>();
        await pdfManager.loadPdf(selectedFile);

        if (pdfManager.currentPdfBytes != null) {
          setState(() {
            _rightPdfBytes = pdfManager.currentPdfBytes;
            _rightFileName = selectedFile.name;
            _rightCurrentPage = 1;
            _rightTotalPages = 0;
            _rightLoading = false;
          });
        } else {
          setState(() {
            _rightError = 'Failed to load PDF';
            _rightLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _rightError = 'Failed to load PDF: $e';
        _rightLoading = false;
      });
    }
  }

  void _closeRightPane() {
    setState(() {
      _rightPdfBytes = null;
      _rightFileName = null;
      _rightCurrentPage = 1;
      _rightTotalPages = 0;
      _rightError = null;
    });
  }

  void _toggleSyncScroll() {
    setState(() {
      _syncScroll = !_syncScroll;
    });
  }

  void _toggleSyncZoom() {
    setState(() {
      _syncZoom = !_syncZoom;
    });
  }

  void _toggleSyncPageNavigation() {
    setState(() {
      _syncPageNavigation = !_syncPageNavigation;
    });
  }

  void _onLeftPageChanged(int newPage) {
    setState(() {
      _leftCurrentPage = newPage;
    });

    if (_syncPageNavigation && _rightPdfBytes != null) {
      // Sync page navigation to right pane
      if (newPage <= _rightTotalPages) {
        _rightController.jumpToPage(newPage);
      }
    }
  }

  void _onRightPageChanged(int newPage) {
    setState(() {
      _rightCurrentPage = newPage;
    });

    if (_syncPageNavigation && _leftPdfBytes != null) {
      // Sync page navigation to left pane
      if (newPage <= _leftTotalPages) {
        _leftController.jumpToPage(newPage);
      }
    }
  }

  void _onLeftZoomChanged(double newZoom) {
    if (_syncZoom && _rightPdfBytes != null) {
      _rightController.zoomLevel = newZoom;
    }
  }

  void _onRightZoomChanged(double newZoom) {
    if (_syncZoom && _leftPdfBytes != null) {
      _leftController.zoomLevel = newZoom;
    }
  }

  Widget _buildPdfPane({
    required String title,
    required PdfViewerController controller,
    required GlobalKey<SfPdfViewerState> viewerKey,
    required Uint8List? pdfBytes,
    required bool isLoading,
    required String? error,
    required int currentPage,
    required int totalPages,
    required Function(int) onPageChanged,
    required Function(double) onZoomChanged,
    bool isLeftPane = true,
  }) {
    return Column(
      children: [
        // Pane header
        GlassContainer(
          borderRadius: BorderRadius.zero,
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (totalPages > 0)
                Text(
                  'Page $currentPage of $totalPages',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
        // PDF viewer or placeholder
        Expanded(
          child: _buildPaneContent(
            controller: controller,
            viewerKey: viewerKey,
            pdfBytes: pdfBytes,
            isLoading: isLoading,
            error: error,
            onPageChanged: onPageChanged,
            onZoomChanged: onZoomChanged,
            onLoadPdf: isLeftPane ? null : _loadRightPdfFromDrive,
            isLeftPane: isLeftPane,
          ),
        ),
        // Pane controls
        if (pdfBytes != null)
          GlassContainer(
            borderRadius: BorderRadius.zero,
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    size: 20,
                    color: currentPage > 1 ? Colors.white : Colors.white24,
                  ),
                  onPressed: currentPage > 1
                      ? () => controller.previousPage()
                      : null,
                  tooltip: 'Previous page',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.zoom_out,
                    size: 20,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    final newZoom = (controller.zoomLevel - 0.25).clamp(
                      0.5,
                      3.0,
                    );
                    controller.zoomLevel = newZoom;
                    onZoomChanged(newZoom);
                  },
                  tooltip: 'Zoom out',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.fit_screen,
                    size: 20,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    controller.zoomLevel = 1.0;
                    onZoomChanged(1.0);
                  },
                  tooltip: 'Fit to width',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.zoom_in,
                    size: 20,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    final newZoom = (controller.zoomLevel + 0.25).clamp(
                      0.5,
                      3.0,
                    );
                    controller.zoomLevel = newZoom;
                    onZoomChanged(newZoom);
                  },
                  tooltip: 'Zoom in',
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: currentPage < totalPages
                        ? Colors.white
                        : Colors.white24,
                  ),
                  onPressed: currentPage < totalPages
                      ? () => controller.nextPage()
                      : null,
                  tooltip: 'Next page',
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaneContent({
    required PdfViewerController controller,
    required GlobalKey<SfPdfViewerState> viewerKey,
    required Uint8List? pdfBytes,
    required bool isLoading,
    required String? error,
    required Function(int) onPageChanged,
    required Function(double) onZoomChanged,
    required VoidCallback? onLoadPdf,
    required bool isLeftPane,
  }) {
    if (isLoading) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Loading PDF...',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load PDF',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (pdfBytes == null) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf,
                size: 64,
                color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 16),
              Text(
                isLeftPane ? 'No PDF loaded' : 'No second PDF loaded',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                ),
              ),
              if (onLoadPdf != null) ...[
                const SizedBox(height: 24),
                ModernButton(
                  onPressed: onLoadPdf,
                  icon: Icons.cloud,
                  label: 'Select PDF from Drive',
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF2A2A2A), // Soft dark grey background
      child: SfPdfViewer.memory(
        pdfBytes,
        key: viewerKey,
        controller: controller,
        onDocumentLoaded: (details) {
          setState(() {
            if (isLeftPane) {
              _leftTotalPages = details.document.pages.count;
            } else {
              _rightTotalPages = details.document.pages.count;
            }
          });
        },
        onPageChanged: (details) {
          onPageChanged(details.newPageNumber);
        },
        onZoomLevelChanged: (details) {
          onZoomChanged(details.newZoomLevel);
        },
      ),
    );
  }

  Widget _buildDivider() {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragStart: (_) {
          setState(() {
            _isDraggingDivider = true;
          });
        },
        onHorizontalDragUpdate: (details) {
          setState(() {
            final screenWidth = MediaQuery.of(context).size.width;
            final newPosition =
                _dividerPosition + (details.delta.dx / screenWidth);
            _dividerPosition = newPosition.clamp(0.2, 0.8);
          });
        },
        onHorizontalDragEnd: (_) {
          setState(() {
            _isDraggingDivider = false;
          });
        },
        child: Container(
          width: 8,
          decoration: BoxDecoration(
            gradient: _isDraggingDivider
                ? LinearGradient(
                    colors: [
                      Colors.blue.withValues(alpha: 0.6),
                      Colors.purple.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : (_rightPdfBytes != null
                    ? LinearGradient(
                        colors: [
                          Colors.blue.withValues(alpha: 0.4),
                          Colors.purple.withValues(alpha: 0.4),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null),
            color: _rightPdfBytes == null
                ? Theme.of(context).scaffoldBackgroundColor
                : null,
          ),
          child: Center(
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: _rightPdfBytes != null
                    ? const LinearGradient(
                        colors: [
                          Colors.blue,
                          Colors.purple,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: _rightPdfBytes == null
                    ? Colors.white.withValues(alpha: 0.3)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only allow on web
    if (!kIsWeb) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Split View'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.web, size: 64, color: Colors.white24),
                SizedBox(height: 16),
                Text(
                  'Split-screen PDF viewer is only available on web',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Split PDF Viewer',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Connectivity indicator
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ConnectivityIndicator(),
          ),
          // Sync controls
          PopupMenuButton<String>(
            icon: const Icon(Icons.sync, color: Colors.white),
            color: AppColors.surface,
            tooltip: 'Sync Options',
            onSelected: (value) {
              switch (value) {
                case 'scroll':
                  _toggleSyncScroll();
                  break;
                case 'zoom':
                  _toggleSyncZoom();
                  break;
                case 'page':
                  _toggleSyncPageNavigation();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'scroll',
                child: Row(
                  children: [
                    Icon(
                      _syncScroll
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Sync Scroll',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'zoom',
                child: Row(
                  children: [
                    Icon(
                      _syncZoom
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Sync Zoom',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'page',
                child: Row(
                  children: [
                    Icon(
                      _syncPageNavigation
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Sync Page Navigation',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Close right pane
          if (_rightPdfBytes != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _closeRightPane,
              tooltip: 'Close right pane',
            ),
        ],
      ),
      body: Row(
        children: [
          // Left pane
          Expanded(
            flex: (_dividerPosition * 1000).round(),
            child: _buildPdfPane(
              title: widget.leftFileName ?? widget.leftFile?.name ?? 'Left PDF',
              controller: _leftController,
              viewerKey: _leftViewerKey,
              pdfBytes: _leftPdfBytes,
              isLoading: _leftLoading,
              error: _leftError,
              currentPage: _leftCurrentPage,
              totalPages: _leftTotalPages,
              onPageChanged: _onLeftPageChanged,
              onZoomChanged: _onLeftZoomChanged,
              isLeftPane: true,
            ),
          ),
          // Divider
          _buildDivider(),
          // Right pane
          Expanded(
            flex: ((1 - _dividerPosition) * 1000).round(),
            child: _buildPdfPane(
              title: _rightFileName ?? 'Right PDF',
              controller: _rightController,
              viewerKey: _rightViewerKey,
              pdfBytes: _rightPdfBytes,
              isLoading: _rightLoading,
              error: _rightError,
              currentPage: _rightCurrentPage,
              totalPages: _rightTotalPages,
              onPageChanged: _onRightPageChanged,
              onZoomChanged: _onRightZoomChanged,
              isLeftPane: false,
            ),
          ),
        ],
      ),
    );
  }
}
