import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for managing application configuration
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize the configuration service
  /// Loads environment variables from .env file
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await dotenv.load(fileName: '.env');
      _isInitialized = true;
    } catch (e) {
      debugPrint('Warning: Could not load .env file: $e');
      debugPrint('Using default configuration values');
      _isInitialized = true;
    }
  }

  /// Get Google OAuth Client ID
  String get googleClientId {
    return dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  }

  /// Get Google OAuth Client Secret (for web)
  String? get googleClientSecret {
    return dotenv.env['GOOGLE_CLIENT_SECRET'];
  }

  /// Get Google OAuth Redirect URI
  String get googleRedirectUri {
    return dotenv.env['GOOGLE_REDIRECT_URI'] ??
        'http://localhost:8080/auth/callback';
  }

  /// Get Backend API Base URL
  String get apiBaseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  }

  /// Get Supabase URL
  String get supabaseUrl {
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  /// Get Supabase Anonymous Key
  String get supabaseAnonKey {
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
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
