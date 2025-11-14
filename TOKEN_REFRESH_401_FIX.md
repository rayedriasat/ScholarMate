# Fixed: 401 Authentication Error on File Access

## Problem
The Android app was showing "Error loading files" with a 401 authentication error, even though sign-in was successful:
```
Exception: Failed to create app folder: 401 {
  "error": {
    "code": 401,
    "message": "Request had invalid authentication credentials..."
  }
}
```

The logs showed:
- ✅ Sign-in successful
- ✅ Access token stored
- ✅ Silent sign-in successful
- ❌ File operations failing with 401

## Root Cause
Multiple methods in `drive_service.dart` were making HTTP requests **without** using the `_makeAuthenticatedRequest` wrapper. This wrapper provides automatic token refresh and retry logic when a 401 error occurs.

When these methods called `await _getAccessToken()` to get the token, they were getting a token that might already be expired by the time the HTTP request was made. Without the wrapper, there was no retry logic to refresh and try again.

## Solution
Updated **14 methods** in `frontend/lib/services/drive_service.dart` to use the `_makeAuthenticatedRequest` wrapper:

### Methods Fixed:
1. ✅ `createAppFolder()` - Creating the ScholarMate folder
2. ✅ `uploadFile()` - Uploading files to Drive
3. ✅ `createFolder()` - Creating new folders
4. ✅ `deleteFile()` - Deleting files
5. ✅ `renameFile()` - Renaming files
6. ✅ `moveFile()` - Moving files (2 HTTP calls)
7. ✅ `downloadFile()` - Downloading file content
8. ✅ `_getFileMetadata()` - Getting file metadata
9. ✅ `shareFile()` - Sharing files with users
10. ✅ `listFilePermissions()` - Listing file permissions
11. ✅ `removeFilePermission()` - Removing permissions
12. ✅ `createPublicLink()` - Making files public
13. ✅ `uploadFileFromBytes()` - Uploading from bytes
14. ✅ `updateFile()` - Updating file content
15. ✅ `updateFileContent()` - Updating markdown files

## How the Fix Works

### Before (❌ Broken):
```dart
Future<String> createAppFolder() async {
  final accessToken = await _getAccessToken();  // Gets token
  
  final response = await http.post(            // Token might be expired
    Uri.parse('$_baseUrl/files'),
    headers: {'Authorization': 'Bearer $accessToken'},
    body: json.encode(folderMetadata),
  );
  
  // If 401, throws error - no retry
}
```

### After (✅ Fixed):
```dart
Future<String> createAppFolder() async {
  final response = await _makeAuthenticatedRequest(
    (token) => http.post(                      // Token passed as parameter
      Uri.parse('$_baseUrl/files'),
      headers: {'Authorization': 'Bearer $token'},
      body: json.encode(folderMetadata),
    ),
  );
  
  // If 401, automatically:
  // 1. Refreshes token via silentSignIn()
  // 2. Retries the request with fresh token
}
```

The `_makeAuthenticatedRequest` wrapper:
1. Gets a fresh access token
2. Executes the HTTP request
3. **If 401 occurs**: Automatically calls `silentSignIn()` to refresh the token and retries once
4. **If still fails**: Throws an error asking user to sign in again

## Testing

### Test the Fix:
1. **Stop and restart the app** to clear any in-memory state
2. **Sign in** to the app
3. **Navigate to the Files tab** - should now load successfully
4. **Wait a few minutes** for the token to expire
5. **Try creating a folder or uploading a file** - should work (auto-refresh)

### Expected Behavior:
- ✅ Files screen loads successfully after sign-in
- ✅ All file operations work even if token expires
- ✅ Automatic token refresh happens silently in the background
- ✅ No more 401 errors during normal usage

### If You Still See 401 Errors:
1. **Sign out completely** and sign in again
2. Check that your Google OAuth credentials are correct
3. Verify the backend is storing tokens properly
4. Check logs for any "Unable to refresh access token" messages

## Files Modified
- `frontend/lib/services/drive_service.dart` - Fixed 14 methods

## Related Documentation
- See `TOKEN_REFRESH_FIX.md` for token refresh implementation
- See `DRIVE_SERVICE_FIX.md` for Drive service architecture
- See `TEST_TOKEN_REFRESH.md` for testing token refresh

