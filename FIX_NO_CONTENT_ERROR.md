# Fix "No content found in selected files" Error

## The Error You're Seeing
```
Failed to generate quiz: No content found in selected files
```

## What This Means
✅ Backend is working
✅ API call is successful
✅ Files are in workspace
❌ **Files are NOT indexed in Pinecone** (no embeddings)

## The Problem
When you add files to a workspace, they link to Drive files by ID. But for AI tools to work, those files must be:
1. Uploaded to the main app
2. **Indexed** (processed and stored in Pinecone vector database)

## Solution: Index Your Files

### Step 1: Go to Main Files Screen
```
App → Files Tab (bottom navigation)
```

### Step 2: Upload Files
If you haven't already:
1. Tap the upload button
2. Select PDF files
3. Wait for upload to complete

### Step 3: Index Files (CRITICAL)
1. Find your uploaded files
2. Look for indexing status
3. If not indexed, tap the file
4. Look for "Index" or "Start Indexing" button
5. Tap it and wait

**Wait for indexing to complete** - this can take 1-5 minutes per file

### Step 4: Verify Indexing
Look for:
- ✅ Green "Indexed" badge on file
- ✅ Or "Indexing complete" message

### Step 5: Add Indexed Files to Workspace
1. Go back to Notebook Studio
2. Open your workspace
3. Go to Files tab
4. Tap "Add from Drive"
5. Select the **indexed** files
6. Add them to workspace

### Step 6: Try Generation Again
1. Go to AI Studio tab
2. Long press any tool
3. Should work now! 🎉

## How to Check if Files Are Indexed

### Method 1: Main App Files Screen
```
Files Tab → Look for files → Check for "Indexed" badge
```

### Method 2: Indexing Service
```
Files Tab → Tap file → Check status
```

### Method 3: Backend Logs
When you try to generate, backend logs will show:
```
# If indexed:
INFO: Retrieved 5 relevant chunks

# If NOT indexed:
ERROR: No content found in selected files
```

## Why This Happens

### The Flow:
1. **Upload file** → Stored in Google Drive
2. **Index file** → Content extracted, chunked, embedded, stored in Pinecone
3. **Add to workspace** → Links workspace to Drive file
4. **Generate content** → Queries Pinecone for file content

**If step 2 (indexing) is skipped, step 4 fails!**

## Quick Test

### Test if Chat Works First
Before using AI Studio:
1. Go to Chat tab in workspace
2. Ask: "What are these documents about?"
3. If chat works → Files are indexed ✅
4. If chat fails → Files not indexed ❌

**If chat works, AI Studio will work too!**

## Alternative: Use Already Indexed Files

If you have files that are already indexed:
1. Go to main Files screen
2. Find files with "Indexed" badge
3. Note their names
4. Go to workspace → Files tab
5. Add those specific files
6. Try generation again

## Troubleshooting

### "I don't see an Index button"
- Files might be auto-indexed
- Check for "Indexed" badge
- Wait a few minutes after upload

### "Indexing is taking forever"
- Large files take longer
- Wait up to 5 minutes
- Check backend logs for progress

### "Indexing failed"
- Check backend is running
- Check API keys configured
- Check Pinecone credentials
- Try re-uploading file

### "Still getting 'No content found'"
1. Verify files have "Indexed" badge
2. Try removing and re-adding files to workspace
3. Check backend logs for specific error
4. Try with a different file

## Backend Check

### Verify Pinecone Has Data
Check backend logs when generating:
```bash
# Should see:
INFO: Retrieved X relevant chunks from Pinecone

# If you see:
ERROR: No content found
→ Files not in Pinecone
```

### Test Pinecone Directly
```python
# In backend
from app.services.pinecone_service import get_pinecone_service

service = get_pinecone_service()
# Check if user namespace has vectors
```

## Summary

**The error "No content found in selected files" means:**
- ✅ Everything else is working
- ❌ Files are not indexed in Pinecone

**To fix:**
1. Index files in main app (Files tab)
2. Wait for "Indexed" badge
3. Add indexed files to workspace
4. Try generation again

**Quick verification:**
- If Chat works → Files are indexed
- If Chat fails → Files not indexed

Once files are properly indexed, all AI Studio tools will work! 🚀
