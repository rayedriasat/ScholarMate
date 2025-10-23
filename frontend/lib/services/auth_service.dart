import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

/// Authentication service handling Google OAuth
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
      _googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? clientId : null,
        serverClientId: serverClientId,
        scopes: [
          'email',
          'profile',
          'https://www.googleapis.com/auth/drive.file',
        ],
      );

      _isInitialized = true;

      // Try silent sign-in
      await _signInSilently();

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize: $e');
      rethrow;
    }
  }

  /// Attempt silent sign-in
  Future<void> _signInSilently() async {
    try {
      final account = await _googleSignIn!.signInSilently();
      if (account != null) {
        final user = await _createUserFromAccount(account);
        _currentUser = user;
        _authStateController.add(user);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
    }
  }

  /// Sign in with Google (explicit user-initiated authentication)
  /// Opens OAuth popup on web, works in incognito mode
  Future<User> signInWithGoogle() async {
    if (!_isInitialized || _googleSignIn == null) {
      throw Exception('AuthService not initialized');
    }

    _setLoading(true);

    try {
      // signIn() opens OAuth popup on web
      final account = await _googleSignIn!.signIn();

      if (account == null) {
        throw Exception('Sign-in was canceled');
      }

      final user = await _createUserFromAccount(account);
      _currentUser = user;
      _authStateController.add(user);
      notifyListeners();

      return user;
    } catch (e) {
      debugPrint('Sign-in failed: $e');

      // Check if it's a People API error
      if (e.toString().contains('People API')) {
        throw Exception(
          'Please enable the People API in your Google Cloud Console:\n'
          'https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=325415234543',
        );
      }

      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    if (!_isInitialized || _googleSignIn == null) {
      debugPrint('AuthService not initialized');
      return;
    }

    _setLoading(true);

    try {
      await _googleSignIn!.signOut();
      _currentUser = null;
      _authStateController.add(null);
      notifyListeners();
    } catch (e) {
      debugPrint('Sign-out failed: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get current access token
  /// Returns null if user is not authenticated or token is not available
  Future<String?> getAccessToken() async {
    if (_currentUser == null) return null;

    try {
      final account = _googleSignIn!.currentUser;
      if (account == null) return null;

      final auth = await account.authentication;
      return auth.accessToken;
    } catch (e) {
      debugPrint('Failed to get access token: $e');
      return null;
    }
  }

  /// Refresh the access token
  /// Returns the new access token or null if refresh failed
  Future<String?> refreshToken() async {
    if (_currentUser == null) return null;

    try {
      final account = _googleSignIn!.currentUser;
      if (account == null) return null;

      // Clear cached tokens
      await account.clearAuthCache();

      // Get fresh authentication
      final auth = await account.authentication;

      if (auth.accessToken != null) {
        // Update the current user with the new token
        _currentUser = _currentUser!.copyWith(
          accessToken: auth.accessToken!,
          idToken: auth.idToken,
        );
        notifyListeners();
        return auth.accessToken;
      }

      return null;
    } catch (e) {
      debugPrint('Failed to refresh token: $e');
      return null;
    }
  }

  /// Request additional scopes
  /// Must be called from user interaction on some platforms
  Future<void> requestScopes(List<String> scopes) async {
    if (!_isInitialized || _googleSignIn == null) {
      throw Exception('AuthService not initialized');
    }

    try {
      final account = _googleSignIn!.currentUser;
      if (account == null) {
        throw Exception('No user signed in');
      }

      await _googleSignIn!.requestScopes(scopes);
    } catch (e) {
      debugPrint('Failed to request scopes: $e');
      rethrow;
    }
  }

  /// Create User object from GoogleSignInAccount
  Future<User> _createUserFromAccount(GoogleSignInAccount account) async {
    // Get authentication tokens
    final auth = await account.authentication;

    return User.fromGoogleSignIn(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      accessToken: auth.accessToken ?? '',
      idToken: auth.idToken,
    );
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateController.close();
    super.dispose();
  }
}
