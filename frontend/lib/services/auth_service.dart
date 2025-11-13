import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import '../models/user.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'config_service.dart';

/// Authentication service handling Google OAuth using google_sign_in_all_platforms
/// Supports all platforms including Windows and Linux
class AuthService extends ChangeNotifier {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Google Sign-In instance
  GoogleSignIn? _googleSignIn;

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

  // Scopes required by the app (Google Drive access)
  static const List<String> _scopes = <String>[
    'openid',
    'profile',
    'email',
    'https://www.googleapis.com/auth/drive',
  ];

  StreamSubscription<GoogleSignInCredentials?>? _authStateSub;

  /// Initialize the Google Sign-In instance
  /// Must be called exactly once before any other methods
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

      // Get client secret from config (required for desktop platforms)
      final configService = ConfigService();
      final clientSecret = configService.googleClientSecret;

      debugPrint('Initializing Google Sign-In All Platforms');
      debugPrint('Platform: ${defaultTargetPlatform.name}');
      debugPrint('Is Web: $kIsWeb');
      
      // Initialize Google Sign-In with platform-appropriate configuration
      _googleSignIn = GoogleSignIn(
        params: GoogleSignInParams(
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: _scopes,
          redirectPort: 8000, // Default port for desktop platforms
          timeout: const Duration(minutes: 2), // Timeout for desktop login
        ),
      );

      // Subscribe to authentication state changes
      _authStateSub = _googleSignIn!.authenticationState.listen(
        _handleAuthStateChange,
        onError: _handleAuthError,
      );

      _isInitialized = true;

      // Attempt silent sign-in to restore previous session
      if (_currentUser != null) {
        debugPrint('User restored from storage, attempting silent sign-in...');
        await silentSignIn();
      }

