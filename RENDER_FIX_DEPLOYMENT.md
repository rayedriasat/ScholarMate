# Render Deployment Fix - Server Restart & Deprecation Issues

## Issues Fixed

1. **LangChain Deprecation Warning** - Upgraded from `langchain_community.embeddings.HuggingFaceEmbeddings` to `langchain_huggingface.HuggingFaceEmbeddings`
2. **Server Restarts** - Implemented lazy-loading for embedding models to prevent startup timeouts
3. **Cold Start Performance** - Added model pre-loading script

## Changes Made

### 1. Updated Imports (rag_query_service.py & rag_indexer.py)
```python
# OLD (deprecated)
from langchain_community.embeddings import HuggingFaceEmbeddings

# NEW (correct)
from langchain_huggingface import HuggingFaceEmbeddings
```

### 2. Lazy-Loading Embeddings
Both services now use lazy-loading to avoid blocking server startup:

```python
@property
def embeddings(self):
    """Lazy-load embeddings model on first access."""
    if self._embeddings is None:
        logger.info(f"Loading embedding model: {self._embedding_model}")
        self._embeddings = HuggingFaceEmbeddings(...)
    return self._embeddings
```

### 3. New Startup Script (backend/start.sh)
Pre-loads the embedding model before starting uvicorn:

```bash
#!/bin/bash
python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')"
exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --workers 1 --timeout-keep-alive 75
```

### 4. Render Configuration (render.yaml)
Proper configuration for Render deployment with health checks.

## Deployment Steps

### Option A: Using render.yaml (Recommended)

1. **Commit changes:**
```bash
git add .
git commit -m "Fix Render deployment: upgrade langchain, lazy-load embeddings"
git push origin main
```

2. **Deploy via Render Dashboard:**
   - Go to [Render Dashboard](https://dashboard.render.com/)
   - Click "New +" → "Blueprint"
   - Connect your GitHub repo
   - Render will detect `render.yaml` and configure automatically
   - Click "Apply"

3. **Set environment variables** in Render dashboard (see below)

### Option B: Manual Configuration

If you already have a service:

1. **Update Build Command:**
```bash
pip install uv && uv sync
```

2. **Update Start Command:**
```bash
bash start.sh
```

3. **Set Health Check Path:**
```
/api/health
```

## Required Environment Variables

Set these in Render Dashboard → Your Service → Environment:

**Required:**
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_KEY` - Your Supabase anon key  
- `SUPABASE_SERVICE_KEY` - Your Supabase service role key
- `GOOGLE_CLIENT_ID` - Google OAuth client ID
- `GOOGLE_CLIENT_SECRET` - Google OAuth client secret
- `ENCRYPTION_KEY` - Generate: `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`

**Optional (for AI features):**
- `PINECONE_API_KEY` - Pinecone vector database
- `GROQ_API_KEY` - Groq API (for RAG chat)
- `DEEPSEEK_API_KEY` - DeepSeek OCR
- `OPENROUTER_API_KEY` - OpenRouter API

**Configuration:**
- `LOG_LEVEL` - Set to `INFO` (default) or `DEBUG`
- `DEBUG` - Set to `false` for production
- `CORS_ORIGINS` - Comma-separated list of allowed origins

## Why Server Was Restarting

The issue was that loading the sentence-transformers model (~80MB) during service initialization was taking too long, causing Render to think the service failed to start. This triggered automatic restarts.

**Solutions implemented:**
1. **Lazy-loading** - Model loads on first request, not at startup
2. **Pre-loading script** - Optional pre-load during build to cache model
3. **Proper timeouts** - Increased keep-alive timeout to 75 seconds

## Monitoring

### Check Deployment Status
```bash
curl https://your-service.onrender.com/api/health
```

Expected response:
```json
{"status": "healthy", "service": "scholarmate-backend"}
```

### View Logs
Render Dashboard → Your Service → Logs

You should now see:
```
RAG Query Service initialized (embeddings will load on first use)
RAG Indexer initialized (embeddings will load on first use)
```

Instead of the deprecation warning.

## Performance Notes

**First RAG Request:**
- Will take 5-10 seconds longer (model loading)
- Subsequent requests will be fast (~1-2 seconds)

**Cold Starts (Free Tier):**
- Service spins down after 15 minutes of inactivity
- First request after spin-down: ~30-60 seconds
- Consider upgrading to Starter plan ($7/month) for always-on service

## Troubleshooting

### Still seeing deprecation warning?
Make sure you deployed the latest code:
```bash
git log -1  # Check latest commit
git push origin main  # Push if needed
```

Then trigger a manual deploy in Render dashboard.

### Server still restarting?
Check logs for:
- Memory issues (upgrade to larger instance)
- Missing environment variables
- Database connection failures

### Model download failing?
The model will download on first use. If it fails:
- Check Render logs for network errors
- Verify you have enough disk space (free tier: 512MB)
- Consider pre-downloading model during build

## Next Steps

1. Deploy changes to Render
2. Test health endpoint
3. Test RAG chat endpoint (first request will be slower)
4. Monitor logs for any remaining issues
5. Update frontend `BACKEND_URL` if needed

## Support

- [Render Documentation](https://render.com/docs)
- [LangChain HuggingFace Docs](https://python.langchain.com/docs/integrations/text_embedding/huggingfacehub)
