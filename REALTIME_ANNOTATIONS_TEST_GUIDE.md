# Realtime Annotations Testing Guide

## Prerequisites

Before testing, you need to integrate the realtime service into your app.

## Step 1: Setup RealtimeService Provider

First, add the RealtimeService to your app's provider setup.

**File: `frontend/lib/main.dart`**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/realtime_service.dart';

// In your main() function, after Supabase initialization:
await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseAnonKey,
);

// Then in your MultiProvider:
MultiProvider(
  providers: [
    // ... existing providers ...
    
    // Add RealtimeService
    Provider<RealtimeService>(
      create: (_) => RealtimeService(Supabase.instance.client),
      dispose: (_, service) => service.dispose(),
    ),
    
    // Update AnnotationSyncService to include RealtimeService
    ProxyProvider<RealtimeService, AnnotationSyncService>(
      update: (context, realtimeService, previous) => AnnotationSyncService(
        database: context.read<AppDatabase>(),
        authService: context.read<AuthService>(),
        baseUrl: backendUrl,
        realtimeService: realtimeService,
      ),
    ),
  ],
  child: MyApp(),
)
```

## Step 2: Quick Integration Option (Easiest to Test)

Add realtime support to your existing CollaborativePdfViewerScreen:

**File: `frontend/lib/screens/collaborative_pdf_viewer_screen.dart`**

Add this import at the top:
```dart
import '../services/realtime_service.dart';
import '../mixins/realtime_annotation_mixin.dart';
```

Add the mixin to your state class:
```dart
class _CollaborativePdfViewerScreenState
    extends State<CollaborativePdfViewerScreen>
    with RealtimeAnnotationMixin {  // Add this!
```

In `initState()`, add after `_initializeCollaboration()`:
```dart
@override
void initState() {
  super.initState();
  _initializeCollaboration();
  
  // Add realtime annotation support
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final realtimeService = context.read<RealtimeService>();
    initializeRealtimeAnnotations(
      fileId: widget.fileId,
      realtimeService: realtimeService,
    );
  });
}
```

Override the annotation callbacks:
```dart
@override
void onAnnotationCreated(PdfAnnotation annotation) {
  if (mounted) {
    // Annotation already shown via CollaborationService
    // This is backup for non-session annotations
    debugPrint('Realtime annotation created: ${annotation.id}');
  }
}

@override
void onAnnotationUpdated(PdfAnnotation annotation) {
  if (mounted) {
    debugPrint('Realtime annotation updated: ${annotation.id}');
  }
}

@override
void onAnnotationDeleted(String annotationId) {
  if (mounted) {
    debugPrint('Realtime annotation deleted: $annotationId');
  }
}
```

In `dispose()`, add:
```dart
@override
void dispose() {
  disposeRealtimeAnnotations();
  // ... existing dispose code ...
  super.dispose();
}
```

## Step 3: Testing Setup

### Option A: Two Devices (Recommended)
- **Device 1**: Your development machine (web or desktop)
- **Device 2**: Android phone or another browser window

### Option B: Two Browser Windows
- **Window 1**: Chrome normal window
- **Window 2**: Chrome incognito window (different Google account)

### Option C: Web + Android
- **Device 1**: Web browser
- **Device 2**: Android phone

## Step 4: Test Realtime Annotations

### Test 1: Basic Realtime Annotation Sync

**User A (Device 1):**
1. Start backend: `cd backend && uv run python run.py`
2. Start frontend: `cd frontend && flutter run -d chrome`
3. Sign in with Google Account A
4. Upload a PDF or open existing PDF
5. Create a collaboration session
6. Copy the Session ID
7. Add a highlight annotation on page 1

**User B (Device 2):**
1. Start frontend: `flutter run -d chrome` (or use Android)
2. Sign in with Google Account B
3. Go to Files → Menu (⋮) → "Join Collaboration"
4. Enter the Session ID from User A
5. **Expected Result**: You should see User A's highlight appear!

**User B continues:**
6. Add an underline annotation on page 2
7. **Expected Result**: User A should see a notification about User B's annotation

### Test 2: Typing Indicators (If Integrated)

If you add typing indicators to the collaboration panel:

**User A:**
1. Click to add a comment annotation
2. Start typing in the comment field

**User B:**
3. **Expected Result**: Should see "User A is typing..." indicator
4. Wait 3 seconds without User A typing
5. **Expected Result**: Typing indicator should disappear

### Test 3: Conflict Resolution

**Setup:** Both users offline, then come online

**User A (Offline):**
1. Turn off WiFi
2. Edit an existing annotation (change color)
3. Note the time

**User B (Offline):**
1. Turn off WiFi
2. Edit the SAME annotation (change text)
3. Note the time (should be after User A)

**Both Users:**
1. Turn WiFi back on
2. Wait for sync
3. **Expected Result**: User B's changes should win (last-write-wins)
4. User A should see a conflict notification

### Test 4: Annotation Notifications

**User A:**
1. Add a highlight on page 3

**User B:**
2. **Expected Result**: Should see a snackbar notification:
   - "User A added highlight on page 3"
   - With a "View" button
3. Click "View" button
4. **Expected Result**: Should jump to page 3

## Step 5: Verify Supabase Realtime

### Check Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to **Database** → **Replication**
3. Verify that Realtime is enabled for the `annotations` table
4. Check **Logs** → **Realtime** to see connection events

### Enable Realtime on Annotations Table

If realtime isn't working, run this SQL in Supabase SQL Editor:

```sql
-- Enable realtime for annotations table
ALTER PUBLICATION supabase_realtime ADD TABLE annotations;

