# Google OAuth Setup Guide for ScholarMate

This guide walks you through setting up Google OAuth credentials for the ScholarMate application.

## Prerequisites

- A Google account
- Access to Google Cloud Console

## Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click on the project dropdown at the top
3. Click "New Project"
4. Enter project name: `ScholarMate` (or your preferred name)
5. Click "Create"

## Step 2: Enable Google Drive API

1. In the Google Cloud Console, go to "APIs & Services" > "Library"
2. Search for "Google Drive API"
3. Click on it and press "Enable"

## Step 3: Configure OAuth Consent Screen

1. Go to "APIs & Services" > "OAuth consent screen"
2. Select "External" user type (unless you have a Google Workspace)
3. Click "Create"
4. Fill in the required fields:
   - **App name**: ScholarMate
   - **User support email**: Your email
   - **Developer contact information**: Your email
5. Click "Save and Continue"
6. On the "Scopes" page, click "Add or Remove Scopes"
7. Add the following scope:
   - `https://www.googleapis.com/auth/drive.file` (View and manage Google Drive files and folders that you have opened or created with this app)
8. Click "Update" and then "Save and Continue"
9. On "Test users" page, add your email for testing
10. Click "Save and Continue"
11. Review and click "Back to Dashboard"

## Step 4: Create OAuth 2.0 Credentials

### For Web (Development)

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Select "Web application"
4. Name: `ScholarMate Web`
5. Add Authorized JavaScript origins:
   - `http://localhost`
   - `http://localhost:8080`
6. Add Authorized redirect URIs:
   - `http://localhost:8080/auth/callback`
7. Click "Create"
8. Copy the **Client ID** and **Client Secret**

### For Android

1. Click "Create Credentials" > "OAuth client ID"
2. Select "Android"
3. Name: `ScholarMate Android`
4. Get your SHA-1 certificate fingerprint:
   ```bash
   # For debug keystore (development)
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
5. Enter the SHA-1 fingerprint
6. Enter package name: `com.scholarmate.frontend` (or your package name)
7. Click "Create"
8. Copy the **Client ID**

### For iOS

1. Click "Create Credentials" > "OAuth client ID"
2. Select "iOS"
3. Name: `ScholarMate iOS`
4. Enter Bundle ID: `com.scholarmate.frontend` (or your bundle ID)
5. Click "Create"
6. Copy the **Client ID**
7. Download the configuration file if prompted

### For macOS (if supporting desktop)

1. Click "Create Credentials" > "OAuth client ID"
2. Select "macOS"
3. Name: `ScholarMate macOS`
4. Enter Bundle ID: `com.scholarmate.frontend` (or your bundle ID)
5. Click "Create"
6. Copy the **Client ID**

## Step 5: Configure Environment Variables

1. Copy `frontend.env.template` to `frontend/.env`
2. Fill in the credentials:

```env
# Use the Web Client ID for web platform
GOOGLE_CLIENT_ID=your_web_client_id_here.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_client_secret_here
GOOGLE_REDIRECT_URI=http://localhost:8080/auth/callback

# Backend API
API_BASE_URL=http://localhost:8000

# Supabase (to be configured later)
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Step 6: Platform-Specific Configuration

### Android Configuration

1. Open `frontend/android/app/build.gradle`
2. Ensure the package name matches what you used in Google Cloud Console
3. The google_sign_in plugin will automatically use the Android OAuth client ID

### iOS Configuration

1. Open `frontend/ios/Runner/Info.plist`
2. Add the following (replace with your iOS Client ID):

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Replace with your REVERSED_CLIENT_ID -->
            <string>325415234543-7o5i28gu9gvv1rp7mvk1palufttvs86s.apps.googleusercontent.com</string>
        </array>
    </dict>
</array>
```

### Web Configuration

The web configuration will be handled programmatically in the Flutter code using the Web Client ID.

## Step 7: Testing

1. Run the app on your desired platform
2. Click the "Sign in with Google" button
3. You should see the Google OAuth consent screen
4. Grant the requested permissions
5. You should be redirected back to the app with authentication successful

## Troubleshooting

### "Error 400: redirect_uri_mismatch"
- Ensure the redirect URI in your code matches exactly what's configured in Google Cloud Console
- Check for trailing slashes and http vs https

### "Access blocked: This app's request is invalid"
- Make sure you've enabled the Google Drive API
- Verify the OAuth consent screen is properly configured
- Check that you've added the correct scopes

### "The app is not verified"
- This is normal for apps in development
- Click "Advanced" and then "Go to ScholarMate (unsafe)" to proceed
- For production, you'll need to submit your app for verification

## Production Deployment

Before deploying to production:

1. Add production redirect URIs to your OAuth client
2. Submit your app for OAuth verification if needed
3. Move from "Testing" to "Production" in the OAuth consent screen
4. Use environment-specific client IDs for different environments
5. Never commit your `.env` file with real credentials to version control

## References

- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Google Drive API Scopes](https://developers.google.com/drive/api/guides/api-specific-auth)
