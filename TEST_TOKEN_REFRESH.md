# Testing Token Refresh & Session Persistence

## Quick Test Guide

### 1. Test Fresh Sign-In

```bash
# Run the app
cd frontend
flutter run -d chrome
```

**Steps:**
1. Sign in with Google
2. Check browser console for:
   ```
   ✓ "Sign-in completed successfully"
   ✓ "Token refresh timer started"
   ```
3. Check SharedPreferences (browser DevTools → Application → Local Storage)
   - Should see `flutter.current_user`
   - Should see `flutter.access_token`
   - Should see `flutter.token_expiry`
   - Should see `flutter.last_auth_time`

**Expected Result:** User signed in, timer started, tokens stored

---

### 2. Test Token Auto-Refresh

**Option A: Wait 50 minutes**
1. Keep app open for 50+ minutes
2. Make any API call (e.g., open a file)
3. Check console for: `"Token expired, refreshing before use..."`

**Option B: Force expiry (for quick testing)**

Add this temporary method to `auth_service.dart`:
```dart
// TESTING ONLY - Remove after testing
Future<void> forceTokenExpiry() async {
  await StorageService.initialize();
  final prefs = await SharedPreferences.getInstance();
  // Set expiry to 1 minute ago
  await prefs.setInt('token_expiry', 
    DateTime.now().subtract(Duration(minutes: 1)).millisecondsSinceEpoch
  );
  debugPrint('Token expiry forced for testing');
}
```

Then in your app:
```dart
// Force expiry
await context.read<AuthService>().forceTokenExpiry();

// Try to get token (should auto-refresh)
final token = await context.read<AuthService>().getAccessToken();
```

**Expected Result:** Token refreshes automatically, no sign-out

---

### 3. Test Periodic Refresh

**Steps:**
1. Sign in
2. Keep app open for 90+ minutes
3. Watch console at 45-minute mark

**Expected Logs:**
```
[45 min] "Periodic token refresh check..."
[45 min] "Tokens expired, attempting silent refresh..."
[45 min] "Token refreshed successfully"
[90 min] "Periodic token refresh check..."
[90 min] "Tokens still valid, no refresh needed"
```

**Expected Result:** Timer fires every 45 minutes, refreshes when needed

---

### 4. Test App Restart (Session Persistence)

**Steps:**
1. Sign in
2. Close browser tab
3. Reopen app (same browser)

**Expected Logs:**
```
✓ "Restored user from storage: [email]"
✓ "User restored with valid tokens"
✓ "Token refresh timer started"
```

**Expected Result:** User automatically signed in, no re-authentication needed

---

### 5. Test App Restart with Expired Token

**Steps:**
1. Sign in
2. Force token expiry (see Option B above)
3. Close and reopen app

**Expected Logs:**
```
✓ "Restored user from storage: [email]"
✓ "Tokens expired, attempting silent refresh..."
✓ "Silent token refresh successful"
✓ "Token refresh timer started"
```

**Expected Result:** User signed in, token refreshed silently

---

### 6. Test Session Expiry (30 days)

**Option A: Wait 30 days** (not practical)

**Option B: Force session expiry**

Add temporary method:
```dart
// TESTING ONLY
Future<void> forceSessionExpiry() async {
  await StorageService.initialize();
  final prefs = await SharedPreferences.getInstance();
  // Set last auth to 31 days ago
  await prefs.setInt('last_auth_time', 
    DateTime.now().subtract(Duration(days: 31)).millisecondsSinceEpoch
  );
  debugPrint('Session expiry forced for testing');
}
```

**Steps:**
1. Sign in
2. Force session expiry
3. Close and reopen app

**Expected Result:** User required to sign in again (session expired)

---

## Automated Test Script

