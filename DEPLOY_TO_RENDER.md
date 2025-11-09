# Deploy Backend to Render - Step by Step

## Step 1: Commit and Push

```bash
git add .
git commit -m "Add Render deployment configuration"
git push origin main
```

## Step 2: Deploy on Render

### Option A: Blueprint (Easiest)
1. Go to https://dashboard.render.com/
2. Click **"New +"** → **"Blueprint"**
3. Click **"Connect account"** to link GitHub
4. Select your repository
5. Render will detect `render.yaml`
6. Click **"Apply"**
7. Wait 3-5 minutes for build

### Option B: Manual
1. Go to https://dashboard.render.com/
2. Click **"New +"** → **"Web Service"**
3. Connect GitHub and select repository
4. Fill in:
   ```
   Name: scholarmate-backend
   Region: Oregon
   Branch: main
   Root Directory: backend
   Runtime: Python 3
   Build Command: pip install uv && uv sync
   Start Command: uv run uvicorn app.main:app --host 0.0.0.0 --port $PORT
   ```
5. Click **"Create Web Service"**

## Step 3: Add Environment Variables

In Render dashboard, go to your service → **Environment** tab.

Click **"Add Environment Variable"** for each:

### Required (Get from your existing setup)
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_anon_key_here
SUPABASE_SERVICE_KEY=your_service_role_key_here
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
```

### Generate Encryption Key
Run this command locally:
```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

Copy the output and add:
```
ENCRYPTION_KEY=the_generated_key_here
```

### Optional (for AI features)
```
PINECONE_API_KEY=your_pinecone_key
OPENROUTER_API_KEY=your_openrouter_key
GROQ_API_KEY=your_groq_key
DEEPSEEK_API_KEY=your_deepseek_key
```

Click **"Save Changes"** - Render will automatically redeploy.

## Step 4: Wait for Deployment

Watch the logs in Render dashboard. You'll see:
```
==> Building...
==> Installing uv...
==> Running uv sync...
==> Starting server...
==> Your service is live 🎉
```

Your backend URL: `https://scholarmate-backend.onrender.com`

## Step 5: Test Backend

```bash
curl https://scholarmate-backend.onrender.com/api/health
```

Expected response:
```json
{"status":"healthy","service":"scholarmate-backend"}
```

## Step 6: Update Frontend

### In Vercel Dashboard
1. Go to https://vercel.com/dashboard
2. Select your project: `scholar-mate-nine`
3. Go to **Settings** → **Environment Variables**
4. Add or update:
   ```
   BACKEND_URL=https://scholarmate-backend.onrender.com
   ```
5. Click **"Save"**
6. Go to **Deployments** tab
7. Click **"Redeploy"** on latest deployment

### Or via Git
```bash
# Frontend will auto-redeploy when you push
git add .
git commit -m "Update backend URL to Render"
git push origin main
```

## Step 7: Update Google OAuth

1. Go to https://console.cloud.google.com/apis/credentials
2. Select your OAuth 2.0 Client ID
3. Add to **Authorized JavaScript origins**:
   ```
   https://scholarmate-backend.onrender.com
   https://scholar-mate-nine.vercel.app
   ```
4. Add to **Authorized redirect URIs**:
   ```
   https://scholarmate-backend.onrender.com/auth/callback
   https://scholar-mate-nine.vercel.app/auth/callback
   ```
5. Click **"Save"**

## Step 8: Test Everything

### Test Backend
```bash
# Health check
curl https://scholarmate-backend.onrender.com/api/health

# API docs
open https://scholarmate-backend.onrender.com/docs
```

### Test Frontend
1. Open https://scholar-mate-nine.vercel.app
2. Click "Sign in with Google"
3. Complete OAuth flow
4. Upload a PDF
5. Try OCR and AI features

## Troubleshooting

### Build Failed
- Check Render logs for specific error
- Verify `backend/pyproject.toml` exists
- Ensure Python 3.12+ is specified

### Service Won't Start
- Check environment variables are set correctly
- Look for errors in Render logs
- Verify `app.main:app` path is correct

### CORS Errors
In Render dashboard, update environment variable:
```
CORS_ORIGINS=https://scholar-mate-nine.vercel.app
```

### Cold Start (30-60s delay)
This is normal on free tier. Options:
1. Accept the delay (free)
2. Upgrade to Starter plan ($7/month)
3. Implement keep-alive ping

### Can't Connect to Backend
- Verify backend URL in Vercel env vars
- Check browser console for errors
- Test backend health endpoint directly

## Success Checklist

- [ ] Backend deployed and running
- [ ] Health check returns 200 OK
- [ ] API docs accessible
- [ ] Frontend updated with backend URL
- [ ] Google OAuth configured
- [ ] Sign-in works
- [ ] File upload works
- [ ] OCR works
- [ ] AI chat works (if configured)

## Your URLs

- **Backend**: https://scholarmate-backend.onrender.com
- **Frontend**: https://scholar-mate-nine.vercel.app
- **API Docs**: https://scholarmate-backend.onrender.com/docs
- **Render Dashboard**: https://dashboard.render.com
- **Vercel Dashboard**: https://vercel.com/dashboard

## Cost

- **Free Tier**: $0/month (with cold starts)
- **Starter Plan**: $7/month (no cold starts, better performance)

## Next Steps

1. Monitor logs for 24 hours
2. Test all features thoroughly
3. Consider upgrading if cold starts are problematic
4. Set up monitoring/alerts
5. Add custom domain (optional)

## Support

- Render Docs: https://render.com/docs
- Render Community: https://community.render.com/
- FastAPI Docs: https://fastapi.tiangolo.com/

---

**Need help?** Check the logs first:
- Render: Dashboard → Your Service → Logs
- Vercel: Dashboard → Your Project → Deployments → Function Logs
