# First Deployment Guide

Follow these steps for your first deployment to Vercel.

## Prerequisites

- [ ] Flutter SDK installed and working
- [ ] Git repository set up
- [ ] Vercel account created (free): https://vercel.com/signup

## Step 1: Verify Configuration

```bash
# Run verification script
test-vercel-config.bat  # Windows
./test-vercel-config.sh  # Linux/Mac
```

**Expected output:** All checks should pass ✅

## Step 2: Build the Web App

```bash
cd frontend
flutter build web --release --web-renderer canvaskit
```

**Expected output:**
```
Building without sound null safety
Compiling lib/main.dart for the Web...
...
✓ Built build/web
```

**Time:** ~2-5 minutes

## Step 3: Verify Build Output

```bash
# Windows
dir frontend\build\web\index.html

# Linux/Mac
ls -lh frontend/build/web/index.html
```

**Expected:** File should exist and be ~5-10 KB

## Step 4: Commit the Build

```bash
cd ..  # Back to project root

# Check what will be committed
git status frontend/build/web/

# Add the build folder
git add frontend/build/web

# Commit
git commit -m "Initial web build for Vercel deployment"
```

**Expected:** Files should be staged and committed

## Step 5: Push to Git

```bash
# Push to your repository
git push origin main
```

**Expected:** Push should succeed with build files

## Step 6: Set Up Vercel

### Option A: Using Vercel Dashboard (Recommended)

1. Go to https://vercel.com/new
2. Click "Import Git Repository"
3. Select your repository
4. Click "Import"
5. Vercel will detect `vercel.json` automatically
6. Click "Deploy" (don't set environment variables yet)

### Option B: Using Vercel CLI

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
vercel --prod
```

**Expected:** Deployment should complete in ~30-60 seconds

## Step 7: Configure Environment Variables

1. Go to your Vercel project dashboard
2. Click "Settings" → "Environment Variables"
3. Add each variable:

| Name | Value | Environment |
|------|-------|-------------|
| `GOOGLE_CLIENT_ID` | `325415234543-menqofjbigrju70tbi7oab4p5ath82lc.apps.googleusercontent.com` | All |
| `GOOGLE_CLIENT_SECRET` | `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` | All |
| `GOOGLE_REDIRECT_URI` | `https://your-app.vercel.app/auth/callback` | All |
| `API_BASE_URL` | `https://your-backend.com` | All |
| `SUPABASE_URL` | `https://rqyzgfgdsedvohxyyqho.supabase.co` | All |
| `SUPABASE_ANON_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` | All |

**Important:** 
- Select all environments (Production, Preview, Development)
- Update `GOOGLE_REDIRECT_URI` with your actual Vercel URL
- Update `API_BASE_URL` with your actual backend URL

## Step 8: Redeploy with Environment Variables

After adding environment variables:

```bash
# Trigger a new deployment
vercel --prod
```

Or in Vercel dashboard:
1. Go to "Deployments"
2. Click "..." on latest deployment
3. Click "Redeploy"

**Expected:** Deployment completes in ~30 seconds

## Step 9: Update Google OAuth

1. Go to https://console.cloud.google.com/
2. Navigate to: APIs & Services → Credentials
3. Click on your OAuth 2.0 Client ID
4. Under "Authorized JavaScript origins", add:
   - `https://your-app.vercel.app`
   - `https://your-app-*.vercel.app` (for preview deployments)
5. Under "Authorized redirect URIs", add:
   - `https://your-app.vercel.app/auth/callback`
   - `https://your-app-*.vercel.app/auth/callback`
6. Click "Save"

## Step 10: Test Your Deployment

### 1. Visit Your App

Open: `https://your-app.vercel.app`

**Expected:** App loads without errors

### 2. Check Browser Console

Press F12 → Console tab

**Expected output:**
```
Detected Vercel environment, fetching config from API...
Successfully loaded config from Vercel API
ConfigService initialized successfully
```

### 3. Test Config Endpoint

```bash
curl https://your-app.vercel.app/api/config
```

**Expected:** JSON with all environment variables

### 4. Test Google Sign-In

1. Click "Sign in with Google"
2. Should redirect to Google OAuth
3. Should redirect back to your app
4. Should show user profile

**Expected:** Sign-in works without errors

### 5. Test Offline Functionality

1. Open DevTools → Network tab
2. Set to "Offline"
3. App should still function with cached data

**Expected:** App works offline

## Troubleshooting

### Build Fails

**Error:** `Flutter not found`
```bash
flutter --version  # Verify installation
```

**Error:** `Dependencies not resolved`
```bash
cd frontend
flutter pub get
flutter build web --release
```

### Git Issues

**Error:** `Build files not tracked`
```bash
git status frontend/build/web/  # Should show files
git add -f frontend/build/web   # Force add if needed
```

### Deployment Issues

**Error:** `404 Not Found`
- Check `vercel.json` output directory
- Verify `index.html` exists in build folder
- Ensure build folder is committed

**Error:** `Blank page`
- Check browser console for errors
- Verify environment variables are set
- Test `/api/config` endpoint

### OAuth Issues

**Error:** `Redirect URI mismatch`
- Verify redirect URI in Vercel env vars
- Check Google Console authorized URIs
- Ensure URLs match exactly (including https://)

## Success Checklist

- [ ] ✅ Build completes successfully
- [ ] ✅ Build files committed to git
- [ ] ✅ Pushed to repository
- [ ] ✅ Deployed to Vercel
- [ ] ✅ Environment variables set
- [ ] ✅ Google OAuth configured
- [ ] ✅ App loads without errors
- [ ] ✅ Config endpoint returns data
- [ ] ✅ Google Sign-In works
- [ ] ✅ Offline functionality works

## Next Steps

### Regular Updates

When you make code changes:

```bash
# 1. Make changes in frontend/lib/
# 2. Rebuild
cd frontend && flutter build web --release && cd ..

# 3. Commit and push
git add frontend/build/web
git commit -m "Update: [describe changes]"
git push

# 4. Vercel auto-deploys
```

### Using Helper Scripts

```bash
# Windows
build-and-deploy.bat
git push
vercel --prod

# Linux/Mac
./build-and-deploy.sh
git push
vercel --prod
```

## Support

- **Build issues**: See `BUILD_AND_DEPLOY.md`
- **Git issues**: See `GITIGNORE_EXPLANATION.md`
- **Deployment issues**: See `VERCEL_DEPLOYMENT.md`
- **Quick help**: See `QUICK_REFERENCE.md`

## Congratulations! 🎉

Your Flutter web app is now deployed to Vercel with:
- ✅ Automatic environment variable handling
- ✅ Fast deployments (~30 seconds)
- ✅ Offline-first functionality
- ✅ Google OAuth integration
- ✅ Serverless API for configuration

**Your app is live at:** `https://your-app.vercel.app`

---

**Deployment time:** ~10-15 minutes (first time)
**Future deployments:** ~3-5 minutes (build + deploy)
