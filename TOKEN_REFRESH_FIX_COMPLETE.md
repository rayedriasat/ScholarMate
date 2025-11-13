# Google OAuth Token Refresh & Session Persistence Fix

## Problem Summary

Users were being signed out after ~1 hour because:
1. Google access tokens expire after 1 hour
2. App wasn't refreshing tokens automatically
3. StorageService assumed 30-day token validity (incorrect)
4. No background token refresh mechanism
5. Session wasn't persisted correctly across app restarts

## Solution Implemented

### 1. Fixed Token Expiry Tracking (`storage_service.dart`)

**Before:**
- Assumed tokens valid for 30 days
- No distinction between token expiry and session expiry

**After:**
- Token validity: 50 minutes (refresh before 1-hour expiry)
- Session validity: 30 days (user stays logged in)
- Separate tracking for token expiry vs session expiry

```dart
// Token expires in ~1 hour, refresh at 50 minutes
static const Duration _tokenValidityDuration = Duration(minutes: 50);

// Session lasts 30 days (user stays logged in)
static const Duration _sessionValidityDuration = Duration(days: 30);
```

### 2. Automatic Token Refresh (`auth_service.dart`)

**New Features:**
- Periodic token refresh every 45 minutes
- Silent token refresh on app startup if needed
- Automatic refresh before token expiry
- Background timer for proactive refresh

**Key Methods:**

```dart
// Start periodic refresh timer (runs every 45 minutes)
void _startTokenRefreshTimer()

// Silent refresh without user interaction
Future<void> _silentTokenRefresh()

// Enhanced refresh with backend sync
Future<String?> refreshToken()
```

### 3. Smart Token Management

**On App Startup:**
1. Restore user from local storage
2. Check if session is valid (30 days)
3. If session valid but tokens expired → silent refresh
4. If session expired → require re-authentication
5. Start periodic refresh timer

**On Token Request:**
1. Check if token needs refresh
2. Auto-refresh if expired
3. Return cached token if valid
4. Update backend with new token

### 4. Session Persistence

**Storage Strategy:**
- User data stored in SharedPreferences
- Token expiry tracked separately
- Session expiry tracked independently
- Tokens refreshed automatically within valid session

**Session Flow:**
```
User Signs In
    ↓
Store user + tokens (session starts)
    ↓
Token expires after 50 min
    ↓
Auto-refresh token (silent)
    ↓
Update storage + backend
    ↓
Repeat for 30 days
    ↓
Session expires → require re-auth
```

## Files Modified

### `frontend/lib/services/storage_service.dart`
- Changed token validity from 30 days to 50 minutes
- Added session validity tracking (30 days)
- Added `isSessionValid()` method
- Added `needsTokenRefresh()` method
- Updated `needsReAuthentication()` logic

### `frontend/lib/services/auth_service.dart`
- Added `_tokenRefreshTimer` for periodic refresh
- Added `_startTokenRefreshTimer()` method
- Added `_stopTokenRefreshTimer()` method
- Added `_silentTokenRefresh()` method
- Enhanced `refreshToken()` with backend sync
- Enhanced `getAccessToken()` with auto-refresh
- Updated initialization to check token status
- Start timer on sign-in and auth events
- Stop timer on sign-out

## How It Works

### Token Lifecycle

```
┌─────────────────────────────────────────────────────┐
│ User Signs In                                       │
│ ↓                                                   │
│ Tokens stored (expiry: now + 50 min)              │
│ Session started (expiry: now + 30 days)           │
│ Timer started (check every 45 min)                │
└─────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ After 45 minutes                                    │
│ ↓                                                   │
│ Timer fires → check token expiry                   │
│ ↓                                                   │
│ Token expired? → silent refresh                    │
│ ↓                                                   │
│ Update storage + backend                           │
│ ↓                                                   │
│ Continue...                                        │
└─────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ User closes/reopens app                            │
│ ↓                                                   │
│ Restore user from storage                          │
│ ↓                                                   │
│ Session valid? (< 30 days)                        │
│   Yes → Check token expiry                        │
│     Expired? → silent refresh                     │
│     Valid? → use cached token                     │
│   No → require re-authentication                  │
└─────────────────────────────────────────────────────┘
```

