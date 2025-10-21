import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'config_service.dart';

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

  String get _baseUrl => _config.apiBaseUrl;

  /// Store OAuth tokens in the backend
  Future<void> storeTokens({
    required String userId,
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
}
