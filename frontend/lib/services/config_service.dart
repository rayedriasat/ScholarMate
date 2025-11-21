import 'package:flutter/foundation.dart';

/// Service for managing application configuration
/// Uses compile-time --dart-define variables
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize the configuration service
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('ConfigService: Loading compile-time configuration');
    _isInitialized = true;
    debugPrint('ConfigService initialized successfully');

    // Log configuration summary for debugging
    if (kDebugMode) {
      debugPrint('Config Summary:');
      debugPrint(
        '  Google Client ID: ${googleClientId.isNotEmpty ? "Configured" : "Missing"}',
      );
      debugPrint('  API Base URL: $apiBaseUrl');
      debugPrint(
        '  Supabase URL: ${supabaseUrl.isNotEmpty ? "Configured" : "Missing"}',
      );
    }
  }

  /// Get configuration value from compile-time constants
  String _getConfigValue(String key, {String defaultValue = ''}) {
    switch (key) {
      case 'GOOGLE_CLIENT_ID':
        return const String.fromEnvironment(
          'GOOGLE_CLIENT_ID',
          defaultValue: '',
        );
      case 'GOOGLE_CLIENT_SECRET':
        return const String.fromEnvironment(
          'GOOGLE_CLIENT_SECRET',
          defaultValue: '',
        );
      case 'GOOGLE_REDIRECT_URI':
        return const String.fromEnvironment(
          'GOOGLE_REDIRECT_URI',
          defaultValue: '',
        );
      case 'API_BASE_URL':
        return const String.fromEnvironment('API_BASE_URL', defaultValue: '');
      case 'SUPABASE_URL':
        return const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
      case 'SUPABASE_ANON_KEY':
        return const String.fromEnvironment(
          'SUPABASE_ANON_KEY',
          defaultValue: '',
        );
      default:
        return defaultValue;
    }
  }

  /// Get Google OAuth Client ID
  String get googleClientId {
    return _getConfigValue('GOOGLE_CLIENT_ID');
  }

  /// Get Google OAuth Client Secret (for web)
  String? get googleClientSecret {
    final value = _getConfigValue('GOOGLE_CLIENT_SECRET');
    return value.isEmpty ? null : value;
  }

  /// Get Google OAuth Redirect URI
  String get googleRedirectUri {
    return _getConfigValue(
      'GOOGLE_REDIRECT_URI',
      defaultValue: 'http://localhost:8080/auth/callback',
    );
  }

  /// Get Backend API Base URL
  String get apiBaseUrl {
    return _getConfigValue(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000',
    );
  }

  /// Alias for apiBaseUrl (for backward compatibility)
  String get backendUrl => apiBaseUrl;

  /// Get Supabase URL
  String get supabaseUrl {
    return _getConfigValue('SUPABASE_URL');
  }

  /// Get Supabase Anonymous Key
  String get supabaseAnonKey {
    return _getConfigValue('SUPABASE_ANON_KEY');
  }

  /// Check if all required configuration is present
  bool get isConfigured {
    return googleClientId.isNotEmpty && apiBaseUrl.isNotEmpty;
  }

  /// Get configuration summary for debugging
  Map<String, String> get configSummary {
    return {
      'googleClientId': googleClientId.isNotEmpty ? 'Configured' : 'Missing',
      'apiBaseUrl': apiBaseUrl,
      'supabaseUrl': supabaseUrl.isNotEmpty ? 'Configured' : 'Missing',
      'isConfigured': isConfigured.toString(),
    };
  }
}
