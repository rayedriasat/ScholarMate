# Task 12.6: Automatic Indexing on Upload - Testing Guide

## Quick Test Steps

### Prerequisites
1. Backend server running (`uv run python run.py` in backend/)
2. Frontend app running (`flutter run` in frontend/)
3. User logged in with Google account
4. GROQ API key configured in backend/.env

### Test 1: Basic PDF Upload with Auto-Indexing
1. Navigate to file explorer screen
2. Click the upload button (FAB menu)
3. Select a PDF file from your device
4. **Expected Results**:
   - Upload progress shows 0-100%
   - Upload completes successfully
   - Blue notification appears: "Indexing started for [filename]"
   - File appears in the file list
   - Indexing badge shows "⟳" (indexing in progress)
   - Indexing progress panel shows the new job

### Test 2: Multiple PDF Uploads
1. Upload 2-3 PDF files simultaneously
2. **Expected Results**:
   - Each file uploads successfully
   - Separate indexing notification for each PDF
   - All files show indexing status
   - Progress panel shows all jobs

### Test 3: Non-PDF Upload (No Indexing)
1. Upload a Markdown (.md) or text (.txt) file
2. **Expected Results**:
   - File uploads successfully
   - NO indexing notification appears
   - File does not show indexing badge

### Test 4: Indexing Progress Tracking
1. Upload a large PDF file (5+ MB)
2. Open the indexing progress panel
3. **Expected Results**:
   - Job status changes: pending → processing → completed
   - Progress percentage updates (0% → 100%)
   - Badge changes: ⟳ (indexing) → ✓ (indexed)
   - Completion time is recorded

### Test 5: Error Handling - Backend Offline
1. Stop the backend server
2. Try to upload a PDF file
3. **Expected Results**:
   - File uploads to Google Drive successfully
   - Orange notification: "Failed to start indexing: [error]"
   - File appears in list without indexing badge
   - User can manually trigger indexing later

### Test 6: Error Handling - Not Authenticated
1. Sign out of the app
2. Try to upload a file (if possible)
3. **Expected Results**:
   - Upload should fail or require authentication
   - No indexing attempt is made

### Test 7: Manual Reindex After Auto-Index
1. Upload a PDF (auto-indexing triggers)
2. Wait for indexing to complete
3. Right-click file → "Reindex"
4. **Expected Results**:
   - New indexing job starts
   - Progress panel shows new job
   - Old embeddings are replaced

### Test 8: View Indexed File in Chat
1. Upload and index a PDF
2. Wait for indexing to complete (✓ badge)
3. Navigate to AI chat (when implemented in Phase 11)
4. Select the file as a source
5. Ask a question about the content
6. **Expected Results**:
   - AI can answer questions from the indexed PDF
   - Citations reference the correct pages

## Verification Checklist

- [ ] PDF files trigger automatic indexing
- [ ] Non-PDF files do NOT trigger indexing
- [ ] Indexing notification appears on success
- [ ] Error notification appears on failure
- [ ] Indexing progress is tracked and displayed
- [ ] Multiple uploads work correctly
- [ ] Backend fetches files from Google Drive
- [ ] User isolation is maintained (per-user collections)
- [ ] Manual reindexing still works
- [ ] App remains responsive during indexing

## Backend Verification

### Check Indexing Job in Database
```sql
-- Connect to Supabase and run:
SELECT job_id, user_id, file_id, status, progress_percentage, created_at
FROM ingestion_jobs
ORDER BY created_at DESC
LIMIT 10;
```

### Check ChromaDB Collection
```python
# In backend, run:
from app.services.chroma_service import ChromaService

chroma = ChromaService()
user_id = "your-user-id"
collection = chroma.get_user_collection(user_id)
print(f"Document count: {collection.count()}")
```

### Check Backend Logs
```bash
# Look for these log messages:
# - "Starting indexing job for file_id: ..."
# - "Fetching file from Google Drive: ..."
# - "Extracted X chunks from PDF"
# - "Generated embeddings for X chunks"
# - "Stored embeddings in collection: user_X_documents"
# - "Indexing job completed: job_id"
```

## Common Issues and Solutions

### Issue: No indexing notification appears
**Solution**: Check that IndexingService is provided in the widget tree

### Issue: Indexing fails immediately
**Solution**: 
- Verify backend is running
- Check GROQ API key is configured
- Verify user has valid Google Drive tokens

### Issue: Progress never updates
**Solution**: 
- Check backend logs for errors
- Verify ChromaDB is running
- Check network connectivity

### Issue: File not found error
**Solution**: 
- Verify file was uploaded to Google Drive successfully
- Check user has valid refresh token
- Verify file_id is correct

## Performance Notes

- Small PDFs (< 1 MB): ~5-10 seconds to index
- Medium PDFs (1-5 MB): ~15-30 seconds to index
- Large PDFs (5+ MB): ~30-60 seconds to index
- Indexing happens asynchronously (non-blocking)
- Multiple files can be indexed simultaneously

## Next Phase Testing

Once Phase 11 (AI Chat) is implemented, test:
- Asking questions about auto-indexed documents
- Verifying citations are accurate
- Testing source selection with auto-indexed files
- Verifying clickable citations open correct pages
