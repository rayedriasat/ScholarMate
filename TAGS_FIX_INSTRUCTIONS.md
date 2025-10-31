# Tags System Fix - Instructions

## Issues Fixed

1. **Backend API Error (422)**: The backend `/api/tags` endpoint requires a `user_id` query parameter, but the frontend wasn't always providing it.
2. **Frontend Database Error**: The local SQLite database didn't have the `tags` and `file_tags` tables.

## Changes Made

### Frontend Changes

1. **api_service.dart**: Made `user_id` required for `getTags()` method
2. **tag_service.dart**: 
   - Added `AuthService` dependency to get current user
   - Updated `_syncTagsFromBackend()` to use authenticated user's ID
3. **main.dart**: Added `authService` parameter to TagService provider
4. **Database schema**: Regenerated with `build_runner` to include tags tables

## How to Test

### Option 1: Clear App Data (Recommended for Android)

```bash
# Stop the app first, then:
adb shell pm clear com.example.frontend

# Or manually: Settings > Apps > ScholarMate > Storage > Clear Data
```

### Option 2: Uninstall and Reinstall

```bash
# Uninstall
adb uninstall com.example.frontend

# Reinstall
cd frontend
flutter run
```

### Option 3: Database Will Auto-Migrate

The database migration should automatically create the new tables when you restart the app. The schema version was bumped from 3 to 4, which includes:

```dart
if (from < 4) {
  // Migration from version 3 to 4: Add tags and file_tags tables
  await m.createTable(tags);
  await m.createTable(fileTags);
}
```

## Verification Steps

1. **Stop the running app** (important!)
2. **Clear app data** using one of the methods above
3. **Restart the app**
4. **Sign in** with your Google account
5. **Try creating a tag** - it should work without errors
6. **Check logs** for any remaining errors

## Expected Behavior

After the fix:
- ✅ Tags can be created, updated, and deleted
- ✅ Tags sync with backend when online
- ✅ Tags work offline and sync later
- ✅ No more "no such table: tags" errors
- ✅ No more "user_id required" API errors

## Troubleshooting

If you still see errors:

1. **Check if user is authenticated**: Tags require a logged-in user
2. **Verify backend is running**: The backend should be accessible at the configured URL
3. **Check Supabase migration**: Ensure the `004_tags.sql` migration ran successfully on Supabase
4. **View logs**: Look for specific error messages in the console

## Backend Verification

To verify the Supabase migration worked:

```sql
-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('tags', 'file_tags');

-- Check RLS policies
SELECT * FROM pg_policies 
WHERE tablename IN ('tags', 'file_tags');
```
