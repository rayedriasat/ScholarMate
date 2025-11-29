# Authentication Fix - Simple Summary

## The Real Problem

`google_sign_in_all_platforms` **already handles refresh tokens automatically** through platform-specific secure storage. Your issue wasn't missing refresh tokens - it was:

1. Not using `silentSignIn()` properly for token refresh
2. Not handling 401 errors with automatic retry
3. Token expiry checks happening too late

## The Solution

### 1. Automatic Token Refresh (Already Implemented)

Your `auth_service.dart` now:
- Checks token expiry 5 minutes before it expires
- Calls `silentSignIn()` to get fresh token (library handles refresh internally)
- Falls back to manual OAuth2 refresh if needed
- Updates storage and backend automatically

### 2. DriveApiHelper for Auto-Retry (New)

Use this for **all** Drive API calls:

```dart
final helper = DriveApiHelper(authService);

// Instead of:
// final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

// Do this:
final response = await helper.authenticatedGet(url);
// Automatically refreshes token and retries on 401
```

### 3. How silentSignIn() Works

The `google_sign_in_all_platforms` library:
- Stores refresh tokens in **platform secure storage** (Keychain, Credential Manager, etc.)
- When you call `silentSignIn()`, it checks if stored credentials are valid
- If access token expired, it uses stored refresh token to get new one
- Returns fresh credentials without user interaction

**You don't need to manually manage refresh tokens!**

## What You Need to Do

### Update Your Drive Service

Find where you make Drive API calls and replace with `DriveApiHelper`:

```dart
class DriveService {
  final AuthService _authService;
  late final DriveApiHelper _apiHelper;
  
  DriveService(this._authService) {
    _apiHelper = DriveApiHelper(_authService);
  }
  
  Future<List<DriveFile>> listFiles() async {
    final response = await _apiHelper.authenticatedGet(
      Uri.parse('https://www.googleapis.com/drive/v3/files?'
        'q=trashed=false&'
        'fields=files(id,name,mimeType,size,modifiedTime,parents)'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['files'] as List)
        .map((f) => DriveFile.fromJson(f))
        .toList();
    }
    throw Exception('Failed to list files: ${response.statusCode}');
  }
  
  Future<Uint8List> downloadFile(String fileId) async {
    final response = await _apiHelper.authenticatedGet(
      Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId?alt=media'),
    );
    
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Failed to download: ${response.statusCode}');
  }
}
```

### For Existing Users Having Issues

If users are still getting logged out frequently:
1. Have them sign out completely
2. Sign in again
3. This refreshes the credentials in platform secure storage

## Testing

1. Sign in to your app
2. Check logs for: `"Token expiry set from ID token: [timestamp]"`
3. Wait 55+ minutes (or manually change token expiry in storage to test)
4. Make a Drive API call
5. Should see: `"Token expiring, attempting refresh..."` then `"Access token refreshed successfully via silentSignIn"`
6. Drive API call succeeds

## Why This Works

**Before:**
- Token expires → Drive API call fails → User sees error → Must sign in again

**After:**
- Token expires in 5 min → Auto-refresh via `silentSignIn()` → Fresh token → Drive API succeeds
- If 401 error → `DriveApiHelper` auto-refreshes → Retries → Succeeds

## Key Files

1. `frontend/lib/services/auth_service.dart` - Token management (FIXED)
2. `frontend/lib/services/drive_api_helper.dart` - Auto-retry wrapper (NEW)
3. `backend/app/services/drive_service.py` - Better error codes (FIXED)

## Common Mistakes to Avoid

❌ Don't manually add `Authorization` headers - use `DriveApiHelper`
❌ Don't try to manually manage refresh tokens - library does it
❌ Don't call `getAccessToken()` without checking if it's null
✅ Use `DriveApiHelper` for all authenticated requests
✅ Let `silentSignIn()` handle token refresh
✅ Sign out/in again if having persistent issues
