# AI Studio "No Content Found" Debugging Guide

## The Issue

AI Studio tools (Quiz, Summary, Flashcards) fail with:
```
No content found in selected files
```

But the Chat tab works fine with the same files.

## Root Cause Analysis

Since Chat works, we know:
- ✅ Files ARE indexed in Pinecone
- ✅ User authentication is working
- ✅ Backend RAG service is functional

The issue is likely one of these:

### 1. File ID Mismatch
The notebook workspace might be storing different file IDs than what's indexed in Pinecone.

### 2. Empty File IDs
The files in the workspace might not have `driveFileId` set properly.

### 3. Backend Filtering Issue
The RAG service might be filtering out results incorrectly.

## Debugging Steps

### Step 1: Check Frontend Logs

I've added detailed logging. Run the app and try generating content. Look for these logs:

```
🔵 Found X files in workspace
   📄 File: filename.pdf, DriveID: 1abc123...
🔵 File IDs with Drive links: X
🔵 Actual file IDs being sent: [1abc123..., 1def456...]
🔵 Calling API for quiz generation with X file IDs...
```

**What to check:**
- Are there any files with `DriveID: null`?
- Do the file IDs look correct (long alphanumeric strings)?
- How many file IDs are being sent?

### Step 2: Check Backend Logs

Look for these logs in your backend console:

```
🔍 Retrieving context with file_ids: ['1abc123...']
🔍 Retrieved X chunks
```

**What to check:**
- Are the file IDs the same as what the frontend sent?
- How many chunks were retrieved? (0 means no match)

### Step 3: Compare with Chat

When you use the Chat tab successfully, check the logs to see what file IDs it sends. They should be identical to what AI Studio sends.

### Step 4: Verify Pinecone Indexing

Run this test script to verify files are indexed:

```bash
# Edit the file first with your actual values
uv run python backend/test_notebook_ai_debug.py
```

## Common Issues & Solutions

### Issue 1: Files Not Linked to Drive

**Symptom:** `DriveID: null` in logs

**Solution:** 
1. Go to Files tab in Notebook Studio
2. Click "Add from Drive"
3. Select files that are already indexed in the main app
4. These files should have Drive IDs

### Issue 2: Wrong File IDs

**Symptom:** File IDs don't match between Chat and AI Studio

**Solution:**
1. Delete files from workspace
2. Re-add them using "Add from Drive"
3. Make sure you're selecting the same files that work in Chat

### Issue 3: Files Not Indexed in Pinecone

**Symptom:** Backend logs show `Retrieved 0 chunks`

**Solution:**
1. Go to main app File Explorer
2. Find the files you want to use
3. Make sure they show "Indexed" status
4. If not indexed, wait for indexing to complete
5. Then add them to your notebook workspace

### Issue 4: User ID Mismatch

**Symptom:** Chat works but AI Studio doesn't, even with same file IDs

**Solution:**
1. Check if you're logged in with the same account
2. Sign out and sign back in
3. Try again

## Quick Test

To quickly test if the issue is with file IDs:

1. **In Chat tab:** Send a message and note which files it uses
2. **In Files tab:** Check if those same files are listed
3. **In AI Studio:** Try generating content
4. **Compare logs:** File IDs should be identical

## Manual Verification

If you want to manually verify file IDs in Pinecone:

```python
# In backend console or test script
from app.services.pinecone_service import get_pinecone_service

pinecone = get_pinecone_service()
# Query with your user_id to see what files are indexed
results = pinecone.query_documents(
    user_id="YOUR_USER_ID",
    query_embeddings=[[0.1] * 384],  # Dummy embedding
    n_results=10,
    filter=None
)
print("Indexed files:", set(r['file_id'] for r in results))
```

## Next Steps

After running through these debugging steps, you should see one of these outcomes:

1. **File IDs are null** → Add files from Drive properly
2. **File IDs don't match** → Re-add files to workspace
3. **Files not indexed** → Index files in main app first
4. **Everything looks correct** → There's a deeper issue, share logs

## Share Debug Info

If still not working, share these logs:

```
Frontend logs:
- 🔵 Found X files in workspace
- 🔵 Actual file IDs being sent: [...]

Backend logs:
- 🔍 Retrieving context with file_ids: [...]
- 🔍 Retrieved X chunks

Error message:
- Full error text from the dialog
```
