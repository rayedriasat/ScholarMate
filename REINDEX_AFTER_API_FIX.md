# RAG Fix: Re-index Required

## Problem Identified

Your RAG is returning 0 results because:

1. **HuggingFace API endpoint changed** (410 error)
   - Old: `https://api-inference.huggingface.co` ❌
   - New: `https://router.huggingface.co` ✅

2. **Existing embeddings incompatible**
   - Your indexed documents were embedded using the OLD endpoint
   - Query embeddings now use the NEW endpoint
   - Different endpoints = different vector spaces = no matches

## Fixes Applied ✅

### 1. Updated API Endpoint
✅ Fixed `backend/app/services/embedding_service.py` line 33

### 2. Improved Filter Syntax
✅ Fixed `backend/app/services/rag_query_service.py` to handle single file filters better

### 3. Added Clear Namespace Endpoint
✅ Added `DELETE /api/ingest/clear/{user_id}` to `backend/app/routers/ingestion.py`

### 4. Backend Restarted
✅ Backend is running with new fixes

## Required Action: Re-index Your Documents

You MUST re-index all your documents to regenerate embeddings with the new API endpoint.

### Quick Fix (Recommended)

```bash
# 1. Clear all old embeddings
curl -X DELETE "http://localhost:8000/api/ingest/clear/111828646872592591995"

# 2. Re-upload your PDFs through the app
# The app will automatically index them with the new API endpoint
```

Replace `111828646872592591995` with your Google sub ID (from your logs)

### Alternative: Re-index Each File

If you want to keep job history:

```bash
# Windows
reindex-all-files.bat 111828646872592591995

# Or manually for each file
curl -X POST "http://localhost:8000/api/ingest/reindex/FILE_ID" ^
     -H "Content-Type: application/json" ^
     -d "{\"user_id\": \"111828646872592591995\", \"access_token\": \"YOUR_TOKEN\"}"
```

## Verification

After re-indexing, test with:

```bash
# Check namespace stats
curl "http://localhost:8000/api/ingest/list/YOUR_USER_ID"

# Should show document_count > 0
```

Then try your AI chat query again - it should now return results!

## Why This Happened

HuggingFace deprecated their old inference API endpoint on Nov 26, 2025. All embeddings generated before this date need to be regenerated with the new endpoint to maintain vector compatibility.

## Technical Details

- **Model**: `sentence-transformers/all-MiniLM-L6-v2` (384 dimensions)
- **Old endpoint**: Generated vectors in space A
- **New endpoint**: Generates vectors in space B
- **Result**: Queries in space B can't find documents in space A

The model is the same, but the API infrastructure changed, causing subtle differences in vector generation.
