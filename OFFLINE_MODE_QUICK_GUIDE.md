# Offline Mode - Quick Visual Guide

## 🎉 Good News!

Your offline mode with task queue **was never lost** - it just needed the UI indicator to be visible!

## What I Found & Fixed

### ✅ Already Working (No Changes Needed)
- **SyncManager** - Handles offline task queue
- **ConnectivityService** - Monitors online/offline status
- **DriveService** - All operations queue when offline
- **CacheService** - SQLite database with sync_queue table
- **Provider setup** - All services properly configured

### ✅ What Was Missing (Now Fixed)
- **ConnectivityIndicator** - Not visible in UI
  - ✅ Added to FileExplorerScreen AppBar
  - ✅ Added to PDFViewerScreen AppBar

## Visual Guide

### Status Indicators You'll See

#### 🟢 Online & Synced
```
┌─────────────────┐
│ 🟢 Online       │
└─────────────────┘
```
Everything is synced with Google Drive.

#### ⚫ Offline Mode
```
┌─────────────────┐
│ ⚫ Offline       │
└─────────────────┘
```
No internet connection. Operations will queue for sync.

#### 🟠 Pending Syncs
```
┌─────────────────┐
│ 🟠 3 pending    │
└─────────────────┘
```
3 operations waiting to sync when online.

#### 🟠 Syncing
```
┌─────────────────┐
│ ⚙️ Syncing      │
└─────────────────┘
```
Currently syncing queued operations to Drive.

#### 🔴 Sync Error
```
┌─────────────────┐
│ 🔴 Sync Error   │
└─────────────────┘
```
Some operations failed to sync. Tap to see details.

### Sync Status Dialog

Tap the connectivity indicator to see:

```
┌───────────────────────────────────┐
│   🟢 Online                       │
├───────────────────────────────────┤
│                                   │
│   Connection        Connected     │
│   Sync Status       Idle          │
│   Pending Actions   3             │
│                                   │
│   [Sync Now]          [Close]     │
│                                   │
└───────────────────────────────────┘
```

## Example Workflows

### Scenario 1: Upload File Offline

```
1. Turn on airplane mode
   └─> ⚫ Offline indicator appears

2. Upload a PDF "Report.pdf"
   └─> ⚫ → 🟠 1 pending
   └─> File appears in list (temp ID)

3. Turn off airplane mode
   └─> 🟠 Syncing... (spinner)
   └─> File uploads to Drive
   └─> 🟢 Online (synced!)
```

### Scenario 2: Create Folder Offline

```
1. Offline mode (⚫ Offline)

2. Create folder "Research"
   └─> Folder appears with temp_xxxxx ID
   └─> 🟠 1 pending

3. Upload file to "Research" folder
   └─> File queued to temp_xxxxx
   └─> 🟠 2 pending

4. Go online
   └─> 🟠 Syncing...
   └─> Folder created (gets real ID)
   └─> File uploaded to real folder
   └─> Temp IDs updated automatically
   └─> 🟢 Online
```

### Scenario 3: Rename & Delete Offline

```
1. Offline mode

2. Rename "Old.pdf" → "New.pdf"
   └─> Name updates in UI
   └─> 🟠 1 pending

3. Delete "Unused.pdf"
   └─> File removed from UI
   └─> 🟠 2 pending

4. Go online
   └─> Both operations sync to Drive
   └─> 🟢 Online
```

### Scenario 4: View Cached PDFs Offline

```
1. Online: Open "Document.pdf"
   └─> PDF cached automatically

2. Go offline

3. Navigate away, then back to file list

4. Open "Document.pdf" again
   └─> Loads from cache instantly!
   └─> Can view and annotate offline
```

## Where to Find the Indicator

### File Explorer Screen
```
┌────────────────────────────────────┐
│ ← Files              🟢 Online  ≡ │
├────────────────────────────────────┤
│ ScholarMate                        │
│ ┌────────────────────────────────┐ │
│ │ 📁 Folder 1                    │ │
│ │ 📄 Document.pdf                │ │
│ │ 📄 Report.pdf                  │ │
│ └────────────────────────────────┘ │
└────────────────────────────────────┘
```

### PDF Viewer Screen
```
┌────────────────────────────────────┐
│ ← Document.pdf       🟢 Online  ⋮ │
├────────────────────────────────────┤
│                                    │
│         PDF Content Here           │
│                                    │
│                                    │
│                                    │
└────────────────────────────────────┘
```

## Testing Checklist

### ✅ Quick Test (5 minutes)

1. **Online Test**
   - [ ] Open app
   - [ ] See 🟢 "Online" indicator
   - [ ] Tap indicator → see connection dialog

2. **Offline Test**
   - [ ] Enable airplane mode
   - [ ] See ⚫ "Offline" indicator
   - [ ] Upload a file → see 🟠 "1 pending"
   - [ ] Tap indicator → see "Pending Actions: 1"

