# Tag System - Quick Reference

## What Was Fixed

| Issue | Solution |
|-------|----------|
| 2 tags created with same name | Backend-first creation with single ID |
| "Research" vs "research" as separate tags | Case-insensitive duplicate detection |
| Tags not syncing | Bidirectional sync with deletion detection |
| Web platform issues | All fixes work on web |

## Test Commands

```bash
# Test backend
cd backend
uv run python test_tags.py

# Start backend
cd backend
uv run python run.py

# Start frontend (web)
cd frontend
flutter run -d chrome

# Start frontend (Windows)
cd frontend
flutter run -d windows
```

## Quick Test Scenarios

### 1. Duplicate Prevention ✅
1. Create tag "Research"
2. Try creating "research" (lowercase)
3. **Expected**: No duplicate, still 1 tag

### 2. Tag Sync ✅
1. Create tag on web
2. Refresh page
3. **Expected**: Tag still appears

### 3. File Tagging ✅
1. Right-click file → "Manage Tags"
2. Select tag → Apply
3. **Expected**: Tag appears on file

### 4. Offline Sync ✅ (Mobile only)
1. Create tag while offline
2. Go online
3. **Expected**: Tag syncs to backend

## Code Examples

### Create Tag
```dart
final tagService = context.read<TagService>();
final tag = await tagService.createTag(
  userId: userId,
  name: 'Research',
  color: '#2196F3',
);
```

### Get Tags
```dart
final tags = await tagService.getTags();
```

### Add Tag to File
```dart
await tagService.addTagToFile(
  userId: userId,
  fileId: fileId,
  tagId: tagId,
);
```

### Sync Offline Tags
```dart
await tagService.syncUnsyncedTags();
```

## Architecture

### Online Flow
```
User → Frontend → Backend (create) → Frontend (save with backend ID)
```

### Offline Flow
```
User → Frontend (create locally) → [Online] → Backend (sync)
```

## Key Files

| File | Purpose |
|------|---------|
| `frontend/lib/services/tag_service.dart` | Core tag logic |
| `backend/app/services/tag_service.py` | Backend tag service |
| `backend/app/routers/tags.py` | Tag API endpoints |
| `frontend/lib/screens/tag_management_screen.dart` | Tag management UI |
| `frontend/lib/widgets/tag_create_dialog.dart` | Create tag dialog |
| `frontend/lib/widgets/tag_selection_dialog.dart` | Tag selection UI |
| `frontend/lib/widgets/tag_chip.dart` | Tag display widget |

## API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/tags?user_id={id}` | Get all tags |
| POST | `/api/tags?user_id={id}` | Create tag |
| PUT | `/api/tags/{tag_id}?user_id={id}` | Update tag |
| DELETE | `/api/tags/{tag_id}?user_id={id}` | Delete tag |
| GET | `/api/tags/file/{file_id}?user_id={id}` | Get file tags |
| POST | `/api/tags/file?user_id={id}` | Add tag to file |
| DELETE | `/api/tags/file/{file_id}/{tag_id}?user_id={id}` | Remove tag from file |

## Database Tables

### tags
- `id` (UUID, PK)
- `user_id` (text)
- `name` (text)
- `color` (text)
- `created_at` (timestamp)
- `updated_at` (timestamp)

### file_tags
- `id` (UUID, PK)
- `user_id` (text)
- `file_id` (text)
- `tag_id` (UUID, FK)
- `created_at` (timestamp)

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Tags not appearing | Check backend is running, verify auth |
| Duplicate tags | Clear cache, restart backend |
| Tags not syncing | Check network, verify backend URL |
| Backend test fails | Check Supabase connection |

## Success Indicators

✅ Only 1 tag created per name
✅ Case variations don't create duplicates
✅ Tags persist after refresh
✅ Tags sync between devices
✅ Offline tags sync when online

## Documentation

- **`TAG_FIXES_SUMMARY.md`** - Complete overview
- **`TAGS_FIX_COMPLETE.md`** - Technical details
- **`TEST_TAGS_NOW.md`** - Testing guide
- **`TAG_QUICK_REFERENCE.md`** - This file

## Status

✅ **COMPLETE** - Ready for testing

Run `test-tags.bat` to verify!
