# Frontend Run Commands

## If Frontend Won't Start

Try these commands in order:

### 1. Clean and Get Dependencies
```bash
cd frontend
flutter clean
flutter pub get
```

### 2. Run on Chrome
```bash
flutter run -d chrome --dart-define-from-file=dart_defines.json
```

### 3. If You See Import Errors

The issue might be that `AnnotationSyncService` is not exported. Let me check if we need to create it or if it already exists.

**Check if file exists:**
```bash
ls frontend/lib/services/annotation_sync_service.dart
```

If it doesn't exist, that's the problem! I created the service but it might not have been saved properly.

### 4. Common Errors and Fixes

**Error: "Can't find RealtimeService"**
- Make sure `frontend/lib/services/realtime_service.dart` exists
- Run `flutter pub get`

**Error: "Can't find AnnotationSyncService"**
- Check if `frontend/lib/services/annotation_sync_service.dart` exists
- If not, we need to create it

**Error: "Undefined name 'RealtimeEventType'"**
- Import is missing in collaborative_pdf_viewer_screen.dart
- Should have: `import '../services/realtime_service.dart';`

### 5. Quick Fix - Remove Realtime Temporarily

If you want to test without realtime first, comment out these lines in `main.dart`:

```dart
// Comment out these providers:
/*
Provider<RealtimeService>(
  create: (_) => RealtimeService(Supabase.instance.client),
  dispose: (_, service) => service.dispose(),
),

ChangeNotifierProxyProvider3<AppDatabase, AuthService, RealtimeService, AnnotationSyncService>(
  // ... entire provider
),
*/
```

And in `collaborative_pdf_viewer_screen.dart`, comment out:
```dart
// _initializeRealtime();  // Comment this line in initState
```

This will let you run the app without realtime while we fix any issues.

## What Error Are You Seeing?

Please copy and paste the exact error message you're getting, and I'll fix it immediately!
