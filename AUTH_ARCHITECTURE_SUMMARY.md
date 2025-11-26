# Authentication Architecture Summary

## The Problem We Solved

You asked: "How does my backend fetch PDFs for RAG if we can never get refresh tokens separately?"

## The Answer

**The backend doesn't manage tokens at all.** The frontend passes fresh access tokens with every request.

## Why This Works

### Platform-Managed Refresh Tokens

`google_sign_in_all_platforms` stores refresh tokens in platform-specific secure storage:
- **Android/iOS**: OS keychain
- **Web**: Browser session
- **Windows/Linux**: Credential manager

You can't extract these tokens, and you shouldn't try.

### The Correct Flow

```
┌─────────────┐
│  Frontend   │
│             │
│ 1. User     │
│    signs in │
│             │
│ 2. Platform │
│    stores   │
│    refresh  │
│    token    │
│             │
│ 3. App gets │
│    access   │
│    token    │
└──────┬──────┘
       │
       │ Access token expires (1 hour)
       │
       ▼
┌──────────────┐
│ silentSignIn()│ ← Platform uses stored refresh token
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Fresh access │
│    token     │
└──────┬───────┘
       │
       │ Make API call
       │
       ▼
┌──────────────────┐
│    Backend       │
│                  │
│ Receives token   │
│ Uses it to fetch │
│ from Drive       │
│                  │
│ If 401 error →   │
│ Return to        │
│ frontend         │
└──────────────────┘
       │
       │ 401 error
       │
       ▼
┌──────────────┐
│  Frontend    │
│              │
│ Calls        │
│ silentSignIn()│
│              │
│ Retries with │
│ fresh token  │
└──────────────┘
```

## Implementation

### Frontend (auth_service.dart) ✅ DONE

```dart
// Get fresh token (auto-refreshes if expired)
Future<String?> getAccessToken() async {
  if (tokenExpired) {
    await _refreshAccessToken(); // Calls silentSignIn()
  }
  return _currentUser?.accessToken;
}

// Make API call
final token = await authService.getAccessToken();
await apiService.startIndexing(
  fileId: fileId,
  accessToken: token, // ← Pass to backend
);
```

### Backend (drive_service.py) ✅ DONE

```python
def get_file_bytes(self, file_id: str, access_token: str) -> bytes:
    """Fetch file using provided access token."""
    headers = {"Authorization": f"Bearer {access_token}"}
    response = requests.get(drive_url, headers=headers)
    
    if response.status_code == 401:
        raise ValueError("Token expired - frontend should refresh")
    
    return response.content
```

### Request Models ⏳ TODO

```python
class StartIndexingRequest(BaseModel):
    user_id: str
    file_id: str
    access_token: str  # ← Add this field
```

### RAG Indexer ⏳ TODO

```python
async def index_file(self, file_id: str, user_id: str, access_token: str):
    # Store token in job data
    job_data = {
        "file_id": file_id,
        "user_id": user_id,
        "access_token": access_token,  # ← Store for background job
    }
    
async def process_indexing_job(self, job_id: str):
    job = await get_job(job_id)
    access_token = job["access_token"]  # ← Use stored token
    file_bytes = self.drive_service.get_file_bytes(file_id, access_token)
```

## Key Principles

1. **Frontend owns tokens** - Platform manages refresh tokens securely
2. **Backend receives tokens** - Fresh access token with each request
3. **Backend is stateless** - No token storage or refresh logic
4. **Frontend handles expiry** - Calls `silentSignIn()` and retries
5. **Follow conventions** - This is how OAuth2 clients should work

## What We Removed

- ❌ Backend token storage in database
- ❌ Backend token refresh logic
- ❌ Manual HTTP token refresh
- ❌ Complex token management

## What We Kept

- ✅ Platform-managed refresh tokens
- ✅ Automatic token refresh via `silentSignIn()`
- ✅ Simple, stateless backend
- ✅ Secure token handling

## Security

- Tokens transmitted over HTTPS only
- Tokens expire in 1 hour (short-lived)
- No token storage in backend database
- Platform-level encryption for refresh tokens
- Automatic token rotation

## Long-Term Access

Users stay logged in indefinitely because:
1. Platform stores refresh token securely
2. `silentSignIn()` gets fresh access token on app startup
3. `getAccessToken()` auto-refreshes when needed
4. No manual token management required

Users only need to re-authenticate if:
- They explicitly sign out
- They revoke app permissions
- Refresh token expires (6 months inactivity)

## Next Steps

See `BACKEND_ACCESS_TOKEN_PATTERN.md` for detailed implementation steps.

## Files Modified

- ✅ `frontend/lib/services/auth_service.dart` - Simplified token refresh
- ✅ `backend/app/services/drive_service.py` - Accept token parameter
- ⏳ `backend/app/models/ingestion.py` - Add access_token field
- ⏳ `backend/app/services/rag_indexer.py` - Store/use token from job
- ⏳ `frontend/lib/services/api_service.dart` - Pass token in requests

## Conclusion

**Don't fight the platform conventions.** Let the platform manage refresh tokens, and just pass access tokens from frontend to backend. It's simpler, more secure, and follows OAuth2 best practices.
