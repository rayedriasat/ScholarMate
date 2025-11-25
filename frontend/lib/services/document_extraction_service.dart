import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/extracted_document.dart';
import 'config_service.dart';
import 'auth_service.dart';
import 'ocr_service.dart';
import 'package:image_picker/image_picker.dart';

/// Service for handling document extraction using OCR + AI
class DocumentExtractionService extends ChangeNotifier {
  final ConfigService _configService;
  final AuthService _authService;
  final OCRService _ocrService;

  DocumentExtractionService({
    required ConfigService configService,
    required AuthService authService,
    required OCRService ocrService,
  }) : _configService = configService,
       _authService = authService,
       _ocrService = ocrService;

  String get _baseUrl => _configService.apiBaseUrl;

  /// Extract structured data from an image using OCR + AI
  Future<ExtractedDocument> extractDocument(XFile image) async {
    try {
      debugPrint('🔍 Starting document extraction...');

      // Step 1: Run OCR on the image
      debugPrint('📸 Running OCR...');
      final ocrResult = await _ocrService.processImages([image]);

      if (!ocrResult.success || ocrResult.pages.isEmpty) {
        throw Exception('OCR failed to extract text from image');
      }

      // Combine all pages text
      final ocrText = ocrResult.pages.map((p) => p.text).join('\n\n');
      debugPrint('📝 OCR extracted ${ocrText.length} characters');

      // Step 2: Send to AI for structured extraction
      debugPrint('🤖 Sending to AI for extraction...');
      final extractedData = await _extractStructuredData(ocrText);

      debugPrint('✅ Extraction complete');
      return extractedData;
    } catch (e) {
      debugPrint('❌ Extraction error: $e');
      rethrow;
    }
  }

  /// Send OCR text to AI backend for structured extraction
  Future<ExtractedDocument> _extractStructuredData(String ocrText) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      throw Exception('User ID not available');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/api/extraction/extract?user_id=$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'ocr_text': ocrText}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Create ExtractedDocument from AI response
      return ExtractedDocument.create(
        userId: userId,
        documentType: data['document_type'] as String,
        extractedData: Map<String, dynamic>.from(
          data['extracted_fields'] as Map,
        ),
        summary: data['summary'] as String,
        tags:
            (data['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
    } else {
      throw Exception('Failed to extract data: ${response.statusCode}');
    }
  }

  /// Save extracted document to backend
  Future<ExtractedDocument> saveExtractedDocument(
    ExtractedDocument document,
    String? imageUrl,
  ) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      throw Exception('User ID not available');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/api/extraction/documents?user_id=$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'document_type': document.documentType,
        'extracted_data': document.extractedData,
        'summary': document.summary,
        'image_url': imageUrl,
        'tags': document.tags,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      notifyListeners();
      return ExtractedDocument.fromJson(data);
    } else {
      throw Exception('Failed to save document: ${response.statusCode}');
    }
  }

  /// Get all extracted documents for current user
  Future<List<ExtractedDocument>> getExtractedDocuments() async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      throw Exception('User ID not available');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/api/extraction/documents?user_id=$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> documents = data['documents'] as List<dynamic>;
      return documents.map((json) => ExtractedDocument.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch documents: ${response.statusCode}');
    }
  }

  /// Get a specific extracted document by ID
  Future<ExtractedDocument> getExtractedDocument(String id) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      throw Exception('User ID not available');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/api/extraction/documents/$id?user_id=$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ExtractedDocument.fromJson(data);
    } else {
      throw Exception('Failed to fetch document: ${response.statusCode}');
    }
  }

  /// Update an extracted document
  Future<ExtractedDocument> updateExtractedDocument(
    ExtractedDocument document,
  ) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      throw Exception('User ID not available');
    }

    final response = await http.put(
      Uri.parse(
        '$_baseUrl/api/extraction/documents/${document.id}?user_id=$userId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'document_type': document.documentType,
        'extracted_data': document.extractedData,
        'summary': document.summary,
        'image_url': document.imagePath,
        'tags': document.tags,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      notifyListeners();
      return ExtractedDocument.fromJson(data);
    } else {
      throw Exception('Failed to update document: ${response.statusCode}');
    }
  }

  /// Delete an extracted document
  Future<void> deleteExtractedDocument(String id) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      throw Exception('User ID not available');
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/api/extraction/documents/$id?user_id=$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      notifyListeners();
    } else {
      throw Exception('Failed to delete document: ${response.statusCode}');
    }
  }

  /// Search extracted documents
  Future<List<ExtractedDocument>> searchDocuments({
    String? query,
    String? documentType,
    List<String>? tags,
  }) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      throw Exception('User ID not available');
    }

    final queryParams = <String, String>{'user_id': userId};
    if (query != null) queryParams['q'] = query;
    if (documentType != null) queryParams['type'] = documentType;
    if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags.join(',');

    final uri = Uri.parse(
      '$_baseUrl/api/extraction/documents',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> documents = data['documents'] as List<dynamic>;
      return documents.map((json) => ExtractedDocument.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search documents: ${response.statusCode}');
    }
  }
}
