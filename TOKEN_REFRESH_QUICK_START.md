# Token Refresh Fix - Quick Start

## What Was Fixed

Google OAuth tokens expire after 1 hour, causing users to be signed out. Now tokens refresh automatically every 50 minutes, and users stay signed in for 30 days.

## Key Changes

### Storage Service
- Token validity: **50 minutes** (was 30 days)
- Session validity: **30 days** (new)
- Separate tracking for token vs session expiry

### Auth Service
- **Automatic token refresh** every 45 minutes
- **Silent refresh** on app startup if needed
- **Background timer** for proactive refresh
- **Auto-refresh** before API calls if token expired

## How It Works

```
Sign In → Store tokens (50 min expiry) + Session (30 days)
    ↓
Timer checks every 45 minutes
    ↓
Token expired? → Refresh silently
    ↓
Update storage + backend
    ↓
Repeat for 30 days
    ↓
Session expires → Re-authenticate
```

## Testing

### Quick Test
1. Sign in
2. Check console: `"Token refresh timer started"`
3. Wait 50+ minutes OR force expiry
4. Make API call → should auto-refresh
5. Close/reopen app → should stay signed in

### Force Token Expiry (for testing)
```dart
// Add to auth_service.dart temporarily
Future<void> forceTokenExpiry() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('token_expiry', 
    DateTime.now().subtract(Duration(minutes: 1)).millisecondsSinceEpoch
  );
}
```

## Debug Logs

Look for:
- ✅ `"Token refresh timer started"`
- ✅ `"Periodic token refresh check..."`
- ✅ `"Token refreshed successfully"`
- ✅ `"User restored with valid tokens"`

## Files Modified

1. `frontend/lib/services/storage_service.dart`
   - Changed token validity to 50 minutes
   - Added session validity (30 days)
   - Added `needsTokenRefresh()` method

2. `frontend/lib/services/auth_service.dart`
   - Added periodic refresh timer
   - Added silent refresh on startup
   - Enhanced `getAccessToken()` with auto-refresh
   - Enhanced `refreshToken()` with backend sync

## No Configuration Needed

The fix works automatically. Just run the app:

```bash
cd frontend
flutter run -d chrome
```

## Expected Behavior

| Action | Result |
|--------|--------|
| Sign in | Tokens stored, timer started |
| Wait 50 min | Token auto-refreshes |
| Close/reopen app | User stays signed in |
| Wait 30 days | Re-authentication required |

## Troubleshooting

**Still getting signed out?**
1. Check browser console for errors
2. Verify network connectivity
3. Check Google OAuth consent screen
4. Clear browser cache and re-test

**Need help?**
- See `TOKEN_REFRESH_FIX_COMPLETE.md` for details
- See `TEST_TOKEN_REFRESH.md` for testing guide

## Summary

✅ Tokens refresh automatically every 50 minutes
✅ Users stay signed in for 30 days
✅ Silent refresh, no user interaction
✅ Works on Flutter Web with google_sign_in v7+
✅ Production-ready, no breaking changes

**Users will no longer be signed out after 1 hour!**
