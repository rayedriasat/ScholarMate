# Pinecone Vector Database Integration

## Overview

ScholarMate now uses **Pinecone** as its vector database, replacing ChromaDB. This enables deployment to free hosting services that don't offer persistent storage.

## Why Pinecone?

- ✅ **Cloud-based**: No local storage needed
- ✅ **Free tier**: 100K vectors, 2GB storage
- ✅ **Auto-scaling**: Handles growth automatically
- ✅ **Persistent**: Data survives container restarts
- ✅ **Fast**: ~200-300ms query time

Perfect for deploying to:
- Render.com (free tier)
- Railway.app (free tier)
- Fly.io (free tier)
- Any hosting without persistent volumes

## Quick Start

### 1. Get API Key (2 minutes)
1. Sign up at [Pinecone.io](https://www.pinecone.io/)
2. Get your API key from the dashboard

### 2. Configure (1 minute)
Edit `backend/.env`:
```bash
PINECONE_API_KEY=your_api_key_here
PINECONE_INDEX_NAME=scholarmate
PINECONE_DIMENSION=384
PINECONE_CLOUD=aws
PINECONE_REGION=us-east-1
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
```

### 3. Install (1 minute)
```bash
cd backend
uv sync
```

### 4. Run (1 minute)
```bash
uv run python run.py
```

Done! The index is created automatically.

## Architecture

### User Isolation
Each user gets their own **namespace** in Pinecone:
- Format: `user_{user_id}`
- Isolated data per user
- Shared index (cost-efficient)

### Embeddings
Uses **HuggingFace sentence-transformers**:
- Model: `all-MiniLM-L6-v2`
- Dimensions: 384
- Free and runs locally
- ~80MB download (cached)

### Data Flow

**Indexing**:
```
PDF → Text → Chunks → Embeddings → Pinecone
```

**Querying**:
```
Question → Embedding → Pinecone Search → GROQ → Answer
```

## API Endpoints

All existing endpoints work unchanged:

### Indexing
```bash
POST /api/ingest/start
GET /api/ingest/status/{job_id}
GET /api/ingest/list/{user_id}
POST /api/ingest/reindex/{file_id}
```

### Querying
```bash
POST /api/ai/chat-rag
POST /api/ai/chat
POST /api/ai/embed
```

## Free Tier Limits

- **Vectors**: 100,000 max
- **Storage**: 2GB
- **Indexes**: 1 serverless
- **Cost**: $0 (no credit card)

**Capacity**:
- ~100 PDFs per user
- ~1000 chunks per PDF
- Multiple users supported

## Performance

| Operation | Time |
|-----------|------|
| Indexing | ~2-3s per page |
| Querying | ~200-300ms |
| First run | +10s (model download) |

## Migration from ChromaDB

If you have existing ChromaDB data:

1. **Backup** (optional):
   ```bash
   cp -r backend/chroma_db backend/chroma_db_backup
   ```

2. **Re-index**: Use the API to re-index your PDFs

3. **Clean up** (optional):
   ```bash
   rm -rf backend/chroma_db
   ```

## Documentation

- 📖 [Quick Start Guide](PINECONE_QUICK_START.md) - Get started in 5 minutes
- 📖 [Migration Guide](PINECONE_MIGRATION_GUIDE.md) - Detailed setup instructions
- 📖 [Implementation Summary](PINECONE_IMPLEMENTATION_SUMMARY.md) - Technical details
- 📖 [Why Pinecone?](WHY_PINECONE.md) - Rationale and comparison
- 📖 [Checklist](PINECONE_CHECKLIST.md) - Setup and verification steps

## Files Changed

### New Files
- `backend/app/services/pinecone_service.py` - Pinecone integration

### Updated Files
- `backend/app/services/rag_indexer.py` - Uses Pinecone + embeddings
- `backend/app/services/rag_query_service.py` - Uses Pinecone for queries
- `backend/app/routers/ingestion.py` - Fixed reindex endpoint
- `backend.env.template` - Added Pinecone config

### Dependencies Added
```toml
pinecone-client = ">=6.0.0"
langchain-pinecone = ">=0.2.13"
sentence-transformers = ">=5.1.2"
```

## Testing

### Health Check
```bash
curl http://localhost:8000/api/health
```

### Index a Document
```bash
curl -X POST http://localhost:8000/api/ingest/start \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user",
    "file_id": "your-file-id",
    "file_name": "test.pdf"
  }'
```

### Query with RAG
```bash
curl -X POST http://localhost:8000/api/ai/chat-rag \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user",
    "question": "What is this about?",
    "top_k": 5
  }'
```

## Deployment

### Render.com
```yaml
services:
  - type: web
    name: scholarmate-backend
    env: python
    buildCommand: "cd backend && uv sync"
    startCommand: "cd backend && uv run python run.py"
    envVars:
      - key: PINECONE_API_KEY
        sync: false
```

### Railway.app
```toml
[build]
builder = "NIXPACKS"
buildCommand = "cd backend && uv sync"

[deploy]
startCommand = "cd backend && uv run python run.py"
```

### Environment Variables
Set in your hosting dashboard:
- `PINECONE_API_KEY`
- `PINECONE_INDEX_NAME`
- `PINECONE_DIMENSION`
- `PINECONE_CLOUD`
- `PINECONE_REGION`
- `EMBEDDING_MODEL`

## Troubleshooting

### "Invalid API key"
- Check API key in Pinecone dashboard
- Verify no extra spaces in `.env`

### "Index creation failed"
- Check region is free tier compatible
- Verify you don't have an existing index

### "Model download slow"
- First run downloads ~80MB
- Subsequent runs use cache
- Check internet connection

### "Out of quota"
- Free tier: 100K vectors max
- Delete old documents
- Upgrade to paid tier

## Support

- Pinecone Docs: https://docs.pinecone.io/
- LangChain Pinecone: https://python.langchain.com/docs/integrations/vectorstores/pinecone
- Sentence Transformers: https://www.sbert.net/

## Benefits

| Feature | ChromaDB | Pinecone |
|---------|----------|----------|
| Storage | Local disk | Cloud |
| Free Hosting | ❌ | ✅ |
| Persistence | Requires volume | Always |
| Scaling | Manual | Automatic |
| Setup | Complex | Simple |

## Next Steps

1. ✅ Get Pinecone API key
2. ✅ Update `.env` file
3. ✅ Run `uv sync`
4. ✅ Test locally
5. ✅ Deploy to free hosting

## License

Same as ScholarMate project.
