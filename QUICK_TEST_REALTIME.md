# Quick Test: Realtime Annotations (5 Minutes)

## Setup (One Time)

### 1. Add RealtimeService to Your App

**Edit: `frontend/lib/main.dart`**

Find your `MultiProvider` and add:

```dart
Provider<RealtimeService>(
  create: (_) => RealtimeService(Supabase.instance.client),
  dispose: (_, service) => service.dispose(),
),
```

### 2. Enable Supabase Realtime

**Run this SQL in Supabase Dashboard → SQL Editor:**

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE annotations;
```

### 3. Quick Integration (Optional but Recommended)

**Edit: `frontend/lib/screens/collaborative_pdf_viewer_screen.dart`**

Add at the top:
```dart
import '../services/realtime_service.dart';
```

In `_initializeCollaboration()` method, add at the end:
```dart
// Add realtime support
final realtimeService = context.read<RealtimeService>();
await realtimeService.subscribeToFile(widget.fileId);

// Listen to events
realtimeService.eventStream.listen((event) {
  if (event.type == RealtimeEventType.annotationCreated) {
    debugPrint('🎉 Realtime annotation created!');
    // Show notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New annotation from collaborator!')),
      );
    }
  }
});
```

## Test (2 Devices)

### User A (Your Computer):

```bash
# Terminal 1: Start backend
cd backend
uv run python run.py

# Terminal 2: Start frontend
cd frontend
flutter run -d chrome
```

1. Sign in with Google Account A
2. Open a PDF
3. Create collaboration session
4. **Copy the Session ID**
5. Add a highlight annotation

### User B (Phone or Another Browser):

```bash
# If testing on another browser window
cd frontend
flutter run -d chrome --web-port=8081
```

1. Sign in with Google Account B
2. Join collaboration with Session ID
3. **Watch for the notification!** 🎉

## What You Should See

✅ **User B sees:**
- Snackbar: "New annotation from collaborator!"
- Console: "🎉 Realtime annotation created!"
- The annotation appears in the PDF

✅ **User A sees:**
- Their own annotation immediately
- If User B adds annotation, same notification

## Troubleshooting

**Nothing happens?**

1. Check browser console for errors
2. Verify Supabase Realtime is enabled (Step 2)
3. Make sure both users are in the same session
4. Check backend logs for annotation creation

**Still not working?**

The realtime system works automatically when annotations are saved to Supabase. Check if:
- Annotations are being saved (check Supabase dashboard → Table Editor → annotations)
- Both users are connected to the same backend
- Supabase Realtime is enabled for the annotations table

## That's It!

If you see the notification and console message, realtime is working! 🎉

The full features (typing indicators, conflict resolution, etc.) need more integration, but the core realtime sync is now functional.
