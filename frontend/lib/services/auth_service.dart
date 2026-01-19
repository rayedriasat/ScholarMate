import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import '../models/user.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'config_service.dart';

/// Authentication service handling Google OAuth
/// Windows: Uses google_sign_in_all_platforms (Client-side flow)
/// Android/Web: Uses Backend Oauth flow (Server-side flow)
class AuthService extends ChangeNotifier {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Google Sign-In instance (Windows only)
  GoogleSignIn? _googleSignIn;
  StreamSubscription<GoogleSignInCredentials?>? _authStateSub;

  // Deep linking (Android/Web)
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

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

  // Scopes required by the app (Google Drive access)
  static const List<String> _scopes = <String>[
    'openid',
    'profile',
    'email',
    'https://www.googleapis.com/auth/drive.file',
  ];

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

      // Try to restore user from local storage
      await _restoreUserFromStorage();

      // Platform-specific initialization
      if (_isWindows()) {
        await _initializeWindows(clientId);
      } else {
        await _initializeBackendAuth();
      }

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

  /// Initialize Windows-specific auth (Client-side SDK)
  Future<void> _initializeWindows(String clientId) async {
    debugPrint('Initializing Windows Auth (google_sign_in_all_platforms)');
    final configService = ConfigService();
    final clientSecret = configService.googleClientSecret;

    _googleSignIn = GoogleSignIn(
      params: GoogleSignInParams(
        clientId: clientId,
        clientSecret: clientSecret,
        scopes: _scopes,
        redirectPort: 3000,
        timeout: const Duration(minutes: 2),
      ),
    );

    _authStateSub = _googleSignIn!.authenticationState.listen(
      _handleAuthStateChange,
      onError: (error) => debugPrint('Auth error: $error'),
    );

    // Silent sign-in for Windows
    if (_currentUser != null) {
      debugPrint('Attempting silent sign-in (Windows)...');
      await silentSignIn();
    }
  }

