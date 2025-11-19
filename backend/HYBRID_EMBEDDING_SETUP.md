# Hybrid Embedding System - Setup Guide

## Overview

The hybrid embedding system supports multiple strategies:
1. **HuggingFace Inference API** (primary) - Free tier, no backend RAM
2. **Local model** (fallback) - Backend-hosted for reliability
3. **On-device** (future) - Android TFLite implementation

## Backend Setup

### 1. Environment Configuration

Add to `backend/.env`:

```bash
# HuggingFace API Token (required for API strategy)
# Get from: https://huggingface.co/settings/tokens
HUGGINGFACEHUB_API_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxx

# Optional: Embedding model name (default: sentence-transformers/all-MiniLM-L6-v2)
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2

# Optional: Embedding batch sizes for memory optimization
EMBEDDING_BATCH_SIZE=3
PDF_PAGE_BATCH_SIZE=2
PINECONE_BATCH_SIZE=25
```

### 2. Install Dependencies

Dependencies already in `pyproject.toml`:
- `sentence-transformers>=5.1.2` (for local fallback)
- `requests>=2.32.5` (for API calls)

No additional packages needed!

### 3. Test the Setup

```bash
# Start backend
cd backend
uv run python run.py

# Test embedding health
curl http://localhost:8000/api/embeddings/health

# Expected response:
{
  "api_available": true,
  "local_available": true,
  "recommended_strategy": "api"
}
```

## How It Works

### Automatic Strategy Selection

The system automatically chooses the best strategy:

1. **For queries** (low volume):
   - Always tries API first (fast, no RAM)
   - Falls back to local if API unavailable

2. **For document indexing** (high volume):
   - Tries API first (free tier: 1000 requests/day)
   - Falls back to local if rate limited or API down

### API Usage Limits

**HuggingFace Inference API Free Tier**:
- 1000 requests/day
- ~30 requests/minute rate limit
- Model loading time: ~5 seconds (first request)

**Typical usage**:
- 1 document = 10-50 chunks = 10-50 API requests
- Free tier covers ~20-100 documents/day
- Queries: 1 request each (negligible)

### Memory Impact

**Before (local only)**:
- Model: ~150-200MB RAM
- Processing: +50-100MB
- Total: ~250-300MB

**After (hybrid with API)**:
- API mode: ~10-20MB RAM (no model loaded)
- Local fallback: ~150-200MB (only when needed)
- Savings: ~230-280MB when using API

## API Endpoints

### Generate Embeddings

```bash
POST /api/embeddings/generate
Content-Type: application/json

{
  "texts": ["text to embed", "another text"],
  "strategy": "auto"  # "auto", "api", or "local"
}

# Response:
{
  "embeddings": [[0.1, 0.2, ...], [0.3, 0.4, ...]],
  "strategy_used": "api",
  "count": 2
}
```

### Check Health

```bash
GET /api/embeddings/health

# Response:
{
  "api_available": true,
  "local_available": true,
  "recommended_strategy": "api"
}
```

## Frontend Integration (Future)

### For Web (Current)

Web continues using backend API - no changes needed. Backend automatically uses hybrid strategy.

### For Android (Future - Phase 2)

When implementing on-device embeddings:

1. **Add TFLite model to Flutter**:
```yaml
# pubspec.yaml
dependencies:
  tflite_flutter: ^0.10.0

flutter:
  assets:
    - assets/models/all-MiniLM-L6-v2.tflite
```

2. **Call backend API as fallback**:
```dart
// lib/services/embedding_service.dart
class EmbeddingService {
  Future<List<List<double>>> generateEmbeddings(List<String> texts) async {
    // Try on-device first
    try {
      return await _generateOnDevice(texts);
    } catch (e) {
      // Fallback to backend API
      return await _generateViaBackend(texts);
    }
  }
}
```

## Monitoring

### Check which strategy is being used

Backend logs show strategy selection:

```
INFO: Generating 10 embeddings via HuggingFace API
INFO: Generated 10 embeddings via API
```

Or if API fails:

```
WARNING: API embedding failed, falling back to local: Rate limit exceeded
INFO: Generating 10 embeddings with local model
```

### Monitor API usage

HuggingFace dashboard: https://huggingface.co/settings/tokens
- View API call counts
- Check rate limit status
- Monitor quota usage

## Troubleshooting

### API returns 503 (Model Loading)

**Cause**: Model is cold-starting on HF servers
**Solution**: System automatically retries after 5 seconds

### API returns 429 (Rate Limit)

**Cause**: Exceeded 1000 requests/day or 30 requests/minute
**Solution**: System automatically falls back to local model

### Local model fails to load

**Cause**: Missing model files or insufficient RAM
**Solution**: 
1. Check `backend/models/all-MiniLM-L6-v2/` exists
2. Ensure backend has 512MB+ RAM available
3. Reduce batch sizes in `.env`

### High memory usage even with API

**Cause**: Local model loaded as fallback and not unloaded
**Solution**: Model auto-unloads after 5 minutes of inactivity (future enhancement)

## Cost Analysis

### Free Tier Limits

**HuggingFace Inference API**:
- 1000 requests/day = FREE
- Typical user: 20-50 documents/day = 200-500 requests
- **Cost: $0/month** for most users

**If exceeding free tier**:
- Upgrade to HF Pro: $9/month (unlimited API calls)
- Or use local fallback (free, uses backend RAM)

### Comparison

| Users | Docs/day | API Requests | Cost (API) | Cost (Backend RAM) |
|-------|----------|--------------|------------|-------------------|
| 10    | 500      | 5,000        | $0 (free)  | $0 (512MB enough) |
| 50    | 2,500    | 25,000       | $9/mo (HF Pro) | $0 (fallback) |
| 100   | 5,000    | 50,000       | $9/mo (HF Pro) | $0 (fallback) |

**Recommendation**: Start with free tier, upgrade to HF Pro ($9/mo) only if needed.

## Next Steps

### Phase 1: Current (Completed)
✅ Hybrid backend with API + local fallback
✅ Automatic strategy selection
✅ API health monitoring

### Phase 2: Android On-Device (Future)
- [ ] Convert model to TFLite format
- [ ] Integrate `tflite_flutter` package
- [ ] Implement on-device embedding generation
- [ ] Add user preference: on-device vs backend

### Phase 3: Optimization (Future)
- [ ] Model quantization for smaller size
- [ ] Lazy unload local model after inactivity
- [ ] Batch optimization for API calls
- [ ] Caching for repeated queries

## Support

For issues or questions:
1. Check logs: `backend/logs/`
2. Test health endpoint: `/api/embeddings/health`
3. Verify HF token: https://huggingface.co/settings/tokens
4. Check API status: https://status.huggingface.co/
