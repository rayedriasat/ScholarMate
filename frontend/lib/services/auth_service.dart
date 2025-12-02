import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'storage_service.dart';
import 'config_service.dart';

/// Authentication service using google_sign_in_all_platforms
///
/// Key design principles (from package documentation):
/// 1. Use silentSignIn() on app startup to restore sessions
/// 2. Use authenticatedClient for API calls - it handles token refresh automatically
/// 3. The package manages refresh tokens internally via platform secure storage
/// 4. Don't manually manage access tokens - let the package handle it
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  GoogleSignIn? _googleSignIn;
  User? _currentUser;
  User? get currentUser => _currentUser;

  final _authStateController = StreamController<User?>.broadcast();
  Stream<User?> get authStateChanges => _authStateController.stream;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<GoogleSignInCredentials?>? _authStateSub;

  // Required scopes for Google Drive access
  static const List<String> _scopes = <String>[
    'openid',
    'profile',
    'email',
    'https://www.googleapis.com/auth/drive.file',
  ];

  /// Initialize the authentication service
  /// Must be called once before any other methods
  Future<void> initialize({
    required String clientId,
    String? serverClientId,
  }) async {
    if (_isInitialized) {
      debugPrint('AuthService already initialized');
      return;
    }

    try {
      await StorageService.initialize();

      final configService = ConfigService();
      final clientSecret = configService.googleClientSecret;

      debugPrint('Initializing GoogleSignIn');
      debugPrint('Platform: ${defaultTargetPlatform.name}, isWeb: $kIsWeb');

      // Token persistence callbacks for session restoration across app restarts
      // These are especially important on mobile where google_sign_in doesn't persist
      _googleSignIn = GoogleSignIn(
        params: GoogleSignInParams(
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: _scopes,
          redirectPort: 3000,
          timeout: const Duration(minutes: 2),
          // Token persistence callbacks - enable session restoration
          saveAccessToken: _saveAccessToken,
          retrieveAccessToken: _retrieveAccessToken,
          deleteAccessToken: _deleteAccessToken,
        ),
      );

      // Subscribe to auth state changes
      _authStateSub = _googleSignIn!.authenticationState.listen(
        _handleAuthStateChange,
        onError: (error) => debugPrint('Auth error: $error'),
      );

      _isInitialized = true;
      notifyListeners();

      // Attempt silent sign-in to restore previous session
      // This is the recommended approach from the package docs
      debugPrint('Attempting silent sign-in on startup...');
      await silentSignIn();

      debugPrint('AuthService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AuthService: $e');
      rethrow;
    }
  }

  /// Save access token to persistent storage (for mobile platforms)
  /// The package passes the token as a JSON string
  Future<void> _saveAccessToken(String tokenJson) async {
    debugPrint('Saving access token to persistent storage');
    try {
      await StorageService.setString('google_access_token', tokenJson);
      debugPrint('Access token saved successfully');
    } catch (e) {
      debugPrint('Failed to save access token: $e');
    }
  }

  /// Retrieve access token from persistent storage (for mobile platforms)
  /// Returns the token as a JSON string
  Future<String?> _retrieveAccessToken() async {
    debugPrint('Retrieving access token from persistent storage');
    try {
      final tokenJson = await StorageService.getString('google_access_token');
      if (tokenJson == null) {
        debugPrint('No stored access token found');
        return null;
      }
      debugPrint('Retrieved stored access token');
      return tokenJson;
    } catch (e) {
      debugPrint('Failed to retrieve access token: $e');
      return null;
    }
  }

  /// Delete access token from persistent storage (for mobile platforms)
  Future<void> _deleteAccessToken() async {
    debugPrint('Deleting access token from persistent storage');
    try {
      await StorageService.remove('google_access_token');
      debugPrint('Access token deleted successfully');
    } catch (e) {
      debugPrint('Failed to delete access token: $e');
    }
  }

  /// Handle authentication state changes from the package
  void _handleAuthStateChange(GoogleSignInCredentials? credentials) async {
    debugPrint(
      'Auth state changed: ${credentials != null ? "signed in" : "signed out"}',
    );

    if (credentials == null) {
      await _handleSignOut();
      return;
    }

    try {
      final user = _createUserFromCredentials(credentials);

      if (_currentUser != null && _currentUser!.id != user.id) {
        debugPrint('Different user signing in, clearing old data');
        await StorageService.clearUser();
      }

      _currentUser = user;
      await StorageService.storeUser(user);

      _authStateController.add(user);
      notifyListeners();

      debugPrint('User authenticated: ${user.email}');
    } catch (e) {
      debugPrint('Error handling auth state change: $e');
    }
  }

  /// Sign in with Google (user-initiated)
  Future<User> signInWithGoogle() async {
    if (!_isInitialized) {
      throw Exception('AuthService not initialized');
    }

    _setLoading(true);

    try {
      debugPrint('Starting Google sign-in...');

      // The signIn() method tries lightweightSignIn first, then signInOnline
      final credentials = await _googleSignIn!.signIn();

      if (credentials == null) {
        throw Exception('Sign-in was cancelled or failed');
      }

      final user = _createUserFromCredentials(credentials);
      _currentUser = user;
      await StorageService.storeUser(user);

      _authStateController.add(user);
      notifyListeners();

      debugPrint('Sign-in completed for: ${user.email}');
      return user;
    } catch (e) {
      debugPrint('Sign-in failed: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Silent sign-in to restore previous session
  /// Recommended to call on app startup
  Future<User?> silentSignIn() async {
    if (!_isInitialized) {
      debugPrint('AuthService not initialized');
      return null;
    }

    try {
      debugPrint('Attempting silent sign-in...');

      // Check if we have a stored user with valid session
      final storedUser = await StorageService.getStoredUser();
      if (storedUser != null && await StorageService.isSessionValid()) {
        debugPrint('Found stored user session: ${storedUser.email}');
      }

      // Try silent sign-in first (uses stored credentials via our callbacks)
      var credentials = await _googleSignIn!.silentSignIn();

      // If silent fails, try lightweight (official recommendation)
      if (credentials == null) {
        debugPrint('Silent sign-in failed, trying lightweight...');
        credentials = await _googleSignIn!.lightweightSignIn();
      }

      if (credentials == null) {
        debugPrint('No credentials available - user needs to sign in');
        return null;
      }

      if (credentials.accessToken.isEmpty) {
        debugPrint('Credentials have no access token - session may be revoked');
        return null;
      }

      final user = _createUserFromCredentials(credentials);
      _currentUser = user;
      await StorageService.storeUser(user);

      _authStateController.add(user);
      notifyListeners();

      debugPrint('Silent sign-in successful: ${user.email}');
      return user;
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
      return null;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    if (!_isInitialized) return;

    _setLoading(true);
    try {
      debugPrint('Signing out: ${_currentUser?.email}');
      await _googleSignIn!.signOut();
    } catch (e) {
      debugPrint('Sign-out error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get the authenticated HTTP client for Google API calls
  /// This is the KEY method - the client handles token refresh automatically!
  Future<http.Client?> getAuthenticatedClient() async {
    if (!_isInitialized || _googleSignIn == null) {
      debugPrint('AuthService not initialized');
      return null;
    }

    try {
      // The package's authenticatedClient automatically:
      // 1. Validates token expiration
      // 2. Refreshes tokens using stored refresh tokens
      // 3. Signs out on unrecoverable failures
      final client = await _googleSignIn!.authenticatedClient;

      if (client == null) {
        debugPrint(
          'Failed to get authenticated client - trying to restore session',
        );

        // Try to restore session
        final restored = await silentSignIn();
        if (restored != null) {
          return await _googleSignIn!.authenticatedClient;
        }
      }

      return client;
    } catch (e) {
      debugPrint('Error getting authenticated client: $e');
      return null;
    }
  }

  /// Get web sign-in button (web platform only)
  Widget? getWebSignInButton() {
    if (!kIsWeb || !_isInitialized || _googleSignIn == null) {
      return null;
    }
    try {
      return _googleSignIn!.signInButton();
    } catch (e) {
      debugPrint('Error getting web sign-in button: $e');
      return null;
    }
  }

  /// Handle sign out
  Future<void> _handleSignOut() async {
    debugPrint('Handling sign out');
    await StorageService.clearUser();
    _currentUser = null;
    _authStateController.add(null);
    notifyListeners();
  }

  /// Create User from credentials
  User _createUserFromCredentials(GoogleSignInCredentials credentials) {
    final userInfo = _decodeIdToken(credentials.idToken);

    // Use the actual expiresIn from credentials (v2.0.0 feature)
    // Fall back to ID token exp claim, then default to 1 hour
    DateTime tokenExpiry;
    if (credentials.expiresIn != null) {
      tokenExpiry = credentials.expiresIn!;
      debugPrint('Using credentials.expiresIn: $tokenExpiry');
    } else if (userInfo.containsKey('exp') && userInfo['exp'] is int) {
      tokenExpiry = DateTime.fromMillisecondsSinceEpoch(userInfo['exp'] * 1000);
      debugPrint('Using ID token exp: $tokenExpiry');
    } else {
      tokenExpiry = DateTime.now().add(const Duration(hours: 1));
      debugPrint('Using default 1 hour expiry: $tokenExpiry');
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

  /// Decode JWT ID token
  Map<String, dynamic> _decodeIdToken(String? idToken) {
    if (idToken == null || idToken.isEmpty) return {};

    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return {};

      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      return json.decode(utf8.decode(base64.decode(payload)));
    } catch (e) {
      debugPrint('Failed to decode ID token: $e');
      return {};
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Get current access token for API calls that need it directly
  /// Note: For Google Drive API calls, prefer using getAuthenticatedClient()
  /// which handles token refresh automatically.
  Future<String?> getAccessToken() async {
    // If we have a current user with a token, return it
    if (_currentUser?.accessToken != null) {
      return _currentUser!.accessToken;
    }

    // Try to restore session
    final user = await silentSignIn();
    return user?.accessToken;
  }

  /// Force logout and clear all data
  Future<void> forceLogout() async {
    debugPrint('Force logout initiated');
    _setLoading(true);

    try {
      await StorageService.clearUser();
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
      _currentUser = null;
      _authStateController.add(null);
      notifyListeners();
    } catch (e) {
      debugPrint('Error during force logout: $e');
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
