# Real-Time File Synchronization - Implementation

## Problem
Once a file is opened and cached, it doesn't fetch the updated version from Google Drive. If a file is modified from another device, the cached version is shown instead of the latest version.

## Solution
Implemented a comprehensive file synchronization system that:
1. Checks for updates before returning cached files
2. Periodically syncs watched files in the background
3. Provides manual refresh options
4. Shows sync status to users

## Components

### 1. FileSyncService (`frontend/lib/services/file_sync_service.dart`)

**Purpose:** Manages real-time file synchronization with Google Drive

**Key Features:**
- **File Watching:** Track specific files for changes
- **Periodic Sync:** Automatically check for updates every 30 seconds (configurable)
- **Update Detection:** Compare modification timestamps to detect changes
- **Cache Refresh:** Automatically download and cache updated files
- **Stream Updates:** Notify listeners when files are updated

**Methods:**
```dart
// Start watching a file for changes
void watchFile(String fileId)

// Stop watching a file
void unwatchFile(String fileId)

// Get stream of updates for a file
Stream<DriveFile> getFileUpdateStream(String fileId)

// Manually trigger sync for a file
Future<bool> syncFile(String fileId)

// Sync all watched files
Future<void> syncAllWatchedFiles()
```

**How It Works:**
1. When a file is opened, call `watchFile(fileId)`
2. Service starts periodic timer (30s interval)
3. On each interval:
   - Fetch file metadata from Drive
   - Compare `modifiedTime` with cached version
   - If Drive version is newer:
     - Download updated file
     - Update cache
     - Notify listeners via stream
4. When file is closed, call `unwatchFile(fileId)`

### 2. Updated DriveService

**Changes to `downloadFile()` method:**
- Added `forceRefresh` parameter
- Checks for updates before returning cached version
- Compares modification timestamps
- Downloads fresh copy if Drive version is newer

**New `_getFileMetadata()` method:**
- Fetches file metadata from Drive
- Used for update detection
- Returns `DriveFile` with current metadata

### 3. UI Components (`frontend/lib/widgets/file_sync_indicator.dart`)

**FileSyncIndicator:**
- Full sync status display
- Shows last sync time
- Manual refresh button
- Syncing indicator

**FileSyncBadge:**
- Compact sync badge for file lists
- Shows sync status icon
- Tooltip with last sync time

**SyncFloatingActionButton:**
- Floating action button for manual sync
- Shows syncing progress
- Displays success/error messages

## Usage

### Setup Services

```dart
// Initialize services
final authService = AuthService();
final cacheService = CacheService();
final connectivityService = ConnectivityService();

final fileSyncService = FileSyncService(
  authService: authService,
  cacheService: cacheService,
  connectivityService: connectivityService,
);

// Provide to widget tree
MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: authService),
    ChangeNotifierProvider.value(value: cacheService),
    ChangeNotifierProvider.value(value: connectivityService),
    ChangeNotifierProvider.value(value: fileSyncService),
  ],
  child: MyApp(),
)
```

### Watch File When Opening

```dart
class PDFViewerScreen extends StatefulWidget {
  final String fileId;
  
  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  late FileSyncService _syncService;
  StreamSubscription<DriveFile>? _updateSubscription;
  
  @override
  void initState() {
    super.initState();
    _syncService = context.read<FileSyncService>();
    
    // Start watching file
    _syncService.watchFile(widget.fileId);
    
    // Listen for updates
    _updateSubscription = _syncService
        .getFileUpdateStream(widget.fileId)
        .listen((updatedFile) {
      // File was updated, reload PDF
      _reloadPDF();
    });
  }
  
  @override
  void dispose() {
    // Stop watching file
    _syncService.unwatchFile(widget.fileId);
    _updateSubscription?.cancel();
    super.dispose();
  }
  
  void _reloadPDF() {
    // Reload PDF with forceRefresh
    driveService.downloadFile(
      widget.fileId,
      forceRefresh: true,
    ).then((bytes) {
      // Update PDF viewer
      setState(() {
        pdfBytes = bytes;
      });
    });
  }
}
```

