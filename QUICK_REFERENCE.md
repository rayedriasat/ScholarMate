# Quick Reference Card

## 🚀 Deploy to Vercel (Prebuilt)

### One-Line Deploy (Windows)
```bash
build-and-deploy.bat && git push && vercel --prod
```

### One-Line Deploy (Linux/Mac)
```bash
./build-and-deploy.sh && git push && vercel --prod
```

### Manual Steps
```bash
# 1. Build
cd frontend && flutter build web --release --web-renderer canvaskit && cd ..

# 2. Commit
git add frontend/build/web && git commit -m "Build for deployment"

# 3. Push & Deploy
git push && vercel --prod
```

## 📋 Checklist

- [ ] Build locally: `flutter build web --release`
- [ ] Commit build: `git add frontend/build/web`
- [ ] Push to git: `git push origin main`
- [ ] Deploy: `vercel --prod`
- [ ] Set env vars in Vercel dashboard
- [ ] Update Google OAuth redirect URIs

## 🔧 Configuration Files

| File | Purpose |
|------|---------|
| `vercel.json` | Vercel config (no build, use prebuilt) |
| `.gitignore` | Force-include `frontend/build/web` |
| `frontend/.gitignore` | Exclude platform builds |
| `api/config.js` | Serverless function for env vars |

## 🌐 Environment Variables (Vercel Dashboard)

```
GOOGLE_CLIENT_ID=325415234543-menqofjbigrju70tbi7oab4p5ath82lc.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=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
GOOGLE_REDIRECT_URI=https://your-app.vercel.app/auth/callback  ⚠️ UPDATE
API_BASE_URL=https://your-backend.com  ⚠️ UPDATE
SUPABASE_URL=https://rqyzgfgdsedvohxyyqho.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 🧪 Testing

```bash
# Verify git config
git status frontend/build/web/

# Test build
cd frontend && flutter build web --release && cd ..

# Test locally
vercel dev

# Test config endpoint
curl https://your-app.vercel.app/api/config
```

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| `VERCEL_QUICK_START.md` | 5-minute setup guide |
| `VERCEL_DEPLOYMENT.md` | Complete deployment guide |
| `VERCEL_DEPLOYMENT_CHECKLIST.md` | Step-by-step checklist |
| `BUILD_AND_DEPLOY.md` | Build process details |
| `GITIGNORE_EXPLANATION.md` | Git configuration |
| `PREBUILT_DEPLOYMENT_SUMMARY.md` | What changed |

## ⚡ Key Points

- ✅ Build locally (not on Vercel)
- ✅ Commit `frontend/build/web` to git
- ✅ Deployment takes ~30 seconds
- ✅ Environment variables from Vercel
- ✅ Auto-detects local vs Vercel

## 🔍 Troubleshooting

| Issue | Solution |
|-------|----------|
| Build files ignored | Check `.gitignore` patterns |
| 404 on Vercel | Verify `vercel.json` output directory |
| Config not loading | Check `/api/config` endpoint |
| OAuth errors | Update redirect URIs in Google Console |

## 📞 Support

- Build issues → `BUILD_AND_DEPLOY.md`
- Git issues → `GITIGNORE_EXPLANATION.md`
- Deploy issues → `VERCEL_DEPLOYMENT.md`
- Quick help → `VERCEL_QUICK_START.md`

---

**Time to deploy:** ~3-5 minutes (build) + ~30 seconds (Vercel)