-- Verify it's enabled
SELECT * FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime';
```

## Step 6: Debugging

### Check Browser Console (User A & B)

Look for these messages:
```
✅ "Realtime annotation created: <id>"
✅ "Annotation created: <id>"
❌ "Error handling annotation created: ..."
```

### Check Backend Logs

```bash
cd backend
uv run python run.py
```

Look for:
```
✅ "Created annotation <id> for file <file_id>"
✅ "Retrieved X annotations for file <file_id>"
❌ "Error creating annotation: ..."
```

### Common Issues

**Issue 1: Annotations not appearing in realtime**
- Check Supabase Realtime is enabled (see Step 5)
- Verify both users are connected to the same backend
- Check browser console for WebSocket errors

**Issue 2: "RealtimeService not found"**
- Make sure you added RealtimeService to providers (Step 1)
- Restart the app after adding providers

**Issue 3: Typing indicators not showing**
- Typing indicators need to be explicitly integrated
- They're not automatically enabled in collaboration

**Issue 4: Conflict dialog not showing**
- Conflicts only show during sync operations
- Try the offline test (Test 3) to trigger conflicts

## Quick Test Script

Here's a quick test you can run:

**Terminal 1 (Backend):**
```bash
cd backend
uv run python run.py
```

**Terminal 2 (User A - Web):**
```bash
cd frontend
flutter run -d chrome
```

**Terminal 3 (User B - Web):**
```bash
cd frontend
flutter run -d chrome --web-port=8081
```

Then follow Test 1 above!

## Expected Behavior Summary

| Action | User A Sees | User B Sees |
|--------|-------------|-------------|
| A adds annotation | Annotation appears immediately | Notification + annotation appears |
| B adds annotation | Notification + annotation appears | Annotation appears immediately |
| A types comment | Own typing | "User A is typing..." |
| Both edit same annotation offline | Conflict notification (if B's timestamp is newer) | Changes saved |
| A deletes annotation | Annotation removed | Notification + annotation removed |

## Next Steps

After basic testing works:

1. **Add typing indicators** to collaboration panel
2. **Test with more users** (3+ people)
3. **Test with large PDFs** (100+ pages)
4. **Test network interruptions** (airplane mode)
5. **Test rapid annotation creation** (stress test)

## Need Help?

If something doesn't work:

1. Check the console logs (both frontend and backend)
2. Verify Supabase Realtime is enabled
3. Make sure both users are in the same collaboration session
4. Check that annotations are being saved to Supabase (check the database)

The realtime system is **passive** - it listens to database changes. So if annotations are saving to the database, realtime should work automatically!
