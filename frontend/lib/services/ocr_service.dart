import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'config_service.dart';

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

  OCRResult({
    required this.success,
    required this.pages,
    required this.totalPages,
    this.message,
  });

  factory OCRResult.fromJson(Map<String, dynamic> json) {
    return OCRResult(
      success: json['success'] as bool,
      pages: (json['pages'] as List)
          .map((page) => OCRPageResult.fromJson(page))
          .toList(),
      totalPages: json['total_pages'] as int,
      message: json['message'] as String?,
    );
  }
}

class OCRService {
  final ConfigService _configService;

  OCRService(this._configService);

  /// Process images with OCR and extract text
  Future<OCRResult> processImages(
    List<File> imageFiles, {
    String language = 'eng',
  }) async {
    try {
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
        return OCRResult.fromJson(data);
      } else {
        throw Exception('OCR processing failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to process OCR: $e');
    }
  }

  /// Check if OCR service is available
  Future<bool> checkHealth() async {
    try {
      final baseUrl = _configService.apiBaseUrl;
      final response = await http.get(Uri.parse('$baseUrl/api/ocr/health'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['available'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
