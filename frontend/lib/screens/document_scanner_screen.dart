import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/ocr_service.dart';
import '../services/drive_service.dart';
import '../services/cache_service.dart';
import '../models/markdown_note.dart';
import 'markdown_editor_screen.dart';
import 'package:universal_html/html.dart' as html;
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../theme/app_colors.dart';

class DocumentScannerScreen extends StatefulWidget {
  final String? parentFolderId;

  const DocumentScannerScreen({super.key, this.parentFolderId});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  CameraController? _cameraController;
  final List<XFile> _capturedImages = [];
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  String? _errorMessage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeCamera();
    } else {
      // On web, skip camera and go straight to file picker mode
      setState(() {
        _isCameraInitialized = true;
        _errorMessage =
            'Camera not supported on web. Use file picker to select images.';
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera available';
        });
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImages.add(image);
      });
    } catch (e) {
      _showError('Failed to capture image: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        setState(() {
          _capturedImages.add(image);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  void _retakeLast() {
    if (_capturedImages.isNotEmpty) {
      setState(() {
        _capturedImages.removeLast();
      });
    }
  }

  Future<File> _createSearchablePDF(
    List<XFile> images,
    OCRResult ocrResult,
    String fileName,
  ) async {
    debugPrint('🔵 Creating text-only PDF...');

    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    for (int i = 0; i < images.length; i++) {
      // Add a new page
      final PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();

      // Add OCR text as visible, readable text (no image)
      if (i < ocrResult.pages.length) {
        final ocrPage = ocrResult.pages[i];
        if (ocrPage.text.isNotEmpty) {
          debugPrint(
            '🔵 Adding text for page ${i + 1}: ${ocrPage.text.length} characters',
          );

          // Use readable font size with black color
          final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);
          final PdfBrush brush = PdfSolidBrush(PdfColor(0, 0, 0)); // Black text

          // Add page header
          final PdfFont headerFont = PdfStandardFont(
            PdfFontFamily.helvetica,
            14,
            style: PdfFontStyle.bold,
          );
          page.graphics.drawString(
            'Page ${i + 1}',
            headerFont,
            bounds: Rect.fromLTWH(40, 30, pageSize.width - 80, 20),
            brush: brush,
          );

          // Draw a line under header
          page.graphics.drawLine(
            PdfPen(PdfColor(0, 0, 0), width: 0.5),
            const Offset(40, 55),
            Offset(pageSize.width - 40, 55),
          );

          // Split text into lines and draw
          final lines = ocrPage.text.split('\n');
          final lineHeight = 16.0;
          double yPosition = 70.0;
          PdfPage currentPage = page;

          for (final line in lines) {
            if (line.trim().isNotEmpty) {
              // Check if we need a new page
              if (yPosition > pageSize.height - 50) {
                // Add new page and reset position
                currentPage = document.pages.add();
                yPosition = 40.0;
              }

              currentPage.graphics.drawString(
                line,
                font,
                bounds: Rect.fromLTWH(
                  40,
                  yPosition,
                  pageSize.width - 80,
                  lineHeight,
                ),
                brush: brush,
                format: PdfStringFormat(
                  alignment: PdfTextAlignment.left,
                  lineAlignment: PdfVerticalAlignment.top,
                ),
              );
              yPosition += lineHeight;
            }
          }

          debugPrint('🔵 Text added successfully');
        }
      }
    }

    // Save the PDF
    final List<int> bytes = await document.save();
    document.dispose();

    if (kIsWeb) {
      // On web, trigger download instead of saving to file system
      debugPrint(
        '🔵 PDF created in memory for web: $fileName (${bytes.length} bytes)',
      );

      // Convert to Uint8List for proper blob creation
      final uint8list = Uint8List.fromList(bytes);

      // Trigger browser download
      final blob = html.Blob([uint8list], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      // ignore: unused_local_variable
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);

      debugPrint('🔵 PDF downloaded: $fileName');

      // Return a dummy file (won't be used for upload on web)
      return File(fileName);
    } else {
      // On mobile/desktop, use actual file system
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = path.join(tempDir.path, fileName);
      final File pdfFile = File(filePath);

      // Write PDF bytes to file
      await pdfFile.writeAsBytes(bytes);

      debugPrint('🔵 PDF created: $filePath');
      return pdfFile;
    }
  }

  Future<void> _processAndSave() async {
    debugPrint(
      '🔵 _processAndSave called with ${_capturedImages.length} images',
    );

    if (_capturedImages.isEmpty) {
      _showError('No images to process');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('🔵 Getting services from context...');
      final ocrService = context.read<OCRService>();
      final driveService = context.read<DriveService>();
      final cacheService = context.read<CacheService>();

      // Show processing dialog
      if (!mounted) return;
      debugPrint('🔵 Showing processing dialog...');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Processing OCR...', style: TextStyle(color: Colors.white)),
              SizedBox(height: 8),
              Text(
                'Detecting best OCR mode...',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      );

      // Process OCR
      debugPrint('🔵 Starting OCR processing...');
      final ocrResult = await ocrService.processImages(_capturedImages);

      debugPrint('🔵 OCR processing complete: ${ocrResult.success}');

      if (!mounted) return;
      Navigator.pop(context); // Close processing dialog

      if (!ocrResult.success) {
        throw Exception('OCR processing failed');
      }

      debugPrint('🔵 Showing OCR preview...');
      // Show OCR preview with mode indicator
      final action = await _showOCRPreview(ocrResult);
      debugPrint('🔵 User chose action: $action');

      if (action == null || action == 'cancel') {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Handle convert to Markdown action
      if (action == 'markdown') {
        await _convertToMarkdown(ocrResult);
        return;
      }

      // Create PDF with OCR text
      final fileName = 'Scanned_${DateTime.now().millisecondsSinceEpoch}.pdf';

      debugPrint('🔵 Creating searchable PDF: $fileName');

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          backgroundColor: AppColors.surface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Creating PDF...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );

      // Create searchable PDF with images and OCR text
      final pdfFile = await _createSearchablePDF(
        _capturedImages,
        ocrResult,
        fileName,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close PDF creation dialog

      // Show upload dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          backgroundColor: AppColors.surface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Uploading to Drive...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      if (kIsWeb) {
        // On web, file was already downloaded, just show success
        if (!mounted) return;
        Navigator.pop(context); // Close upload dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF downloaded: $fileName'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } else {
        // On mobile/desktop, upload to Drive
        debugPrint('🔵 Uploading PDF to Drive...');
        final driveFile = await driveService.uploadFile(
          pdfFile,
          widget.parentFolderId ?? '',
          customName: fileName,
        );

        debugPrint('🔵 Upload complete, caching metadata...');

        // Cache the file metadata
        await cacheService.cacheFileMetadata(driveFile);

        if (!mounted) return;
        Navigator.pop(context); // Close upload dialog

        // Show success and return
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document saved: $fileName'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, driveFile);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in _processAndSave: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        // Try to close any open dialogs
        try {
          Navigator.pop(context);
        } catch (_) {}
        _showError('Failed to process document: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<String?> _showOCRPreview(OCRResult ocrResult) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Text('OCR Preview', style: TextStyle(color: Colors.white)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.document_scanner, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Tesseract OCR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ocrResult.pages.length,
            itemBuilder: (context, index) {
              final page = ocrResult.pages[index];
              return Card(
                color: Colors.white.withValues(alpha: 0.1),
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Page ${page.pageNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (page.confidence != null)
                        Text(
                          'Confidence: ${page.confidence!.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        page.text.isEmpty ? '[No text detected]' : page.text,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'markdown'),
            child: const Text('Save as Markdown'),
          ),
          ModernButton(
            onPressed: () => Navigator.pop(context, 'pdf'),
            label: 'Save as PDF',
            width: 120,
            height: 36,
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _convertToMarkdown(OCRResult ocrResult) async {
    try {
      // Combine all pages into one markdown document
      final markdownContent = ocrResult.pages
          .map((page) => '# Page ${page.pageNumber}\n\n${page.text}\n\n---\n')
          .join('\n');

      if (!mounted) return;

      // Navigate to markdown editor with pre-filled content
      final note = MarkdownNote.create(
        title: 'Scanned_${DateTime.now().millisecondsSinceEpoch}',
        content: markdownContent,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkdownEditorScreen(existingNote: note),
        ),
      );

      if (mounted) {
        Navigator.pop(context); // Return to file explorer
      }
    } catch (e) {
      _showError('Failed to convert to Markdown: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Scan Document',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_capturedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ModernButton(
                onPressed: _isProcessing ? () {} : _processAndSave,
                icon: Icons.check,
                label: 'Done (${_capturedImages.length})',
                backgroundColor: Colors.green,
                width: 120,
                height: 36,
              ),
            ),
        ],
      ),
      body: kIsWeb
          ? _buildWebUI()
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ModernButton(
                    onPressed: _pickFromGallery,
                    icon: Icons.photo_library,
                    label: 'Pick from Gallery',
                  ),
                ],
              ),
            )
          : !_isCameraInitialized
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                // Camera preview
                Expanded(
                  flex: 3,
                  child: _cameraController != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CameraPreview(_cameraController!),
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                ),
                // Captured images preview
                if (_capturedImages.isNotEmpty)
                  Container(
                    height: 120,
                    color: Colors.black,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _capturedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: FutureBuilder<Uint8List>(
                                future: _capturedImages[index].readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        snapshot.data!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  }
                                  return const SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                onPressed: () => _removeImage(index),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.all(4),
                                  minimumSize: const Size(24, 24),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                // Controls
                GlassContainer(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: _pickFromGallery,
                        icon: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      FloatingActionButton(
                        onPressed: _isProcessing ? null : _captureImage,
                        backgroundColor: AppColors.primary,
                        child: const Icon(
                          Icons.camera,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _capturedImages.isEmpty ? null : _retakeLast,
                        icon: const Icon(
                          Icons.undo,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWebUI() {
    return Column(
      children: [
        // Header with instructions
        GlassContainer(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.primary.withValues(alpha: 0.1),
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Select images from your computer to extract text using OCR',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ),
            ],
          ),
        ),

        // Image preview or empty state
        Expanded(
          child: _capturedImages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 100,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No images selected',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Click the button below to select images',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ModernButton(
                        onPressed: _pickFromGallery,
                        icon: Icons.add_photo_alternate,
                        label: 'Select Images',
                        width: 200,
                        height: 48,
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _capturedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FutureBuilder<Uint8List>(
                              future: _capturedImages[index].readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  );
                                }
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                            onPressed: () => _removeImage(index),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.all(4),
                              minimumSize: const Size(24, 24),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),

        // Bottom controls for web
        if (_capturedImages.isNotEmpty)
          GlassContainer(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            color: AppColors.surface,
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ModernButton(
                  onPressed: _pickFromGallery,
                  icon: Icons.add_photo_alternate,
                  label: 'Add More',
                  backgroundColor: Colors.transparent,
                  textColor: Colors.white,
                ),
                const SizedBox(width: 16),
                ModernButton(
                  onPressed: _isProcessing ? () {} : _processAndSave,
                  icon: Icons.check,
                  label: 'Process Images',
                  backgroundColor: AppColors.primary,
                  width: 180,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
