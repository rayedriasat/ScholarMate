# Bug Fix: Missing PDFs in AI Chat Source Selection

## Problem
Not all PDFs are appearing in the source selection sidebar of the AI chat screen.

## Root Cause
The `_loadAvailableFiles()` method in `AIChatScreen` was only loading PDFs from the **root app folder**, not from subfolders.

### Original Code
```dart
final appFolderId = await driveService.getAppFolderId();
final files = await driveService.listFiles(appFolderId);  // ❌ Only root folder
```

This meant PDFs in subfolders (like "Notes", "Research", etc.) were not visible in the source selection panel.

## Solution
Changed to use `listAllFiles()` which recursively loads files from all folders.

### Updated Code
```dart
// Use listAllFiles() to get PDFs from all folders recursively
final files = await driveService.listAllFiles();  // ✅ All folders
```

## Changes Made

**File: `frontend/lib/screens/ai_chat_screen.dart`**

In the `_loadAvailableFiles()` method:
- Removed: `final appFolderId = await driveService.getAppFolderId();`
- Removed: `final files = await driveService.listFiles(appFolderId);`
- Added: `final files = await driveService.listAllFiles();`

## Impact

### Before Fix
- ❌ Only PDFs in root folder visible
- ❌ PDFs in subfolders not selectable
- ❌ Incomplete source selection

### After Fix
- ✅ All PDFs from all folders visible
- ✅ PDFs in subfolders selectable
- ✅ Complete source selection

## Testing

1. **Create test structure**:
   ```
   ScholarMate/
   ├── document1.pdf          (root)
   ├── Research/
   │   └── paper1.pdf         (subfolder)
   └── Notes/
       └── notes1.pdf         (subfolder)
   ```

2. **Open AI Chat**
3. **Click filter icon** (source selection)
4. **Verify all 3 PDFs appear** in the list

## Related Methods

The `DriveService` already had the recursive method:
```dart
/// List all files recursively from the app folder
Future<List<DriveFile>> listAllFiles() async {
  final allFiles = <DriveFile>[];
  final appFolderId = await getAppFolderId();
  await _listFilesRecursive(appFolderId, allFiles);
  return allFiles;
}
```

This was just not being used in the AI chat screen.

## Performance Considerations

- `listAllFiles()` may be slower for large folder structures
- Consider adding caching if performance becomes an issue
- Current implementation is acceptable for typical use cases

## Files Changed
- `frontend/lib/screens/ai_chat_screen.dart` - Updated `_loadAvailableFiles()`

## Future Improvements

Consider:
1. **Folder grouping** in source selection UI
2. **Search/filter** for large file lists
3. **Recently used** PDFs at the top
4. **Caching** file list to avoid repeated API calls
5. **Incremental loading** for very large libraries
