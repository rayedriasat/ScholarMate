# Vercel Deployment Guide

This guide explains how to deploy the ScholarMate Flutter web app to Vercel with proper environment variable handling.

## Architecture

The app uses a hybrid approach for environment variables:

- **Local Development**: Uses `.env` file via `flutter_dotenv`
- **Vercel Production**: Fetches config from `/api/config` serverless function

The `ConfigService` automatically detects the environment and loads configuration accordingly.

## Setup Steps

### 1. Build the Web App Locally

```bash
cd frontend
flutter build web --release --web-renderer canvaskit
cd ..
```

**Important**: The build folder is committed to git for Vercel deployment.

### 2. Install Vercel CLI (Optional)

```bash
npm install -g vercel
```

### 3. Configure Environment Variables in Vercel

Go to your Vercel project dashboard → Settings → Environment Variables and add:

```
GOOGLE_CLIENT_ID=325415234543-menqofjbigrju70tbi7oab4p5ath82lc.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=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
GOOGLE_REDIRECT_URI=https://your-app.vercel.app/auth/callback
API_BASE_URL=https://your-backend-api.com
SUPABASE_URL=https://rqyzgfgdsedvohxyyqho.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxeXpnZmdkc2Vkdm9oeHl5cWhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwNTM5NzQsImV4cCI6MjA3NjYyOTk3NH0.mynXFTLHdzKg7Em2mfKXwNcRMPIsM9yv-7I9aWBkijE
```

**Important**: Update `GOOGLE_REDIRECT_URI` and `API_BASE_URL` to match your production URLs.

### 4. Commit and Push the Build

```bash
# Add the build folder (force-included in .gitignore)
git add frontend/build/web

# Commit
git commit -m "Add prebuilt web app for Vercel deployment"

# Push to your repository
git push origin main
```

### 5. Deploy to Vercel

#### Option A: Using Vercel CLI

```bash
# Login to Vercel
vercel login

# Deploy
vercel --prod
```

#### Option B: Using GitHub Integration

1. Push your code to GitHub (with build folder)
2. Import the repository in Vercel dashboard
3. Vercel will automatically detect the `vercel.json` configuration
4. Add environment variables in the dashboard
5. Deploy (no build step needed, uses prebuilt files)

### 6. Update Google OAuth Redirect URIs

Add your Vercel deployment URL to Google Cloud Console:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to APIs & Services → Credentials
3. Edit your OAuth 2.0 Client ID
4. Add to "Authorized redirect URIs":
   - `https://your-app.vercel.app/auth/callback`
   - `https://your-app.vercel.app` (if needed)

## How It Works

### ConfigService Detection

The `ConfigService` automatically detects the environment:

```dart
bool _detectVercelEnvironment() {
  if (kIsWeb) {
    final hostname = Uri.base.host;
    return hostname.contains('vercel.app') || 
           hostname.contains('vercel.com');
  }
  return false;
}
```

### Serverless Function

The `/api/config.js` serverless function:
- Runs on Vercel's edge network
- Reads environment variables from Vercel's secure storage
- Returns them as JSON to the Flutter app
- Includes CORS headers for cross-origin requests

### Local Development

For local development, the app continues to use the `.env` file:

```bash
cd frontend
flutter run -d chrome
```

## Troubleshooting

### Config Not Loading

Check browser console for errors:
```javascript
// Should see: "Detected Vercel environment, fetching config from API..."
// Or: "Local web environment, loading .env file..."
```

### CORS Errors

Ensure the serverless function includes proper CORS headers (already configured in `api/config.js`).

### Environment Variables Not Set

Verify in Vercel dashboard that all required environment variables are set for the Production environment.

### Custom Domain

If using a custom domain, update the detection logic in `config_service.dart`:

```dart
bool _detectVercelEnvironment() {
  if (kIsWeb) {
    final hostname = Uri.base.host;
    return hostname.contains('vercel.app') || 
           hostname.contains('your-custom-domain.com');
  }
  return false;
}
```

## Security Notes

- Environment variables are never exposed in the client bundle
- The serverless function runs server-side with secure access to env vars
- CORS is configured to allow requests from your frontend
- Consider adding authentication to the `/api/config` endpoint for additional security

## Build Configuration

The `vercel.json` file configures:
- Build command: `null` (using prebuilt files)
- Output directory: `frontend/build/web`
- API routes: `/api/config` → serverless function
- Headers: CORS and security headers

**Note**: You build the Flutter web app locally and commit the `frontend/build/web` folder to git. Vercel deploys the prebuilt files directly.

## Testing Locally

To test the Vercel environment locally:

```bash
# Build the web app first
cd frontend
flutter build web --release --web-renderer canvaskit
cd ..

# Install Vercel CLI
npm install -g vercel

# Run local development server
vercel dev
```

This will simulate the Vercel environment on `localhost:3000`.

## Updating the Deployment

When you make changes to the app:

```bash
# 1. Make your code changes
# 2. Rebuild the web app
cd frontend
flutter build web --release --web-renderer canvaskit
cd ..

# 3. Commit the new build
git add frontend/build/web
git commit -m "Update web build"
git push

# 4. Vercel auto-deploys (or use vercel --prod)
```
