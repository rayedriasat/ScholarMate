# Apply Annotation Sync - Setup Guide

## Step 1: Apply Database Migration

Run this SQL in Supabase SQL Editor:

```sql
-- Copy the entire content from backend/migrations/006_collaboration_annotations.sql
```

Or manually:

1. Go to https://supabase.com/dashboard/project/rqyzgfgdsedvohxyyqho/sql/new
2. Open `backend/migrations/006_collaboration_annotations.sql`
3. Copy all content
4. Paste and click "Run"

## Step 2: Restart Backend

```bash
cd backend
uv run run.py
```

## Step 3: Restart Frontend

```bash
cd frontend
flutter run -d chrome --web-port=8080 --dart-define-from-file=dart_defines.json
```

## What's New

### Backend
✅ New table: `collaboration_annotations`
✅ API endpoint: `POST /api/collaboration/sessions/{id}/annotations`
✅ API endpoint: `GET /api/collaboration/sessions/{id}/annotations`
✅ API endpoint: `DELETE /api/collaboration/sessions/{id}/annotations/{id}`
✅ Supabase Realtime enabled for annotations

### Frontend
✅ Annotation events captured
✅ Annotations sent to backend
✅ Annotations synced via Supabase Realtime (automatic)

## Testing

### Test Annotation Sync

1. **User A:** Open PDF → Start collaboration
2. **User B:** Join session
3. **User A:** Highlight some text (yellow highlight)
4. **Check User B's screen:** Should see the highlight appear instantly!
5. **User B:** Highlight different text
6. **Check User A's screen:** Should see User B's highlight!

### Debug Console

Open browser console (F12) and look for:
- `Annotation added: ...`
- `Annotation synced successfully`
- `Annotation deleted successfully`

### Check Database

Go to Supabase → Table Editor → `collaboration_annotations`
- Should see annotations being saved
- Each annotation has session_id, user_id, bounds, color, etc.

## Expected Behavior

✅ User A highlights → User B sees it in real-time
✅ User B highlights → User A sees it in real-time
✅ Annotations persist in database
✅ Annotations load when joining session
✅ Delete annotation → Removed for all users

## Troubleshooting

**Annotations not appearing:**
- Check browser console for errors
- Verify backend is running
- Check Supabase Realtime is enabled
- Verify migration was applied

**"Failed to add annotation" error:**
- Check backend logs
- Verify Supabase connection
- Check RLS policies allow insert

**Annotations disappear on refresh:**
- Need to implement "load existing annotations" on join
- Currently only syncs new annotations

## Architecture

```
User A                          Backend                         User B
  |                               |                               |
  | Highlight text                |                               |
  |---POST /annotations---------->|                               |
  |                               |                               |
  |                               | Save to Supabase              |
  |                               | collaboration_annotations     |
  |                               |                               |
  |                               |--Supabase Realtime---------->|
  |                               |  (broadcast annotation)       |
  |                               |                               |
  |                               |                               | Display highlight
  |<--Supabase Realtime-----------|                               |
  | (receive confirmation)        |                               |
```

## Files Modified

**Backend:**
- `backend/migrations/006_collaboration_annotations.sql` (NEW)
- `backend/app/routers/collaboration.py` (added endpoints)
- `backend/app/services/collaboration_service.py` (added methods)

**Frontend:**
- `frontend/lib/screens/collaborative_pdf_viewer_screen.dart` (annotation sync)

## Next Enhancement

To load existing annotations when joining:
1. Call `GET /api/collaboration/sessions/{id}/annotations` on join
2. Add annotations to PDF viewer programmatically
3. Subscribe to Realtime for new annotations
