import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import 'auth_service.dart';
import '../models/tag.dart';
import '../models/indexing_job.dart';

/// Exception thrown when API calls fail
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Service for making API calls to the backend
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _config = ConfigService();
  final _authService = AuthService();

  String get _baseUrl => _config.apiBaseUrl;

  /// Store OAuth tokens in the backend
  Future<void> storeTokens({
    required String userId,
    required String email,
    String? name,
    String? pictureUrl,
    required String accessToken,
    String? refreshToken,
    String? idToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/store-tokens'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'email': email,
          'name': name,
          'picture_url': pictureUrl,
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'id_token': idToken,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          'Failed to store tokens: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to store tokens: $e');
    }
  }

  /// Refresh access token from the backend
  Future<String?> refreshToken({required String userId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/refresh-token?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'] as String?;
      } else {
        throw ApiException(
          'Failed to refresh token: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('Failed to refresh token: $e');
      return null;
    }
  }

  /// Delete user tokens from the backend (sign out)
  Future<void> deleteTokens({required String userId}) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/auth/tokens?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to delete tokens: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete tokens: $e');
    }
  }

  /// Check backend health
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }

  // ==================== Tag Management ====================

  /// Get all tags for a user
  Future<List<Tag>> getTags({String? userId}) async {
    try {
      // user_id is required by the backend
      if (userId == null) {
        throw ApiException('user_id is required to get tags');
      }

      final uri = Uri.parse('$_baseUrl/api/tags?user_id=$userId');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tagsList = data['tags'] as List;
        return tagsList.map((json) => Tag.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to get tags: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get tags: $e');
    }
  }

  /// Create a new tag
  Future<Tag> createTag({
    required String userId,
    required String name,
    String color = '#2196F3',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tags?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'color': color}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Tag.fromJson(data);
      } else {
        throw ApiException(
          'Failed to create tag: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create tag: $e');
    }
  }

  /// Update a tag
  Future<Tag> updateTag({
    required String tagId,
    required String userId,
    String? name,
    String? color,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (color != null) updates['color'] = color;

      final response = await http.put(
        Uri.parse('$_baseUrl/api/tags/$tagId?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Tag.fromJson(data);
      } else {
        throw ApiException(
          'Failed to update tag: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update tag: $e');
    }
  }

  /// Delete a tag
  Future<void> deleteTag({
    required String tagId,
    required String userId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/tags/$tagId?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 204) {
        throw ApiException(
          'Failed to delete tag: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete tag: $e');
    }
  }

  /// Get tags for a file
  Future<List<Tag>> getTagsForFile({
    required String fileId,
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tags/file/$fileId?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tagsList = data['tags'] as List;
        return tagsList.map((json) => Tag.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to get file tags: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get file tags: $e');
    }
  }

  /// Add a tag to a file
  Future<void> addTagToFile({
    required String userId,
    required String fileId,
    required String tagId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tags/file?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'file_id': fileId, 'tag_id': tagId}),
      );

      if (response.statusCode != 201) {
        throw ApiException(
          'Failed to add tag to file: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to add tag to file: $e');
    }
  }

  /// Remove a tag from a file
  Future<void> removeTagFromFile({
    required String userId,
    required String fileId,
    required String tagId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/tags/file/$fileId/$tagId?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 204) {
        throw ApiException(
          'Failed to remove tag from file: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to remove tag from file: $e');
    }
  }

  /// Bulk tag files
  Future<void> bulkTagFiles({
    required String userId,
    required List<String> fileIds,
    required List<String> tagIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tags/bulk?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'file_ids': fileIds, 'tag_ids': tagIds}),
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to bulk tag files: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to bulk tag files: $e');
    }
  }

  // ==================== RAG Indexing ====================

  /// Start indexing a file for RAG
  Future<String> startIndexing({
    required String userId,
    required String fileId,
    String? fileName,
  }) async {
    try {
      // Get fresh access token
      final accessToken = await _authService.getAccessToken();
      if (accessToken == null) {
        throw ApiException('Not authenticated', 401);
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/ingest/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'file_id': fileId,
          'file_name': fileName,
          'access_token': accessToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['job_id'] as String;
      } else if (response.statusCode == 401) {
        // Token expired, retry once with fresh token
        final newToken = await _authService.getAccessToken();
        if (newToken != null) {
          final retryResponse = await http.post(
            Uri.parse('$_baseUrl/api/ingest/start'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'file_id': fileId,
              'file_name': fileName,
              'access_token': newToken,
            }),
          );
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            return data['job_id'] as String;
          }
        }
        throw ApiException('Authentication failed', 401);
      } else {
        throw ApiException(
          'Failed to start indexing: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to start indexing: $e');
    }
  }

  /// Get indexing job status
  Future<IndexingJob> getJobStatus({required String jobId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/ingest/status/$jobId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return IndexingJob.fromJson(data);
      } else {
        throw ApiException(
          'Failed to get job status: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get job status: $e');
    }
  }

  /// List all indexing jobs for a user
  Future<List<IndexingJob>> listUserJobs({required String userId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/ingest/list/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final jobsList = data['jobs'] as List;
        return jobsList.map((json) => IndexingJob.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to list user jobs: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to list user jobs: $e');
    }
  }

  /// Reindex a file (delete old embeddings and create new ones)
  Future<String> reindexFile({
    required String userId,
    required String fileId,
    String? fileName,
  }) async {
    try {
      // Get fresh access token
      final accessToken = await _authService.getAccessToken();
      if (accessToken == null) {
        throw ApiException('Not authenticated', 401);
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/ingest/reindex/$fileId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'file_name': fileName,
          'access_token': accessToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['job_id'] as String;
      } else if (response.statusCode == 401) {
        // Token expired, retry once
        final newToken = await _authService.getAccessToken();
        if (newToken != null) {
          final retryResponse = await http.post(
            Uri.parse('$_baseUrl/api/ingest/reindex/$fileId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'file_name': fileName,
              'access_token': newToken,
            }),
          );
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            return data['job_id'] as String;
          }
        }
        throw ApiException('Authentication failed', 401);
      } else {
        throw ApiException(
          'Failed to reindex file: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to reindex file: $e');
    }
  }

  // ==================== AI Chat ====================

  /// Send a chat message with RAG and source filtering
  Future<Map<String, dynamic>> sendChatMessage({
    required String question,
    required String userId,
    List<String>? selectedFileIds,
    int topK = 5,
  }) async {
    try {
      final requestBody = {
        'question': question,
        'user_id': userId,
        'top_k': topK,
      };

      if (selectedFileIds != null && selectedFileIds.isNotEmpty) {
        requestBody['selected_file_ids'] = selectedFileIds;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/ai/chat-rag'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          'Failed to send chat message: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to send chat message: $e');
    }
  }

  // ==================== Notebook AI Studio ====================

  /// Generate quiz questions from files
  Future<Map<String, dynamic>> generateQuiz({
    required String userId,
    required List<String> fileIds,
    int numQuestions = 5,
    String difficulty = 'medium',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/notebook-ai/generate-quiz'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'file_ids': fileIds,
          'num_questions': numQuestions,
          'difficulty': difficulty,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          'Failed to generate quiz: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to generate quiz: $e');
    }
  }

  /// Generate summary from files
  Future<Map<String, dynamic>> generateSummary({
    required String userId,
    required List<String> fileIds,
    String length = 'medium',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/notebook-ai/generate-summary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'file_ids': fileIds,
          'length': length,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          'Failed to generate summary: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to generate summary: $e');
    }
  }

  /// Generate flashcards from files
  Future<Map<String, dynamic>> generateFlashcards({
    required String userId,
    required List<String> fileIds,
    int numCards = 10,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/notebook-ai/generate-flashcards'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'file_ids': fileIds,
          'num_cards': numCards,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          'Failed to generate flashcards: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to generate flashcards: $e');
    }
  }

  /// Generate audio review script from files
  Future<Map<String, dynamic>> generateAudioReview({
    required String userId,
    required List<String> fileIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/notebook-ai/generate-audio'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'file_ids': fileIds}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>;
      } else {
        throw ApiException(
          'Failed to generate audio review: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to generate audio review: $e');
    }
  }
}


  // ==================== Notebook AI Studio ====================

  /// Generate quiz questions from files
