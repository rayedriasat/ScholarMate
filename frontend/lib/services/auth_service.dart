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
      _googleSignIn = GoogleSignIn.instance;

      await _googleSignIn!.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );

      // Listen to authentication events
      _googleSignIn!.authenticationEvents.listen(
        _handleAuthenticationEvent,
        onError: _handleAuthenticationError,
      );

      _isInitialized = true;

      // Attempt lightweight authentication (may show UI on some platforms)
      attemptLightweightAuthentication();

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize: $e');
      rethrow;
    }
  }

  /// Attempt lightweight authentication (previously signInSilently)
  /// May show UI on some platforms (e.g., account selection on Android)
  void attemptLightweightAuthentication() {
    if (!_isInitialized || _googleSignIn == null) {
      debugPrint('AuthService not initialized');
      return;
    }

    // This may or may not return a Future depending on the platform
    // We handle the result via the authenticationEvents stream
    _googleSignIn!.attemptLightweightAuthentication();
  }

  /// Sign in with Google (explicit user-initiated authentication)
  /// On web, this triggers the FedCM prompt. On other platforms, uses authenticate()
  Future<User> signInWithGoogle() async {
    if (!_isInitialized || _googleSignIn == null) {
      throw Exception('AuthService not initialized');
    }

    _setLoading(true);

    try {
      // On web, authenticate() is not supported, so we just trigger the prompt
      // The actual sign-in happens via the authenticationEvents stream
      if (kIsWeb || !_googleSignIn!.supportsAuthenticate()) {
        // On web, we need to wait for the authentication event
        // Create a completer to wait for the result
        final completer = Completer<User>();

        // Listen for authentication events (only once)
        late StreamSubscription subscription;
        subscription = authStateChanges.listen((user) {
          if (user != null && !completer.isCompleted) {
            completer.complete(user);
            subscription.cancel();
          }
        });

        // Trigger the FedCM prompt
        attemptLightweightAuthentication();

        // Wait for authentication with timeout
        try {
          final user = await completer.future.timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              subscription.cancel();
              throw Exception(
                'Sign-in timed out. Please check your browser settings and allow third-party sign-in for this site.',
              );
            },
          );
          return user;
        } catch (e) {
          subscription.cancel();
          rethrow;
        }
      }

      // On non-web platforms, use authenticate()
      final account = await _googleSignIn!.authenticate(
        scopeHint: ['https://www.googleapis.com/auth/drive.file'],
      );

      // Get authentication tokens
      final auth = await account.authorizationClient.authorizationForScopes([
        'https://www.googleapis.com/auth/drive.file',
      ]);

      final user = await _createUserFromAccount(account, auth);
      _currentUser = user;
      _authStateController.add(user);
      notifyListeners();

      return user;
    } catch (e) {
      debugPrint('Sign-in failed: $e');
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
    if (_currentUser == null || _googleSignIn == null) return null;

    try {
      // Get authorization for the required scopes
      final authClient = _googleSignIn!.authorizationClient;
      final auth = await authClient.authorizationForScopes([
        'https://www.googleapis.com/auth/drive.file',
      ]);

      return auth?.accessToken;
    } catch (e) {
      debugPrint('Failed to get access token: $e');
      return null;
    }
  }

  /// Refresh the access token
  /// Returns the new access token or null if refresh failed
  Future<String?> refreshToken() async {
    if (_currentUser == null || _googleSignIn == null) return null;

    try {
      final authClient = _googleSignIn!.authorizationClient;

      // Clear the cached authorization token to force a refresh
      if (_currentUser?.accessToken != null) {
        await authClient.clearAuthorizationToken(
          accessToken: _currentUser!.accessToken!,
        );
      }

      // Request authorization again (this will get a fresh token)
      final auth = await authClient.authorizationForScopes([
        'https://www.googleapis.com/auth/drive.file',
      ]);

      if (auth != null) {
        // Update the current user with the new token
        _currentUser = _currentUser!.copyWith(accessToken: auth.accessToken);
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
      final authClient = _googleSignIn!.authorizationClient;
      await authClient.authorizeScopes(scopes);
    } catch (e) {
      debugPrint('Failed to authorize scopes: $e');
      rethrow;
    }
  }

  /// Check if specific scopes are already authorized
  Future<bool> hasScopes(List<String> scopes) async {
    if (_currentUser == null || _googleSignIn == null) return false;

    try {
      final authClient = _googleSignIn!.authorizationClient;
      final auth = await authClient.authorizationForScopes(scopes);
      return auth != null;
    } catch (e) {
      debugPrint('Failed to check scopes: $e');
      return false;
    }
  }

  /// Handle authentication events from the stream
  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) async {
    // Check if it's a sign-in or sign-out event
    if (event is GoogleSignInAuthenticationEventSignIn) {
      final account = event.user;

      try {
        // Get authorization for the required scopes
        final auth = await account.authorizationClient.authorizationForScopes([
          'https://www.googleapis.com/auth/drive.file',
        ]);

        final user = await _createUserFromAccount(account, auth);
        _currentUser = user;
        _authStateController.add(user);
        notifyListeners();
      } catch (e) {
        debugPrint('Error handling sign-in event: $e');
      }
    } else if (event is GoogleSignInAuthenticationEventSignOut) {
      _currentUser = null;
      _authStateController.add(null);
      notifyListeners();
    }
  }

  /// Handle authentication errors from the stream
  void _handleAuthenticationError(Object error) {
    debugPrint('Authentication error: $error');
    debugPrint('Error type: ${error.runtimeType}');
    debugPrint('Error details: ${error.toString()}');
    _currentUser = null;
    _authStateController.add(null);
    notifyListeners();
  }

  /// Create User object from GoogleSignInAccount
  Future<User> _createUserFromAccount(
    GoogleSignInAccount account,
    GoogleSignInClientAuthorization? auth,
  ) async {
    // Get ID token
    final authentication = account.authentication;

    return User.fromGoogleSignIn(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      accessToken: auth?.accessToken ?? '',
      idToken: authentication.idToken,
    );
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Check if the platform supports the authenticate() method
  bool supportsAuthenticate() {
    return _googleSignIn?.supportsAuthenticate() ?? false;
  }

  @override
  void dispose() {
    _authStateController.close();
    super.dispose();
  }
}
