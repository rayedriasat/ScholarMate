# Pinecone Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Get Pinecone API Key (2 minutes)

1. Go to [Pinecone.io](https://www.pinecone.io/)
2. Click "Sign Up" (no credit card required)
3. Verify your email
4. Go to "API Keys" in the dashboard
5. Copy your API key

### Step 2: Configure Backend (1 minute)

Edit `backend/.env`:

```bash
# Add these lines
PINECONE_API_KEY=pc-xxxxxxxxxxxxxxxxxxxxx
PINECONE_INDEX_NAME=scholarmate
PINECONE_DIMENSION=384
PINECONE_CLOUD=aws
PINECONE_REGION=us-east-1
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
```

### Step 3: Install Dependencies (1 minute)

```bash
cd backend
uv sync
```

### Step 4: Start Backend (1 minute)

```bash
uv run python run.py
```

That's it! The Pinecone index will be created automatically on first run.

## ✅ Verify It Works

### Test 1: Check Health
```bash
curl http://localhost:8000/api/health
```

### Test 2: Index a Document
```bash
curl -X POST http://localhost:8000/api/ingest/start \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user-123",
    "file_id": "your-google-drive-file-id",
    "file_name": "test.pdf"
  }'
```

### Test 3: Query with RAG
```bash
curl -X POST http://localhost:8000/api/ai/chat-rag \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user-123",
    "question": "What is this document about?",
    "top_k": 5
  }'
```

## 📊 What Happens Behind the Scenes

1. **First Run**: Downloads embedding model (~80MB, cached)
2. **Index Creation**: Creates Pinecone serverless index
3. **Indexing**: Generates embeddings and stores in Pinecone
4. **Querying**: Generates query embedding and searches Pinecone

## 🎯 Key Features

- ✅ **No Persistent Storage**: Perfect for free hosting
- ✅ **Free Tier**: 100K vectors, 2GB storage
- ✅ **Auto-Scaling**: Pinecone handles scaling
- ✅ **User Isolation**: Each user gets their own namespace
- ✅ **Fast**: ~200-300ms query time

## 🔧 Configuration Options

### Change Embedding Model

```bash
# Smaller, faster (default)
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
PINECONE_DIMENSION=384

# Larger, more accurate
EMBEDDING_MODEL=sentence-transformers/all-mpnet-base-v2
PINECONE_DIMENSION=768
```

**Note**: If you change the model, you must:
1. Update `PINECONE_DIMENSION` to match
2. Delete and recreate the index
3. Re-index all documents

### Change Region

Free tier regions:
- AWS: `us-east-1` (default)
- GCP: `gcp-starter`

```bash
PINECONE_CLOUD=aws
PINECONE_REGION=us-east-1
```

## 🐛 Troubleshooting

### "Invalid API key"
- Check your API key is correct
- Ensure no extra spaces in `.env` file

### "Index creation failed"
- Verify region is available for free tier
- Check you don't already have an index (free tier = 1 index)

### "Model download slow"
- First run downloads ~80MB model
- Subsequent runs use cached model
- Check your internet connection

### "Out of quota"
- Free tier: 100K vectors max
- Each PDF = ~1000 vectors
- Delete old documents or upgrade

## 📚 API Endpoints

### Indexing
- `POST /api/ingest/start` - Start indexing
- `GET /api/ingest/status/{job_id}` - Check status
- `GET /api/ingest/list/{user_id}` - List jobs
- `POST /api/ingest/reindex/{file_id}` - Reindex file

### Querying
- `POST /api/ai/chat-rag` - RAG chat with citations
- `POST /api/ai/chat` - Direct GROQ chat
- `POST /api/ai/embed` - Generate embeddings

### Docs
- Swagger: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 🚢 Deploy to Free Hosting

### Render.com
```yaml
# render.yaml
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
# railway.toml
[build]
builder = "NIXPACKS"
buildCommand = "cd backend && uv sync"

[deploy]
startCommand = "cd backend && uv run python run.py"
```

### Fly.io
```toml
# fly.toml
[build]
  builder = "paketobuildpacks/builder:base"

[env]
  PORT = "8000"
```

## 💡 Tips

1. **First deployment**: Allow extra time for model download
2. **Environment variables**: Set in hosting dashboard
3. **Health checks**: Use `/api/health` endpoint
4. **Logs**: Check for "Pinecone initialized" message
5. **Testing**: Use Swagger UI at `/docs`

## 📖 Next Steps

- Read [PINECONE_MIGRATION_GUIDE.md](PINECONE_MIGRATION_GUIDE.md) for details
- Check [PINECONE_IMPLEMENTATION_SUMMARY.md](PINECONE_IMPLEMENTATION_SUMMARY.md) for technical info
- Review API docs at http://localhost:8000/docs

## 🆘 Need Help?

- Pinecone Docs: https://docs.pinecone.io/
- LangChain Pinecone: https://python.langchain.com/docs/integrations/vectorstores/pinecone
- Sentence Transformers: https://www.sbert.net/

## ✨ Benefits Over ChromaDB

| Feature | ChromaDB | Pinecone |
|---------|----------|----------|
| Storage | Local disk | Cloud |
| Persistence | Requires volume | Always |
| Free Hosting | ❌ Needs disk | ✅ Works |
| Scaling | Manual | Automatic |
| Setup | Complex | Simple |
| Cost | Free | Free tier |
