# Render Deployment Setup Guide

## Quick Setup

### 1. Configuration File

The `backend/render.yaml` is configured for:
- **Region:** Singapore (Southeast Asia)
- **Plan:** Free tier
- **Branch:** main
- **Root Directory:** backend
- **Build Command:** `uv sync --frozen`
- **Start Command:** `bash start.sh`
- **Health Check:** `/api/health`

### 2. Environment Variables

All environment variables are managed manually (not in render.yaml):

**Set in Render Dashboard → Your Service → Environment:**

#### Required Variables

```bash
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_supabase_anon_key
SUPABASE_SERVICE_KEY=your_supabase_service_key

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Encryption (generate with: python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
ENCRYPTION_KEY=your_generated_encryption_key
```

#### Optional Variables (AI Features)

```bash
# Pinecone (Vector Database)
PINECONE_API_KEY=your_pinecone_api_key
PINECONE_INDEX_NAME=scholarmate
PINECONE_DIMENSION=384
PINECONE_CLOUD=aws
PINECONE_REGION=us-east-1

# GROQ AI (for RAG chat)
GROQ_API_KEY=your_groq_api_key
GROQ_CHAT_MODEL=llama-3.3-70b-versatile

# OpenRouter (alternative AI provider)
OPENROUTER_API_KEY=your_openrouter_api_key

# DeepSeek OCR (optional, for high-accuracy online OCR)
DEEPSEEK_API_KEY=your_deepseek_api_key
```

#### Optional Variables (Configuration)

```bash
# Server
DEBUG=false
LOG_LEVEL=INFO

# CORS (comma-separated)
CORS_ORIGINS=https://your-frontend.vercel.app,https://your-domain.com

# Memory Optimization (for free tier 512MB limit)
EMBEDDING_BATCH_SIZE=10
PDF_PAGE_BATCH_SIZE=5

# Embedding Model
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
```

### 3. Local Development

Copy the template and fill in your values:

```bash
# Copy template
cp backend.env.template backend/.env

# Edit with your values
# Then add to .gitignore (already done)
```

## Deployment Methods

### Method 1: Blueprint (Recommended)

1. **Push to GitHub:**
   ```bash
   git add .
   git commit -m "Add Render configuration"
   git push origin main
   ```

2. **Deploy via Render:**
   - Go to [Render Dashboard](https://dashboard.render.com/)
   - Click "New +" → "Blueprint"
   - Connect your GitHub repository
   - Render detects `backend/render.yaml`
   - Click "Apply"

3. **Set Environment Variables:**
   - Go to your service → Environment
   - Add all required variables (see above)
   - Click "Save Changes"

4. **Trigger Deploy:**
   - Render will auto-deploy
   - Or click "Manual Deploy"

### Method 2: Manual Setup

1. **Create Web Service:**
   - Go to [Render Dashboard](https://dashboard.render.com/)
   - Click "New +" → "Web Service"
   - Connect your GitHub repository

2. **Configure Service:**
   - **Name:** scholarmate-backend
   - **Region:** Singapore (Southeast Asia)
   - **Branch:** main
   - **Root Directory:** backend
   - **Runtime:** Python 3
   - **Build Command:** `uv sync --frozen`
   - **Start Command:** `bash start.sh`

3. **Advanced Settings:**
   - **Health Check Path:** `/api/health`
   - **Plan:** Free

4. **Set Environment Variables:**
   - Add all required variables (see above)

5. **Create Web Service:**
   - Click "Create Web Service"
   - Wait for deployment

## Verification

### 1. Check Deployment Status

Watch logs in Render Dashboard → Logs:

```
Starting ScholarMate Backend (Memory-Optimized)...
Pre-loading embedding model (optional)...
Starting uvicorn server...
INFO:     Started server process
RAG Query Service initialized (embeddings will load on first use)
RAG Indexer initialized: chunk_size=500, embedding_batch=10, page_batch=5
INFO:     Application startup complete.
```

### 2. Test Health Endpoint

```bash
curl https://your-service.onrender.com/api/health
```

Expected response:
```json
{"status": "healthy", "service": "scholarmate-backend"}
```

### 3. Test API Documentation

Visit:
- Swagger UI: `https://your-service.onrender.com/docs`
- ReDoc: `https://your-service.onrender.com/redoc`

## Memory Optimization

The deployment is optimized for Render's free tier (512MB):

- **Chunk size:** 500 characters (reduced from 1000)
- **Batch processing:** 10 chunks at a time
- **Page processing:** 5 pages at a time
- **Target memory:** <400MB
- **Actual usage:** 150-250MB

### Tuning (if needed)

If you see memory issues, reduce batch sizes in Environment:

```bash
EMBEDDING_BATCH_SIZE=5   # Reduce from 10
PDF_PAGE_BATCH_SIZE=3    # Reduce from 5
```

If processing is too slow, increase (carefully):

```bash
EMBEDDING_BATCH_SIZE=15  # Increase from 10
PDF_PAGE_BATCH_SIZE=10   # Increase from 5
```

Monitor memory usage in Render Dashboard → Metrics.

## Troubleshooting

### Build Fails

**Error:** `uv: command not found`

**Fix:** Render should auto-install uv. If not, update build command:
```bash
pip install uv && uv sync --frozen
```

### Server Restarts

**Check:**
1. Health endpoint responds: `/api/health`
2. Startup time <5 seconds
3. No missing environment variables

**Fix:** Check logs for specific errors

### Memory Crashes

**Symptoms:**
- Server restarts during PDF indexing
- "Out of memory" errors

**Fix:**
1. Reduce batch sizes (see Tuning above)
2. Check logs for memory usage
3. Consider upgrading to Starter plan ($7/month, 2GB)

### Slow First Request

**Expected:** First RAG request takes 5-10 seconds (model loading)

**Normal:** Subsequent requests take 1-2 seconds

**If too slow:** Model pre-loading may be timing out. Edit `backend/start.sh`:
```bash
# Comment out this line:
# python -c "from sentence_transformers import SentenceTransformer; ..."
```

## Production Checklist

- [ ] All required environment variables set
- [ ] Health endpoint responds
- [ ] API documentation accessible
- [ ] Test PDF indexing (50+ pages)
- [ ] Test RAG chat
- [ ] Monitor memory usage (<400MB)
- [ ] Update frontend BACKEND_URL
- [ ] Test end-to-end workflow

## Support

- **Render Docs:** https://render.com/docs
- **Memory Issues:** See `MEMORY_OPTIMIZATION.md`
- **Deployment Issues:** See `DEPLOY_CHECKLIST.md`

## Summary

✓ Configuration in `backend/render.yaml`
✓ Environment variables managed in Render Dashboard
✓ Memory-optimized for free tier (512MB)
✓ Region: Singapore (Southeast Asia)
✓ Auto-deploy on push to main branch

**Ready to deploy!**
