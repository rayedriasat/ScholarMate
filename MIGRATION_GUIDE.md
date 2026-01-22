# Migration Guide: Unified Authentication System

## Quick Start

This guide helps you migrate from the old mixed authentication system to the new unified FastAPI-based system.

## For Users

### What Changed?
- **Windows users:** You'll now sign in through your browser (same as Web/Android)
- **All users:** Your sessions will persist better across app restarts
- **Security:** All tokens now managed securely by the backend

### First Login After Update
1. You may be asked to sign in again
2. The process is the same - click "Sign in with Google"
3. After successful login, you'll stay logged in automatically

### What Stays the Same?
- Your Google account
- Your files and data
- All app features

## For Developers

### Prerequisites
- Flutter 3.9.2+
- Backend running with updated auth router
- Valid Google OAuth credentials

### Step 1: Update Backend

If not already done:

```bash
cd backend
# The auth router already supports Windows platform
# No additional changes needed
```

Verify these endpoints exist:
- `GET /api/auth/google?platform={android|web|windows}`
- `GET /api/auth/google/callback`
- `GET /api/auth/session?code={encrypted_code}`
- `GET /api/drive/access-token?user_id={userId}`

### Step 2: Update Frontend

```bash
cd frontend

# Clean old build artifacts
flutter clean

# Update dependencies (removes google_sign_in_all_platforms)
flutter pub get

# Rebuild the app
flutter run  # or flutter build windows/web/apk
```

### Step 3: Verify Configuration

Ensure your `.env` or compile-time variables include:

```bash
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret  # Backend only
API_BASE_URL=http://localhost:8000
```

### Step 4: Test the Flow

#### Windows Testing
```bash
cd frontend
flutter run -d windows
```

**Expected behavior:**
1. App starts → shows SplashScreen
2. No saved session → shows LoginScreen
3. Click "Sign in with Google"
4. Browser opens to Google OAuth
5. Grant permission
6. Browser shows success page (auto-closes)
7. App shows HomeScreen

**Restart app:**
1. App starts → shows SplashScreen
2. Saved session found → directly shows HomeScreen ✅

#### Web Testing
```bash
cd frontend
flutter run -d chrome
```

**Expected behavior:**
1. Click "Sign in with Google"
2. Redirects to Google (same tab)
3. Redirects back to app
4. Shows HomeScreen

#### Android Testing
```bash
cd frontend
flutter run -d android
```

**Expected behavior:**
1. Click "Sign in with Google"
2. Opens Chrome/browser
3. Deep link returns to app
4. Shows HomeScreen

### Step 5: Common Issues & Solutions

#### Issue: "Port 3000 already in use" (Windows)

**Cause:** Previous server instance didn't stop properly

**Solution:**
```bash
# Windows PowerShell
Get-Process -Id (Get-NetTCPConnection -LocalPort 3000).OwningProcess | Stop-Process

# Or restart the app
```

#### Issue: "Could not launch auth URL"

**Cause:** Browser restrictions or URL launcher not working

**Solution:**
- Check if default browser is set
- Verify `url_launcher` plugin is installed
- Check browser permissions

#### Issue: "Session code expired"

**Cause:** Taking too long to complete OAuth flow

**Solution:**
- Session codes expire after 5 minutes
- Complete OAuth flow faster
- Or restart sign-in process

#### Issue: "Failed to retrieve tokens"

**Cause:** Backend can't exchange auth code

**Solution:**
- Verify `GOOGLE_CLIENT_SECRET` is set in backend
- Check backend logs for errors
- Ensure redirect URI matches Google Console

#### Issue: Auto-login not working

**Cause:** Session expired or corrupted

**Solution:**
```dart
// Clear storage and sign in again
await StorageService.clearUser();
// Restart app and sign in
```

### Step 6: Debug Mode

Enable verbose logging:

```dart
// In auth_service.dart, debugPrint statements already included
// Check console for:
// - [Auth] messages
// - [WindowsAuthServer] messages
// - [Windows Auth] messages (now removed)
```

### Code Changes Reference

#### Removed Code
```dart
// ❌ No longer needed
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';

// ❌ No longer needed
GoogleSignIn? _googleSignIn;
StreamSubscription<GoogleSignInCredentials?>? _authStateSub;

// ❌ No longer needed
Future<void> _initializeWindows(String clientId) async { ... }
Future<void> _windowsSignIn() async { ... }
Future<String?> _windowsGetAccessToken() async { ... }
Future<User?> silentSignIn() async { ... }
```

#### Added Code
```dart
// ✅ New Windows auth server
import 'windows_auth_server.dart';
WindowsAuthServer? _windowsAuthServer;

// ✅ Unified backend OAuth for Windows
Future<void> _windowsBackendOAuthSignIn() async { ... }

// ✅ Single token refresh method
Future<String?> getAccessToken({bool forceRefresh = false}) async {
  return _backendGetAccessToken(forceRefresh: forceRefresh);
}
```

## Backend Changes Summary

### auth.py
```python
# ✅ Added Windows platform support
@router.get("/google")
async def google_login(platform: str = Query(..., regex="^(android|web|windows)$")):

# ✅ Added Windows redirect URL
WINDOWS_LOOPBACK_URL = "http://localhost:3000"

# ✅ Updated callback routing
if platform == "windows":
    redirect_url = f"{WINDOWS_LOOPBACK_URL}?code={encrypted_session}"
```

## Rollback Plan (If Needed)

If you need to rollback to the old system:

```bash
cd frontend

# 1. Restore old pubspec.yaml
git checkout HEAD~1 frontend/pubspec.yaml

# 2. Restore old auth_service.dart
git checkout HEAD~1 frontend/lib/services/auth_service.dart

# 3. Remove new file
rm frontend/lib/services/windows_auth_server.dart

# 4. Update dependencies
flutter pub get

# 5. Rebuild
flutter clean
flutter run
```

## Testing Checklist

Before deploying:

- [ ] Windows: Sign in works
- [ ] Windows: Sign out works
- [ ] Windows: Auto-login after restart
- [ ] Windows: Token refresh works
- [ ] Web: Sign in works
- [ ] Web: Auto-login works
- [ ] Android: Sign in works
- [ ] Android: Auto-login works
- [ ] All: Session expiry handled
- [ ] All: Error messages clear
- [ ] Backend: Logs show no errors
- [ ] Backend: All platforms accepted

## Performance Notes

- **Startup time:** Slightly faster (no SDK initialization)
- **Sign-in time:** Similar (network dependent)
- **Token refresh:** Same (backend call)
- **Memory usage:** Lower (no client-side SDK)

## Security Audit

Changes improve security:

1. ✅ No refresh tokens on client
2. ✅ Backend-only token management
3. ✅ Encrypted token storage
4. ✅ Short-lived session codes
5. ✅ Consistent security model

## Support

If you encounter issues:

1. Check console logs
2. Verify backend is running
3. Check Google OAuth configuration
4. Review this migration guide
5. Check `UNIFIED_AUTH_IMPLEMENTATION.md` for details

## Conclusion

The migration is straightforward:

1. Update backend (already done)
2. Clean and rebuild frontend
3. Test sign-in flow
4. Verify auto-login
5. Deploy!

**Total time:** ~10-15 minutes

**Downtime:** None (backward compatible)

**User impact:** Minimal (may need to re-authenticate once)
