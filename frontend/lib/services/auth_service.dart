import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import '../models/user.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'config_service.dart';
import 'windows_auth_server.dart';

/// Authentication service handling Google OAuth
/// All platforms (Windows, Web, Android) now use FastAPI Backend OAuth flow
class AuthService extends ChangeNotifier {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Deep linking (Android/Web) and Windows loopback server
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  WindowsAuthServer? _windowsAuthServer;

  // Current user
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Authentication state stream controller
  final _authStateController = StreamController<User?>.broadcast();
  Stream<User?> get authStateChanges => _authStateController.stream;

  // Initialization state
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Token refresh tracking to prevent loops
  bool _isRefreshing = false;

  /// Initialize the Authentication Service
  Future<void> initialize({
    required String clientId,
    String? serverClientId,
  }) async {
    if (_isInitialized) {
      debugPrint('AuthService already initialized');
      return;
    }

    try {
      // Initialize storage service
      await StorageService.initialize();

      // Restore user from storage (all platforms)
      await _restoreUserFromStorage();

      // Initialize backend auth with deep links
      await _initializeBackendAuth();

      _isInitialized = true;
      notifyListeners();
      debugPrint('AuthService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AuthService: $e');
      rethrow;
    }
  }

  /// Check if running on Windows
  bool _isWindows() {
    return !kIsWeb && Platform.isWindows;
  }

  /// Initialize Backend Auth (All platforms now use deep links / loopback)
  Future<void> _initializeBackendAuth() async {
    debugPrint('Initializing Backend Auth');
    _appLinks = AppLinks();

    // Handle incoming links (Deep links / Redirects)
    // Note: On Windows with loopback server, this won't be triggered
    // but we keep it for Android/Web compatibility
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Handle initial link if app was launched via link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Check token validity if user is restored
    if (_currentUser != null) {
      debugPrint('User restored from storage: ${_currentUser!.email}');
      // Validate expiry and ownership
      if (await StorageService.isSessionValid()) {
        debugPrint('Session is valid, checking token...');
        // Optionally verify with backend or refresh if needed
        await getAccessToken();
      } else {
        debugPrint('Session expired, clearing user');
        await _clearUserData();
      }
    } else {
      debugPrint('No user found in storage');
    }
  }

  /// Handle deep links for Auth Callback
  void _handleDeepLink(Uri uri) async {
    debugPrint('Received valid deep link: $uri');

    // Check for auth success code
    // Patterns:
    // Android: myapp://auth-success?code=XYZ
    // Web: http://.../auth-callback?code=XYZ

    // We check for 'code' parameter regardless of path/scheme for robustness
    final code = uri.queryParameters['code'];

    if (code != null && code.isNotEmpty) {
      debugPrint('Auth code found in link, exchanging for session...');
      await _exchangeCodeForSession(code);
    }
  }

