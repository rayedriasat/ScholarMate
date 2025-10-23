import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

/// Authentication service handling Google OAuth (google_sign_in ^7.x)
class AuthService extends ChangeNotifier {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Google Sign-In account for the current session
  GoogleSignInAccount? _account;

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

  // Scopes required by the app (request Drive file access when needed)
  static const List<String> _scopes = <String>[
    'https://www.googleapis.com/auth/drive.file',
  ];

  StreamSubscription<GoogleSignInAuthenticationEvent>? _authEventsSub;

  /// Initialize the Google Sign-In singleton
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
      // Initialize plugin
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb ? clientId : null,
        serverClientId: kIsWeb ? null : serverClientId,
      );

      // Listen to authentication events
      _authEventsSub = GoogleSignIn.instance.authenticationEvents
          .listen(_handleAuthEvent, onError: _handleAuthError);

      _isInitialized = true;

      // Try lightweight authentication (may or may not return a Future)
      GoogleSignIn.instance.attemptLightweightAuthentication();

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize: $e');
      rethrow;
    }
  }

  void _handleAuthEvent(GoogleSignInAuthenticationEvent event) async {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn():
        _account = event.user;
        final user = await _createUserFromAccount(event.user);
        _currentUser = user;
        _authStateController.add(user);
        notifyListeners();
      case GoogleSignInAuthenticationEventSignOut():
        _account = null;
        _currentUser = null;
        _authStateController.add(null);
        notifyListeners();
    }
  }

  void _handleAuthError(Object error) {
    debugPrint('Authentication error: $error');
  }

  /// Sign in with Google (explicit user-initiated authentication)
  Future<User> signInWithGoogle() async {
    if (!_isInitialized) {
      throw Exception('AuthService not initialized');
    }

    _setLoading(true);

    try {
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw UnsupportedError(
            'Explicit authenticate() is not supported on this platform');
      }

      // Hint to combine auth + authorization when supported
      final account = await GoogleSignIn.instance
          .authenticate(scopeHint: _scopes);

      // Try to get tokens for required scopes; prompt if necessary
      final authz = await account.authorizationClient
          .authorizationForScopes(_scopes);
      final accessToken = authz?.accessToken ??
          (await account.authorizationClient.authorizeScopes(_scopes))
              .accessToken;

      final user = User.fromGoogleSignIn(
        id: account.id,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        accessToken: accessToken,
        idToken: account.authentication.idToken,
      );

      _account = account;
      _currentUser = user;
      _authStateController.add(user);
      notifyListeners();
      return user;
    } on GoogleSignInException catch (e) {
      debugPrint('Sign-in failed: ${e.code} ${e.description}');
      rethrow;
    } catch (e) {
      debugPrint('Sign-in failed: $e');
      rethrow;
    } finally {
      _setLoading(false);
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
      await GoogleSignIn.instance.signOut();
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
    if (_account == null) return null;
    try {
      final authz = await _account!.authorizationClient
          .authorizationForScopes(_scopes);
      return authz?.accessToken;
    } catch (e) {
      debugPrint('Failed to get access token: $e');
      return null;
    }
  }

  /// Refresh the access token (non-interactive if possible)
  Future<String?> refreshToken() async {
    if (_account == null) return null;
    try {
      final existing = await _account!.authorizationClient
          .authorizationForScopes(_scopes);
      if (existing != null) {
        // Invalidate cached token then re-read
        await _account!.authorizationClient
            .clearAuthorizationToken(accessToken: existing.accessToken);
      }
      final refreshed = await _account!.authorizationClient
          .authorizationForScopes(_scopes);
      if (refreshed != null) {
        _currentUser = _currentUser?.copyWith(accessToken: refreshed.accessToken);
        notifyListeners();
        return refreshed.accessToken;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to refresh token: $e');
      return null;
    }
  }

  /// Create User object from GoogleSignInAccount
  Future<User> _createUserFromAccount(GoogleSignInAccount account) async {
    // idToken is part of authentication; access token requires authorization
    final idToken = account.authentication.idToken;
    final authz = await account.authorizationClient
        .authorizationForScopes(_scopes);
    return User.fromGoogleSignIn(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      accessToken: authz?.accessToken,
      idToken: idToken,
    );
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _authEventsSub?.cancel();
    _authStateController.close();
    super.dispose();
  }
}