### Add Sync Indicator to UI

```dart
// Full sync indicator with refresh button
FileSyncIndicator(
  fileId: fileId,
  onRefresh: () {
    // Reload PDF after sync
    _reloadPDF();
  },
)

// Compact badge for file list
FileSyncBadge(
  fileId: fileId,
  showLastSync: true,
)

// Floating action button
SyncFloatingActionButton(
  fileId: fileId,
  onSyncComplete: () {
    // Reload PDF after sync
    _reloadPDF();
  },
)
```

### Manual Sync

```dart
// Sync a specific file
final success = await fileSyncService.syncFile(fileId);
if (success) {
  // File synced, reload if needed
}

// Sync all watched files
await fileSyncService.syncAllWatchedFiles();
```

### Configure Sync Interval

```dart
// Change sync interval (default: 30 seconds)
fileSyncService.syncInterval = Duration(seconds: 15); // Check every 15s
fileSyncService.syncInterval = Duration(minutes: 1);  // Check every minute
```

## How Update Detection Works

### 1. Timestamp Comparison
```dart
// Get cached file metadata
final cachedFile = await cacheService.getCachedFile(fileId);
final cachedModified = cachedFile.modifiedTime; // e.g., 2025-10-28 10:00:00

// Get current file metadata from Drive
final driveFile = await getFileMetadata(fileId);
final driveModified = driveFile.modifiedTime; // e.g., 2025-10-28 10:05:00

// Compare timestamps
if (driveModified.isAfter(cachedModified)) {
  // File was updated on Drive, refresh cache
  await refreshFileCache(fileId, driveFile);
}
```

### 2. Cache Refresh Process
```dart
// 1. Update metadata in cache
await cacheService.cacheFileMetadata(updatedMetadata);

// 2. Download updated file content
final response = await http.get(
  Uri.parse('$baseUrl/files/$fileId?alt=media'),
  headers: {'Authorization': 'Bearer $accessToken'},
);

// 3. Update cached PDF bytes
final bytes = response.bodyBytes;
await cacheService.cachePdfBytes(fileId, bytes);

// 4. Notify listeners
notifyListeners();
```

### 3. Stream Notification
```dart
// Notify listeners via stream
_fileUpdateControllers[fileId]?.add(updatedFile);

// Listeners receive update
_updateSubscription = syncService
    .getFileUpdateStream(fileId)
    .listen((updatedFile) {
  // Reload PDF viewer with updated file
  _reloadPDF();
});
```

## Performance Considerations

### 1. Efficient Polling
- Only checks watched files (not all cached files)
- Configurable sync interval (default: 30s)
- Stops polling when no files are watched
- Only polls when online

### 2. Minimal API Calls
- Uses metadata endpoint (lightweight)
- Only downloads full file if update detected
- Caches metadata to avoid redundant checks

### 3. Smart Caching
- Compares timestamps before downloading
- Reuses cached files when up-to-date
- Updates cache atomically

### 4. Resource Management
- Stops watching when file is closed
- Cancels timers when no files watched
- Cleans up stream controllers

## Testing

### Manual Testing Checklist

1. **Basic Sync**
   - [ ] Open file on Device A
   - [ ] Modify file on Device B (or web)
   - [ ] Wait 30 seconds
   - [ ] Verify Device A shows updated version

2. **Manual Refresh**
   - [ ] Open file
   - [ ] Modify file elsewhere
   - [ ] Click refresh button
   - [ ] Verify updated version loads

3. **Offline Behavior**
   - [ ] Open file online
   - [ ] Go offline
   - [ ] Verify cached version still accessible
   - [ ] Go back online
   - [ ] Verify sync resumes

4. **Multiple Files**
   - [ ] Open multiple files
   - [ ] Modify one file elsewhere
   - [ ] Verify only modified file syncs
   - [ ] Verify other files unchanged

5. **Sync Indicators**
   - [ ] Verify "Checking..." shows initially
   - [ ] Verify "Checked Xs ago" updates
   - [ ] Verify syncing spinner shows during sync
   - [ ] Verify refresh button works