3. **Sync Test**
   - [ ] Disable airplane mode
   - [ ] See 🟠 "Syncing" (spinner)
   - [ ] Wait for completion
   - [ ] See 🟢 "Online"
   - [ ] File appears in Google Drive

### ✅ Full Test (15 minutes)

1. **Offline Operations**
   - [ ] Go offline
   - [ ] Create folder "Test"
   - [ ] Upload file to "Test"
   - [ ] Rename a file
   - [ ] Delete a file
   - [ ] See 🟠 "4 pending"

2. **Sync All**
   - [ ] Go online
   - [ ] Watch sync progress
   - [ ] All operations sync successfully
   - [ ] Verify in Google Drive web interface

3. **Cached PDF**
   - [ ] Open PDF while online (caches it)
   - [ ] Go offline
   - [ ] Reopen same PDF
   - [ ] Loads from cache (no error)
   - [ ] Can view and annotate offline

4. **Manual Sync**
   - [ ] Go offline
   - [ ] Perform action
   - [ ] Go online
   - [ ] Tap indicator → "Sync Now"
   - [ ] Syncs immediately

## Behind the Scenes

### When You Perform an Action Offline

```
User Action (e.g., upload file)
         ↓
   DriveService
         ↓
   Check: isOnline?
         ↓
        NO
         ↓
   SyncManager.queueAction()
         ↓
   Save to SQLite (sync_queue)
         ↓
   Update UI immediately
         ↓
   Show as "pending"
```

### When You Come Back Online

```
ConnectivityService detects connection
         ↓
   Notify SyncManager
         ↓
   SyncManager.processSyncQueue()
         ↓
   Load from SQLite (sync_queue)
         ↓
   Sort by dependency (folders first)
         ↓
   Process each action:
   1. Create folders
   2. Upload files
   3. Rename/move/delete
         ↓
   Update temp IDs → real IDs
         ↓
   Remove from queue on success
         ↓
   Retry on failure (max 5 times)
         ↓
   Update UI
```

## SQLite Database

Your offline actions are stored in a local database:

### Location
- **Android:** `/data/data/com.scholarmate/databases/cache.db`
- **iOS:** `Library/Application Support/cache.db`
- **Web:** IndexedDB

### Tables
- `files` - Cached file metadata
- `cached_pdfs` - PDF content for offline viewing
- `annotations` - PDF annotations
- **`sync_queue`** - Offline operations waiting to sync

### View Sync Queue (Debug)
```dart
final db = cacheService.database;
final pendingActions = await db.getPendingSyncOperations();

for (final action in pendingActions) {
  print('${action.operationType} ${action.resourceType}');
  print('Status: ${action.status}');
  print('Retries: ${action.retryCount}');
}
```

## Troubleshooting

### Q: Indicator not showing?
**A:** Check that these screens are open:
- ✅ FileExplorerScreen
- ✅ PDFViewerScreen

Other screens don't have the indicator (yet).

### Q: Actions not syncing?
**A:** 
1. Tap indicator to see status
2. Check "Pending Actions" count
3. If online, tap "Sync Now"
4. If errors, check "Last Error" message

### Q: Sync keeps failing?
**A:**
1. Check Google account is still signed in
2. Check Drive API access token
3. Try signing out and back in
4. Clear failed actions:
   ```dart
   syncManager.clearFailedActions()
   ```

### Q: Want to clear all pending actions?
**A:**
```dart
// Clear failed actions only
await syncManager.clearFailedActions();

// OR manually clear database
final db = cacheService.database;
await db.delete(db.syncQueue).go();
```

## Configuration

### Change Retry Settings
**File:** `frontend/lib/services/sync_manager.dart`

```dart
// Current: Max 5 retries
const maxRetries = 5;

// Change backoff timing
final backoffSeconds = (2 << (newRetryCount - 1)).clamp(1, 60);
// ↓
final backoffSeconds = (2 << (newRetryCount - 1)).clamp(5, 120);
// (Longer waits: 5-120 seconds instead of 1-60)
```

## Summary

✅ **Offline mode fully functional**  
✅ **ConnectivityIndicator now visible**  
✅ **All operations queue and sync automatically**  
✅ **No code was lost - just needed UI visibility!**

The feature was always there, working silently in the background. Now you can see it! 🎉

---

## Quick Reference

| Indicator | Meaning | What Happens |
|-----------|---------|--------------|
| 🟢 Online | Connected & synced | Operations execute immediately |
| ⚫ Offline | No connection | Operations queue for later |
| 🟠 X pending | X actions queued | Will sync when online |
| 🟠 Syncing | Sync in progress | Wait for completion |
| 🔴 Sync Error | Some failed | Tap to see details, retry |

**Tap the indicator anytime** to see detailed status and manually trigger sync!

