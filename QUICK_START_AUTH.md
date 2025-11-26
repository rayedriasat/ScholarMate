# Quick Start: Authentication Pattern

## For Frontend Developers

### Making API Calls That Need Drive Access

```dart
// ✅ CORRECT - API service handles tokens automatically
final jobId = await apiService.startIndexing(
  userId: user.id,
  fileId: fileId,
  fileName: fileName,
);

// ❌ WRONG - Don't manually manage tokens
final token = await authService.getAccessToken();
// ... manual HTTP call with token
```

### Adding New API Methods

```dart
Future<Result> myNewMethod({required String fileId}) async {
  try {
    // 1. Get fresh access token (auto-refreshes if needed)
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw ApiException('Not authenticated', 401);
    }

    // 2. Make request with token in body
    final response = await http.post(
      Uri.parse('$_baseUrl/api/my-endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'file_id': fileId,
        'access_token': accessToken,  // ← Include token
      }),
    );

    // 3. Handle 401 with automatic retry
    if (response.statusCode == 401) {
      final newToken = await _authService.getAccessToken();
      if (newToken != null) {
        // Retry once with fresh token
        final retryResponse = await http.post(/* same request */);
        if (retryResponse.statusCode == 200) {
          return parseResponse(retryResponse);
        }
      }
      throw ApiException('Authentication failed', 401);
    }

    // 4. Handle success
    if (response.statusCode == 200) {
      return parseResponse(response);
    }
    
    throw ApiException('Request failed', response.statusCode);
  } catch (e) {
    if (e is ApiException) rethrow;
    throw ApiException('Request failed: $e');
  }
}
```

## For Backend Developers

### Adding New Endpoints That Need Drive Access

#### 1. Update Request Model

```python
# backend/app/models/my_feature.py
from pydantic import BaseModel, Field

class MyFeatureRequest(BaseModel):
    file_id: str = Field(..., description="Google Drive file ID")
    user_id: str = Field(..., description="User UUID")
    access_token: str = Field(..., description="User's access token")  # ← Add this
```

#### 2. Update Router

```python
# backend/app/routers/my_feature.py
from app.services.drive_service import get_drive_service

@router.post("/my-endpoint")
async def my_endpoint(request: MyFeatureRequest):
    try:
        drive_service = get_drive_service()
        
        # Use access token from request
        file_bytes = drive_service.get_file_bytes(
            request.file_id,
            request.access_token  # ← Pass token from request
        )
        
        # Process file...
        
        return {"success": True}
    except ValueError as e:
        # Drive service raises ValueError for auth errors
        if "expired" in str(e).lower():
            raise HTTPException(status_code=401, detail=str(e))
        raise HTTPException(status_code=400, detail=str(e))
```

#### 3. For Background Jobs

```python
# Store token in job metadata
job_data = {
    "file_id": file_id,
    "user_id": user_id,
    "access_token": access_token,  # ← Store for later use
    "status": "pending",
}

# Use token in background processing
async def process_job(job_id: str):
    job = await get_job(job_id)
    access_token = job["access_token"]  # ← Retrieve from job
    
    if not access_token:
        await fail_job(job_id, "No access token")
        return
    
    # Use token to fetch from Drive
    file_bytes = drive_service.get_file_bytes(file_id, access_token)
```

## Common Patterns

### Pattern 1: Simple API Call

```dart
// Frontend
final token = await authService.getAccessToken();
await http.post(url, body: {'access_token': token});
```

```python
# Backend
@router.post("/endpoint")
async def endpoint(request: MyRequest):
    file_bytes = drive_service.get_file_bytes(
        request.file_id,
        request.access_token
    )
```

### Pattern 2: Background Job

```dart
// Frontend - Start job
final jobId = await apiService.startJob(fileId: fileId);

// Poll for status
final status = await apiService.getJobStatus(jobId);
```

```python
# Backend - Create job with token
job_data = {
    "access_token": request.access_token,  # Store token
    "status": "pending",
}

# Process job later
async def process_job(job_id):
    job = await get_job(job_id)
    token = job["access_token"]  # Use stored token
    file_bytes = drive_service.get_file_bytes(file_id, token)
```

### Pattern 3: Handle Token Expiry

```dart
// Frontend - Automatic retry
try {
  final result = await apiService.myMethod();
} catch (e) {
  if (e is ApiException && e.statusCode == 401) {
    // Token expired, getAccessToken() will refresh
    await authService.silentSignIn();
    final result = await apiService.myMethod();  // Retry
  }
}
```

```python
# Backend - Return 401 for expired tokens
try:
    file_bytes = drive_service.get_file_bytes(file_id, access_token)
except ValueError as e:
    if "expired" in str(e).lower():
        raise HTTPException(
            status_code=401,
            detail="Access token expired. Please refresh and retry."
        )
```

## Key Rules

### Frontend ✅ DO
- ✅ Use `authService.getAccessToken()` before API calls
- ✅ Include `access_token` in request body
- ✅ Handle 401 errors with automatic retry
- ✅ Let `getAccessToken()` handle token refresh

### Frontend ❌ DON'T
- ❌ Store tokens in variables
- ❌ Manually refresh tokens via HTTP
- ❌ Cache tokens for long periods
- ❌ Pass tokens in URL parameters

### Backend ✅ DO
- ✅ Accept `access_token` in request models
- ✅ Use token immediately (don't store)
- ✅ Return 401 for expired tokens
- ✅ Store token in job metadata for background jobs

### Backend ❌ DON'T
- ❌ Store tokens in database permanently
- ❌ Try to refresh tokens
- ❌ Assume tokens are always valid
- ❌ Use tokens from previous requests

## Troubleshooting

### "Not authenticated" Error
```dart
// Check if user is signed in
final user = authService.currentUser;
if (user == null) {
  // User needs to sign in
  await authService.signInWithGoogle();
}
```

### "Token expired" Error
```dart
// Force token refresh
await authService.silentSignIn();
// Retry the request
```

### Background Job Fails with 401
```python
# Job fails if token expired during processing
# Frontend must retry with fresh token
await fail_job(job_id, "Token expired - please retry from app")
```

## Testing

### Test Token Refresh
```dart
// 1. Sign in
await authService.signInWithGoogle();

// 2. Wait for token to expire (or mock expiry)
await Future.delayed(Duration(hours: 1));

// 3. Make API call - should auto-refresh
final result = await apiService.startIndexing(...);
// Should succeed without user interaction
```

### Test 401 Handling
```dart
// Mock 401 response
when(mockHttp.post(any)).thenAnswer((_) async => 
  http.Response('Unauthorized', 401)
);

// Should retry automatically
final result = await apiService.startIndexing(...);
verify(mockHttp.post(any)).called(2);  // Original + retry
```

## Summary

**Frontend**: Get fresh token → Include in request → Handle 401 with retry
**Backend**: Accept token → Use immediately → Return 401 if invalid

That's it! Simple, secure, and follows OAuth2 best practices.
