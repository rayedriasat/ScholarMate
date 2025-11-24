import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/drive_file.dart';
import '../services/pdf_viewer_manager.dart';
import '../services/auth_service.dart';
import '../services/drive_service.dart';
import '../services/connectivity_service.dart';
import '../services/tts_service.dart';
import '../services/metadata_service.dart';
import '../services/analytics_service.dart';
import '../database/database.dart' hide Annotation;
import '../widgets/annotation_toolbar.dart';
import '../widgets/annotation_list_panel.dart';
import '../widgets/tts_controls.dart';
import '../widgets/file_metadata_sidebar.dart';
import '../widgets/connectivity_indicator.dart';
import '../widgets/collapsible_sidebar.dart';
import '../theme/app_colors.dart';
import 'ai_chat_screen.dart';
import 'split_pdf_viewer_screen.dart';

/// Full-screen PDF viewer with navigation controls and annotations
class PdfViewerScreen extends StatefulWidget {
  final DriveFile? file;
  final String? fileId;
  final String? fileName;
  final int? initialPage;
  final String? searchQuery;

  const PdfViewerScreen({
    super.key,
    this.file,
    this.fileId,
    this.fileName,
    this.initialPage,
    this.searchQuery,
  }) : assert(
         file != null || (fileId != null && fileName != null),
         'Either file or both fileId and fileName must be provided',
       );

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen>
    with WidgetsBindingObserver {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  int _currentPage = 1;
  int _totalPages = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Annotation state
  bool _showAnnotations = false;
  bool _showAnnotationToolbar = false;
  Color _selectedAnnotationColor = const Color(0xFFFFEB3B); // Yellow
  List<Annotation> _annotations = [];

  // TTS state
  bool _showTtsControls = false;
  String _currentPageText = '';
  TtsService? _ttsService;

  // Metadata sidebar state
  bool _showMetadataSidebar = false;

  // Toolbar expansion state
  bool _showExpandedToolbar = false;

  // Chat panel state
  bool _showChatPanel = false;
  double _chatPanelWidth = 400;
  bool _chatPanelFullscreen = false;
  static const double _minChatWidth = 300;
  static const double _maxChatWidthPercent = 0.7;

  // Zoom state
  double _zoomLevel = 1.0;

  // Analytics tracking
  AnalyticsService? _analyticsService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPdf();
    _initializeAnnotationSettings();
    _initializeAnalytics();

    // Navigate to initial page and/or trigger search
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // First, jump to the initial page if specified
      if (widget.initialPage != null && widget.initialPage! > 0) {
        // Wait a bit for PDF to load
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _pdfViewerController.jumpToPage(widget.initialPage!);
        }
      }

