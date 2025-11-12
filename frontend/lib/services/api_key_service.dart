import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_key.dart';

class ApiKeyService {
  final String baseUrl;
  final String userId;

  ApiKeyService({required this.baseUrl, required this.userId});

  /// Get list of supported providers
  Future<List<ProviderConfig>> getProviders() async {
    final response = await http.get(Uri.parse('$baseUrl/api/keys/providers'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['providers'] as List)
          .map((p) => ProviderConfig.fromJson(p))
          .toList();
    } else {
      throw Exception('Failed to load providers');
    }
  }

  /// Validate API key without saving
  Future<Map<String, dynamic>> validateKey(
    String provider,
    String apiKey,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/keys/validate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'provider': provider, 'api_key': apiKey}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to validate key');
    }
  }

  /// Create or update API key
  Future<ApiKeyModel> saveKey({
    required String provider,
    required String apiKey,
    int priority = 0,
    bool validate = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/keys/$userId?validate=$validate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': provider,
        'api_key': apiKey,
        'priority': priority,
      }),
    );

    if (response.statusCode == 200) {
      return ApiKeyModel.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to save key');
    }
  }

  /// Get all user's API keys
  Future<List<ApiKeyModel>> getUserKeys() async {
    final response = await http.get(Uri.parse('$baseUrl/api/keys/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['keys'] as List)
          .map((k) => ApiKeyModel.fromJson(k))
          .toList();
    } else {
      throw Exception('Failed to load keys');
    }
  }

  /// Update key status or priority
  Future<ApiKeyModel> updateKey({
    required String keyId,
    bool? isActive,
    int? priority,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/keys/$userId/$keyId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (isActive != null) 'is_active': isActive,
        if (priority != null) 'priority': priority,
      }),
    );

    if (response.statusCode == 200) {
      return ApiKeyModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update key');
    }
  }

  /// Delete API key
  Future<void> deleteKey(String keyId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/keys/$userId/$keyId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete key');
    }
  }

  /// Get usage statistics
  Future<List<UsageStats>> getUsageStats({int days = 30}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/keys/$userId/usage/stats?days=$days'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['stats'] as List)
          .map((s) => UsageStats.fromJson(s))
          .toList();
    } else {
      throw Exception('Failed to load usage stats');
    }
  }
}
