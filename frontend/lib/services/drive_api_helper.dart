import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Helper service for making Google Drive API calls with automatic token refresh
///
/// Uses AuthService.getAuthenticatedClient() which handles token refresh automatically
/// via the google_sign_in_all_platforms package.
class DriveApiHelper {
  final AuthService _authService;

  DriveApiHelper(this._authService);

  /// Get authenticated HTTP client
  Future<http.Client> _getClient() async {
    final client = await _authService.getAuthenticatedClient();
    if (client == null) {
      throw Exception('No authenticated client available. Please sign in.');
    }
    return client;
  }

  /// Make an authenticated HTTP GET request
  Future<http.Response> authenticatedGet(
    Uri uri, {
    Map<String, String>? headers,
    int maxRetries = 1,
  }) async {
    try {
      final client = await _getClient();
      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 401 && maxRetries > 0) {
        debugPrint('Got 401, retrying with fresh client...');
        // Try to get a fresh client (will attempt silent sign-in)
        final freshClient = await _getClient();
        return await freshClient.get(uri, headers: headers);
      }

      return response;
    } catch (e) {
      debugPrint('Error in authenticated GET request: $e');
      rethrow;
    }
  }

  /// Make an authenticated HTTP POST request
  Future<http.Response> authenticatedPost(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    int maxRetries = 1,
  }) async {
    try {
      final client = await _getClient();
      final response = await client.post(
        uri,
        headers: headers,
        body: body,
        encoding: encoding,
      );

      if (response.statusCode == 401 && maxRetries > 0) {
        debugPrint('Got 401, retrying with fresh client...');
        final freshClient = await _getClient();
        return await freshClient.post(
          uri,
          headers: headers,
          body: body,
          encoding: encoding,
        );
      }

      return response;
    } catch (e) {
      debugPrint('Error in authenticated POST request: $e');
      rethrow;
    }
  }

  /// Make an authenticated HTTP PATCH request
  Future<http.Response> authenticatedPatch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    int maxRetries = 1,
  }) async {
    try {
      final client = await _getClient();
      final response = await client.patch(
        uri,
        headers: headers,
        body: body,
        encoding: encoding,
      );

      if (response.statusCode == 401 && maxRetries > 0) {
        debugPrint('Got 401, retrying with fresh client...');
        final freshClient = await _getClient();
        return await freshClient.patch(
          uri,
          headers: headers,
          body: body,
          encoding: encoding,
        );
      }

      return response;
    } catch (e) {
      debugPrint('Error in authenticated PATCH request: $e');
      rethrow;
    }
  }

  /// Make an authenticated HTTP DELETE request
  Future<http.Response> authenticatedDelete(
    Uri uri, {
    Map<String, String>? headers,
    int maxRetries = 1,
  }) async {
    try {
      final client = await _getClient();
      final response = await client.delete(uri, headers: headers);

      if (response.statusCode == 401 && maxRetries > 0) {
        debugPrint('Got 401, retrying with fresh client...');
        final freshClient = await _getClient();
        return await freshClient.delete(uri, headers: headers);
      }

      return response;
    } catch (e) {
      debugPrint('Error in authenticated DELETE request: $e');
      rethrow;
    }
  }
}