  /// Exchange temporary code for session data
  Future<void> _exchangeCodeForSession(String code) async {
    _setLoading(true);
    try {
      final configService = ConfigService();
      // Ensure backendUrl doesn't have trailing slash for clean path building
      final baseUrl = configService.apiBaseUrl.endsWith('/')
          ? configService.apiBaseUrl.substring(
              0,
              configService.apiBaseUrl.length - 1,
            )
          : configService.apiBaseUrl;

      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/session?code=$code'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final oldUserId = _currentUser?.id;
        
        // Parse User from response
        final user = User(
          id: data['user_id'],
          email: data['email'],
          displayName: data['name'],
          photoUrl: data['picture_url'],
          accessToken: data['access_token'],
          refreshToken: null, // Refresh token is stored in backend
          tokenExpiry: DateTime.parse(data['token_expiry']),
        );

        // Check if this is a different user and clear cached data
        if (oldUserId != null && oldUserId != user.id) {
          debugPrint('Different user detected (old: $oldUserId, new: ${user.id}), clearing cache...');
          await _clearUserData();
          // Add flag to indicate cache should be cleared
          await StorageService.setBool('_cache_clear_needed', true);
        }

        _currentUser = user;
        await StorageService.storeUser(user);

        _authStateController.add(user);
        notifyListeners();
        debugPrint('Backend auth successful: ${user.email}');
      } else {
        debugPrint(
          'Failed to exchange code: ${response.statusCode} - ${response.body}',
        );
        // Show error?
      }
    } catch (e) {
      debugPrint('Error exchanging code: $e');
    } finally {
      // Clear query params from URL on web to avoid re-triggering?
      // Not easily possible without navigation.
      _setLoading(false);
    }
  }

  /// Sign In - Now unified across all platforms
  Future<void> signInWithGoogle() async {
    if (!_isInitialized) {
      throw Exception('AuthService not initialized');
    }

    _setLoading(true);
    try {
      if (_isWindows()) {
        await _windowsBackendOAuthSignIn();
      } else {
        await _backendOAuthSignIn();
      }
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  /// Windows Backend OAuth Sign In (using loopback server)
  Future<void> _windowsBackendOAuthSignIn() async {
    try {
      final configService = ConfigService();
      final baseUrl = configService.apiBaseUrl.endsWith('/')
          ? configService.apiBaseUrl.substring(
              0,
              configService.apiBaseUrl.length - 1,
            )
          : configService.apiBaseUrl;

      // Start local server to receive callback
      _windowsAuthServer = WindowsAuthServer(port: 3000);
      
      // Start server and get auth code future
      final authCodeFuture = _windowsAuthServer!.waitForAuthCode();

      // Open browser for auth
      final authUrl = '$baseUrl/api/auth/google?platform=windows';
      final uri = Uri.parse(authUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        await _windowsAuthServer?.stop();
        throw Exception('Could not launch auth URL');
      }

      // Wait for auth code from callback
      debugPrint('[Auth] Waiting for auth code from loopback server...');
      final encryptedCode = await authCodeFuture;
      debugPrint('[Auth] Received encrypted session code');

      // Exchange code for session
      await _exchangeCodeForSession(encryptedCode);
    } catch (e) {
      debugPrint('Error in Windows backend auth: $e');
      await _windowsAuthServer?.stop();
      rethrow;
    } finally {
      await _windowsAuthServer?.stop();
    }
  }

  /// Backend OAuth Sign In (Android/Web)
  Future<void> _backendOAuthSignIn() async {
    try {
      final configService = ConfigService();
      final baseUrl = configService.apiBaseUrl.endsWith('/')
          ? configService.apiBaseUrl.substring(
              0,
              configService.apiBaseUrl.length - 1,
            )
          : configService.apiBaseUrl;

      final platform = kIsWeb ? 'web' : 'android';
      final authUrl = '$baseUrl/api/auth/google?platform=$platform';

      final uri = Uri.parse(authUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: kIsWeb
              ? LaunchMode
                    .platformDefault // Same tab for web (default)
              : LaunchMode.externalApplication, // Browser for Android
          webOnlyWindowName: '_self',
        );
      } else {
        throw Exception('Could not launch auth URL');
      }
    } catch (e) {
      debugPrint('Error launching backend auth: $e');
      rethrow;
    }
  }

  /// Get Access Token - Now unified via backend for all platforms
  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    if (_currentUser?.accessToken == null) {
      return null;
    }

    debugPrint(
      '[Auth] getAccessToken called. forceRefresh: $forceRefresh',
    );

    return _backendGetAccessToken(forceRefresh: forceRefresh);
  }

  /// Backend: Get/Refresh Token (All platforms)
  Future<String?> _backendGetAccessToken({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final expiryThreshold = now.add(const Duration(minutes: 5));
    final needsRefresh =
        _currentUser!.tokenExpiry != null &&
        expiryThreshold.isAfter(_currentUser!.tokenExpiry!);

    if (forceRefresh || needsRefresh) {
      if (_isRefreshing) {
        return _waitForRefresh();
      }
      _isRefreshing = true;
      try {
        // Call backend to refresh access token
        final configService = ConfigService();
        final baseUrl = configService.apiBaseUrl.endsWith('/')
            ? configService.apiBaseUrl.substring(
                0,
                configService.apiBaseUrl.length - 1,
              )
            : configService.apiBaseUrl;

        final response = await http.get(
          Uri.parse(
            '$baseUrl/api/drive/access-token?user_id=${_currentUser!.id}',
          ),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final newAccessToken = data['access_token'];

          // Update local user
          final updatedUser = _currentUser!.copyWith(
            accessToken: newAccessToken,
            tokenExpiry: DateTime.now().add(
              const Duration(hours: 1),
            ), // Assume 1h if not provided
          );

          _currentUser = updatedUser;
          await StorageService.storeUser(updatedUser);
          notifyListeners();
          return newAccessToken;
        } else {
          debugPrint('Backend token refresh failed: ${response.statusCode}');
          // If failed, return current token or null?
          return null;
        }
      } catch (e) {
        debugPrint('Error refreshing token via backend: $e');
        return null;
      } finally {
        _isRefreshing = false;
      }
    }
    return _currentUser!.accessToken;
  }

  Future<String?> _waitForRefresh() async {
    int attempts = 0;
    while (_isRefreshing && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    return _currentUser?.accessToken;
  }

  /// Sign Out - Unified for all platforms
  Future<void> signOut() async {
    _setLoading(true);
    try {
      // Set flag to clear cache (will be handled by app-level listener)
      await StorageService.setBool('_cache_clear_needed', true);
      
      // Backend logout - call delete tokens
      if (_currentUser != null) {
        try {
          await ApiService().deleteTokens(userId: _currentUser!.id);
        } catch (e) {
          debugPrint('Backend logout api failed (ignoring): $e');
        }
      }
      
      await _handleSignOut();
    } finally {
      _setLoading(false);
    }
  }

  // ------------------------------------------------------------------------
  // Shared Helpers
  // ------------------------------------------------------------------------

  Future<void> _handleSignOut() async {
    await _clearUserData();
    _currentUser = null;
    _authStateController.add(null);
    notifyListeners();
  }

  Future<void> _clearUserData() async {
    debugPrint('Clearing user data and cache...');
    await StorageService.clearUser();
    // Note: Cache clearing is handled by the app-level services
    // to avoid circular dependencies
  }

  Future<void> _restoreUserFromStorage() async {
    try {
      final storedUser = await StorageService.getStoredUser();
      if (storedUser != null) {
        debugPrint('Restored user from storage: ${storedUser.email}');
        _currentUser = storedUser;
        _authStateController.add(storedUser);
      }
    } catch (e) {
      debugPrint('Error restoring user from storage: $e');
      await StorageService.clearUser();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Force complete logout and clear all data
  Future<void> forceLogout() async {
    debugPrint('Force logout initiated');
    _setLoading(true);

    try {
      // Set flag to clear cache (will be handled by app-level listener)
      await StorageService.setBool('_cache_clear_needed', true);
      
      // Clear user data first
      await _clearUserData();

      // Sign out from platform specific providers
      await signOut();

      _currentUser = null;
      _authStateController.add(null);
      notifyListeners();

      debugPrint('Force logout completed');
    } catch (e) {
      debugPrint('Error during force logout: $e');
      // Even if there's an error, clear local state
      _currentUser = null;
      await StorageService.clearUser();
      await StorageService.setBool('_cache_clear_needed', true);
      _authStateController.add(null);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _windowsAuthServer?.stop();
    _authStateController.close();
    super.dispose();
  }
}