      notifyListeners();
      debugPrint('AuthService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AuthService: $e');
      rethrow;
    }
  }

  /// Handle authentication state changes from the stream
  void _handleAuthStateChange(GoogleSignInCredentials? credentials) async {
    debugPrint('Auth state changed: ${credentials != null ? "signed in" : "signed out"}');

    if (credentials == null) {
      // User signed out
      await _handleSignOut();
      return;
    }

    try {
      // Create user from credentials
      final user = await _createUserFromCredentials(credentials);

      // Check if this is a different user
      if (_currentUser != null && _currentUser!.id != user.id) {
        debugPrint('Different user signing in, clearing old data');
        await _clearUserData();
      }

      _currentUser = user;

      // Store user data locally
      await StorageService.storeUser(user);

      // Store user and tokens in backend
      await _storeUserInBackend(user);

      _authStateController.add(user);
      notifyListeners();

      debugPrint('User authenticated: ${user.email}');
    } catch (e) {
      debugPrint('Error handling auth state change: $e');
    }
  }

  /// Handle authentication errors
  void _handleAuthError(Object error) {
    debugPrint('Authentication error: $error');
  }

  /// Sign in with Google (explicit user-initiated authentication)
  /// This is the primary sign-in method that should be called when user clicks sign-in button
  Future<User> signInWithGoogle() async {
    if (!_isInitialized) {
      throw Exception('AuthService not initialized');
    }

    _setLoading(true);

    try {
      debugPrint('Starting Google sign-in...');

      // Clear any existing user data first
      if (_currentUser != null) {
        debugPrint('Clearing existing user data before new sign-in');
        await _clearUserData();
      }

      // Perform sign-in (will try lightweight first, then online if needed)
      final credentials = await _googleSignIn!.signIn();

      if (credentials == null) {
        throw Exception('Sign-in was cancelled or failed');
      }

      // Create user from credentials
      final user = await _createUserFromCredentials(credentials);

      _currentUser = user;

      // Store user data locally
      await StorageService.storeUser(user);

      // Store user and tokens in backend
      await _storeUserInBackend(user);

      _authStateController.add(user);
      notifyListeners();

      debugPrint('Sign-in completed successfully for user: ${user.email}');
      return user;
    } catch (e) {
      debugPrint('Sign-in failed: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Silent sign-in (restores previous session without user interaction)
  /// Recommended to call on app startup
  Future<User?> silentSignIn() async {
    if (!_isInitialized) {
      debugPrint('AuthService not initialized');
      return null;
    }

    try {
      debugPrint('Attempting silent sign-in...');

      final credentials = await _googleSignIn!.silentSignIn();

      if (credentials == null) {
        debugPrint('Silent sign-in returned no credentials');
        return null;
      }

      // Create user from credentials
      final user = await _createUserFromCredentials(credentials);

      _currentUser = user;

      // Store user data locally
      await StorageService.storeUser(user);

      // Store user and tokens in backend
      await _storeUserInBackend(user);

      _authStateController.add(user);
      notifyListeners();

      debugPrint('Silent sign-in successful for user: ${user.email}');
      return user;
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
      return null;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    if (!_isInitialized) {
      debugPrint('AuthService not initialized');
      return;
    }

    _setLoading(true);
    try {
      debugPrint('Signing out user: ${_currentUser?.email}');
      await _googleSignIn!.signOut();
      // State change will be handled by the stream listener
    } catch (e) {
      debugPrint('Sign-out failed: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get the web sign-in button widget (for web platform only)
  /// Returns null on non-web platforms
  Widget? getWebSignInButton() {
    if (!kIsWeb || !_isInitialized || _googleSignIn == null) {
      return null;
    }

    try {
      // Get the sign-in button from the GoogleSignIn instance
      return _googleSignIn!.signInButton();
    } catch (e) {
      debugPrint('Error getting web sign-in button: $e');
      return null;
    }
  }

  /// Handle sign out event
  Future<void> _handleSignOut() async {
    debugPrint('Handling sign out for user: ${_currentUser?.email}');

    // Clear user data
    await _clearUserData();

    _currentUser = null;

    _authStateController.add(null);
    notifyListeners();
  }

  /// Clear all user data (local and backend)
  Future<void> _clearUserData() async {
    try {
      // Delete tokens from backend if user exists
      if (_currentUser != null) {
        debugPrint('Deleting backend tokens for user: ${_currentUser!.email}');
        try {
          await ApiService().deleteTokens(userId: _currentUser!.id);
        } catch (e) {
          debugPrint('Failed to delete backend tokens: $e');
          // Continue with local cleanup even if backend fails
        }
      }

      // Clear local storage
      await StorageService.clearUser();

      debugPrint('User data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

  /// Get current access token
  /// Returns null if user is not authenticated or token is not available
  Future<String?> getAccessToken() async {
    if (_currentUser?.accessToken == null) {
      debugPrint('No access token available');
      return null;
    }

    // Check if token is expired
    if (_currentUser!.tokenExpiry != null &&
        DateTime.now().isAfter(_currentUser!.tokenExpiry!)) {
      debugPrint('Access token expired, attempting refresh...');
      
      // Token expired, try to refresh using silent sign-in
      final user = await silentSignIn();
      if (user != null) {
        return user.accessToken;
      }
      
      return null;
    }

    return _currentUser!.accessToken;
  }

  /// Create User object from GoogleSignInCredentials
  Future<User> _createUserFromCredentials(
    GoogleSignInCredentials credentials,
  ) async {
    // Decode ID token to extract user information
    final userInfo = _decodeIdToken(credentials.idToken);
    
    return User.fromGoogleSignIn(
      id: userInfo['sub'] ?? '',
      email: userInfo['email'] ?? '',
      displayName: userInfo['name'],
      photoUrl: userInfo['picture'],
      accessToken: credentials.accessToken,
      refreshToken: credentials.refreshToken,
      idToken: credentials.idToken,
      tokenExpiry: credentials.expiresIn,
    );
  }

  /// Decode JWT ID token to extract user claims
  /// Returns a map with user information (sub, email, name, picture, etc.)
  Map<String, dynamic> _decodeIdToken(String? idToken) {
    if (idToken == null || idToken.isEmpty) {
      return {};
    }

    try {
      // JWT format: header.payload.signature
      final parts = idToken.split('.');
      if (parts.length != 3) {
        debugPrint('Invalid ID token format');
        return {};
      }

      // Decode the payload (second part)
      final payload = parts[1];
      
      // Add padding if needed (JWT base64 doesn't use padding)
      var normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }

      // Decode base64
      final decoded = utf8.decode(base64.decode(normalized));
      final jsonData = json.decode(decoded) as Map<String, dynamic>;

      return jsonData;
    } catch (e) {
      debugPrint('Failed to decode ID token: $e');
      return {};
    }
  }

  /// Restore user from local storage
  Future<void> _restoreUserFromStorage() async {
    try {
      final storedUser = await StorageService.getStoredUser();
      if (storedUser != null) {
        // Check if session is still valid
        if (await StorageService.isSessionValid()) {
          _currentUser = storedUser;
          _authStateController.add(storedUser);
          debugPrint('Restored user from storage: ${storedUser.email}');
        } else {
          debugPrint('Stored session expired for user: ${storedUser.email}');
          await StorageService.clearUser();
        }
      } else {
        debugPrint('No stored user found');
      }
    } catch (e) {
      debugPrint('Failed to restore user from storage: $e');
      // Clear corrupted data
      await StorageService.clearUser();
    }
  }

  /// Store user and tokens in backend database
  Future<void> _storeUserInBackend(User user) async {
    try {
      // Skip if no access token
      if (user.accessToken == null || user.accessToken!.isEmpty) {
        debugPrint('No access token available, skipping backend storage');
        return;
      }

      await ApiService().storeTokens(
        userId: user.id,
        email: user.email,
        name: user.displayName,
        pictureUrl: user.photoUrl,
        accessToken: user.accessToken!,
        refreshToken: user.refreshToken,
        idToken: user.idToken,
      );
      
      debugPrint('Successfully stored user and tokens in backend: ${user.email}');
    } catch (e) {
      debugPrint('Failed to store user in backend: $e');
      // Don't throw - this shouldn't prevent local authentication
    }
  }

  /// Set loading state
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

      // Sign out from Google
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }

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

  @override
  void dispose() {
    _authStateSub?.cancel();
    _authStateController.close();
    super.dispose();
  }
}