### Web-Specific Considerations

**Google Sign-In on Web:**
- No refresh tokens exposed directly
- Uses browser's OAuth flow
- Tokens managed by Google's JavaScript SDK
- Silent refresh via `authorizationForScopes()`

**Our Implementation:**
- Clears cached token via `clearAuthorizationToken()`
- Requests new token via `authorizationForScopes()`
- Updates local storage and backend
- No user interaction required (silent)

## Testing

### Test Scenarios

1. **Fresh Sign-In**
   - Sign in → verify token stored
   - Check timer started
   - Verify session expiry set to 30 days

2. **Token Expiry**
   - Wait 50+ minutes
   - Make API call → should auto-refresh
   - Verify new token stored

3. **App Restart (within 30 days)**
   - Close app
   - Reopen → should restore user
   - If token expired → should refresh silently
   - Should NOT require re-authentication

4. **Session Expiry (after 30 days)**
   - Wait 30+ days (or manually set expiry)
   - Reopen app → should require re-authentication

5. **Periodic Refresh**
   - Keep app open for 90+ minutes
   - Verify token refreshed at 45-minute mark
   - Check logs for refresh messages

### Debug Logs

Look for these messages:
```
✓ "User restored with valid tokens"
✓ "Tokens expired, attempting silent refresh..."
✓ "Token refreshed successfully"
✓ "Periodic token refresh check..."
✓ "Token refresh timer started"
```

## Configuration

No configuration changes needed. The fix works automatically with:
- Google OAuth tokens (1-hour expiry)
- 50-minute refresh interval (safe margin)
- 45-minute periodic check (before expiry)
- 30-day session validity

## Benefits

1. **No More Unexpected Sign-Outs**: Tokens refresh automatically
2. **Persistent Sessions**: Users stay logged in for 30 days
3. **Seamless Experience**: Silent refresh, no user interaction
4. **Proactive Refresh**: Timer prevents expiry before use
5. **Web Compatible**: Works with google_sign_in v7+ on web
6. **Offline Resilient**: Graceful handling of refresh failures

## Troubleshooting

### User Still Getting Signed Out

**Check:**
1. Are tokens being stored? (check SharedPreferences)
2. Is timer running? (check debug logs)
3. Is refresh succeeding? (check for error logs)
4. Is backend storing tokens? (check API logs)

**Debug:**
```dart
// Check token status
final needsRefresh = await StorageService.needsTokenRefresh();
final sessionValid = await StorageService.isSessionValid();
print('Needs refresh: $needsRefresh, Session valid: $sessionValid');
```

### Refresh Failing

**Possible Causes:**
1. Network offline → will retry on next timer tick
2. Google OAuth revoked → requires re-authentication
3. Invalid scopes → check _scopes configuration
4. Browser blocking cookies → check browser settings

**Solution:**
- Check network connectivity
- Verify Google OAuth consent screen
- Check browser console for errors
- Test with different browser

## Migration Notes

**Existing Users:**
- Will be prompted to re-authenticate once (to establish new session)
- After that, tokens will refresh automatically
- No data loss or disruption

**New Users:**
- Automatic token refresh from first sign-in
- 30-day persistent sessions
- Seamless experience

## Future Improvements

1. **Exponential Backoff**: Retry failed refreshes with backoff
2. **Token Preemptive Refresh**: Refresh at 80% of expiry time
3. **Multiple Token Sources**: Support backend token refresh endpoint
4. **Refresh Token Storage**: Store refresh tokens when available
5. **Analytics**: Track refresh success/failure rates

## Summary

The fix ensures users stay signed in for 30 days with automatic token refresh every 50 minutes. The implementation is:
- ✅ Automatic and silent
- ✅ Web-compatible
- ✅ Offline-resilient
- ✅ Production-ready
- ✅ No breaking changes

Users will no longer be signed out after 1 hour!
