# Complete Deployment Guide - Frontend + Backend

## Overview

- **Frontend**: Vercel (https://scholar-mate-nine.vercel.app)
- **Backend**: Render.com (https://scholarmate-backend.onrender.com)

## Step 1: Deploy Backend to Render

### 1.1 Push Code to GitHub
```bash
git add .
git commit -m "Add Render deployment config"
git push origin main
```

### 1.2 Create Render Service

**Option A: Blueprint (Recommended)**
1. Go to https://dashboard.render.com/
2. Click **New +** → **Blueprint**
3. Connect your GitHub repository
4. Render will detect `render.yaml` automatically
5. Click **Apply**

**Option B: Manual Setup**
1. Go to https://dashboard.render.com/
2. Click **New +** → **Web Service**
3. Connect your GitHub repository
4. Configure:
   - **Name**: `scholarmate-backend`
   - **Region**: Oregon (or closest to you)
   - **Branch**: `main`
   - **Root Directory**: `backend`
   - **Runtime**: Python 3
   - **Build Command**: `pip install uv && uv sync`
   - **Start Command**: `uv run uvicorn app.main:app --host 0.0.0.0 --port $PORT`
5. Click **Create Web Service**

### 1.3 Add Environment Variables in Render

Go to your service → **Environment** tab and add these **secret** variables:

**Required:**
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_KEY=your_supabase_anon_key
SUPABASE_SERVICE_KEY=your_supabase_service_role_key
GOOGLE_CLIENT_ID=your_google_oauth_client_id
GOOGLE_CLIENT_SECRET=your_google_oauth_client_secret
ENCRYPTION_KEY=generate_with_command_below
```

**Generate Encryption Key:**
```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

**Optional (for AI features):**
```
PINECONE_API_KEY=your_pinecone_api_key
OPENROUTER_API_KEY=your_openrouter_api_key
GROQ_API_KEY=your_groq_api_key
DEEPSEEK_API_KEY=your_deepseek_api_key
```

### 1.4 Wait for Deployment
- First build takes ~3-5 minutes
- Watch logs in Render dashboard
- Service URL: `https://scholarmate-backend.onrender.com`

### 1.5 Test Backend
```bash
curl https://scholarmate-backend.onrender.com/api/health
```

Expected response:
```json
{"status": "healthy", "service": "scholarmate-backend"}
```

## Step 2: Update Frontend Configuration

### 2.1 Update Vercel Environment Variables

Go to https://vercel.com/your-username/scholar-mate-nine/settings/environment-variables

Add or update:
```
BACKEND_URL=https://scholarmate-backend.onrender.com
API_BASE_URL=https://scholarmate-backend.onrender.com
```

### 2.2 Update api/config.js

The file should already be configured, but verify it includes:
```javascript
export default function handler(req, res) {
  res.status(200).json({
    GOOGLE_CLIENT_ID: process.env.GOOGLE_CLIENT_ID,
    GOOGLE_CLIENT_SECRET: process.env.GOOGLE_CLIENT_SECRET,
    GOOGLE_REDIRECT_URI: process.env.GOOGLE_REDIRECT_URI,
    API_BASE_URL: process.env.API_BASE_URL || process.env.BACKEND_URL,
    SUPABASE_URL: process.env.SUPABASE_URL,
    SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY,
  });
}
```

### 2.3 Redeploy Frontend

**Option A: Automatic (if connected to GitHub)**
```bash
git add .
git commit -m "Update backend URL to Render"
git push origin main
```
Vercel will auto-deploy.

**Option B: Manual**
```bash
cd frontend
flutter build web --release
# Then upload to Vercel dashboard
```

## Step 3: Update CORS Configuration

### 3.1 Update Backend CORS

In Render dashboard, add/update environment variable:
```
CORS_ORIGINS=https://scholar-mate-nine.vercel.app,https://scholarmate-backend.onrender.com
```

If you have a custom domain, add it too:
```
CORS_ORIGINS=https://scholar-mate-nine.vercel.app,https://your-custom-domain.com
```

### 3.2 Redeploy Backend
After updating CORS, Render will automatically redeploy.

## Step 4: Update Google OAuth Configuration

### 4.1 Add Authorized Origins
Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)

Add to **Authorized JavaScript origins**:
```
https://scholar-mate-nine.vercel.app
https://scholarmate-backend.onrender.com
```

### 4.2 Add Authorized Redirect URIs
Add to **Authorized redirect URIs**:
```
https://scholar-mate-nine.vercel.app/auth/callback
https://scholarmate-backend.onrender.com/auth/callback
```

## Step 5: Test Full Stack

### 5.1 Test Health Endpoints
```bash
# Backend
curl https://scholarmate-backend.onrender.com/api/health

# Frontend (should load)
curl https://scholar-mate-nine.vercel.app
```

### 5.2 Test Authentication Flow
1. Open https://scholar-mate-nine.vercel.app
2. Click "Sign in with Google"
3. Complete OAuth flow
4. Verify you're logged in

### 5.3 Test API Integration
1. Upload a PDF
2. Try OCR processing
3. Test AI chat features

## Monitoring & Troubleshooting

### Backend Logs
- Render Dashboard → Your Service → Logs tab
- Real-time log streaming

### Frontend Logs
- Vercel Dashboard → Your Project → Deployments → View Function Logs
- Browser console (F12)

### Common Issues

**1. CORS Errors**
- Update `CORS_ORIGINS` in Render to include your frontend URL
- Verify Google OAuth origins are correct

**2. Cold Start Delays**
- Free tier spins down after 15 min inactivity
- First request takes 30-60 seconds
- Solution: Upgrade to Starter plan ($7/month) or implement keep-alive

**3. Environment Variables Not Loading**
- Verify all required variables are set in Render
- Check for typos in variable names
- Redeploy after adding variables

**4. Build Failures**
- Check Render logs for specific errors
- Verify `pyproject.toml` has all dependencies
- Ensure Python version is 3.12+

## Cost Summary

**Free Tier:**
- Vercel: Unlimited bandwidth, 100GB/month
- Render: 750 hours/month (1 service 24/7)
- Total: $0/month

**Recommended Production:**
- Vercel: Free (sufficient)
- Render Starter: $7/month (no cold starts)
- Total: $7/month

## API Documentation

Once deployed:
- Swagger UI: https://scholarmate-backend.onrender.com/docs
- ReDoc: https://scholarmate-backend.onrender.com/redoc

## Next Steps

1. Set up custom domain (optional)
2. Configure monitoring/alerts
3. Set up CI/CD for automated testing
4. Implement keep-alive for free tier
5. Add error tracking (Sentry, etc.)

## Support Resources

- [Render Documentation](https://render.com/docs)
- [Vercel Documentation](https://vercel.com/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Flutter Web Documentation](https://flutter.dev/web)
