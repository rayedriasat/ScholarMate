# Windows Database Fix

## Problem
**Error**: `SqliteException(14): while opening the database, unable to open database file`

When running the ScholarMate app on Windows desktop, the file explorer view showed a database error. This was caused by SQLite not being able to create/open the database file.

## Root Cause
The `driftDatabase()` function in `database.dart` was using default configuration for native platforms, which sometimes fails on Windows because:
1. The database directory doesn't exist
2. The path is not properly specified for Windows
3. Permissions issues with the default location

## Solution
Updated `frontend/lib/database/database.dart` to explicitly specify the database path for native platforms (Windows, Linux, macOS, Android, iOS):

### Changes Made

1. **Added imports**:
   - `package:flutter/foundation.dart` - for `kIsWeb` platform detection
   - `package:path_provider/path_provider.dart` - for getting proper application directory
   - `package:path/path.dart` - for cross-platform path joining

2. **Updated `_openConnection()` function**:
   - Split logic between web and native platforms
   - For native platforms, use `DriftNativeOptions` with explicit `databasePath`
   - Database is now stored at: `{ApplicationDocumentsDirectory}/scholarmate_cache.db`

3. **Added `_getDatabasePathSync()` helper**:
   - Gets the application documents directory
   - Creates proper database file path using platform-appropriate path separators

### Database Location by Platform
- **Windows**: `C:\Users\{username}\Documents\scholarmate_cache.db`
- **Android**: `/data/data/com.yourapp/files/scholarmate_cache.db`
- **iOS**: `{app_documents}/scholarmate_cache.db`
- **macOS**: `~/Documents/scholarmate_cache.db`
- **Linux**: `~/Documents/scholarmate_cache.db`
- **Web**: IndexedDB (browser storage)

## Testing
The app should now:
✅ Open successfully on Windows
✅ Display the file explorer view without errors
✅ Store data persistently in the local database
✅ Work across all platforms (web, Android, iOS, Windows, Linux, macOS)

## Additional Notes
- The `path_provider` package is already included in `pubspec.yaml`
- No additional dependencies were needed
- The fix maintains cross-platform compatibility
- Database will be automatically created on first run

