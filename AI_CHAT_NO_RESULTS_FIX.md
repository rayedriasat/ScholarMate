# AI Chat "No Relevant Information" Fix

## Problem
When sending messages to the AI Assistant, you get:
> "I couldn't find any relevant information in the selected documents to answer your questions"

## Root Cause
**Your PDF documents haven't been indexed yet.** The AI chat uses RAG (Retrieval Augmented Generation) which requires documents to be indexed in ChromaDB before they can be queried.

## Solution

### Step 1: Index Your Documents

1. **Open the File Explorer** in ScholarMate
2. **Find a PDF file** you want to chat about
3. **Right-click (or tap the ⋮ menu)** on the PDF
4. **Select "Reindex for AI"**
5. **Wait for indexing to complete** (progress shown in UI)
6. **Repeat for all PDFs** you want to include in chat

### Step 2: Verify Indexing

Run this command to check if documents are indexed:

```bash
cd backend
uv run python test_user_indexing.py YOUR_USER_ID
```

Replace `YOUR_USER_ID` with your Google user ID (shown in app or use default `111319857386978820359`).

### Step 3: Test Chat

1. Go to **AI Chat** screen
2. Click the **filter icon** (top right) to select sources
3. **Select the PDFs** you just indexed
4. **Ask a question** about the content
5. You should now get relevant answers with citations!

## How It Works

```
┌─────────────────┐
│  Upload PDF     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Manual Index   │ ← YOU MUST DO THIS
│  (Right-click)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  ChromaDB       │
│  (Vector Store) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  AI Chat        │
│  (RAG Query)    │
└─────────────────┘
```

## Common Issues

### Issue 1: "No documents indexed"
**Solution:** Index your PDFs using the "Reindex for AI" option in File Explorer.

### Issue 2: "Selected sources but still no results"
**Solution:** 
- Make sure the selected PDFs are actually indexed (check indexing status badge)
- Wait for indexing to complete (don't chat while indexing is in progress)
- Try refreshing the file list

### Issue 3: "Backend connection error"
**Solution:**
- Make sure backend is running: `cd backend && uv run python run.py`
- Check backend logs for errors
- Verify GROQ_API_KEY is set in `backend/.env`

## Technical Details

### Backend Flow
1. **Indexing API** (`POST /api/ingestion/index`) processes PDF
2. **OCR Service** extracts text from PDF pages
3. **RAG Indexer** chunks text and generates embeddings
4. **ChromaDB** stores vectors in user-specific collection

### Chat Flow
1. **User sends question** with optional file filters
2. **RAG Query Service** searches ChromaDB for relevant chunks
3. **GROQ LLM** generates answer based on retrieved context
4. **Citations** are extracted and returned to frontend

### Checking Collection Stats

```python
from app.services.chroma_service import get_chroma_service

cs = get_chroma_service()
stats = cs.get_collection_stats("YOUR_USER_ID")
print(f"Documents indexed: {stats['document_count']}")
```

### Manual Indexing via API

```bash
curl -X POST http://localhost:8000/api/ingestion/index \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "YOUR_USER_ID",
    "file_id": "FILE_ID_FROM_DRIVE",
    "file_name": "document.pdf"
  }'
```

## Future Improvements

Consider implementing:
1. **Auto-indexing** on file upload
2. **Bulk indexing** for all PDFs at once
3. **Index status indicator** in file list
4. **Background indexing** queue
5. **Index health check** on app startup

## Quick Reference

| Action | Location | Purpose |
|--------|----------|---------|
| Index PDF | File Explorer → Right-click → "Reindex for AI" | Add document to vector store |
| Select Sources | AI Chat → Filter icon | Choose which PDFs to query |
| Check Status | File Explorer → Indexing badge | See indexing progress |
| Test Backend | `uv run python test_user_indexing.py` | Verify indexing works |

## Need Help?

1. Check backend logs: `cd backend && uv run python run.py`
2. Verify environment: Check `backend/.env` has `GROQ_API_KEY`
3. Test ChromaDB: `uv run python check_user_docs.py YOUR_USER_ID`
4. Check API docs: http://localhost:8000/docs
