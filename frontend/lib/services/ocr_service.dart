import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'config_service.dart';

enum OCRMode {
  online, // DeepSeek OCR (high accuracy)
  offline, // Tesseract OCR (basic)
}

class OCRPageResult {
  final int pageNumber;
  final String text;
  final double? confidence;

  OCRPageResult({
    required this.pageNumber,
    required this.text,
    this.confidence,
  });

  factory OCRPageResult.fromJson(Map<String, dynamic> json) {
    return OCRPageResult(
      pageNumber: json['page_number'] as int,
      text: json['text'] as String,
      confidence: json['confidence'] as double?,
    );
  }
}

class OCRResult {
  final bool success;
  final List<OCRPageResult> pages;
  final int totalPages;
  final String? message;
  final OCRMode mode;

  OCRResult({
    required this.success,
    required this.pages,
    required this.totalPages,
    this.message,
    required this.mode,
  });

  factory OCRResult.fromJson(Map<String, dynamic> json, OCRMode mode) {
    return OCRResult(
      success: json['success'] as bool,
      pages: (json['pages'] as List)
          .map((page) => OCRPageResult.fromJson(page))
          .toList(),
      totalPages: json['total_pages'] as int,
      message: json['message'] as String?,
      mode: mode,
    );
  }
}

class OCRService {
  final ConfigService _configService;
  bool _tesseractInitialized = false;

  OCRService(this._configService);

  /// Check if device is online
  Future<bool> _isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);
    } catch (e) {
      return false;
    }
  }

  /// Initialize Tesseract (copy language data from assets to device)
  Future<void> _initializeTesseract() async {
    if (_tesseractInitialized) return;

    try {
      // Copy tessdata from assets to device storage
      final appDir = await getApplicationDocumentsDirectory();
      final tessdataDir = Directory(path.join(appDir.path, 'tessdata'));

      if (!await tessdataDir.exists()) {
        await tessdataDir.create(recursive: true);
      }

      // Copy eng.traineddata if not already present
      final engFile = File(path.join(tessdataDir.path, 'eng.traineddata'));
      if (!await engFile.exists()) {
        debugPrint('Copying tessdata from assets...');
        final data = await rootBundle.load('assets/tessdata/eng.traineddata');
        final bytes = data.buffer.asUint8List();
        await engFile.writeAsBytes(bytes);
        debugPrint('Tessdata copied successfully: ${engFile.path}');
      }

      _tesseractInitialized = true;
      debugPrint(
        'Tesseract initialized with language data at: ${tessdataDir.path}',
      );
    } catch (e) {
      debugPrint('Tesseract initialization error: $e');
      rethrow;
    }
  }

  /// Process images with online OCR (DeepSeek via backend)
  Future<OCRResult> _processImagesOnline(
    List<dynamic> imageFiles, {
    String language = 'eng',
  }) async {
    // Convert images to base64
    final base64Images = <String>[];
    for (final file in imageFiles) {
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);
      base64Images.add(base64);
    }

    // Send to backend
    final baseUrl = _configService.apiBaseUrl;
    final response = await http.post(
      Uri.parse('$baseUrl/api/ocr/process'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'images': base64Images, 'language': language}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OCRResult.fromJson(data, OCRMode.online);
    } else {
      throw Exception('OCR processing failed: ${response.body}');
    }
  }

  /// Process images with offline OCR (Tesseract on Android)
  Future<OCRResult> _processImagesOffline(
    List<dynamic> imageFiles, {
    String language = 'eng',
  }) async {
    await _initializeTesseract();

    final pages = <OCRPageResult>[];

    // Get tessdata directory path
    final appDir = await getApplicationDocumentsDirectory();
    final tessdataPath = appDir.path;

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        debugPrint('Processing image ${i + 1} with Tesseract (offline)...');
        debugPrint('Using tessdata path: $tessdataPath');

        // Get file path (handle both File and XFile)
        String filePath;
        if (imageFiles[i] is File) {
          filePath = (imageFiles[i] as File).path;
        } else {
          // XFile - need to get path or save temporarily
          filePath = imageFiles[i].path;
        }

        // Extract text using Tesseract with explicit tessdata path
        final text = await FlutterTesseractOcr.extractText(
          filePath,
          language: language,
          args: {
            "psm": "3", // Fully automatic page segmentation
            "preserve_interword_spaces": "1",
            "tessdata": tessdataPath, // Specify tessdata directory
          },
        );

        debugPrint('Extracted ${text.length} characters from page ${i + 1}');

        pages.add(
          OCRPageResult(
            pageNumber: i + 1,
            text: text.trim(),
            confidence:
                null, // Tesseract doesn't provide easy confidence in this package
          ),
        );
      } catch (e) {
        debugPrint('Offline OCR error for page ${i + 1}: $e');
        debugPrint('Error details: ${e.toString()}');
        pages.add(
          OCRPageResult(
            pageNumber: i + 1,
            text: '[Error: $e]',
            confidence: 0.0,
          ),
        );
      }
    }

    return OCRResult(
      success: true,
      pages: pages,
      totalPages: pages.length,
      message: 'Processed ${pages.length} pages using Tesseract (offline)',
      mode: OCRMode.offline,
    );
  }

  /// Process images with hybrid OCR (online preferred, offline fallback)
  Future<OCRResult> processImages(
    List<dynamic> imageFiles, {
    String language = 'eng',
    bool forceOffline = false,
  }) async {
    try {
      // On web, always use online mode (no offline support)
      if (kIsWeb) {
        debugPrint('Web platform detected, using online OCR only');
        return await _processImagesOnline(imageFiles, language: language);
      }

      // On mobile/desktop: try online first, fallback to offline
      if (!forceOffline && await _isOnline()) {
        try {
          return await _processImagesOnline(imageFiles, language: language);
        } catch (e) {
          debugPrint('Online OCR failed, falling back to offline: $e');
          // Fall through to offline mode
        }
      }

      // Use offline mode (mobile/desktop only)
      try {
        return await _processImagesOffline(imageFiles, language: language);
      } catch (e) {
        debugPrint('Offline OCR failed: $e');
        throw Exception(
          'OCR failed. Please check your internet connection and try again.',
        );
      }
    } catch (e) {
      throw Exception('Failed to process OCR: $e');
    }
  }

  /// Convert PDF to Markdown (online only, requires DeepSeek)
  Future<String> pdfToMarkdown(File pdfFile) async {
    try {
      if (!await _isOnline()) {
        throw Exception(
          'PDF to Markdown conversion requires internet connection',
        );
      }

      final bytes = await pdfFile.readAsBytes();
      final baseUrl = _configService.apiBaseUrl;

      final response = await http.post(
        Uri.parse('$baseUrl/api/ocr/pdf-to-markdown'),
        headers: {'Content-Type': 'application/octet-stream'},
        body: bytes,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['markdown'] as String;
      } else {
        throw Exception('PDF to Markdown conversion failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to convert PDF to Markdown: $e');
    }
  }

  /// Check if OCR service is available
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final baseUrl = _configService.apiBaseUrl;
      final response = await http.get(Uri.parse('$baseUrl/api/ocr/health'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'available': true,
          'tesseract_available': data['tesseract_available'] ?? false,
          'deepseek_available': data['deepseek_available'] ?? false,
          'ocr_mode': data['ocr_mode'] ?? 'unknown',
        };
      }
      return {'available': false};
    } catch (e) {
      return {'available': false, 'error': e.toString()};
    }
  }
}
