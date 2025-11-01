import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import 'storage_service.dart';
import 'api_service.dart';

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
  // Using drive scope to access all files in ScholarMate folder (including manually uploaded ones)
  static const List<String> _scopes = <String>[
    'https://www.googleapis.com/auth/drive',
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
      // Initialize storage service
      await StorageService.initialize();

      // Try to restore user from local storage
      await _restoreUserFromStorage();

      // Initialize plugin
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb ? clientId : null,
        serverClientId: kIsWeb ? null : serverClientId,
      );

      // Listen to authentication events
      _authEventsSub = GoogleSignIn.instance.authenticationEvents.listen(
        _handleAuthEvent,
        onError: _handleAuthError,
      );

      _isInitialized = true;

      // Only attempt lightweight authentication if we don't have valid tokens AND no current user
      if (_currentUser == null &&
          await StorageService.needsReAuthentication()) {
        debugPrint(
          'No valid tokens found, attempting lightweight authentication',
        );
        GoogleSignIn.instance.attemptLightweightAuthentication();
      } else {
        debugPrint(
          'Valid tokens found or user already restored, skipping lightweight authentication',
        );
      }

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
        try {
          final user = await _createUserFromAccount(event.user);
          _currentUser = user;

          // Store user data locally
          await StorageService.storeUser(user);

          // Store user and tokens in backend database
          await _storeUserInBackend(user);

          _authStateController.add(user);
          notifyListeners();
        } catch (e) {
          debugPrint('Error creating user from account: $e');
          // Don't update state if we can't get proper user data
        }
      case GoogleSignInAuthenticationEventSignOut():
        _account = null;
        _currentUser = null;

        // Clear stored user data
        await StorageService.clearUser();

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
          'Explicit authenticate() is not supported on this platform',
        );
      }

      // Use authenticate with scopeHint to get both auth and authorization in one step
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: _scopes,
      );

      // Get authorization - this should be available after authenticate with scopeHint
      final authz = await account.authorizationClient.authorizationForScopes(
        _scopes,
      );

      String? accessToken = authz?.accessToken;

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

      // Store user data locally
      await StorageService.storeUser(user);

      // Store user and tokens in backend database
      await _storeUserInBackend(user);

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

      // Clear stored user data
      await StorageService.clearUser();
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
    // First check if we have a valid cached token
    if (_currentUser?.accessToken != null &&
        await StorageService.areTokensValid()) {
      debugPrint('Using cached access token');
      return _currentUser!.accessToken;
    }

    // If no account, return null
    if (_account == null) {
      debugPrint('No Google account available');
      return null;
    }

    try {
      // Try to get existing authorization without prompting
      var authz = await _account!.authorizationClient.authorizationForScopes(
        _scopes,
      );

      // If no authorization exists, try to authorize (may prompt user on web)
      if (authz == null) {
        debugPrint('No existing authorization, requesting scopes...');
        authz = await _account!.authorizationClient.authorizeScopes(_scopes);
      }

      final token = authz.accessToken;
      if (_currentUser != null) {
        // Update current user with fresh token
        _currentUser = _currentUser!.copyWith(accessToken: token);

        // Update stored token with new expiry
        await StorageService.updateAccessToken(token);

        debugPrint('Updated access token and stored with new expiry');
        notifyListeners();
      }

      return token;
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
        await _account!.authorizationClient.clearAuthorizationToken(
          accessToken: existing.accessToken,
        );
      }
      final refreshed = await _account!.authorizationClient
          .authorizationForScopes(_scopes);
      if (refreshed != null) {
        _currentUser = _currentUser!.copyWith(
          accessToken: refreshed.accessToken,
        );

        // Update stored token
        await StorageService.updateAccessToken(refreshed.accessToken);

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

    // Try to get authorization, but don't prompt for additional scopes here
    // The access token will be obtained when needed via getAccessToken()
    String? accessToken;
    try {
      final authz = await account.authorizationClient.authorizationForScopes(
        _scopes,
      );
      accessToken = authz?.accessToken;
    } catch (e) {
      debugPrint('Could not get access token during user creation: $e');
      // Continue without access token - it can be obtained later
    }

    return User.fromGoogleSignIn(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      accessToken: accessToken,
      idToken: idToken,
    );
  }

  /// Restore user from local storage
  Future<void> _restoreUserFromStorage() async {
    try {
      final storedUser = await StorageService.getStoredUser();
      if (storedUser != null) {
        _currentUser = storedUser;
        _authStateController.add(storedUser);
        debugPrint('Restored user from storage: ${storedUser.email}');
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
      await ApiService().storeTokens(
        userId: user.id,
        email: user.email,
        name: user.displayName,
        pictureUrl: user.photoUrl,
        accessToken: user.accessToken ?? '',
        idToken: user.idToken,
      );
      debugPrint('Successfully stored user in backend: ${user.email}');
    } catch (e) {
      debugPrint('Failed to store user in backend: $e');
      // Don't throw - this shouldn't prevent local authentication
      // The user can still use the app offline, and we'll retry on next API call
    }
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
