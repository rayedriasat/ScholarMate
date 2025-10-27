# Manual Refresh Implementation

## Problem
Cached PDF files were not being updated when modified on Google Drive from another device. Users were seeing stale versions.

## Solution
Added a **manual refresh button** in the PDF viewer that forces a fresh download from Google Drive, bypassing the cache.

## Implementation

### 1. PDF Viewer Screen
Added a refresh button in the app bar that:
- Only shows when online (disabled when offline)
- Forces a fresh download from Google Drive
- Updates the cache with the new version
- Shows feedback to the user

### 2. Updated Methods

#### `_refreshPdf()` - New method in PDF Viewer Screen
```dart
Future<void> _refreshPdf() async {
  // Show loading indicator
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Checking for updates...'),
        ],
      ),
      duration: Duration(seconds: 2),
    ),
  );
  
  // Force refresh from Drive
  await _loadPdf(forceRefresh: true);
  
  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('PDF refreshed from Google Drive'),
      backgroundColor: Colors.green,
    ),
  );
}
```

#### `_loadPdf()` - Updated to support force refresh
```dart
Future<void> _loadPdf({bool forceRefresh = false}) async {
  final pdfManager = context.read<PdfViewerManager>();
  await pdfManager.loadPdf(widget.file, forceRefresh: forceRefresh);
}
```

### 3. PdfViewerManager Service
Updated `loadPdf()` method to support `forceRefresh` parameter:

```dart
Future<Uint8List?> loadPdf(DriveFile file, {bool forceRefresh = false}) async {
  // If forceRefresh is true, skip cache and download from Drive
  if (!forceRefresh) {
    // Try to load from cache first
    final cachedPdf = await _cacheService.getCachedPdf(file.id);
    if (cachedPdf != null) {
      return cachedPdf; // Return cached version
    }
  } else {
    debugPrint('Force refresh requested, downloading from Drive');
  }
  
  // Download from Drive
  final pdfBytes = await _driveService.downloadFile(
    file.id,
    forceRefresh: forceRefresh,
  );
  
  // Update cache with new version
  await _cacheService.cachePdfBytes(file.id, pdfBytes);
  
  return pdfBytes;
}
```

### 4. DriveService
The `downloadFile()` method already supports `forceRefresh`:

```dart
Future<Uint8List?> downloadFile(
  String fileId, {
  bool forceRefresh = false,
}) async {
  // If forceRefresh is true, skip cache check
  if (!forceRefresh && _cacheService != null) {
    final cachedPdf = await _cacheService.getCachedPdf(fileId);
    if (cachedPdf != null) {
      return cachedPdf; // Return cached version
    }
  }
  
  // Download from Drive
  final response = await http.get(
    Uri.parse('$baseUrl/files/$fileId?alt=media'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );
  
  // Cache the new version
  await _cacheService.cachePdfBytes(fileId, response.bodyBytes);
  
  return response.bodyBytes;
}
```

## User Experience

### Refresh Button Location
The refresh button is located in the app bar, next to other action buttons:
```
[<] [PDF Name]  [🔄 Refresh] [✏️ Edit] [🔖 Annotations] [🔍 Search] [#]
```

### Button States
1. **Online**: Button is enabled (normal color)
   - Tooltip: "Refresh from Google Drive"
   
2. **Offline**: Button is disabled (grey)
   - Tooltip: "Offline - Cannot refresh"

### User Flow
1. User opens a PDF (loads from cache if available)
2. User clicks the refresh button (🔄)
3. Shows "Checking for updates..." snackbar
4. Downloads fresh copy from Google Drive
5. Updates cache with new version
6. Shows "PDF refreshed from Google Drive" success message
7. PDF viewer reloads with updated content

## Testing

### Manual Test Steps

1. **Basic Refresh**
   - [ ] Open a PDF on Device A
   - [ ] Modify the PDF on Device B (or web)
   - [ ] On Device A, click refresh button
   - [ ] Verify updated version is shown

2. **Offline Behavior**
   - [ ] Open a PDF while online
   - [ ] Go offline
   - [ ] Verify refresh button is disabled
   - [ ] Verify tooltip shows "Offline - Cannot refresh"

3. **Cache Update**
   - [ ] Open a PDF
   - [ ] Modify it elsewhere
   - [ ] Click refresh
   - [ ] Close and reopen the PDF
   - [ ] Verify it shows the updated version (cache was updated)

4. **Error Handling**
   - [ ] Open a PDF
   - [ ] Delete it from Drive
   - [ ] Click refresh
   - [ ] Verify error message is shown

5. **Loading Indicator**
   - [ ] Click refresh button
   - [ ] Verify "Checking for updates..." message shows
   - [ ] Verify success message shows after download

## Code Changes

### Files Modified
1. **frontend/lib/screens/pdf_viewer_screen.dart**
   - Added `_refreshPdf()` method
   - Updated `_loadPdf()` to accept `forceRefresh` parameter
   - Added refresh button to app bar with online/offline state

2. **frontend/lib/services/pdf_viewer_manager.dart**
   - Updated `loadPdf()` to accept `forceRefresh` parameter
   - Skip cache when `forceRefresh` is true

3. **frontend/lib/services/drive_service.dart**
   - Already had `forceRefresh` parameter (no changes needed)

## Benefits

### For Users
✓ Always can get the latest version with one click  
✓ Clear visual feedback (loading and success messages)  
✓ Works seamlessly with offline mode  
✓ Simple and intuitive (just click refresh)  

### For Developers
✓ Clean implementation (single parameter)  
✓ Reuses existing download logic  
✓ No background polling (battery friendly)  
✓ Easy to test and debug  

## Comparison with Auto-Sync

### Manual Refresh (Current Implementation)
- ✓ User controls when to check for updates
- ✓ No battery drain from background polling
- ✓ Simple implementation
- ✓ Clear user intent
- ✗ Requires user action

### Auto-Sync (Previous Approach)
- ✓ Automatic updates
- ✗ Battery drain from periodic polling
- ✗ Complex implementation
- ✗ May interrupt user
- ✗ Network usage even when not needed

## Future Enhancements

1. **Smart Refresh**
   - Check modification time before downloading
   - Only download if file actually changed
   - Show "Already up to date" message

2. **Auto-Refresh on Open**
   - Optional setting to check for updates on file open
   - User can enable/disable in settings

3. **Refresh All**
   - Button to refresh all cached PDFs
   - Useful after being offline for a while

4. **Last Modified Indicator**
   - Show when file was last modified
   - Show when cache was last updated
   - Help user decide if refresh is needed

5. **Push Notifications**
   - Use Supabase Realtime to notify of changes
   - Show notification when file is updated
   - User can tap to refresh

## Summary

The manual refresh implementation provides a simple, reliable way for users to get the latest version of their PDFs from Google Drive. It's battery-efficient, easy to use, and works seamlessly with the existing offline-first architecture.

**Key Points:**
- One-click refresh from Google Drive
- Only enabled when online
- Updates cache automatically
- Clear user feedback
- No background polling
- Battery friendly

The implementation is complete and ready for use!
