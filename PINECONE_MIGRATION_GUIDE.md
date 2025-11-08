# Pinecone Migration Guide

## Overview

Successfully migrated from ChromaDB to Pinecone for vector storage. This change enables deployment to free hosting services that don't offer persistent storage.

## What Changed

### 1. Vector Database
- **Before**: ChromaDB (local persistent storage)
- **After**: Pinecone (cloud-based, serverless)

### 2. Architecture
- **User Isolation**: Changed from ChromaDB collections to Pinecone namespaces
- **Embeddings**: Now using HuggingFace `sentence-transformers/all-MiniLM-L6-v2` (free, runs locally)
- **Storage**: Vectors stored in Pinecone cloud (free tier: 1 index, 100K vectors)

### 3. Files Modified
- `backend/app/services/pinecone_service.py` - New service replacing `chroma_service.py`
- `backend/app/services/rag_indexer.py` - Updated to use Pinecone and generate embeddings
- `backend/app/services/rag_query_service.py` - Updated to use Pinecone with query embeddings
- `backend.env.template` - Added Pinecone configuration

### 4. Dependencies Added
```bash
uv add pinecone-client langchain-pinecone sentence-transformers
```

## Setup Instructions

### 1. Get Pinecone API Key

1. Sign up at [Pinecone](https://www.pinecone.io/)
2. Create a free account (no credit card required)
3. Go to API Keys section
4. Copy your API key

### 2. Configure Environment

Update your `backend/.env` file:

```bash
# Pinecone Configuration
PINECONE_API_KEY=your_pinecone_api_key_here
PINECONE_INDEX_NAME=scholarmate
PINECONE_DIMENSION=384
PINECONE_CLOUD=aws
PINECONE_REGION=us-east-1

# Embedding Model
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
```

**Important**: 
- `PINECONE_DIMENSION=384` matches the `all-MiniLM-L6-v2` model
- If you change the embedding model, update the dimension accordingly
- Free tier regions: `us-east-1` (AWS) or `gcp-starter` (GCP)

### 3. Install Dependencies

```bash
cd backend
uv sync
```

### 4. Start Backend

```bash
cd backend
uv run python run.py
```

The Pinecone index will be created automatically on first run.

## Migration from ChromaDB

If you have existing data in ChromaDB, you'll need to re-index your documents:

1. **Backup ChromaDB data** (optional):
   ```bash
   cp -r backend/chroma_db backend/chroma_db_backup
   ```

2. **Re-index documents**: Use the indexing API endpoints to re-index your PDFs
   - The new system will generate embeddings and store them in Pinecone
   - User namespaces will be created automatically

3. **Clean up** (optional):
   ```bash
   rm -rf backend/chroma_db
   ```

## Key Differences

### ChromaDB vs Pinecone

| Feature | ChromaDB | Pinecone |
|---------|----------|----------|
| Storage | Local files | Cloud-based |
| Isolation | Collections | Namespaces |
| Embeddings | Built-in default | Must provide |
| Free Tier | Unlimited | 100K vectors |
| Persistence | Requires disk | Always available |

### API Changes

The service interfaces remain the same, but internally:

1. **Embeddings are required**: Pinecone doesn't generate embeddings, so we use HuggingFace models
2. **Namespace-based**: Users are isolated by namespaces instead of collections
3. **Metadata storage**: Text is stored in metadata for retrieval

## Free Tier Limits

Pinecone free tier includes:
- 1 serverless index
- 100,000 vectors
- 2GB storage
- No credit card required

For ScholarMate:
- ~1000 chunks per PDF (1000 char chunks)
- Free tier = ~100 PDFs per user
- Multiple users share the same index (isolated by namespace)

## Troubleshooting

### Index Creation Fails
- Check your API key is correct
- Verify region is available for free tier
- Ensure dimension matches your embedding model

### Embeddings Too Slow
- First run downloads the model (~80MB)
- Subsequent runs use cached model
- Consider using GPU if available (update `device: 'cuda'`)

### Out of Quota
- Free tier: 100K vectors max
- Delete old documents: Use the delete endpoints
- Upgrade to paid tier if needed

## Testing

Test the integration:

```bash
# Test indexing
curl -X POST http://localhost:8000/api/rag/index \
  -H "Content-Type: application/json" \
  -d '{"file_id": "your_file_id", "user_id": "your_user_id"}'

# Test querying
curl -X POST http://localhost:8000/api/rag/query \
  -H "Content-Type: application/json" \
  -d '{"question": "What is this about?", "user_id": "your_user_id"}'
```

## Benefits

1. **No persistent storage needed**: Perfect for free hosting (Render, Railway, etc.)
2. **Scalable**: Pinecone handles scaling automatically
3. **Always available**: No data loss on container restarts
4. **Free tier**: Sufficient for development and small deployments
5. **LangChain compatible**: Easy integration with existing code

## Next Steps

1. Update your `.env` file with Pinecone credentials
2. Re-index your documents
3. Test the RAG functionality
4. Deploy to your free hosting service

## Support

- Pinecone Docs: https://docs.pinecone.io/
- LangChain Pinecone: https://python.langchain.com/docs/integrations/vectorstores/pinecone
- Sentence Transformers: https://www.sbert.net/
