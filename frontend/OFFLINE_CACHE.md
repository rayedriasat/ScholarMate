# Offline Cache Implementation

## Overview

ScholarMate now supports full offline functionality with automatic synchronization when connectivity is restored. This implementation uses SQLite for local caching and a queue-based sync system.

## Architecture

### Services

1. **CacheService** (`lib/services/cache_service.dart`)
   - Manages SQLite database with tables for files, cached PDFs, annotations, and sync queue
   - Provides methods for caching and retrieving file metadata and PDF content
   - Tracks cache statistics and manages storage

2. **ConnectivityService** (`lib/services/connectivity_service.dart`)
   - Monitors network connectivity using `connectivity_plus` package
   - Provides real-time connectivity status updates via streams
   - Detects online/offline transitions

3. **SyncManager** (`lib/services/sync_manager.dart`)
   - Queues offline operations (create, delete, rename, move, upload)
   - Automatically syncs queued actions when connectivity is restored
   - Implements exponential backoff for failed sync attempts (max 5 retries)
   - Provides sync status updates for UI

4. **DriveService** (updated)
   - Integrated with CacheService and ConnectivityService
   - Falls back to cached data when offline
   - Queues operations via SyncManager when offline
   - Automatically caches downloaded PDFs

### Database Schema

```sql
-- File metadata
CREATE TABLE files (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  mime_type TEXT,
  size INTEGER,
  parent_id TEXT,
  modified_time TEXT,
  created_time TEXT,
  thumbnail_link TEXT,
  is_folder INTEGER NOT NULL,
  is_shared INTEGER NOT NULL,
  is_cached INTEGER DEFAULT 0,
  last_synced TEXT
);

-- Cached PDF content
CREATE TABLE cached_pdfs (
  file_id TEXT PRIMARY KEY,
  pdf_bytes BLOB NOT NULL,
  cached_at TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  FOREIGN KEY (file_id) REFERENCES files (id) ON DELETE CASCADE
);

-- PDF annotations
CREATE TABLE annotations (
  id TEXT PRIMARY KEY,
  file_id TEXT NOT NULL,
  page_number INTEGER NOT NULL,
  annotation_type TEXT NOT NULL,
  content TEXT,
  position TEXT,
  color TEXT,
  created_at TEXT NOT NULL,
  modified_at TEXT NOT NULL,
  is_synced INTEGER DEFAULT 0,
  FOREIGN KEY (file_id) REFERENCES files (id) ON DELETE CASCADE
);

-- Offline operation queue
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  operation_type TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT,
  payload TEXT NOT NULL,
  created_at TEXT NOT NULL,
  retry_count INTEGER DEFAULT 0,
  last_error TEXT,
  status TEXT DEFAULT 'pending'
);
```

## UI Components

### ConnectivityIndicator Widget

Located in the app bar, displays:
- **Green** with cloud icon: Online and synced
- **Orange** with sync icon: Syncing in progress
- **Orange** with upload icon: Pending actions (shows count)
- **Gray** with offline icon: Offline mode
- **Red** with error icon: Sync error

Tap the indicator to see detailed sync status and manually trigger sync.

### Cached File Indicators

PDF files that are cached for offline access show a green checkmark badge on their icon.

## Offline Operations

### Supported Operations

All operations work offline and are automatically synced when online:

1. **File Operations**
   - Upload files (queued until online)
   - Delete files (cached locally, synced when online)
   - Rename files (updated in cache, synced when online)
   - Move files (updated in cache, synced when online)

2. **Folder Operations**
   - Create folders (temporary ID assigned, synced when online)
   - Delete folders (cached locally, synced when online)
   - Rename folders (updated in cache, synced when online)

3. **PDF Viewing**
   - View cached PDFs offline
   - Download PDFs when online (automatically cached)
   - Annotations (queued for sync when online)

### Sync Behavior

- **Automatic Sync**: Triggered when connectivity is restored
- **Manual Sync**: Tap connectivity indicator and press "Sync Now"
- **Retry Logic**: Failed operations retry with exponential backoff (1s, 2s, 4s, 8s, 16s)
- **Max Retries**: 5 attempts before marking as failed
- **Failed Actions**: Can be viewed and cleared from sync status dialog

## Testing

### Test Scenarios

1. **Offline File Browsing**
   - Open app while online
   - Browse folders to cache metadata
   - Turn off network
   - Verify folders and files still load from cache

2. **Offline Operations**
   - Turn off network
   - Create a folder (should show temporary ID)
   - Rename a file
   - Delete a file
   - Verify operations are queued (check pending count)
   - Turn on network
   - Verify automatic sync completes

3. **PDF Caching**
   - Open a PDF while online (automatically cached)
   - Turn off network
   - Close and reopen the PDF
   - Verify it loads from cache

4. **Sync Recovery**
   - Queue multiple operations offline
   - Turn on network briefly (partial sync)
   - Turn off network again
   - Turn on network
   - Verify remaining operations sync

## Performance Considerations

- **Cache Size**: Monitor with `CacheService.getCacheStats()`
- **PDF Storage**: Large PDFs consume significant storage
- **Sync Queue**: Processes operations sequentially to avoid conflicts
- **Database Indexes**: Optimized for parent_id and file_id lookups

## Future Enhancements

- [ ] Cache size limits with LRU eviction
- [ ] Selective PDF caching (user choice)
- [ ] Background sync service
- [ ] Conflict resolution for concurrent edits
- [ ] Offline search in cached content
- [ ] Cache management UI (clear cache, view storage)

## Dependencies

```yaml
dependencies:
  sqflite: ^2.4.2          # SQLite database
  connectivity_plus: ^7.0.0 # Network connectivity monitoring
  path: ^1.9.1             # Path manipulation
```

## Database Migrations

The cache database uses versioned migrations to handle schema changes:

- **Version 1**: Initial schema with `parents` column
- **Version 2**: Removed redundant `parents` column (parent_id is sufficient)

Migrations are applied automatically on app startup. If you encounter database errors after an update, you may need to clear app data to force a fresh database creation.

## Troubleshooting

### Cache Not Working
- Check if database initialized: `CacheService.database`
- Verify permissions for local storage
- Check cache stats: `CacheService.getCacheStats()`

### Sync Not Triggering
- Verify connectivity service is running
- Check pending action count in sync manager
- Look for errors in sync status dialog

### Database Errors
- Clear app data to reset database (Settings > Apps > ScholarMate > Storage > Clear Data)
- Check for SQLite version compatibility
- Verify schema migrations are applied
- Check logs for migration errors

## Code Examples

### Checking Cache Status

```dart
final cacheService = context.read<CacheService>();
final stats = await cacheService.getCacheStats();
print('Cached files: ${stats['file_count']}');
print('Cached PDFs: ${stats['cached_pdf_count']}');
print('Total size: ${stats['total_cache_size']} bytes');
```

### Manual Sync

```dart
final syncManager = context.read<SyncManager>();
if (syncManager.pendingActionCount > 0) {
  await syncManager.manualSync();
}
```

### Checking Connectivity

```dart
final connectivityService = context.read<ConnectivityService>();
if (connectivityService.isOnline) {
  // Perform online operation
} else {
  // Use cached data
}
```
