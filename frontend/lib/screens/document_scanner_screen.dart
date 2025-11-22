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
    print('🔵 Creating text-only PDF...');

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
          print(
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
            Offset(40, 55),
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

          print('🔵 Text added successfully');
        }
      }
    }

    // Save the PDF
    final List<int> bytes = await document.save();
    document.dispose();

    if (kIsWeb) {
      // On web, trigger download instead of saving to file system
      print(
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

      print('🔵 PDF downloaded: $fileName');

      // Return a dummy file (won't be used for upload on web)
      return File(fileName);
    } else {
      // On mobile/desktop, use actual file system
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = path.join(tempDir.path, fileName);
      final File pdfFile = File(filePath);

      // Write PDF bytes to file
      await pdfFile.writeAsBytes(bytes);

      print('🔵 PDF created: $filePath');
      return pdfFile;
    }
  }

  Future<void> _processAndSave() async {
    print('🔵 _processAndSave called with ${_capturedImages.length} images');

    if (_capturedImages.isEmpty) {
      _showError('No images to process');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      print('🔵 Getting services from context...');
      final ocrService = context.read<OCRService>();
      final driveService = context.read<DriveService>();
      final cacheService = context.read<CacheService>();

      // Show processing dialog
      if (!mounted) return;
      print('🔵 Showing processing dialog...');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing OCR...'),
              SizedBox(height: 8),
              Text(
                'Detecting best OCR mode...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );

      // Process OCR
      print('🔵 Starting OCR processing...');
      final ocrResult = await ocrService.processImages(_capturedImages);

      print('🔵 OCR processing complete: ${ocrResult.success}');

      if (!mounted) return;
      Navigator.pop(context); // Close processing dialog

      if (!ocrResult.success) {
        throw Exception('OCR processing failed');
      }

      print('🔵 Showing OCR preview...');
      // Show OCR preview with mode indicator
      final action = await _showOCRPreview(ocrResult);
      print('🔵 User chose action: $action');

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

      print('🔵 Creating searchable PDF: $fileName');

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Creating PDF...'),
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Uploading to Drive...'),
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
        print('🔵 Uploading PDF to Drive...');
        final driveFile = await driveService.uploadFile(
          pdfFile,
          widget.parentFolderId ?? '',
          customName: fileName,
        );

        print('🔵 Upload complete, caching metadata...');

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
      print('❌ Error in _processAndSave: $e');
      print('Stack trace: $stackTrace');
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
        title: Row(
          children: [
            const Text('OCR Preview'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.document_scanner,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tesseract OCR',
                    style: const TextStyle(
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
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Page ${page.pageNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (page.confidence != null)
                        Text(
                          'Confidence: ${page.confidence!.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        page.text.isEmpty ? '[No text detected]' : page.text,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'pdf'),
            child: const Text('Save as PDF'),
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
      appBar: AppBar(
        title: const Text('Scan Document'),
        actions: [
          if (_capturedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processAndSave,
                icon: const Icon(Icons.check),
                label: Text('Done (${_capturedImages.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
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
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick from Gallery'),
                  ),
                ],
              ),
            )
          : !_isCameraInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Camera preview
                Expanded(
                  flex: 3,
                  child: _cameraController != null
                      ? CameraPreview(_cameraController!)
                      : const Center(child: CircularProgressIndicator()),
                ),
                // Captured images preview
                if (_capturedImages.isNotEmpty)
                  Container(
                    height: 120,
                    color: Colors.black87,
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
                                    return Image.memory(
                                      snapshot.data!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return const SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: Center(
                                      child: CircularProgressIndicator(),
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
                                ),
                                onPressed: () => _removeImage(index),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.all(4),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                // Controls
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black87,
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
                        child: const Icon(Icons.camera, size: 32),
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
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Select images from your computer to extract text using OCR',
                  style: TextStyle(color: Colors.blue[900]),
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
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No images selected',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Click the button below to select images',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Select Images'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
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
                            border: Border.all(color: Colors.grey[300]!),
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
                                  child: CircularProgressIndicator(),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => _removeImage(index),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.all(4),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),

        // Bottom action bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (_capturedImages.isNotEmpty) ...[
                Text(
                  '${_capturedImages.length} image(s) selected',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.add),
                  label: const Text('Add More'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _processAndSave,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Process OCR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