### Automated Testing

```dart
// Test update detection
test('detects file updates', () async {
  final syncService = FileSyncService(
    authService: mockAuthService,
    cacheService: mockCacheService,
    connectivityService: mockConnectivityService,
  );
  
  // Cache old version
  await mockCacheService.cacheFileMetadata(oldFile);
  
  // Mock Drive returning newer version
  when(mockDriveService.getFileMetadata(fileId))
      .thenAnswer((_) async => newFile);
  
  // Start watching
  syncService.watchFile(fileId);
  
  // Wait for sync
  await Future.delayed(Duration(seconds: 1));
  
  // Verify cache was updated
  verify(mockCacheService.cachePdfBytes(fileId, any)).called(1);
});
```

## Configuration

### Sync Interval
```dart
// Default: 30 seconds
fileSyncService.syncInterval = Duration(seconds: 30);

// For real-time collaboration: 10-15 seconds
fileSyncService.syncInterval = Duration(seconds: 10);

// For battery saving: 1-2 minutes
fileSyncService.syncInterval = Duration(minutes: 1);
```

### Watched Files Limit
```dart
// Limit number of watched files to conserve resources
const maxWatchedFiles = 10;

if (_watchedFiles.length >= maxWatchedFiles) {
  // Remove oldest watched file
  final oldest = _watchedFiles.first;
  unwatchFile(oldest);
}
```

## Troubleshooting

### File Not Updating

**Possible Causes:**
1. File not being watched
2. Offline mode
3. Sync interval too long
4. Timestamp comparison issue

**Solutions:**
```dart
// 1. Verify file is watched
print('Watched files: ${syncService._watchedFiles}');

// 2. Check connectivity
print('Online: ${connectivityService.isOnline}');

// 3. Reduce sync interval
syncService.syncInterval = Duration(seconds: 10);

// 4. Force manual sync
await syncService.syncFile(fileId);
```

### High Battery Usage

**Possible Causes:**
1. Too many watched files
2. Sync interval too short
3. Large files being synced frequently

**Solutions:**
```dart
// 1. Limit watched files
if (_watchedFiles.length > 5) {
  unwatchFile(oldestFileId);
}

// 2. Increase sync interval
syncService.syncInterval = Duration(minutes: 1);

// 3. Only watch active file
// Unwatch files when navigating away
```

### Sync Conflicts

**Scenario:** File modified on multiple devices simultaneously

**Current Behavior:** Last-write-wins (Drive's modification time)

**Future Enhancement:** Conflict resolution UI

## Future Enhancements

1. **Real-time Updates via Supabase Realtime**
   - Push notifications for file changes
   - Instant updates without polling
   - Lower battery usage

2. **Conflict Resolution UI**
   - Show both versions when conflict detected
   - Allow user to choose which version to keep
   - Merge changes if possible

3. **Selective Sync**
   - User can choose which files to sync
   - Priority sync for important files
   - Pause sync for large files on metered connections

4. **Sync History**
   - Track sync history
   - Show what changed
   - Rollback to previous versions

5. **Bandwidth Optimization**
   - Delta sync (only changed parts)
   - Compression
   - Adaptive sync interval based on activity

## Files Created/Modified

### New Files
- ✓ `frontend/lib/services/file_sync_service.dart`
- ✓ `frontend/lib/widgets/file_sync_indicator.dart`
- ✓ `FILE_SYNC_IMPLEMENTATION.md`

### Modified Files
- ✓ `frontend/lib/services/drive_service.dart`
  - Added `forceRefresh` parameter to `downloadFile()`
  - Added `_getFileMetadata()` method
  - Added update detection logic

## Summary

The file synchronization system ensures users always see the latest version of their files by:
- Automatically checking for updates every 30 seconds
- Comparing modification timestamps
- Downloading updated files when detected
- Providing manual refresh options
- Showing sync status to users

This solves the issue of cached files becoming stale and enables real-time collaboration across devices.
