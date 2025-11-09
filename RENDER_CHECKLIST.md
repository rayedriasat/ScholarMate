# Render Deployment Checklist

## Pre-Deployment
- [ ] Code pushed to GitHub
- [ ] `render.yaml` in root directory
- [ ] `backend/pyproject.toml` has all dependencies
- [ ] `backend/app/main.py` exists and is correct

## Render Setup
- [ ] Created Render account
- [ ] Connected GitHub repository
- [ ] Created web service (Blueprint or Manual)
- [ ] Service name: `scholarmate-backend`
- [ ] Region selected (Oregon recommended)

## Environment Variables (in Render Dashboard)
### Required
- [ ] `SUPABASE_URL`
- [ ] `SUPABASE_KEY`
- [ ] `SUPABASE_SERVICE_KEY`
- [ ] `GOOGLE_CLIENT_ID`
- [ ] `GOOGLE_CLIENT_SECRET`
- [ ] `ENCRYPTION_KEY` (generated with Fernet)

### Optional (for AI features)
- [ ] `PINECONE_API_KEY`
- [ ] `OPENROUTER_API_KEY`
- [ ] `GROQ_API_KEY`
- [ ] `DEEPSEEK_API_KEY`

### Auto-configured (from render.yaml)
- [ ] `CORS_ORIGINS` includes your Vercel URL
- [ ] `DEBUG=false`
- [ ] `LOG_LEVEL=INFO`

## Deployment
- [ ] First build completed successfully
- [ ] Service is running (green status)
- [ ] Health check passes: `curl https://scholarmate-backend.onrender.com/api/health`
- [ ] API docs accessible: `https://scholarmate-backend.onrender.com/docs`

## Frontend Integration
- [ ] Updated Vercel environment variable: `BACKEND_URL=https://scholarmate-backend.onrender.com`
- [ ] Updated `api/config.js` to support BACKEND_URL
- [ ] Frontend redeployed
- [ ] Frontend can reach backend

## Google OAuth
- [ ] Added `https://scholarmate-backend.onrender.com` to Authorized JavaScript origins
- [ ] Added `https://scholarmate-backend.onrender.com/auth/callback` to Authorized redirect URIs
- [ ] Added `https://scholar-mate-nine.vercel.app` to Authorized JavaScript origins
- [ ] Added `https://scholar-mate-nine.vercel.app/auth/callback` to Authorized redirect URIs

## Testing
- [ ] Backend health check works
- [ ] Frontend loads successfully
- [ ] Google sign-in works
- [ ] Can upload files
- [ ] OCR processing works
- [ ] AI chat works (if configured)

## Monitoring
- [ ] Checked Render logs for errors
- [ ] Checked Vercel logs for errors
- [ ] Tested on multiple devices/browsers

## Optional Optimizations
- [ ] Set up custom domain
- [ ] Upgrade to Starter plan ($7/month) to avoid cold starts
- [ ] Set up monitoring/alerts
- [ ] Configure CI/CD pipeline
- [ ] Add error tracking (Sentry, etc.)

## Troubleshooting
If something doesn't work:
1. Check Render logs
2. Verify all environment variables are set
3. Test backend health endpoint
4. Check CORS configuration
5. Verify Google OAuth settings
6. Check browser console for errors

## URLs to Save
- Backend: https://scholarmate-backend.onrender.com
- Frontend: https://scholar-mate-nine.vercel.app
- API Docs: https://scholarmate-backend.onrender.com/docs
- Render Dashboard: https://dashboard.render.com
- Vercel Dashboard: https://vercel.com/dashboard

## Next Steps After Deployment
1. Monitor logs for first 24 hours
2. Test all features thoroughly
3. Share with beta users
4. Collect feedback
5. Iterate and improve
