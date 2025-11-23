import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/drive_file.dart';
import '../services/auth_service.dart';
import '../services/tts_service.dart';
import '../services/metadata_service.dart';
import '../services/analytics_service.dart';
import '../services/pdf_viewer_manager.dart';
import '../services/drive_service.dart';
import '../services/connectivity_service.dart';
import '../database/database.dart' hide Annotation;
import '../widgets/annotation_list_panel.dart';
import '../widgets/tts_controls.dart';
import '../widgets/file_metadata_sidebar.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../theme/app_colors.dart';
import 'collaborative_pdf_viewer_screen.dart';
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
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
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

  // Zoom state
  double _zoomLevel = 1.0;

  // Analytics tracking
  AnalyticsService? _analyticsService;

  // UI State
  bool _showControls = true;
  late AnimationController _controlsController;
  late Animation<double> _controlsAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPdf();
    _initializeAnnotationSettings();
    _initializeAnalytics();

    _controlsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controlsAnimation = CurvedAnimation(
      parent: _controlsController,
      curve: Curves.easeInOut,
    );
    _controlsController.forward();

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
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
    _controlsController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _controlsController.forward();
      } else {
        _controlsController.reverse();
      }
    });
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
          backgroundColor: AppColors.surface,
          title: const Text(
            'Go to Page',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Page number (1-$_totalPages)',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
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
            ModernButton(
              label: 'Go',
              onPressed: () {
                Navigator.pop(context);
                _jumpToPage(targetPage);
              },
              width: 80,
              height: 36,
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
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          color: AppColors.surface,
          child: AnnotationListPanel(
            annotations: _annotations,
            onAnnotationTap: (annotation) {
              Navigator.pop(context);
              _onAnnotationTap(annotation);
            },
            onAnnotationDelete: _onAnnotationDelete,
          ),
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
          builder: (context, scrollController) => GlassContainer(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            color: AppColors.surface,
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
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
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        color: AppColors.surface,
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
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),

            // Change Color
            ListTile(
              leading: const Icon(Icons.palette, color: Colors.white),
              title: const Text(
                'Change Color',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showColorPickerForAnnotation(annotation);
              },
            ),

            // Delete
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Annotation',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteAnnotation(annotation);
              },
            ),

            // Cancel
            const SizedBox(height: 8),
            ModernButton(
              label: 'Cancel',
              variant: ModernButtonVariant.outline,
              onPressed: () => Navigator.pop(context),
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
        backgroundColor: AppColors.surface,
        title: const Text(
          'Choose Color',
          style: TextStyle(color: Colors.white),
        ),
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
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.2),
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
    // Note: In a real implementation, we would need to recreate the specific annotation type
    // This is a simplification as the syncfusion_flutter_pdfviewer package handles this internally
    // when we update settings, but for existing annotations we might need to recreate them.
    // For now, we'll just show a message as the package might not support direct color change easily.

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'To change color, please recreate the annotation with the new color selected.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _confirmDeleteAnnotation(Annotation annotation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Annotation',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this annotation? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ModernButton(
            label: 'Delete',
            backgroundColor: Colors.red,
            onPressed: () {
              Navigator.pop(context);
              _onAnnotationDelete(annotation);
            },
            width: 100,
            height: 36,
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

    _ttsService?.speak(_currentPageText);
  }

  @override
  Widget build(BuildContext context) {
    final pdfManager = context.watch<PdfViewerManager>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PDF Viewer
          if (pdfManager.isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (pdfManager.currentPdfBytes != null)
            GestureDetector(
              onTap: _toggleControls,
              child: SfPdfViewer.memory(
                pdfManager.currentPdfBytes!,
                controller: _pdfViewerController,
                key: _pdfViewerKey,
                onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                  setState(() {
                    _totalPages = details.document.pages.count;
                  });
                },
                onPageChanged: (PdfPageChangedDetails details) {
                  setState(() {
                    _currentPage = details.newPageNumber;
                  });
                  // If TTS is active, stop it when page changes
                  if (_ttsService?.isPlaying ?? false) {
                    _ttsService?.stop();
                  }
                },
                onAnnotationAdded: _onAnnotationAdded,
                // onAnnotationDeserialized: (Annotation annotation) {
                //   // This is called when annotations are loaded from the document
                //   // We don't need to do anything here as we get them via controller
                // },
                canShowScrollHead: false,
                canShowScrollStatus: false,
                enableDoubleTapZooming: true,
                enableTextSelection: true,
                // searchTextHighlightColor: Colors.yellow.withValues(alpha: 0.5),
                onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
                  if (details.selectedText != null &&
                      details.selectedText!.isNotEmpty) {
                    // Show context menu for selected text
                    // This is handled by the package, but we could add custom actions
                  }
                },
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load PDF',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ModernButton(
                    label: 'Retry',
                    onPressed: () => _loadPdf(forceRefresh: true),
                  ),
                ],
              ),
            ),

          // Top Toolbar (Glassmorphism)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _controlsAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(_controlsAnimation),
                child: GlassContainer(
                  borderRadius: BorderRadius.zero,
                  opacity: 0.2,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 12,
                    left: 16,
                    right: 16,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.fileName ?? 'Document',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Page $_currentPage of $_totalPages',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isSearching)
                        Expanded(
                          child: Container(
                            height: 40,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Search...',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              onSubmitted: (_) => _performSearch(),
                            ),
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          _isSearching ? Icons.close : Icons.search,
                          color: Colors.white,
                        ),
                        onPressed: _toggleSearch,
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        color: AppColors.surface,
                        onSelected: (value) {
                          switch (value) {
                            case 'refresh':
                              _refreshPdf();
                              break;
                            case 'metadata':
                              _toggleMetadataSidebar();
                              break;
                            case 'tts':
                              _toggleTtsControls();
                              break;
                            case 'annotations':
                              _toggleAnnotationPanel();
                              break;
                            case 'toolbar':
                              _toggleAnnotationToolbar();
                              break;
                            case 'split':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SplitPdfViewerScreen(
                                    leftFileId: widget.fileId,
                                    leftFileName: widget.fileName,
                                  ),
                                ),
                              );
                              break;
                            case 'collaborate':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CollaborativePdfViewerScreen(
                                        fileId: widget.fileId!,
                                        fileName: widget.fileName!,
                                      ),
                                ),
                              );
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'refresh',
                            child: Row(
                              children: [
                                Icon(Icons.refresh, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Refresh',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'metadata',
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Metadata',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'tts',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.record_voice_over,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Read Aloud',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'annotations',
                            child: Row(
                              children: [
                                Icon(Icons.comment, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Annotations',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'toolbar',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Annotation Tools',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'split',
                            child: Row(
                              children: [
                                Icon(Icons.vertical_split, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Split View',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'collaborate',
                            child: Row(
                              children: [
                                Icon(Icons.people, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Collaborate',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Controls (Glassmorphism)
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: FadeTransition(
              opacity: _controlsAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_controlsAnimation),
                child: Center(
                  child: GlassContainer(
                    borderRadius: BorderRadius.circular(30),
                    opacity: 0.2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.navigate_before,
                            color: Colors.white,
                          ),
                          onPressed: _previousPage,
                          tooltip: 'Previous Page',
                        ),
                        InkWell(
                          onTap: _showPageNavigator,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              '$_currentPage / $_totalPages',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.navigate_next,
                            color: Colors.white,
                          ),
                          onPressed: _nextPage,
                          tooltip: 'Next Page',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Annotation Toolbar
          if (_showAnnotationToolbar)
            Positioned(
              top: 100,
              right: 16,
              child: GlassContainer(
                borderRadius: BorderRadius.circular(16),
                opacity: 0.2,
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _buildAnnotationTool(
                      PdfAnnotationMode.highlight,
                      Icons.highlight,
                    ),
                    _buildAnnotationTool(
                      PdfAnnotationMode.underline,
                      Icons.format_underlined,
                    ),
                    _buildAnnotationTool(
                      PdfAnnotationMode.strikethrough,
                      Icons.format_strikethrough,
                    ),
                    _buildAnnotationTool(
                      PdfAnnotationMode.squiggly,
                      Icons.waves,
                    ),
                    _buildAnnotationTool(
                      PdfAnnotationMode.stickyNote,
                      Icons.note,
                    ),
                    const Divider(color: Colors.white24),
                    IconButton(
                      icon: Icon(Icons.circle, color: _selectedAnnotationColor),
                      onPressed: () => _showColorPickerForAnnotation(
                        HighlightAnnotation(
                          bounds: Rect.zero,
                          color: _selectedAnnotationColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Side Panels (Annotations / Metadata)
          if (_showAnnotations && MediaQuery.of(context).size.width >= 600)
            Positioned(
              top: 80,
              bottom: 0,
              right: 0,
              width: 300,
              child: GlassContainer(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                color: AppColors.surface,
                child: AnnotationListPanel(
                  annotations: _annotations,
                  onAnnotationTap: _onAnnotationTap,
                  onAnnotationDelete: _onAnnotationDelete,
                ),
              ),
            ),

          if (_showMetadataSidebar && MediaQuery.of(context).size.width >= 600)
            Positioned(
              top: 80,
              bottom: 0,
              right: 0,
              width: 300,
              child: GlassContainer(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                color: AppColors.surface,
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
                  onClose: _toggleMetadataSidebar,
                ),
              ),
            ),

          // TTS Controls
          if (_showTtsControls)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(24),
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(16),
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: TtsControls(
                    onPlay: () {
                      if (_ttsService?.isPlaying ?? false) {
                        _ttsService?.stop();
                      } else {
                        _speakCurrentPage();
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnnotationTool(PdfAnnotationMode mode, IconData icon) {
    final isSelected = _pdfViewerController.annotationMode == mode;
    return IconButton(
      icon: Icon(icon, color: isSelected ? AppColors.primary : Colors.white),
      onPressed: () => _onAnnotationModeChanged(mode),
      tooltip: mode.toString().split('.').last,
    );
  }
}
