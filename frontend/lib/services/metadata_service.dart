import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pdf_metadata.dart';

class MetadataService {
  final String baseUrl;
  final Future<String?> Function() getToken;
  final String Function() getUserId;

  MetadataService({
    required this.baseUrl,
    required this.getToken,
    required this.getUserId,
  });

  /// Extract metadata from a PDF file
  Future<PDFMetadata?> extractMetadata({
    required String fileId,
    required String fileName,
    bool extractFromContent = true,
  }) async {
    try {
      final token = await getToken();
      final userId = getUserId();

      if (token == null || token.isEmpty) {
        print('ERROR: No authentication token available');
        throw Exception('Not authenticated');
      }

      if (userId.isEmpty) {
        print('ERROR: No user ID available');
        throw Exception('User ID not found');
      }

      print('Extracting metadata for file: $fileName (ID: $fileId)');
      print('API URL: $baseUrl/api/metadata/extract?user_id=$userId');
      print('Token length: ${token.length}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/metadata/extract?user_id=$userId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'file_id': fileId,
              'file_name': fileName,
              'extract_from_content': extractFromContent,
              'access_token': token,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timed out after 30 seconds');
            },
          );

      print('Metadata extraction response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final metadata = PDFMetadata.fromJson(data);
        print('Successfully parsed metadata: ${metadata.title}');
        return metadata;
      } else if (response.statusCode == 404) {
        print('File not found in Google Drive');
        throw Exception('File not found in Google Drive');
      } else if (response.statusCode == 401) {
        print('Authentication failed');
        throw Exception('Authentication failed - please sign in again');
      } else {
        print('Failed to extract metadata: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error extracting metadata: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Generate citations from an identifier (DOI, ISBN, PMID, arXiv, URL)
  Future<Citation?> generateCitation({
    required String identifierType,
    required String identifierValue,
  }) async {
    try {
      final token = await getToken();
      final userId = getUserId();
      final response = await http.post(
        Uri.parse('$baseUrl/api/metadata/citation/generate?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'identifier_type': identifierType,
          'identifier_value': identifierValue,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Citation.fromJson(data);
      } else {
        print('Failed to generate citation: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error generating citation: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Generate citations from existing metadata
  Future<Citation?> generateCitationFromMetadata(PDFMetadata metadata) async {
    try {
      final token = await getToken();
      final userId = getUserId();
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/metadata/citation/from-metadata?user_id=$userId',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(metadata.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Citation.fromJson(data);
      } else {
        print(
          'Failed to generate citation from metadata: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('Error generating citation from metadata: $e');
      return null;
    }
  }
}
