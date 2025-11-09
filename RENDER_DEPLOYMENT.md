# Render.com Backend Deployment Guide

## Quick Start

### 1. Push to GitHub
```bash
git add .
git commit -m "Add Render deployment config"
git push origin main
```

### 2. Deploy to Render

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click **"New +"** → **"Blueprint"**
3. Connect your GitHub repository
4. Render will automatically detect `render.yaml`
5. Click **"Apply"**

### 3. Set Environment Variables

In the Render dashboard, go to your service and add these **secret** environment variables:

**Required:**
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_KEY` - Your Supabase anon key
- `SUPABASE_SERVICE_KEY` - Your Supabase service role key
- `GOOGLE_CLIENT_ID` - Google OAuth client ID
- `GOOGLE_CLIENT_SECRET` - Google OAuth client secret
- `ENCRYPTION_KEY` - Generate with: `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`

**Optional (for AI features):**
- `PINECONE_API_KEY` - Pinecone vector database
- `OPENROUTER_API_KEY` - OpenRouter API
- `GROQ_API_KEY` - Groq API
- `DEEPSEEK_API_KEY` - DeepSeek OCR

### 4. Update Frontend Config

Once deployed, update your frontend to use the Render backend URL:

**Vercel Environment Variables:**
```
BACKEND_URL=https://scholarmate-backend.onrender.com
```

Or update `frontend/.env`:
```
BACKEND_URL=https://scholarmate-backend.onrender.com
```

## Deployment Details

### Free Tier Limitations
- Service spins down after 15 minutes of inactivity
- First request after spin-down takes ~30-60 seconds (cold start)
- 750 hours/month free (enough for 1 service running 24/7)

### Build Process
1. Render installs `uv` (Python package manager)
2. Runs `uv sync` to install dependencies from `pyproject.toml`
3. Starts server with `uvicorn` on dynamic `$PORT`

### CORS Configuration
The backend is configured to accept requests from:
- `https://scholar-mate-nine.vercel.app` (your Vercel frontend)

To add more origins, update the `CORS_ORIGINS` environment variable in Render dashboard (comma-separated).

## Monitoring

### Health Check
```bash
curl https://scholarmate-backend.onrender.com/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "scholarmate-backend"
}
```

### API Documentation
- Swagger UI: `https://scholarmate-backend.onrender.com/docs`
- ReDoc: `https://scholarmate-backend.onrender.com/redoc`

### Logs
View logs in Render dashboard → Your Service → Logs tab

## Troubleshooting

### Cold Start Issues
If users experience slow first requests:
1. Consider upgrading to paid plan ($7/month) for always-on service
2. Or implement a keep-alive ping from frontend every 10 minutes

### Build Failures
Check that:
- `backend/pyproject.toml` has all required dependencies
- Python version is 3.12+
- `uv.lock` is committed to git

### CORS Errors
Update `CORS_ORIGINS` in Render dashboard to include your frontend URL.

## Alternative: Manual Deployment

If you prefer not to use Blueprint:

1. **New Web Service**
2. **Connect Repository**
3. **Configure:**
   - Name: `scholarmate-backend`
   - Region: Oregon (or closest to you)
   - Branch: `main`
   - Root Directory: `backend`
   - Runtime: Python 3
   - Build Command: `pip install uv && uv sync`
   - Start Command: `uv run uvicorn app.main:app --host 0.0.0.0 --port $PORT`
4. **Add Environment Variables** (see step 3 above)
5. **Create Web Service**

## Cost Optimization

Free tier is sufficient for development/testing. For production:
- **Starter Plan ($7/month)**: No cold starts, better performance
- **Standard Plan ($25/month)**: More resources, faster builds

## Next Steps

After deployment:
1. Test health endpoint
2. Update frontend `BACKEND_URL`
3. Test authentication flow
4. Test OCR and AI features
5. Monitor logs for errors

## Support

- [Render Documentation](https://render.com/docs)
- [Render Community](https://community.render.com/)
