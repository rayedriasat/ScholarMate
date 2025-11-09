# Vercel Deployment Checklist

Use this checklist to ensure a smooth deployment to Vercel.

## Pre-Deployment

- [ ] **Test locally**: Ensure the app works in local development
  ```bash
  cd frontend
  flutter run -d chrome
  ```

- [ ] **Build for production**: Build the web app locally
  ```bash
  cd frontend
  flutter build web --release --web-renderer canvaskit
  ```

- [ ] **Verify build output**: Check that `frontend/build/web` contains all files
  ```bash
  dir frontend\build\web  # Windows
  ls frontend/build/web   # Linux/Mac
  ```

- [ ] **Review environment variables**: Check `frontend/.env` for current values

- [ ] **Update redirect URIs**: Note your Vercel deployment URL for OAuth setup

## Vercel Setup

- [ ] **Create Vercel account**: Sign up at https://vercel.com

- [ ] **Install Vercel CLI** (optional):
  ```bash
  npm install -g vercel
  ```

- [ ] **Connect repository**: 
  - Push code to GitHub/GitLab/Bitbucket
  - Import repository in Vercel dashboard

## Environment Variables

Set these in Vercel dashboard (Settings → Environment Variables):

- [ ] `GOOGLE_CLIENT_ID` = `325415234543-menqofjbigrju70tbi7oab4p5ath82lc.apps.googleusercontent.com`
- [ ] `GOOGLE_CLIENT_SECRET` = `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`
- [ ] `GOOGLE_REDIRECT_URI` = `https://your-app.vercel.app/auth/callback` ⚠️ **UPDATE THIS**
- [ ] `API_BASE_URL` = `https://your-backend.com` ⚠️ **UPDATE THIS**
- [ ] `SUPABASE_URL` = `https://rqyzgfgdsedvohxyyqho.supabase.co`
- [ ] `SUPABASE_ANON_KEY` = `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

**Important**: Select all environments (Production, Preview, Development) for each variable.

## Google OAuth Configuration

- [ ] **Open Google Cloud Console**: https://console.cloud.google.com/
- [ ] **Navigate to**: APIs & Services → Credentials
- [ ] **Edit OAuth 2.0 Client ID**
- [ ] **Add Authorized JavaScript origins**:
  - `https://your-app.vercel.app`
  - `https://your-app-*.vercel.app` (for preview deployments)
- [ ] **Add Authorized redirect URIs**:
  - `https://your-app.vercel.app/auth/callback`
  - `https://your-app-*.vercel.app/auth/callback`

## Deploy

- [ ] **Commit the build folder**:
  ```bash
  git add frontend/build/web
  git commit -m "Build web app for deployment"
  git push origin main
  ```

- [ ] **Deploy via CLI**:
  ```bash
  vercel --prod
  ```
  OR
- [ ] **Deploy via GitHub**: Push to main branch (auto-deploys)

- [ ] **Wait for deployment**: Should complete in ~30 seconds (no build step)

## Post-Deployment Verification

- [ ] **Visit deployment URL**: Open `https://your-app.vercel.app`

- [ ] **Check browser console**: Should see:
  ```
  Detected Vercel environment, fetching config from API...
  Successfully loaded config from Vercel API
  ConfigService initialized successfully
  ```

- [ ] **Test config endpoint**: 
  ```bash
  curl https://your-app.vercel.app/api/config
  ```
  Should return JSON with all environment variables

- [ ] **Test Google Sign-In**: Click "Sign in with Google"
  - Should redirect to Google OAuth
  - Should redirect back to app after authentication
  - Should show user profile

- [ ] **Test offline functionality**: 
  - Open DevTools → Network tab
  - Set to "Offline"
  - App should still function with cached data

## Custom Domain (Optional)

- [ ] **Add domain in Vercel**: Settings → Domains
- [ ] **Configure DNS**: Follow Vercel's instructions
- [ ] **Update environment variables**:
  - `GOOGLE_REDIRECT_URI` = `https://your-domain.com/auth/callback`
- [ ] **Update Google OAuth**: Add custom domain to authorized URIs
- [ ] **Update detection logic**: Edit `frontend/lib/services/config_service.dart`:
  ```dart
  return hostname.contains('vercel.app') || 
         hostname.contains('your-domain.com');
  ```

## Troubleshooting

### Deployment Fails

- [ ] Verify `frontend/build/web` folder is committed to git
- [ ] Check that `.gitignore` force-includes `frontend/build/web`
- [ ] Ensure `vercel.json` points to correct output directory
- [ ] Check Vercel deployment logs for errors

### Config Not Loading

- [ ] Verify environment variables are set in Vercel
- [ ] Check `/api/config` endpoint returns data
- [ ] Review browser console for errors

### OAuth Errors

- [ ] Verify redirect URI matches exactly
- [ ] Check Google Cloud Console authorized URIs
- [ ] Ensure `GOOGLE_CLIENT_ID` is correct

### CORS Errors

- [ ] Verify `api/config.js` includes CORS headers
- [ ] Check browser console for specific CORS error
- [ ] Ensure API endpoint is accessible

## Rollback

If deployment fails:

- [ ] **Via CLI**: Deploy previous version
  ```bash
  vercel rollback
  ```
- [ ] **Via Dashboard**: Deployments → Select previous → Promote to Production

## Monitoring

- [ ] **Set up monitoring**: Vercel Analytics (optional)
- [ ] **Check logs**: Vercel dashboard → Logs
- [ ] **Monitor errors**: Browser console + Vercel logs

## Security Review

- [ ] **Environment variables**: Never committed to git
- [ ] **API keys**: Stored securely in Vercel
- [ ] **CORS**: Configured appropriately
- [ ] **HTTPS**: Enabled by default on Vercel
- [ ] **OAuth**: Using secure redirect URIs

## Documentation

- [ ] **Update README**: Add deployment URL
- [ ] **Document custom domain**: If applicable
- [ ] **Share with team**: Deployment URL and access

---

## Quick Deploy Commands

```bash
# Build locally
cd frontend && flutter build web --release --web-renderer canvaskit && cd ..

# Commit and push
git add frontend/build/web && git commit -m "Update web build" && git push

# Deploy to Vercel
vercel --prod
```

## Support

- Vercel Docs: https://vercel.com/docs
- Flutter Web: https://docs.flutter.dev/platform-integration/web
- Issues: Check browser console and Vercel logs
