# Configuration Setup

ScholarMate uses compile-time environment variables for configuration instead of `.env` files.

## Quick Start

1. Copy the template file:
   ```bash
   copy dart_defines.json.template dart_defines.json
   ```

2. Edit `dart_defines.json` with your actual values

3. Run the app:
   ```bash
   run_dev.bat
   ```

## Configuration Files

- `dart_defines.json` - Your local configuration (gitignored, never commit!)
- `dart_defines.json.template` - Template for team members
- `run_dev.bat` - Run app with config
- `build_apk.bat` - Build Android APK with config
- `build_web.bat` - Build web app with config

## How It Works

### All Platforms (Mobile/Desktop/Web/Production)
Uses `--dart-define-from-file=dart_defines.json` to inject environment variables at compile time.

For Vercel deployment, set environment variables in Vercel dashboard and use the same build command with `--dart-define` flags.

## Required Variables

```json
{
  "GOOGLE_CLIENT_ID": "Your Google OAuth Client ID",
  "GOOGLE_CLIENT_SECRET": "Your Google OAuth Client Secret (web only)",
  "GOOGLE_REDIRECT_URI": "OAuth redirect URI",
  "API_BASE_URL": "Backend API URL",
  "SUPABASE_URL": "Supabase project URL",
  "SUPABASE_ANON_KEY": "Supabase anonymous key"
}
```

## Manual Run Commands

If you prefer not to use the batch scripts:

```bash
# Run on Android
flutter run -d android --dart-define-from-file=dart_defines.json

# Run on Web
flutter run -d chrome --dart-define-from-file=dart_defines.json

# Build APK
flutter build apk --dart-define-from-file=dart_defines.json

# Build Web
flutter build web --dart-define-from-file=dart_defines.json
```

## VS Code Launch Configuration

Add to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Dev)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define-from-file=dart_defines.json"
      ]
    }
  ]
}
```

## Benefits Over .env Files

✅ Works consistently across all platforms (Android, iOS, Web, Desktop)
✅ No asset bundling issues
✅ Compile-time constants (better performance)
✅ No runtime file loading errors
✅ Cleaner Vercel deployment (no .env in web build)
✅ Type-safe with `String.fromEnvironment()`