      // Show notification
      if (mounted &&
          (widget.initialPage != null || widget.searchQuery != null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  widget.searchQuery != null ? Icons.search : Icons.bookmark,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.searchQuery != null
                        ? 'Searching for "${widget.searchQuery}"${widget.initialPage != null ? " on page ${widget.initialPage}" : ""}'
                        : 'Navigated to page ${widget.initialPage} from citation',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Then trigger search if searchQuery is provided
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        // Wait for page jump to complete
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          setState(() {
            _isSearching = true;
            _searchController.text = widget.searchQuery!;
          });
          // Wait a bit more before searching
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            _performSearch();
          }
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get TTS service reference
    _ttsService = context.read<TtsService>();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Stop TTS when app goes to background or is paused
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _ttsService?.stop();
    }
  }

  void _initializeAnnotationSettings() {
    // Set default author for all annotations
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user != null) {
      _pdfViewerController.annotationSettings.author =
          user.displayName ?? user.email;
    }

    // Set default colors for each annotation type
    _pdfViewerController.annotationSettings.highlight.color =
        _selectedAnnotationColor;
    _pdfViewerController.annotationSettings.underline.color =
        _selectedAnnotationColor;
    _pdfViewerController.annotationSettings.strikethrough.color =
        _selectedAnnotationColor;
    _pdfViewerController.annotationSettings.squiggly.color =
        _selectedAnnotationColor;
    _pdfViewerController.annotationSettings.stickyNote.color =
        _selectedAnnotationColor;
  }

  Future<void> _initializeAnalytics() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) return;

    final database = context.read<AppDatabase>();
    _analyticsService = AnalyticsService(database, user.id);

    // Start reading session
    final fileId = widget.file?.id ?? widget.fileId!;
    final fileName = widget.file?.name ?? widget.fileName!;
    await _analyticsService?.startSession(
      fileId,
      fileName,
      _totalPages > 0 ? _totalPages : null,
    );
  }

  Future<void> _loadPdf({bool forceRefresh = false}) async {
    final pdfManager = context.read<PdfViewerManager>();

    // If file is provided directly, use it
    if (widget.file != null) {
      await pdfManager.loadPdf(widget.file!, forceRefresh: forceRefresh);
    } else if (widget.fileId != null) {
      // Otherwise, create a DriveFile from fileId and fileName
      final driveFile = DriveFile(
        id: widget.fileId!,
        name: widget.fileName!,
        mimeType: 'application/pdf',
      );
      await pdfManager.loadPdf(driveFile, forceRefresh: forceRefresh);
    }
  }

  Future<void> _refreshPdf() async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16),
            Text('Checking for updates...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    // Force refresh from Drive
    await _loadPdf(forceRefresh: true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF refreshed from Google Drive'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Stop TTS when closing PDF viewer (always stop, regardless of controls visibility)
    _ttsService?.stop();

    // End analytics session
    _analyticsService?.endSession();

    // Save to Drive when closing PDF if there are annotations and we have a file ID
    final fileId = widget.file?.id ?? widget.fileId;
    if (_annotations.isNotEmpty && fileId != null) {
      _savePdfWithAnnotations(uploadToDrive: true);
    }
    _pdfViewerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _jumpToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _pdfViewerController.jumpToPage(page);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _pdfViewerController.nextPage();
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pdfViewerController.previousPage();
    }
  }

  void _showPageNavigator() {
    showDialog(
      context: context,
      builder: (context) {
        int targetPage = _currentPage;
        return AlertDialog(
          title: const Text('Go to Page'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Page number (1-$_totalPages)',
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              targetPage = int.tryParse(value) ?? _currentPage;
            },
            onSubmitted: (value) {
              final page = int.tryParse(value);
              if (page != null) {
                Navigator.pop(context);
                _jumpToPage(page);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _jumpToPage(targetPage);
              },
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _pdfViewerController.clearSelection();
      }
    });
  }

  void _performSearch() {
    if (_searchController.text.isNotEmpty) {
      _pdfViewerController.searchText(_searchController.text);
    }
  }

  void _toggleAnnotationPanel() {
    // On mobile, show bottom sheet
    if (MediaQuery.of(context).size.width < 600) {
      _showMobileAnnotationPanel();
    } else {
      // On desktop, toggle side panel
      setState(() {
        _showAnnotations = !_showAnnotations;
      });
    }
  }

  void _showMobileAnnotationPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => AnnotationListPanel(
          annotations: _annotations,
          onAnnotationTap: (annotation) {
            Navigator.pop(context);
            _onAnnotationTap(annotation);
          },
          onAnnotationDelete: _onAnnotationDelete,
        ),
      ),
    );
  }

  void _toggleAnnotationToolbar() {
    setState(() {
      _showAnnotationToolbar = !_showAnnotationToolbar;
      if (!_showAnnotationToolbar) {
        _pdfViewerController.annotationMode = PdfAnnotationMode.none;
      }
    });
  }

  void _toggleMetadataSidebar() {
    // On mobile (width < 600), show metadata in a bottom sheet
    if (MediaQuery.of(context).size.width < 600) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Metadata content
                Expanded(
                  child: FileMetadataSidebar(
                    file:
                        widget.file ??
                        DriveFile(
                          id: widget.fileId ?? '',
                          name: widget.fileName ?? '',
                          mimeType: 'application/pdf',
                          modifiedTime: DateTime.now(),
                          size: 0,
                        ),
                    metadataService: context.read<MetadataService>(),
                    onClose: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // On desktop/tablet, toggle sidebar
      setState(() {
        _showMetadataSidebar = !_showMetadataSidebar;
      });
    }
  }

  void _onAnnotationModeChanged(PdfAnnotationMode mode) {
    setState(() {
      _pdfViewerController.annotationMode = mode;
    });
  }

  void _onAnnotationColorChanged(Color color) {
    setState(() {
      _selectedAnnotationColor = color;
      // Update annotation settings with new color for all types
      final settings = _pdfViewerController.annotationSettings;
      settings.highlight.color = color;
      settings.underline.color = color;
      settings.strikethrough.color = color;
      settings.squiggly.color = color;
      settings.stickyNote.color = color;
    });
  }

  Future<void> _savePdfWithAnnotations({bool uploadToDrive = false}) async {
    try {
      // Save the PDF document with annotations
      final List<int> bytes = await _pdfViewerController.saveDocument();

      // Convert to Uint8List
      final Uint8List pdfBytes = Uint8List.fromList(bytes);

      // Get file ID (from either file object or fileId parameter)
      final fileId = widget.file?.id ?? widget.fileId;
      final fileName = widget.file?.name ?? widget.fileName;

      if (fileId == null) {
        debugPrint('Cannot save PDF: file ID is null');
        return;
      }

      // Update the cached PDF with annotations
      final cacheService = context.read<PdfViewerManager>().cacheService;
      await cacheService.cachePdfBytes(fileId, pdfBytes);

      debugPrint('PDF with annotations saved to cache');

      // Upload to Google Drive only if explicitly requested
      if (uploadToDrive) {
        final driveService = context.read<DriveService>();
        final connectivityService = context.read<ConnectivityService>();

        if (connectivityService.isOnline) {
          try {
            await driveService.updateFile(
              fileId,
              pdfBytes,
              fileName ?? 'document.pdf',
            );
            debugPrint('PDF with annotations uploaded to Google Drive');
          } catch (e) {
            debugPrint('Error uploading to Drive: $e');
            // Don't fail the save if Drive upload fails
          }
        } else {
          debugPrint('Offline - PDF will sync to Drive when online');
        }
      }
    } catch (e) {
      debugPrint('Error saving PDF with annotations: $e');
    }
  }

  void _onAnnotationAdded(Annotation annotation) {
    setState(() {
      _annotations = _pdfViewerController.getAnnotations();
    });

    // Auto-save to local cache only (not Drive)
    _savePdfWithAnnotations();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Annotation added'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onAnnotationTap(Annotation annotation) {
    // Navigate to the page with the annotation
    _jumpToPage(annotation.pageNumber);
    // Select the annotation
    _pdfViewerController.selectAnnotation(annotation);

    // Close annotation panel on mobile
    if (MediaQuery.of(context).size.width < 600) {
      setState(() {
        _showAnnotations = false;
      });
    }
  }

  void _onAnnotationDelete(Annotation annotation) {
    _pdfViewerController.removeAnnotation(annotation);
    setState(() {
      _annotations = _pdfViewerController.getAnnotations();
    });

    // Auto-save PDF with annotations
    _savePdfWithAnnotations();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Annotation deleted'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAnnotationContextMenu(Annotation annotation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(_getAnnotationIcon(annotation), color: annotation.color),
                  const SizedBox(width: 8),
                  Text(
                    'Annotation Options',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),

            // Change Color
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Change Color'),
              onTap: () {
                Navigator.pop(context);
                _showColorPickerForAnnotation(annotation);
              },
            ),

            // Delete
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Annotation'),
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteAnnotation(annotation);
              },
            ),

            // Cancel
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAnnotationIcon(Annotation annotation) {
    if (annotation is HighlightAnnotation) return Icons.highlight;
    if (annotation is UnderlineAnnotation) return Icons.format_underlined;
    if (annotation is StrikethroughAnnotation) {
      return Icons.format_strikethrough;
    }
    if (annotation is SquigglyAnnotation) return Icons.waves;
    if (annotation is StickyNoteAnnotation) return Icons.note;
    return Icons.bookmark;
  }

  void _showColorPickerForAnnotation(Annotation annotation) {
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            return InkWell(
              onTap: () {
                Navigator.pop(context);
                _changeAnnotationColor(annotation, color);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: annotation.color.value == color.value
                        ? Colors.black
                        : Colors.grey[300]!,
                    width: annotation.color.value == color.value ? 3 : 1,
                  ),
                ),
                child: annotation.color.value == color.value
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _changeAnnotationColor(Annotation annotation, Color color) {
    // Remove the old annotation
    _pdfViewerController.removeAnnotation(annotation);

    // Create a new annotation with the same properties but different color

    // Auto-save after color change
    _savePdfWithAnnotations();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Annotation color changed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmDeleteAnnotation(Annotation annotation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Annotation'),
        content: const Text(
          'Are you sure you want to delete this annotation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _onAnnotationDelete(annotation);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // TTS Methods
  void _toggleTtsControls() {
    setState(() {
      _showTtsControls = !_showTtsControls;
      if (!_showTtsControls) {
        // Stop TTS when hiding controls
        _ttsService?.stop();
      }
    });
  }

  Future<void> _extractCurrentPageText() async {
    try {
      final pdfManager = context.read<PdfViewerManager>();
      if (pdfManager.currentPdfBytes == null) {
        setState(() {
          _currentPageText = '';
        });
        return;
      }

      // Load PDF document from bytes
      final PdfDocument document = PdfDocument(
        inputBytes: pdfManager.currentPdfBytes!,
      );

      // Extract text from current page (page index is 0-based)
      final String text = PdfTextExtractor(document).extractText(
        startPageIndex: _currentPage - 1,
        endPageIndex: _currentPage - 1,
      );

      // Clean up
      document.dispose();

      setState(() {
        _currentPageText = text.trim();
      });
    } catch (e) {
      debugPrint('Error extracting text: $e');
      setState(() {
        _currentPageText = '';
      });
    }
  }

  Future<void> _speakCurrentPage() async {
    await _extractCurrentPageText();

    if (_currentPageText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No text found on this page'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    await _ttsService?.speak(
      _currentPageText,
      onComplete: () {
        // Auto-advance to next page when current page completes
        if (_showTtsControls && _currentPage < _totalPages) {
          _onTtsNextPage();
        }
      },
    );
  }

  void _onTtsNextPage() {
    if (_currentPage < _totalPages) {
      _nextPage();
      // Wait for page to load, then speak
      Future.delayed(const Duration(milliseconds: 500), () {
        _speakCurrentPage();
      });
    } else {
      // Reached end of document
      _ttsService?.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reached end of document'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onTtsPreviousPage() {
    if (_currentPage > 1) {
      _previousPage();
      // Wait for page to load, then speak
      Future.delayed(const Duration(milliseconds: 500), () {
        _speakCurrentPage();
      });
    }
  }

  // Zoom Methods
  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel + 0.25).clamp(0.25, 3.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel - 0.25).clamp(0.25, 3.0);
    });
  }

  void _fitToPage() {
    setState(() {
      _zoomLevel = 1.0;
    });
  }

  void _openAiChatWithPdf() {
    // Get the current file
    final fileId = widget.file?.id ?? widget.fileId;
    final fileName = widget.file?.name ?? widget.fileName;

    if (fileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open chat: file information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check screen width
    final isWideScreen = MediaQuery.of(context).size.width >= 900;

    if (isWideScreen) {
      setState(() {
        _showChatPanel = !_showChatPanel;
        // Close other sidebars if opening chat
        if (_showChatPanel) {
          _showMetadataSidebar = false;
          _showAnnotations = false;
        }
      });
    } else {
      // Navigate to AI chat screen with the current PDF preselected
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIChatScreen(
            preselectedFileId: fileId,
            preselectedFileName: fileName,
          ),
        ),
      ).then((_) {
        // When returning from chat, we could optionally refresh or do something
      });
    }
  }

  void _openSplitView() {
    // Only available on web
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Split view is only available on web'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final fileId = widget.file?.id ?? widget.fileId;
    final fileName = widget.file?.name ?? widget.fileName;

    if (fileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot open split view: file information not available',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to split PDF viewer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SplitPdfViewerScreen(
          leftFile: widget.file,
          leftFileId: fileId,
          leftFileName: fileName,
        ),
      ),
    );
  }

  Widget _buildChatPanel(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * _maxChatWidthPercent;
    final effectiveWidth = _chatPanelFullscreen
        ? screenWidth
        : _chatPanelWidth.clamp(_minChatWidth, maxWidth);

    return Row(
      children: [
        // Resize handle
        if (!_chatPanelFullscreen)
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _chatPanelWidth = (_chatPanelWidth - details.delta.dx).clamp(
                    _minChatWidth,
                    maxWidth,
                  );
                });
              },
              child: Container(
                width: 8,
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    width: 2,
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        // Chat panel
        Container(
          width: effectiveWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surface
                : Colors.white,
            border: Border(
              left: BorderSide(color: Theme.of(context).dividerColor, width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Chat content
              Expanded(
                child: AIChatScreen(
                  preselectedFileId: widget.file?.id ?? widget.fileId,
                  preselectedFileName: widget.file?.name ?? widget.fileName,
                  isEmbedded: true,
                  onClose: () {
                    setState(() {
                      _showChatPanel = false;
                    });
                  },
                  onToggleFullscreen: () {
                    setState(() {
                      _chatPanelFullscreen = !_chatPanelFullscreen;
                    });
                  },
                  isFullscreen: _chatPanelFullscreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.fileName ?? widget.file?.name ?? 'PDF Document',
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            if (_totalPages > 0)
              Flexible(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Page $_currentPage of $_totalPages',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.initialPage != null && !isAndroid) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bookmark,
                              size: 10,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'From citation',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
        actions: [
          // Cached indicator in app bar
          Consumer<PdfViewerManager>(
            builder: (context, pdfManager, child) {
              if (pdfManager.isFromCache) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.offline_pin,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cached',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Connectivity and sync status indicator
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ConnectivityIndicator(),
          ),
          // On Android, use overflow menu to prevent toolbar overflow
          if (isAndroid)
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'refresh':
                    final connectivity = context.read<ConnectivityService>();
                    if (connectivity.isOnline) await _refreshPdf();
                    break;
                  case 'tts':
                    _toggleTtsControls();
                    break;
                  case 'annotate':
                    _toggleAnnotationToolbar();
                    break;
                  case 'annotations':
                    _toggleAnnotationPanel();
                    break;
                  case 'save':
                    await _savePdfWithAnnotations(uploadToDrive: true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'PDF saved and uploaded to Google Drive',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    break;
                  case 'search':
                    _toggleSearch();
                    break;
                  case 'goto':
                    if (_totalPages > 0) _showPageNavigator();
                    break;
                  case 'metadata':
                    _toggleMetadataSidebar();
                    break;
                  case 'splitview':
                    _openSplitView();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (kIsWeb)
                  const PopupMenuItem(
                    value: 'splitview',
                    child: Row(
                      children: [
                        Icon(Icons.view_column, size: 20, color: Colors.blue),
                        SizedBox(width: 12),
                        Text('Split View'),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'refresh',
                  enabled: context.read<ConnectivityService>().isOnline,
                  child: const Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 12),
                      Text('Refresh'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'tts',
                  child: Row(
                    children: [
                      Icon(
                        _showTtsControls ? Icons.volume_off : Icons.volume_up,
                        size: 20,
                        color: _showTtsControls ? Colors.blue : null,
                      ),
                      const SizedBox(width: 12),
                      const Text('Read Aloud'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'annotate',
                  child: Row(
                    children: [
                      Icon(
                        _showAnnotationToolbar ? Icons.edit_off : Icons.edit,
                        size: 20,
                        color: _showAnnotationToolbar ? Colors.blue : null,
                      ),
                      const SizedBox(width: 12),
                      const Text('Annotations'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'annotations',
                  child: Row(
                    children: [
                      Icon(
                        Icons.bookmark,
                        size: 20,
                        color: _showAnnotations ? Colors.blue : null,
                      ),
                      const SizedBox(width: 12),
                      const Text('Show Annotations'),
                    ],
                  ),
                ),
                if (_annotations.isNotEmpty)
                  const PopupMenuItem(
                    value: 'save',
                    child: Row(
                      children: [
                        Icon(Icons.cloud_upload, size: 20),
                        SizedBox(width: 12),
                        Text('Upload to Drive'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'search',
                  child: Row(
                    children: [
                      Icon(_isSearching ? Icons.close : Icons.search, size: 20),
                      const SizedBox(width: 12),
                      const Text('Search'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'goto',
                  enabled: _totalPages > 0,
                  child: const Row(
                    children: [
                      Icon(Icons.format_list_numbered, size: 20),
                      SizedBox(width: 12),
                      Text('Go to Page'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'metadata',
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: _showMetadataSidebar ? Colors.blue : null,
                      ),
                      const SizedBox(width: 12),
                      const Text('Metadata & Citations'),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            // Toolbar expand/collapse button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _showExpandedToolbar
                    ? (Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue[900]
                          : Colors.blue[50])
                    : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[100]),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _showExpandedToolbar
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue[700]!
                            : Colors.blue[300]!)
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey[300]!),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  _showExpandedToolbar ? Icons.close : Icons.more_horiz,
                  color: _showExpandedToolbar
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue[300]
                            : Colors.blue[700])
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey[700]),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showExpandedToolbar = !_showExpandedToolbar;
                  });
                },
                tooltip: _showExpandedToolbar
                    ? 'Hide tools'
                    : 'Show more tools',
                iconSize: 20,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),

            // Expanded toolbar buttons (only show when expanded)
            if (_showExpandedToolbar) ...[
              // Desktop/non-Android: Show all buttons in toolbar with theme-aware design
              if (kIsWeb)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.view_column_outlined,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.grey[700],
                      size: 20,
                    ),
                    onPressed: _openSplitView,
                    tooltip: 'Split View',
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              Consumer<ConnectivityService>(
                builder: (context, connectivity, child) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: connectivity.isOnline
                          ? (isDark ? Colors.grey[800] : Colors.grey[100])
                          : (isDark ? Colors.grey[850] : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: connectivity.isOnline
                            ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
                            : (isDark ? Colors.grey[800]! : Colors.grey[400]!),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh_outlined,
                        color: connectivity.isOnline
                            ? (isDark ? Colors.grey[300] : Colors.grey[700])
                            : (isDark ? Colors.grey[700] : Colors.grey[400]),
                        size: 20,
                      ),
                      onPressed: connectivity.isOnline ? _refreshPdf : null,
                      tooltip: connectivity.isOnline
                          ? 'Refresh from Google Drive'
                          : 'Offline - Cannot refresh',
                      iconSize: 20,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  );
                },
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _showTtsControls
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue[900]
                            : Colors.blue[50])
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _showTtsControls
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue[700]!
                              : Colors.blue[300]!)
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    _showTtsControls
                        ? Icons.volume_off_outlined
                        : Icons.volume_up_outlined,
                    color: _showTtsControls
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue[300]
                              : Colors.blue[700])
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[700]),
                    size: 20,
                  ),
                  onPressed: _toggleTtsControls,
                  tooltip: 'Read Aloud',
                  iconSize: 20,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _showAnnotationToolbar
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.orange[900]
                            : Colors.orange[50])
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _showAnnotationToolbar
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.orange[700]!
                              : Colors.orange[300]!)
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    _showAnnotationToolbar
                        ? Icons.edit_off_outlined
                        : Icons.edit_outlined,
                    color: _showAnnotationToolbar
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.orange[300]
                              : Colors.orange[700])
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[700]),
                    size: 20,
                  ),
                  onPressed: _toggleAnnotationToolbar,
                  tooltip: 'Annotations',
                  iconSize: 20,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),

              if (_annotations.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green[900]
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.green[700]!
                          : Colors.green[300]!,
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.cloud_upload_outlined,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.green[300]
                          : Colors.green[700],
                      size: 20,
                    ),
                    onPressed: () async {
                      await _savePdfWithAnnotations(uploadToDrive: true);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'PDF saved and uploaded to Google Drive',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    tooltip: 'Upload to Drive',
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _isSearching
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.amber[900]
                            : Colors.amber[50])
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSearching
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.amber[700]!
                              : Colors.amber[300]!)
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close_outlined : Icons.search_outlined,
                    color: _isSearching
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.amber[300]
                              : Colors.amber[800])
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[700]),
                    size: 20,
                  ),
                  onPressed: _toggleSearch,
                  tooltip: 'Search',
                  iconSize: 20,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]!
                        : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.format_list_numbered_outlined,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.grey[700],
                    size: 20,
                  ),
                  onPressed: _totalPages > 0 ? _showPageNavigator : null,
                  tooltip: 'Go to page',
                  iconSize: 20,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _showMetadataSidebar
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.teal[900]
                            : Colors.teal[50])
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _showMetadataSidebar
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.teal[700]!
                              : Colors.teal[300]!)
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.info_outlined,
                    color: _showMetadataSidebar
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.teal[300]
                              : Colors.teal[700])
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[700]),
                    size: 20,
                  ),
                  onPressed: _toggleMetadataSidebar,
                  tooltip: 'Metadata & Citations',
                  iconSize: 20,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ], // End of expanded toolbar
          ],
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Consumer<PdfViewerManager>(
              builder: (context, pdfManager, child) {
                if (pdfManager.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          pdfManager.downloadProgress < 1.0
                              ? 'Downloading... ${(pdfManager.downloadProgress * 100).toStringAsFixed(0)}%'
                              : 'Loading PDF...',
                        ),
                        if (pdfManager.downloadProgress > 0 &&
                            pdfManager.downloadProgress < 1.0)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            child: LinearProgressIndicator(
                              value: pdfManager.downloadProgress,
                            ),
                          ),
                      ],
                    ),
                  );
                }

                if (pdfManager.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load PDF',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pdfManager.errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadPdf,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (pdfManager.currentPdfBytes == null) {
                  return const Center(child: Text('No PDF loaded'));
                }

                return Column(
                  children: [
                    // TTS Controls
                    if (_showTtsControls)
                      TtsControls(
                        onPlay: _speakCurrentPage,
                        onNextPage: _onTtsNextPage,
                        onPreviousPage: _onTtsPreviousPage,
                        canGoNext: _currentPage < _totalPages,
                        canGoPrevious: _currentPage > 1,
                      ),
                    // Search bar
                    if (_isSearching)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.grey[200],
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Search in PDF...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onSubmitted: (_) => _performSearch(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.search_outlined, size: 20),
                              onPressed: _performSearch,
                              tooltip: 'Search',
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),
                    // Annotation toolbar
                    if (_showAnnotationToolbar)
                      AnnotationToolbar(
                        selectedMode: _pdfViewerController.annotationMode,
                        selectedColor: _selectedAnnotationColor,
                        onModeChanged: _onAnnotationModeChanged,
                        onColorChanged: _onAnnotationColorChanged,
                      ),
                    // Zoom controls bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.grey[100],
                        border: Border(
                          bottom: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Zoom out
                          IconButton(
                            icon: Icon(
                              Icons.zoom_out_outlined,
                              size: 20,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                            onPressed: _zoomLevel > 0.25 ? _zoomOut : null,
                            tooltip: 'Zoom out',
                            iconSize: 20,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          // Zoom level display
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[600]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              '${(_zoomLevel * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[200]
                                    : Colors.grey[800],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Zoom in
                          IconButton(
                            icon: Icon(
                              Icons.zoom_in_outlined,
                              size: 20,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                            onPressed: _zoomLevel < 3.0 ? _zoomIn : null,
                            tooltip: 'Zoom in',
                            iconSize: 20,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 16),
                          // Fit to page
                          TextButton.icon(
                            onPressed: _fitToPage,
                            icon: Icon(
                              Icons.fit_screen_outlined,
                              size: 18,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[300]
                                  : null,
                            ),
                            label: Text(
                              'Fit',
                              style: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[300]
                                    : null,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // PDF Viewer with annotation panel
                    Expanded(
                      child: Row(
                        children: [
                          // PDF Viewer with horizontal letterboxing for zoom < 100%
                          Expanded(
                            child: Container(
                              color: const Color(0xFF333333),
                              child: Row(
                                children: [
                                  // Left black bar (only visible when zoomed < 100%)
                                  if (_zoomLevel < 1.0)
                                    Expanded(
                                      flex: ((1.0 - _zoomLevel) * 100).toInt(),
                                      child: Container(
                                        color: const Color(0xFF333333),
                                      ),
                                    ),
                                  // PDF Viewer (fills vertical space)
                                  Expanded(
                                    flex: (_zoomLevel * 200).toInt(),
                                    child: Container(
                                      color: const Color(
                                        0xFF2A2A2A,
                                      ), // Soft dark grey background
                                      child: SfPdfViewer.memory(
                                        pdfManager.currentPdfBytes!,
                                        key: _pdfViewerKey,
                                        controller: _pdfViewerController,
                                        onDocumentLoaded:
                                            (PdfDocumentLoadedDetails details) {
                                              setState(() {
                                                _totalPages = details
                                                    .document
                                                    .pages
                                                    .count;
                                                _annotations =
                                                    _pdfViewerController
                                                        .getAnnotations();
                                              });
                                            },
                                        onPageChanged:
                                            (PdfPageChangedDetails details) {
                                              setState(() {
                                                _currentPage =
                                                    details.newPageNumber;
                                              });
                                              // Track page read
                                              _analyticsService
                                                  ?.updateCurrentPage(
                                                    _currentPage,
                                                  );
                                            },
                                        onAnnotationAdded:
                                            (Annotation annotation) {
                                              _onAnnotationAdded(annotation);
                                            },
                                        onAnnotationSelected:
                                            (Annotation annotation) {
                                              // Show context menu for annotation
                                              _showAnnotationContextMenu(
                                                annotation,
                                              );
                                            },
                                        onAnnotationDeselected:
                                            (Annotation annotation) {
                                              // Annotation deselected
                                            },
                                        onAnnotationEdited:
                                            (Annotation annotation) {
                                              setState(() {
                                                _annotations =
                                                    _pdfViewerController
                                                        .getAnnotations();
                                              });
                                              // Auto-save when annotation is edited
                                              _savePdfWithAnnotations();
                                            },
                                        onAnnotationRemoved:
                                            (Annotation annotation) {
                                              setState(() {
                                                _annotations =
                                                    _pdfViewerController
                                                        .getAnnotations();
                                              });
                                              // Auto-save when annotation is removed
                                              _savePdfWithAnnotations();
                                            },
                                      ),
                                    ),
                                  ),
                                  // Right black bar (only visible when zoomed < 100%)
                                  if (_zoomLevel < 1.0)
                                    Expanded(
                                      flex: ((1.0 - _zoomLevel) * 100).toInt(),
                                      child: Container(
                                        color: const Color(0xFF333333),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // Annotation panel (desktop) or bottom sheet (mobile)
                          if (_showAnnotations &&
                              MediaQuery.of(context).size.width >= 600)
                            CollapsibleSidebar(
                              width: 300,
                              title: 'Annotations',
                              onClose: () {
                                setState(() {
                                  _showAnnotations = false;
                                });
                              },
                              child: AnnotationListPanel(
                                annotations: _annotations,
                                onAnnotationTap: _onAnnotationTap,
                                onAnnotationDelete: _onAnnotationDelete,
                              ),
                            ),
                          // Metadata sidebar (desktop only)
                          if (_showMetadataSidebar &&
                              MediaQuery.of(context).size.width >= 600)
                            CollapsibleSidebar(
                              width: 350,
                              title: 'Metadata',
                              onClose: () {
                                setState(() {
                                  _showMetadataSidebar = false;
                                });
                              },
                              child: FileMetadataSidebar(
                                file:
                                    widget.file ??
                                    DriveFile(
                                      id: widget.fileId ?? '',
                                      name: widget.fileName ?? '',
                                      mimeType: 'application/pdf',
                                      modifiedTime: DateTime.now(),
                                      size: 0,
                                    ),
                                metadataService: context
                                    .read<MetadataService>(),
                                onClose: () {
                                  setState(() {
                                    _showMetadataSidebar = false;
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_showChatPanel && MediaQuery.of(context).size.width >= 900)
            _buildChatPanel(context),
        ],
      ),
      floatingActionButton: !_showChatPanel
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF0844), Color(0xFFFFB199)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF0844).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _openAiChatWithPdf,
                tooltip: 'Chat with this PDF',
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
