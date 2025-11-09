# 🚀 Vercel Quick Start

Deploy your Flutter web app to Vercel in 5 minutes.

## Prerequisites

- Vercel account (free): https://vercel.com/signup
- Git repository (GitHub/GitLab/Bitbucket)

## Step 1: Build and Push to Git

```bash
# Build the web app locally
cd frontend
flutter build web --release --web-renderer canvaskit
cd ..

# Commit everything including the build folder
git add .
git commit -m "Add Vercel deployment support with prebuilt web"
git push origin main
```

**Note**: The `frontend/build/web` folder is force-included in git for Vercel deployment.

## Step 2: Import to Vercel

1. Go to https://vercel.com/new
2. Click "Import Git Repository"
3. Select your repository
4. Click "Import"

## Step 3: Set Environment Variables

In Vercel dashboard → Settings → Environment Variables, add:

| Name | Value | Notes |
|------|-------|-------|
| `GOOGLE_CLIENT_ID` | `325415234543-menqofjbigrju70tbi7oab4p5ath82lc.apps.googleusercontent.com` | From `.env` |
| `GOOGLE_CLIENT_SECRET` | `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` | From `.env` |
| `GOOGLE_REDIRECT_URI` | `https://your-app.vercel.app/auth/callback` | ⚠️ **UPDATE THIS** |
| `API_BASE_URL` | `https://your-backend.com` | ⚠️ **UPDATE THIS** |
| `SUPABASE_URL` | `https://rqyzgfgdsedvohxyyqho.supabase.co` | From `.env` |
| `SUPABASE_ANON_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` | From `.env` |

**Important**: Select all environments (Production, Preview, Development).

## Step 4: Deploy

Click "Deploy" in Vercel dashboard. Deployment should complete in ~30 seconds (no build needed, using prebuilt files).

## Step 5: Update Google OAuth

1. Go to https://console.cloud.google.com/
2. Navigate to: APIs & Services → Credentials
3. Edit your OAuth 2.0 Client ID
4. Add to "Authorized redirect URIs":
   - `https://your-app.vercel.app/auth/callback`
   - `https://your-app-*.vercel.app/auth/callback` (for previews)

## Step 6: Test

Visit your deployment URL and verify:
- ✅ App loads without errors
- ✅ Browser console shows: "Successfully loaded config from Vercel API"
- ✅ Google Sign-In works
- ✅ Config endpoint works: `https://your-app.vercel.app/api/config`

## Done! 🎉

Your app is now live on Vercel with secure environment variable handling.

---

## CLI Deployment (Alternative)

```bash
# Build locally first
cd frontend
flutter build web --release --web-renderer canvaskit
cd ..

# Commit the build
git add frontend/build/web
git commit -m "Update web build"
git push

# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
vercel --prod
```

---

## Troubleshooting

### Build fails
- Check build logs in Vercel dashboard
- Verify Flutter is installed in build environment (handled by `vercel.json`)

### Config not loading
- Verify all environment variables are set
- Check `/api/config` endpoint returns data

### OAuth errors
- Ensure redirect URI matches exactly
- Check Google Cloud Console authorized URIs

---

## What Happens Automatically

✅ Prebuilt web files deployed from `frontend/build/web`
✅ Environment variables loaded from Vercel
✅ Serverless function deployed
✅ HTTPS enabled
✅ CDN distribution
✅ Automatic deployments on git push (rebuild locally first)

---

## Custom Domain (Optional)

1. Vercel dashboard → Settings → Domains
2. Add your domain
3. Update DNS records (Vercel provides instructions)
4. Update `GOOGLE_REDIRECT_URI` environment variable
5. Update Google OAuth authorized URIs

---

## Cost

**Free tier includes**:
- Unlimited deployments
- 100 GB bandwidth/month
- Automatic HTTPS
- Serverless functions
- Preview deployments

Perfect for ScholarMate! 🎓

---

## Need Help?

- 📚 Full guide: `VERCEL_DEPLOYMENT.md`
- ✅ Checklist: `VERCEL_DEPLOYMENT_CHECKLIST.md`
- 🔧 Environment setup: `VERCEL_ENV_SETUP.md`
- 📖 Complete docs: `VERCEL_SETUP_COMPLETE.md`
