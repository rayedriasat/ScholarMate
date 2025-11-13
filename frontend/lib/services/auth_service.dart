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
  Timer? _tokenRefreshTimer;

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

      // Check if we need to refresh tokens or re-authenticate
      if (_currentUser != null) {
        // User restored from storage, check if tokens need refresh
        if (await StorageService.needsTokenRefresh()) {
          debugPrint('Tokens expired, attempting silent refresh...');
          await _silentTokenRefresh();
        } else {
          debugPrint('User restored with valid tokens');
        }
        // Start periodic token refresh
        _startTokenRefreshTimer();
      } else if (!await StorageService.needsReAuthentication()) {
        // Session still valid but user not restored, try lightweight auth
        debugPrint('Session valid, attempting lightweight authentication');
        GoogleSignIn.instance.attemptLightweightAuthentication();
      } else {
        debugPrint('No valid session, user needs to sign in');
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

          // Check if this is a different user than the current one
          if (_currentUser != null && _currentUser!.id != user.id) {
            debugPrint('Different user signing in, clearing old data');
            await _clearUserData();
          }

          _currentUser = user;

          // Store user data locally
          await StorageService.storeUser(user);

          // Store user and tokens in backend database
          await _storeUserInBackend(user);

          // Start token refresh timer if not already running
          if (_tokenRefreshTimer == null) {
            _startTokenRefreshTimer();
          }

          _authStateController.add(user);
          notifyListeners();
        } catch (e) {
          debugPrint('Error creating user from account: $e');
          // Don't update state if we can't get proper user data
        }
      case GoogleSignInAuthenticationEventSignOut():
        await _handleSignOut();
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
      // Clear any existing user data first
      if (_currentUser != null) {
        debugPrint('Clearing existing user data before new sign-in');
        await _clearUserData();
      }

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

      // Start token refresh timer
      _startTokenRefreshTimer();

      notifyListeners();

      debugPrint('Sign-in completed successfully for user: ${user.email}');
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

  /// Handle sign out event
  Future<void> _handleSignOut() async {
    debugPrint('Handling sign out for user: ${_currentUser?.email}');

    // Stop token refresh timer
    _stopTokenRefreshTimer();

    // Clear user data
    await _clearUserData();

    _account = null;
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
  /// Automatically refreshes token if expired
  Future<String?> getAccessToken() async {
    // Check if tokens need refresh
    if (await StorageService.needsTokenRefresh()) {
      debugPrint('Token expired, refreshing before use...');
      final refreshedToken = await refreshToken();
      if (refreshedToken != null) {
        return refreshedToken;
      }
      // If refresh failed, continue to try getting token normally
    }

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
    if (_account == null) {
      debugPrint('No account available for token refresh');
      return null;
    }

    try {
      debugPrint('Refreshing access token...');

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
        final newToken = refreshed.accessToken;

        if (_currentUser != null) {
          // Update current user with fresh token
          _currentUser = _currentUser!.copyWith(accessToken: newToken);

          // Update stored token with new expiry
          await StorageService.updateAccessToken(newToken);

          // Update backend with new token
          await _storeUserInBackend(_currentUser!);

          debugPrint('Token refreshed successfully');
          notifyListeners();
        }

        return newToken;
      }

      debugPrint('Failed to get refreshed token');
      return null;
    } catch (e) {
      debugPrint('Failed to refresh token: $e');
      return null;
    }
  }

  /// Silent token refresh (no user interaction)
  Future<void> _silentTokenRefresh() async {
    try {
      final newToken = await refreshToken();
      if (newToken == null) {
        debugPrint('Silent token refresh failed, will retry later');
      } else {
        debugPrint('Silent token refresh successful');
      }
    } catch (e) {
      debugPrint('Error during silent token refresh: $e');
    }
  }

  /// Start periodic token refresh timer
  void _startTokenRefreshTimer() {
    // Cancel existing timer if any
    _tokenRefreshTimer?.cancel();

    // Check and refresh tokens every 45 minutes
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 45), (_) async {
      if (_currentUser != null) {
        debugPrint('Periodic token refresh check...');
        if (await StorageService.needsTokenRefresh()) {
          await _silentTokenRefresh();
        } else {
          debugPrint('Tokens still valid, no refresh needed');
        }
      }
    });

    debugPrint('Token refresh timer started');
  }

  /// Stop token refresh timer
  void _stopTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
    debugPrint('Token refresh timer stopped');
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
        // Verify tokens are still valid
        if (await StorageService.areTokensValid()) {
          _currentUser = storedUser;
          _authStateController.add(storedUser);
          debugPrint('Restored user from storage: ${storedUser.email}');
        } else {
          debugPrint('Stored tokens expired for user: ${storedUser.email}');
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
      // Get fresh access token if not available
      String? accessToken = user.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint(
          'No access token in user object, attempting to get fresh token',
        );
        accessToken = await getAccessToken();
      }

      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('No access token available for user: ${user.email}');
        // Still create user record without tokens
        try {
          await ApiService().storeTokens(
            userId: user.id,
            email: user.email,
            name: user.displayName,
            pictureUrl: user.photoUrl,
            accessToken:
                'placeholder', // Will be rejected by backend, but user record will be created
            idToken: user.idToken,
          );
        } catch (e) {
          debugPrint('Expected error creating user without valid token: $e');
        }
        return;
      }

      await ApiService().storeTokens(
        userId: user.id,
        email: user.email,
        name: user.displayName,
        pictureUrl: user.photoUrl,
        accessToken: accessToken,
        idToken: user.idToken,
      );
      debugPrint(
        'Successfully stored user and tokens in backend: ${user.email}',
      );
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

  /// Force complete logout and clear all data
  Future<void> forceLogout() async {
    debugPrint('Force logout initiated');
    _setLoading(true);

    try {
      // Clear user data first
      await _clearUserData();

      // Sign out from Google
      await GoogleSignIn.instance.signOut();

      // Disconnect to ensure complete logout
      await GoogleSignIn.instance.disconnect();

      _account = null;
      _currentUser = null;

      _authStateController.add(null);
      notifyListeners();

      debugPrint('Force logout completed');
    } catch (e) {
      debugPrint('Error during force logout: $e');
      // Even if there's an error, clear local state
      _account = null;
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
    _authEventsSub?.cancel();
    _tokenRefreshTimer?.cancel();
    _authStateController.close();
    super.dispose();
  }
}
