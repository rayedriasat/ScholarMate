import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service for managing application configuration
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Store config values fetched from Vercel
  Map<String, String> _vercelConfig = {};
  bool _isVercelEnvironment = false;

  /// Initialize the configuration service
  /// Loads environment variables from .env file (local) or Vercel API (production)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if running on web and detect Vercel environment
      if (kIsWeb) {
        _isVercelEnvironment = _detectVercelEnvironment();
        
        if (_isVercelEnvironment) {
          debugPrint('Detected Vercel environment, fetching config from API...');
          await _loadVercelConfig();
        } else {
          debugPrint('Local web environment, loading .env file...');
          await dotenv.load(fileName: '.env');
        }
      } else {
        // Mobile/Desktop: always use .env
        await dotenv.load(fileName: '.env');
      }
      
      _isInitialized = true;
      debugPrint('ConfigService initialized successfully');
    } catch (e) {
      debugPrint('Warning: Could not load configuration: $e');
      debugPrint('Using default configuration values');
      _isInitialized = true;
    }
  }

  /// Detect if running on Vercel by checking the hostname
  bool _detectVercelEnvironment() {
    // In web, check if the hostname contains 'vercel.app'
    // This is a simple heuristic - you can also use environment-specific URLs
    if (kIsWeb) {
      final hostname = Uri.base.host;
      return hostname.contains('vercel.app') || 
             hostname.contains('vercel.com') ||
             // Add your custom domain here if you have one
             hostname.contains('your-custom-domain.com');
    }
    return false;
  }

  /// Load configuration from Vercel serverless function
  Future<void> _loadVercelConfig() async {
    try {
      final response = await http.get(
        Uri.parse('/api/config'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _vercelConfig = data.map((key, value) => MapEntry(key, value.toString()));
        debugPrint('Successfully loaded config from Vercel API');
      } else {
        debugPrint('Failed to load config from Vercel API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading config from Vercel API: $e');
    }
  }

  /// Get configuration value (from Vercel API or .env)
  String _getConfigValue(String key, {String defaultValue = ''}) {
    if (_isVercelEnvironment) {
      return _vercelConfig[key] ?? defaultValue;
    }
    return dotenv.env[key] ?? defaultValue;
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
