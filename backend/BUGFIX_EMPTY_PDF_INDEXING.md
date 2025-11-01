# Bug Fix: Empty PDF Indexing Failure

## Issue
When indexing PDFs with no extractable text (empty PDFs or image-only PDFs), the indexer crashes with:
```
ERROR: Failed to store embeddings: Non-empty lists are required for ['ids', 'metadatas', 'documents'] in add.
```

## Root Cause
The RAG indexer was attempting to store empty document lists in ChromaDB, which rejects empty lists.

### Example from Logs
```
"Extracted 1 pages from 323_1.pdf"
"Created 0 chunks from 323_1.pdf"
"Generating embeddings for 0 chunks"
"Failed to store embeddings: Non-empty lists are required..."
```

## Solution
Added two safety checks:

### 1. Early Return for Empty Documents
In `process_indexing_job()`:
```python
# Handle empty documents (PDF with no extractable text)
if len(documents) == 0:
    logger.warning(f"No chunks created from {file_name} - PDF may be empty or contain only images")
    await self._update_job_status(
        job_id,
        "completed",
        error_message="No text content extracted from PDF. The file may be empty or contain only images."
    )
    logger.info(f"Indexing job {job_id} completed with no content")
    return
```

### 2. Safety Check in store_embeddings()
```python
# Safety check: don't try to store empty documents
if not documents or len(documents) == 0:
    logger.warning(f"Attempted to store 0 documents for file {file_id} - skipping")
    return
```

## Behavior After Fix

### Empty PDFs
- ✅ Job completes with status "completed"
- ✅ Error message explains: "No text content extracted from PDF"
- ✅ No crash or retry loop
- ✅ User sees clear feedback in UI

### Valid PDFs
- ✅ Normal indexing continues as before
- ✅ Chunks created and stored successfully

## Testing

### Test Empty PDF
```bash
cd backend
uv run python -c "
from app.services.rag_indexer import get_rag_indexer
import asyncio

async def test():
    indexer = get_rag_indexer()
    job_id = await indexer.index_file(
        file_id='EMPTY_PDF_FILE_ID',
        user_id='test_user',
        file_name='empty.pdf'
    )
    await indexer.process_indexing_job(job_id)
    print(f'Job {job_id} completed')

asyncio.run(test())
"
```

### Expected Result
- Job completes without errors
- Status: "completed"
- Error message: "No text content extracted from PDF..."

## Files Changed
- `backend/app/services/rag_indexer.py`
  - Added empty document check in `process_indexing_job()`
  - Added safety check in `store_embeddings()`

## Related Issues
- Fixes retry loop for image-only PDFs
- Prevents ChromaDB errors on empty document lists
- Provides clear user feedback for non-indexable PDFs

## Future Improvements
Consider:
1. **OCR fallback** for image-only PDFs
2. **Pre-validation** before starting indexing job
3. **Better error messages** in UI for different failure types
4. **Partial success** handling (some pages fail, others succeed)
