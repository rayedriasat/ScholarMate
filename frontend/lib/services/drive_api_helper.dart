import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Helper service for making Google Drive API calls with automatic token refresh
class DriveApiHelper {
  final AuthService _authService;

  DriveApiHelper(this._authService);

  /// Make an authenticated HTTP GET request with automatic token refresh
  /// Retries once with refreshed token if initial request returns 401
  Future<http.Response> authenticatedGet(
    Uri uri, {
    Map<String, String>? headers,
    int maxRetries = 1,
  }) async {
    String? accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token available. Please sign in.');
    }

    final authHeaders = {'Authorization': 'Bearer $accessToken', ...?headers};

    try {
      final response = await http.get(uri, headers: authHeaders);

      // If 401 Unauthorized, try refreshing token and retry
      if (response.statusCode == 401 && maxRetries > 0) {
        debugPrint('Got 401, refreshing token and retrying...');

        // Force refresh the token
        accessToken = await _authService.getAccessToken(forceRefresh: true);

        if (accessToken == null) {
          throw Exception('Token refresh failed. Please sign in again.');
        }

        // Retry with new token
        final retryHeaders = {
          'Authorization': 'Bearer $accessToken',
          ...?headers,
        };

        return await http.get(uri, headers: retryHeaders);
      }

      return response;
    } catch (e) {
      debugPrint('Error in authenticated GET request: $e');
      rethrow;
    }
  }

  /// Make an authenticated HTTP POST request with automatic token refresh
  Future<http.Response> authenticatedPost(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    int maxRetries = 1,
  }) async {
    String? accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token available. Please sign in.');
    }

    final authHeaders = {'Authorization': 'Bearer $accessToken', ...?headers};

    try {
      final response = await http.post(
        uri,
        headers: authHeaders,
        body: body,
        encoding: encoding,
      );

      // If 401 Unauthorized, try refreshing token and retry
      if (response.statusCode == 401 && maxRetries > 0) {
        debugPrint('Got 401, refreshing token and retrying...');

        // Force refresh the token
        accessToken = await _authService.getAccessToken(forceRefresh: true);

        if (accessToken == null) {
          throw Exception('Token refresh failed. Please sign in again.');
        }

        // Retry with new token
        final retryHeaders = {
          'Authorization': 'Bearer $accessToken',
          ...?headers,
        };

        return await http.post(
          uri,
          headers: retryHeaders,
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

  /// Make an authenticated HTTP PATCH request with automatic token refresh
  Future<http.Response> authenticatedPatch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    int maxRetries = 1,
  }) async {
    String? accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token available. Please sign in.');
    }

    final authHeaders = {'Authorization': 'Bearer $accessToken', ...?headers};

    try {
      final response = await http.patch(
        uri,
        headers: authHeaders,
        body: body,
        encoding: encoding,
      );

      // If 401 Unauthorized, try refreshing token and retry
      if (response.statusCode == 401 && maxRetries > 0) {
        debugPrint('Got 401, refreshing token and retrying...');

        // Force refresh the token
        accessToken = await _authService.getAccessToken(forceRefresh: true);

        if (accessToken == null) {
          throw Exception('Token refresh failed. Please sign in again.');
        }

        // Retry with new token
        final retryHeaders = {
          'Authorization': 'Bearer $accessToken',
          ...?headers,
        };

        return await http.patch(
          uri,
          headers: retryHeaders,
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

  /// Make an authenticated HTTP DELETE request with automatic token refresh
  Future<http.Response> authenticatedDelete(
    Uri uri, {
    Map<String, String>? headers,
    int maxRetries = 1,
  }) async {
    String? accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token available. Please sign in.');
    }

    final authHeaders = {'Authorization': 'Bearer $accessToken', ...?headers};

    try {
      final response = await http.delete(uri, headers: authHeaders);

      // If 401 Unauthorized, try refreshing token and retry
      if (response.statusCode == 401 && maxRetries > 0) {
        debugPrint('Got 401, refreshing token and retrying...');

        // Force refresh the token
        accessToken = await _authService.getAccessToken(forceRefresh: true);

        if (accessToken == null) {
          throw Exception('Token refresh failed. Please sign in again.');
        }

        // Retry with new token
        final retryHeaders = {
          'Authorization': 'Bearer $accessToken',
          ...?headers,
        };

        return await http.delete(uri, headers: retryHeaders);
      }

      return response;
    } catch (e) {
      debugPrint('Error in authenticated DELETE request: $e');
      rethrow;
    }
  }
}
