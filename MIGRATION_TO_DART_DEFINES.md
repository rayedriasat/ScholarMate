# Migration from flutter_dotenv to dart_defines

## Summary of Changes

Successfully migrated from `flutter_dotenv` (.env files) to compile-time environment variables using `--dart-define-from-file`.

## What Changed

### Removed
- ❌ `flutter_dotenv` package dependency
- ❌ `.env` file from assets in `pubspec.yaml`
- ❌ Vercel serverless function for config (no longer needed)
- ❌ Runtime .env file loading

### Added
- ✅ `dart_defines.json` - Local configuration file (gitignored)
- ✅ `dart_defines.json.template` - Template for team members
- ✅ Simplified `ConfigService` using `String.fromEnvironment()`
- ✅ Enhanced launcher scripts with ADB port forwarding
- ✅ Comprehensive documentation

## New Files

### Configuration
- `frontend/dart_defines.json` - Your local config (gitignored)
- `frontend/dart_defines.json.template` - Template

### Scripts
- `start-frontend.bat` - Enhanced interactive launcher
- `frontend/run_dev.bat` - Quick run with device selection
- `frontend/build_apk.bat` - Build Android APK
- `frontend/build_web.bat` - Build web app
- `frontend/quick-android-localhost.bat` - One-click Android + localhost
- `stop-adb-forwarding.bat` - Remove ADB port forwarding

### Documentation
- `FRONTEND_SETUP.md` - Complete setup guide
- `frontend/CONFIG_SETUP.md` - Configuration details
- `frontend/ADB_PORT_FORWARDING.md` - ADB guide
- `MIGRATION_TO_DART_DEFINES.md` - This file

## Migration Steps for Team Members

### 1. Pull Latest Changes
```bash
git pull
```

### 2. Remove Old Dependencies
```bash
cd frontend
flutter pub get
```

### 3. Create Configuration
```bash
copy dart_defines.json.template dart_defines.json
```

Edit `dart_defines.json` with your values.

### 4. Run the App
```bash
# From root directory
start-frontend.bat

# Or from frontend directory
run_dev.bat
```

## Benefits

### Before (flutter_dotenv)
- ❌ Asset bundling issues
- ❌ Platform inconsistencies
- ❌ Runtime file loading errors
- ❌ Vercel deployment complications
- ❌ Web build includes .env file

### After (dart_defines)
- ✅ Works consistently on all platforms
- ✅ Compile-time constants (better performance)
- ✅ No asset bundling needed
- ✅ Clean Vercel deployment
- ✅ No sensitive data in web builds
- ✅ Type-safe with `String.fromEnvironment()`

## Technical Details

### Old Approach
```dart
// Load .env file at runtime
await dotenv.load(fileName: '.env');
String value = dotenv.env['KEY'] ?? '';
```

### New Approach
```dart
// Use compile-time constants
const String value = String.fromEnvironment('KEY', defaultValue: '');
```

### Build Command
```bash
# Old
flutter run

# New
flutter run --dart-define-from-file=dart_defines.json
```

## Configuration Format

### dart_defines.json
```json
{
  "GOOGLE_CLIENT_ID": "your-client-id",
  "GOOGLE_CLIENT_SECRET": "your-client-secret",
  "GOOGLE_REDIRECT_URI": "http://localhost:8080/auth/callback",
  "API_BASE_URL": "http://localhost:8000",
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key"
}
```

## Vercel Deployment

No serverless function needed! Set environment variables in Vercel dashboard:

1. Go to Project Settings → Environment Variables
2. Add all variables from `dart_defines.json`
3. Build command automatically uses them

## Troubleshooting

### "dart_defines.json not found"
```bash
cd frontend
copy dart_defines.json.template dart_defines.json
```

### Old .env file still exists
It's safe to keep for reference, but it's no longer used. You can delete it if you want.

### VS Code launch configuration
Update `.vscode/launch.json` to include:
```json
"args": ["--dart-define-from-file=dart_defines.json"]
```

## Rollback (if needed)

If you need to rollback:

1. Restore `flutter_dotenv` dependency:
   ```bash
   flutter pub add flutter_dotenv
   ```

2. Add `.env` back to assets in `pubspec.yaml`

3. Revert `ConfigService` changes

However, the new approach is more robust and recommended.

## Questions?

See documentation:
- [FRONTEND_SETUP.md](FRONTEND_SETUP.md) - Complete setup guide
- [frontend/CONFIG_SETUP.md](frontend/CONFIG_SETUP.md) - Config details
- [frontend/ADB_PORT_FORWARDING.md](frontend/ADB_PORT_FORWARDING.md) - ADB guide
