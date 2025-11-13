import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Local storage service for persisting user data and app state
class StorageService {
  static const String _userKey = 'current_user';
  static const String _accessTokenKey = 'access_token';
  static const String _idTokenKey = 'id_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _lastAuthKey = 'last_auth_time';

  // Google access tokens expire in ~1 hour, but we'll refresh at 50 minutes to be safe
  static const Duration _tokenValidityDuration = Duration(minutes: 50);

  // Session validity (keep user logged in for 30 days even if tokens need refresh)
  static const Duration _sessionValidityDuration = Duration(days: 30);

  static SharedPreferences? _prefs;

  /// Initialize the storage service
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Store user data locally with token expiry
  static Future<void> storeUser(User user) async {
    await initialize();

    final userJson = jsonEncode(user.toJson());
    await _prefs!.setString(_userKey, userJson);

    if (user.accessToken != null) {
      await _prefs!.setString(_accessTokenKey, user.accessToken!);
      // Set token expiry to 30 days from now
      final expiryTime = DateTime.now().add(_tokenValidityDuration);
      await _prefs!.setInt(_tokenExpiryKey, expiryTime.millisecondsSinceEpoch);
    }

    if (user.idToken != null) {
      await _prefs!.setString(_idTokenKey, user.idToken!);
    }

    // Store last authentication time
    await _prefs!.setInt(_lastAuthKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Retrieve stored user data
  static Future<User?> getStoredUser() async {
    await initialize();

    final userJson = _prefs!.getString(_userKey);
    if (userJson == null) return null;

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;

      // Get fresh tokens from separate storage
      final accessToken = _prefs!.getString(_accessTokenKey);
      final idToken = _prefs!.getString(_idTokenKey);

      // Update user with fresh tokens
      userMap['accessToken'] = accessToken;
      userMap['idToken'] = idToken;

      return User.fromJson(userMap);
    } catch (e) {
      // If parsing fails, clear corrupted data
      await clearUser();
      return null;
    }
  }

  /// Update stored access token with new expiry
  static Future<void> updateAccessToken(String accessToken) async {
    await initialize();
    await _prefs!.setString(_accessTokenKey, accessToken);

    // Update token expiry to 30 days from now
    final expiryTime = DateTime.now().add(_tokenValidityDuration);
    await _prefs!.setInt(_tokenExpiryKey, expiryTime.millisecondsSinceEpoch);

    // Also update the user object if it exists
    final userJson = _prefs!.getString(_userKey);
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        userMap['accessToken'] = accessToken;
        await _prefs!.setString(_userKey, jsonEncode(userMap));
      } catch (e) {
        // If update fails, just update the token
      }
    }
  }

  /// Check if stored tokens are still valid (not expired)
  static Future<bool> areTokensValid() async {
    await initialize();

    final expiryTimestamp = _prefs!.getInt(_tokenExpiryKey);
    if (expiryTimestamp == null) return false;

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
    return DateTime.now().isBefore(expiryTime);
  }

  /// Check if the session is still valid (user should stay logged in)
  static Future<bool> isSessionValid() async {
    await initialize();

    final lastAuthTimestamp = _prefs!.getInt(_lastAuthKey);
    if (lastAuthTimestamp == null) return false;

    final lastAuthTime = DateTime.fromMillisecondsSinceEpoch(lastAuthTimestamp);
    final sessionExpiry = lastAuthTime.add(_sessionValidityDuration);
    return DateTime.now().isBefore(sessionExpiry);
  }

  /// Get time until token expiry
  static Future<Duration?> getTimeUntilExpiry() async {
    await initialize();

    final expiryTimestamp = _prefs!.getInt(_tokenExpiryKey);
    if (expiryTimestamp == null) return null;

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
    final now = DateTime.now();

    if (now.isAfter(expiryTime)) return Duration.zero;
    return expiryTime.difference(now);
  }

  /// Check if user needs to re-authenticate (session expired)
  static Future<bool> needsReAuthentication() async {
    await initialize();

    // Check if user exists
    if (!await hasStoredUser()) return true;

    // Check if session is still valid (30 days)
    // Even if tokens expired, we can try to refresh them silently
    return !await isSessionValid();
  }

  /// Check if tokens need to be refreshed (expired but session still valid)
  static Future<bool> needsTokenRefresh() async {
    await initialize();

    // If no user, no need to refresh
    if (!await hasStoredUser()) return false;

    // If session expired, need full re-auth
    if (!await isSessionValid()) return false;

    // Check if tokens are expired
    return !await areTokensValid();
  }

  /// Clear all stored user data
  static Future<void> clearUser() async {
    await initialize();
    await _prefs!.remove(_userKey);
    await _prefs!.remove(_accessTokenKey);
    await _prefs!.remove(_idTokenKey);
    await _prefs!.remove(_tokenExpiryKey);
    await _prefs!.remove(_refreshTokenKey);
    await _prefs!.remove(_lastAuthKey);
  }

  /// Check if user data exists in storage
  static Future<bool> hasStoredUser() async {
    await initialize();
    return _prefs!.containsKey(_userKey);
  }

  /// Store arbitrary key-value data
  static Future<void> setString(String key, String value) async {
    await initialize();
    await _prefs!.setString(key, value);
  }

  /// Get stored string value
  static Future<String?> getString(String key) async {
    await initialize();
    return _prefs!.getString(key);
  }

  /// Store boolean value
  static Future<void> setBool(String key, bool value) async {
    await initialize();
    await _prefs!.setBool(key, value);
  }

  /// Get stored boolean value
  static Future<bool?> getBool(String key) async {
    await initialize();
    return _prefs!.getBool(key);
  }

  /// Remove a specific key
  static Future<void> remove(String key) async {
    await initialize();
    await _prefs!.remove(key);
  }

  /// Clear all stored data
  static Future<void> clearAll() async {
    await initialize();
    await _prefs!.clear();
  }
}