  /// Initialize Backend Auth (Android/Web)
  Future<void> _initializeBackendAuth() async {
    debugPrint('Initializing Backend Auth (Deep Links)');
    _appLinks = AppLinks();

    // Handle incoming links (Deep links / Redirects)
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
      // Validate expiry and ownership
      if (await StorageService.isSessionValid()) {
        // Optionally verify with backend or refresh if needed
        await getAccessToken();
      } else {
        debugPrint('Session expired, clearing user');
        await _clearUserData();
      }
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

  /// Sign In - Platform Aware
  Future<void> signInWithGoogle() async {
    if (!_isInitialized) throw Exception('AuthService not initialized');

    if (_isWindows()) {
      await _windowsSignIn();
    } else {
      await _backendOAuthSignIn();
    }
  }

  /// Windows Client-Side Sign In
  Future<void> _windowsSignIn() async {
    _setLoading(true);
    try {
      if (_currentUser != null) await _clearUserData();
      final credentials = await _googleSignIn!.signIn();
      if (credentials == null) throw Exception('Sign-in cancelled');

      final user = await _createUserFromCredentials(credentials);
      _currentUser = user;
      await StorageService.storeUser(user);
      await _storeUserInBackend(user); // Calls old store-tokens logic

      _authStateController.add(user);
      notifyListeners();
    } finally {
      _setLoading(false);
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

  /// Get Access Token - Platform Aware
  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    if (_currentUser?.accessToken == null) return null;

    if (_isWindows()) {
      return _windowsGetAccessToken(forceRefresh: forceRefresh);
    } else {
      return _backendGetAccessToken(forceRefresh: forceRefresh);
    }
  }

  /// Windows: Get/Refresh Token
  Future<String?> _windowsGetAccessToken({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final expiryThreshold = now.add(const Duration(minutes: 5));
    final needsRefresh =
        _currentUser!.tokenExpiry != null &&
        expiryThreshold.isAfter(_currentUser!.tokenExpiry!);

    if (forceRefresh || needsRefresh) {
      if (_isRefreshing) return _waitForRefresh();
      _isRefreshing = true;
      try {
        return await _refreshAccessToken(); // Uses google_sign_in internal refresh
      } finally {
        _isRefreshing = false;
      }
    }
    return _currentUser!.accessToken;
  }

  /// Backend: Get/Refresh Token
  Future<String?> _backendGetAccessToken({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final expiryThreshold = now.add(const Duration(minutes: 5));
    final needsRefresh =
        _currentUser!.tokenExpiry != null &&
        expiryThreshold.isAfter(_currentUser!.tokenExpiry!);

    if (forceRefresh || needsRefresh) {
      if (_isRefreshing) return _waitForRefresh();
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

  /// Sign Out - Platform Aware
  Future<void> signOut() async {
    _setLoading(true);
    try {
      if (_isWindows()) {
        await _googleSignIn?.signOut();
      } else {
        // Backend logout - call delete tokens
        if (_currentUser != null) {
          try {
            await ApiService().deleteTokens(userId: _currentUser!.id);
          } catch (e) {
            debugPrint('Backend logout api failed (ignoring): $e');
          }
        }
      }
      await _handleSignOut();
    } finally {
      _setLoading(false);
    }
  }

  // ------------------------------------------------------------------------
  // Existing Windows Helper Methods (Kept for compatibility)
  // ------------------------------------------------------------------------

  void _handleAuthStateChange(GoogleSignInCredentials? credentials) async {
    if (credentials == null) {
      await _handleSignOut();
      return;
    }
    try {
      final user = await _createUserFromCredentials(credentials);
      if (_currentUser != null && _currentUser!.id != user.id) {
        await _clearUserData();
      }
      _currentUser = user;
      await StorageService.storeUser(user);
      await _storeUserInBackend(user);
      _authStateController.add(user);
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling auth state change: $e');
    }
  }

  Future<User?> silentSignIn() async {
    if (!_isInitialized) return null;

    if (_isWindows()) {
      try {
        var credentials = await _googleSignIn!.silentSignIn();
        if (credentials == null) {
          credentials = await _googleSignIn!.lightweightSignIn();
        }
        if (credentials != null) {
          final user = await _createUserFromCredentials(credentials);
          // Update state
          if (_currentUser != null && _currentUser!.id != user.id) {
            await _clearUserData();
          }
          _currentUser = user;
          await StorageService.storeUser(user);
          await _storeUserInBackend(user);
          _authStateController.add(user);
          notifyListeners();
          return user;
        }
      } catch (e) {
        debugPrint('Silent sign in failed: $e');
      }
    } else {
      // For Backend Auth, silent sign-in is managed by persistence restoration
      // We check if the current user is valid
      if (_currentUser != null) {
        return _currentUser;
      }

      // Try to restore again?
      await _restoreUserFromStorage();
      return _currentUser;
    }
    return null;
  }

  Future<String?> _refreshAccessToken() async {
    // Windows logic for refreshing map
    try {
      var credentials = await _googleSignIn!.silentSignIn();
      if (credentials == null)
        credentials = await _googleSignIn!.lightweightSignIn();

      if (credentials != null) {
        final user = await _createUserFromCredentials(credentials);
        _currentUser = user;
        await StorageService.storeUser(user);
        return user.accessToken;
      }
    } catch (e) {
      debugPrint('Windows refresh failed: $e');
    }
    return null;
  }

  // ------------------------------------------------------------------------
  // Shared Helpers
  // ------------------------------------------------------------------------

  Future<User> _createUserFromCredentials(
    GoogleSignInCredentials credentials,
  ) async {
    final userInfo = _decodeIdToken(credentials.idToken);
    DateTime tokenExpiry;
    if (userInfo.containsKey('exp') && userInfo['exp'] is int) {
      tokenExpiry = DateTime.fromMillisecondsSinceEpoch(
        (userInfo['exp'] as int) * 1000,
      );
    } else {
      tokenExpiry = DateTime.now().add(const Duration(hours: 1));
    }
    return User.fromGoogleSignIn(
      id: userInfo['sub'] ?? '',
      email: userInfo['email'] ?? '',
      displayName: userInfo['name'],
      photoUrl: userInfo['picture'],
      accessToken: credentials.accessToken,
      refreshToken: credentials.refreshToken,
      idToken: credentials.idToken,
      tokenExpiry: tokenExpiry,
    );
  }

  Map<String, dynamic> _decodeIdToken(String? idToken) {
    if (idToken == null || idToken.isEmpty) return {};
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return {};
      final payload = parts[1];
      var normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) normalized += '=';
      final decoded = utf8.decode(base64.decode(normalized));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<void> _handleSignOut() async {
    await _clearUserData();
    _currentUser = null;
    _authStateController.add(null);
    notifyListeners();
  }

  Future<void> _clearUserData() async {
    await StorageService.clearUser();
  }

  Future<void> _restoreUserFromStorage() async {
    try {
      final storedUser = await StorageService.getStoredUser();
      if (storedUser != null) {
        _currentUser = storedUser;
        _authStateController.add(storedUser);
      }
    } catch (e) {
      await StorageService.clearUser();
    }
  }

  Future<void> _storeUserInBackend(User user) async {
    try {
      if (user.accessToken == null || user.accessToken!.isEmpty) return;
      await ApiService().storeTokens(
        userId: user.id,
        email: user.email,
        name: user.displayName,
        pictureUrl: user.photoUrl,
        accessToken: user.accessToken!,
        refreshToken: user.refreshToken,
        idToken: user.idToken,
      );
    } catch (e) {
      debugPrint('Failed to store user in backend: $e');
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
      _authStateController.add(null);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // No longer needed for Web specifically, but keeping empty compatible signature if needed
  Widget? getWebSignInButton() => null;

  // Support custom last resort refresh if ever needed manually
  Future<String?> refreshAccessTokenWithRefreshToken() async => null;

  @override
  void dispose() {
    _authStateSub?.cancel();
    _linkSubscription?.cancel();
    _authStateController.close();
    super.dispose();
  }
}
