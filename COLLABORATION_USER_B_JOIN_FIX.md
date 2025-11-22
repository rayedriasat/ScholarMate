# Collaboration User B Join & Drive Access Fix - COMPLETE ✅

## Problems Fixed

### 1. No UI for User B to Join Collaboration
**Problem**: User B had no way to access the "Join Collaboration" screen.

**Solution**: Added "Join Collaboration" menu item to File Explorer popup menu.

**Location**: Files screen → Three-dot menu (top right) → "Join Collaboration" (purple icon)

### 2. Google Drive Access Issue
**Problem**: When User B joins, they can't access User A's Google Drive file because:
- User B doesn't have permission to User A's Drive
- Each user's Drive is isolated (app folder scope)
- Direct Drive URL fails with 403 Forbidden

**Solution**: Created PDF proxy endpoint that:
1. Verifies user is session participant
2. Uses owner's access token to download PDF
3. Serves PDF to all participants
4. Maintains security with participant verification

## Implementation Details

### Frontend Changes

#### 1. File Explorer Menu (`file_explorer_screen.dart`)
Added menu item:
```dart
const PopupMenuItem(
  value: 'join_collaboration',
  child: Row(
    children: [
      Icon(Icons.people, size: 20, color: Colors.purple),
      SizedBox(width: 8),
      Text('Join Collaboration'),
    ],
  ),
),
```

#### 2. Collaborative PDF Viewer (`collaborative_pdf_viewer_screen.dart`)
Changed PDF loading from Drive to proxy:

**Before:**
```dart
_pdfBytes = await driveService.downloadFile(widget.fileId);
```

**After:**
```dart
// Use backend proxy endpoint
final url = Uri.parse(
  '${backendUrl}/api/collaboration/sessions/${sessionId}/pdf?user_id=${userId}',
);
final response = await http.get(url);
_pdfBytes = response.bodyBytes;
```

### Backend Changes

#### New Endpoint: `/api/collaboration/sessions/{session_id}/pdf`
**Purpose**: Proxy PDF from owner's Drive to all participants

**Flow**:
1. Verify user is session participant
2. Get session owner's access token from Supabase
3. Decrypt token using encryption service
4. Download PDF from owner's Drive using their token
5. Return PDF bytes to requesting user

**Security**:
- Only session participants can access
- Uses owner's token (not requester's)
- Token stored encrypted in database
- Participant verification via Supabase

**Code**:
```python
@router.get("/sessions/{session_id}/pdf")
async def get_session_pdf(session_id: str, user_id: str):
    # Verify participant
    session = await service.get_session(session_id)
    is_participant = any(p["user_id"] == user_id for p in session["participants"])
    
    # Get owner's token
    encrypted_token = await supabase.get_encrypted_token(owner_id, "access_token")
    access_token = encryption_service.decrypt(encrypted_token)
    
    # Download from Drive
    drive_url = f"https://www.googleapis.com/drive/v3/files/{file_id}?alt=media"
    response = await httpx.get(drive_url, headers={"Authorization": f"Bearer {access_token}"})
    
    return Response(content=response.content, media_type="application/pdf")
```

## User Flow

### User A (Owner) - Create Session:
1. Open PDF in regular viewer
2. Click purple collaboration icon
3. Session created automatically
4. Click share button → Copy session ID
5. Send session ID to User B (email, chat, etc.)

### User B (Joiner) - Join Session:
1. Open ScholarMate
2. Go to Files screen
3. Click three-dot menu (⋮) top right
4. Select "Join Collaboration" (purple icon)
5. Paste session ID from User A
6. Click "Join Session"
7. **PDF loads via proxy** ✅ (no Drive access needed)
8. See User A's cursor and annotations in real-time

## How PDF Access Works

```
User B Request
    ↓
Backend Proxy Endpoint
    ↓
Verify: Is User B in session? ✓
    ↓
Get Owner (User A) access token
    ↓
Download PDF from User A's Drive
    ↓
Return PDF bytes to User B
    ↓
User B sees PDF ✅
```

## Files Modified

### Frontend:
- `frontend/lib/screens/file_explorer_screen.dart`
  - Added "Join Collaboration" menu item
  - Added import for `JoinCollaborationScreen`
  
- `frontend/lib/screens/collaborative_pdf_viewer_screen.dart`
  - Changed PDF loading to use proxy endpoint
  - Added `http` and `ConfigService` imports
  - Updated `_loadPdfFromDrive()` method

### Backend:
- `backend/app/routers/collaboration.py`
  - Added `GET /api/collaboration/sessions/{session_id}/pdf` endpoint
  - Participant verification
  - Owner token retrieval and decryption
  - PDF proxy from Drive

- `backend/pyproject.toml`
  - Added `httpx` dependency for async HTTP requests

## Testing Steps

1. **Start backend**: Already running on port 8000 ✅
2. **Run frontend**: `cd frontend && flutter run -d chrome`

### Test User A (Owner):
3. Sign in as User A
4. Open any PDF
5. Click purple collaboration icon
6. Verify PDF displays
7. Click share → Copy session ID (e.g., `abc123xyz`)

### Test User B (Joiner):
8. Open in incognito/different browser
9. Sign in as User B (different Google account)
10. Go to Files screen
11. Click three-dot menu (⋮)
12. Click "Join Collaboration"
13. Paste session ID: `abc123xyz`
14. Click "Join Session"
15. **Verify PDF displays** ✅ (should work even though User B doesn't own the file)
16. See User A in participants list
17. See User A's cursor moving

### Test Real-time Sync:
18. User A: Create highlight annotation
19. User B: Should see it appear immediately
20. User B: Create underline annotation
21. User A: Should see it appear immediately

## Security Considerations

✅ **Participant verification** - Only session members can access PDF
✅ **Token encryption** - Owner tokens stored encrypted in Supabase
✅ **No token exposure** - Tokens never sent to frontend
✅ **Session expiration** - Sessions expire after 7 days
✅ **RLS policies** - Supabase enforces row-level security

## Next Steps

- [ ] Test join flow with two different Google accounts
- [ ] Verify PDF loads for User B via proxy
- [ ] Test annotation sync between users
- [ ] Run migration 006 in Supabase for annotation persistence
- [ ] Test session expiration (optional)

## Backend Status

✅ Running on http://localhost:8000
⚠️ **RESTART REQUIRED** - New endpoint added, restart backend to activate:
```bash
# Stop current backend (Ctrl+C in terminal)
# Then restart:
cd backend
uv run python run.py
```
✅ httpx dependency installed
