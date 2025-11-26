# Backend Access Token Pattern

## Architecture: Frontend Passes Tokens to Backend

Since `google_sign_in_all_platforms` manages refresh tokens internally via platform-specific secure storage, the backend **cannot** and **should not** try to refresh tokens.

### The Correct Pattern

```
Frontend (has fresh token)
    ↓
Makes API call to backend
    ↓
Includes access_token in request body/header
    ↓
Backend uses token to fetch from Drive
    ↓
If 401 error → Return error to frontend
    ↓
Frontend refreshes token via silentSignIn()
    ↓
Frontend retries request with new token
```

## Implementation Changes Required

### 1. Update Request Models

Add `access_token` field to all requests that need Drive access:

```python
# backend/app/models/ingestion.py
class StartIndexingRequest(BaseModel):
    user_id: str
    file_id: str
    file_name: Optional[str] = None
    access_token: str  # ← ADD THIS

# backend/app/models/metadata.py
class ExtractMetadataRequest(BaseModel):
    file_id: str
    file_name: str
    extract_from_content: bool = True
    access_token: str  # ← ADD THIS
```

### 2. Update Drive Service (DONE ✓)

```python
# backend/app/services/drive_service.py
class BackendDriveService:
    def get_file_bytes(self, file_id: str, access_token: str) -> bytes:
        """Fetch file using provided access token."""
        # No token storage, no refresh logic
        # Just use the token provided by frontend
```

### 3. Update RAG Indexer

Store access token in job metadata, use it when processing:

```python
# backend/app/services/rag_indexer.py
async def index_file(
    self,
    file_id: str,
    user_id: str,
    access_token: str,  # ← ADD THIS
    file_name: Optional[str] = None
) -> str:
    """Create indexing job with access token."""
    job_id = str(uuid.uuid4())
    
    job_data = {
        "id": job_id,
        "user_id": user_id,
        "file_id": file_id,
        "access_token": access_token,  # ← STORE IN JOB
        "status": "pending",
        # ...
    }
    
    await self.supabase_service.create_indexing_job(job_data)
    return job_id

async def process_indexing_job(self, job_id: str, retry_count: int = 0):
    """Process job using stored access token."""
    job_data = await self._get_job_data(job_id)
    
    access_token = job_data["access_token"]  # ← GET FROM JOB
    file_id = job_data["file_id"]
    
    # Use token to fetch file
    file_bytes = self.drive_service.get_file_bytes(file_id, access_token)
    
    # If 401 error, job fails - frontend must retry with fresh token
```

### 4. Update Routers

Pass access token from request to service:

```python
# backend/app/routers/ingestion.py
@router.post("/start")
async def start_indexing(request: StartIndexingRequest, background_tasks: BackgroundTasks):
    job_id = await rag_indexer.index_file(
        file_id=request.file_id,
        user_id=request.user_id,
        access_token=request.access_token,  # ← PASS TOKEN
        file_name=request.file_name
    )
    
    background_tasks.add_task(
        rag_indexer.process_indexing_job,
        job_id=job_id,
        retry_count=0
    )
    
    return StartIndexingResponse(job_id=job_id, status="pending", ...)
```

### 5. Update Frontend API Calls

Frontend must get fresh token before each backend call:

```dart
// frontend/lib/services/api_service.dart
class ApiService {
  final AuthService _authService = AuthService();
  
  Future<String> startIndexing({
    required String userId,
    required String fileId,
    String? fileName,
  }) async {
    // Get fresh access token (auto-refreshes if needed)
    final accessToken = await _authService.getAccessToken();
    
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/ingest/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'file_id': fileId,
        'file_name': fileName,
        'access_token': accessToken,  // ← INCLUDE TOKEN
      }),
    );
    
    if (response.statusCode == 401) {
      // Token expired during request, retry once
      final newToken = await _authService.getAccessToken();
      if (newToken != null) {
        // Retry with fresh token
        return startIndexing(userId: userId, fileId: fileId, fileName: fileName);
      }
    }
    
    // Handle response...
  }
}
```

## Benefits of This Approach

1. **Follows platform conventions** - Respects how google_sign_in_all_platforms works
2. **No token storage in backend** - Backend is stateless regarding auth
3. **Automatic refresh** - Frontend handles token refresh transparently
4. **Better security** - Tokens never stored in backend database
5. **Simpler backend** - No complex refresh logic needed

## Migration Steps

1. ✅ Update `BackendDriveService` to accept `access_token` parameter
2. ✅ Add `access_token` field to request models
3. ✅ Update `RAGIndexer` to store and use access token from job data
4. ✅ Update routers to pass access token to services
5. ✅ Update frontend `ApiService` to include access token in requests
6. ✅ Update frontend `AuthService` to use silentSignIn() for refresh
7. ⏳ Remove old token storage/refresh logic from backend (optional cleanup)
8. ⏳ Update database schema to remove encrypted_tokens table (optional cleanup)

## Token Expiry Handling

### Backend Response
```json
{
  "error": "Access token expired or invalid. Please refresh token in app and retry.",
  "code": "TOKEN_EXPIRED"
}
```

### Frontend Handling
```dart
try {
  final result = await apiService.startIndexing(...);
} catch (e) {
  if (e.toString().contains('TOKEN_EXPIRED')) {
    // Force token refresh
    await authService.silentSignIn();
    // Retry request
    final result = await apiService.startIndexing(...);
  }
}
```

## Security Considerations

### Access Token in Request Body
- ✅ Use HTTPS (required)
- ✅ Short-lived tokens (1 hour expiry)
- ✅ No token storage in backend
- ✅ Tokens in request body (not URL params)

### Alternative: Authorization Header
Could also use standard Bearer token pattern:

```dart
headers: {
  'Authorization': 'Bearer $accessToken',
  'Content-Type': 'application/json',
}
```

Backend extracts from header:
```python
from fastapi import Header

async def start_indexing(
    request: StartIndexingRequest,
    authorization: str = Header(...)
):
    access_token = authorization.replace('Bearer ', '')
    # Use token...
```

## Conclusion

This pattern aligns with how modern OAuth2 clients work:
- Client manages tokens (refresh handled by platform)
- Server receives fresh tokens with each request
- Server is stateless regarding authentication
- Simple, secure, follows conventions
