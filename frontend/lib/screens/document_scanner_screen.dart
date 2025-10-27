import 'dart:io';
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

class DocumentScannerScreen extends StatefulWidget {
  final String? parentFolderId;

  const DocumentScannerScreen({super.key, this.parentFolderId});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  CameraController? _cameraController;
  List<File> _capturedImages = [];
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  String? _errorMessage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
        _capturedImages.add(File(image.path));
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
          _capturedImages.add(File(image.path));
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
    List<File> images,
    OCRResult ocrResult,
    String fileName,
  ) async {
    print('🔵 Creating searchable PDF...');

    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    for (int i = 0; i < images.length; i++) {
      // Add a new page
      final PdfPage page = document.pages.add();

      // Load and draw the image
      final imageBytes = await images[i].readAsBytes();
      final PdfBitmap image = PdfBitmap(imageBytes);

      // Calculate size to fit page while maintaining aspect ratio
      final Size pageSize = page.getClientSize();
      final double imageAspect = image.width / image.height;
      final double pageAspect = pageSize.width / pageSize.height;

      double drawWidth, drawHeight;
      if (imageAspect > pageAspect) {
        // Image is wider than page
        drawWidth = pageSize.width;
        drawHeight = pageSize.width / imageAspect;
      } else {
        // Image is taller than page
        drawHeight = pageSize.height;
        drawWidth = pageSize.height * imageAspect;
      }

      // Draw the image
      page.graphics.drawImage(
        image,
        Rect.fromLTWH(0, 0, drawWidth, drawHeight),
      );

      // Add OCR text as invisible layer for searchability
      if (i < ocrResult.pages.length) {
        final ocrPage = ocrResult.pages[i];
        if (ocrPage.text.isNotEmpty) {
          // Create a text element with very small, transparent font
          final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 1);
          final PdfBrush brush = PdfSolidBrush(
            PdfColor(255, 255, 255, 1), // Almost transparent white
          );

          // Draw the OCR text in small font at bottom of page
          // This makes the PDF searchable without visible text overlay
          page.graphics.drawString(
            ocrPage.text,
            font,
            bounds: Rect.fromLTWH(0, pageSize.height - 10, pageSize.width, 10),
            brush: brush,
          );
        }
      }
    }

    // Save the PDF to a temporary file
    final List<int> bytes = await document.save();
    document.dispose();

    // Get temporary directory
    final Directory tempDir = await getTemporaryDirectory();
    final String filePath = path.join(tempDir.path, fileName);
    final File pdfFile = File(filePath);

    // Write PDF bytes to file
    await pdfFile.writeAsBytes(bytes);

    print('🔵 PDF created: $filePath');
    return pdfFile;
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
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing OCR...'),
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
      // Show OCR preview
      final shouldSave = await _showOCRPreview(ocrResult);
      print('🔵 User chose to save: $shouldSave');

      if (!shouldSave) {
        setState(() {
          _isProcessing = false;
        });
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

      print('🔵 Uploading PDF to Drive...');
      // Upload PDF to Drive
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

  Future<bool> _showOCRPreview(OCRResult ocrResult) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OCR Preview'),
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return result ?? false;
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
      body: _errorMessage != null
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
                              child: Image.file(
                                _capturedImages[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
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
}