Create `frontend/test/auth_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholarmate/services/storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.initialize();
  });

  group('Token Expiry Tests', () {
    test('Fresh tokens should be valid', () async {
      // Store token with current time
      await StorageService.updateAccessToken('test_token');
      
      final valid = await StorageService.areTokensValid();
      expect(valid, true);
    });

    test('Expired tokens should be invalid', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Set expiry to 1 hour ago
      await prefs.setInt('token_expiry',
        DateTime.now().subtract(Duration(hours: 1)).millisecondsSinceEpoch
      );
      
      final valid = await StorageService.areTokensValid();
      expect(valid, false);
    });

    test('Should need refresh when tokens expired', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Set valid session but expired token
      await prefs.setInt('last_auth_time',
        DateTime.now().millisecondsSinceEpoch
      );
      await prefs.setInt('token_expiry',
        DateTime.now().subtract(Duration(hours: 1)).millisecondsSinceEpoch
      );
      await prefs.setString('current_user', '{"id":"test","email":"test@test.com"}');
      
      final needsRefresh = await StorageService.needsTokenRefresh();
      expect(needsRefresh, true);
    });

    test('Valid session should not need re-auth', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Set recent auth time
      await prefs.setInt('last_auth_time',
        DateTime.now().millisecondsSinceEpoch
      );
      await prefs.setString('current_user', '{"id":"test","email":"test@test.com"}');
      
      final needsReauth = await StorageService.needsReAuthentication();
      expect(needsReauth, false);
    });

    test('Expired session should need re-auth', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Set auth time to 31 days ago
      await prefs.setInt('last_auth_time',
        DateTime.now().subtract(Duration(days: 31)).millisecondsSinceEpoch
      );
      await prefs.setString('current_user', '{"id":"test","email":"test@test.com"}');
      
      final needsReauth = await StorageService.needsReAuthentication();
      expect(needsReauth, true);
    });
  });
}
```

Run tests:
```bash
cd frontend
flutter test test/auth_service_test.dart
```

---

## Manual Testing Checklist

- [ ] Fresh sign-in works
- [ ] Token stored with correct expiry
- [ ] Timer started after sign-in
- [ ] Token auto-refreshes when expired
- [ ] Periodic refresh fires every 45 minutes
- [ ] App restart restores user
- [ ] App restart with expired token refreshes silently
- [ ] Session persists for 30 days
- [ ] Session expiry requires re-authentication
- [ ] Sign-out stops timer
- [ ] Sign-out clears storage

---

## Debug Commands

### Check Token Status
```dart
// In your app (e.g., in a debug button)
final needsRefresh = await StorageService.needsTokenRefresh();
final sessionValid = await StorageService.isSessionValid();
final tokensValid = await StorageService.areTokensValid();

print('Needs refresh: $needsRefresh');
print('Session valid: $sessionValid');
print('Tokens valid: $tokensValid');
```

### Check Storage
```dart
final prefs = await SharedPreferences.getInstance();
print('Keys: ${prefs.getKeys()}');
print('Token expiry: ${prefs.getInt('token_expiry')}');
print('Last auth: ${prefs.getInt('last_auth_time')}');
```

### Force Refresh
```dart
final token = await context.read<AuthService>().refreshToken();
print('New token: $token');
```

---

## Expected Behavior Summary

| Scenario | Expected Behavior |
|----------|------------------|
| Fresh sign-in | Store tokens, start timer |
| Token expires (< 30 days) | Auto-refresh silently |
| App restart (< 30 days) | Restore user, refresh if needed |
| Session expires (> 30 days) | Require re-authentication |
| Periodic check (45 min) | Refresh if needed |
| Sign-out | Stop timer, clear storage |
| Network offline | Graceful failure, retry later |

---

## Troubleshooting

### Timer Not Starting
- Check: `_startTokenRefreshTimer()` called after sign-in
- Check: No errors in console
- Check: `_tokenRefreshTimer` not null

### Refresh Not Working
- Check: Network connectivity
- Check: Google OAuth consent valid
- Check: Browser allows cookies
- Check: `_account` not null

### User Getting Signed Out
- Check: Session expiry (should be 30 days)
- Check: Token expiry (should be 50 minutes)
- Check: Refresh succeeding (check logs)
- Check: Backend storing tokens

---

## Success Criteria

✅ User stays signed in for 30 days
✅ Tokens refresh automatically every 50 minutes
✅ No user interaction required for refresh
✅ App restart preserves session
✅ Periodic timer prevents token expiry
✅ Graceful handling of refresh failures

If all criteria met, the fix is working correctly!
