# Reset Indexing - Quick Reference

## Problem: Stuck Jobs at 0%

Your indexing jobs are stuck because of the previous memory issues. The new memory-optimized code will work, but you need to clean up the old stuck jobs first.

## Solution: Reset Indexing Data

### Quick Start (Easiest)

```bash
cd backend
uv run python quick_reset.py
```

Then:
1. Choose option 1 to list users
2. Choose option 2 to reset a user
3. Enter the user ID (Google sub or UUID)
4. Confirm with "yes"

### What Gets Deleted

✗ **Deleted:**
- All vectors in Pinecone (user's namespace)
- All indexing jobs (pending, processing, failed, completed)
- All `indexed_at` timestamps on files

✓ **Safe (NOT deleted):**
- User account data
- File metadata (name, size, mime_type, etc.)
- Google Drive files (source of truth)
- Annotations, tags, sharing settings

### After Reset

1. User's files will show as "not indexed" in frontend
2. User can click "Index" to start fresh
3. New indexing will use memory-optimized batch processing
4. Should complete successfully without crashes

## Command Line Options

```bash
# Interactive mode (recommended)
uv run python quick_reset.py

# Reset specific user
uv run python reset_indexing.py --user-id <user_id>

# Preview only (dry run)
uv run python reset_indexing.py --user-id <user_id> --dry-run

# Reset ALL users (dangerous!)
uv run python reset_indexing.py --all --confirm
```

## Example Output

```
Resetting indexing data for user: 111828646872592591995
============================================================

1. Resolving user ID...
✓ Found user:
  - UUID: 550e8400-e29b-41d4-a716-446655440000
  - Email: user@example.com
  - Name: John Doe
  - Google Sub: 111828646872592591995

2. Checking Pinecone namespace...
✓ Namespace: user_550e8400_e29b_41d4_a716_446655440000
  - Vectors: 150
  - Deleting 150 vectors...
  ✓ Deleted all vectors from namespace

3. Checking ingestion jobs...
✓ Found 3 indexing jobs
  - pending: 1
  - failed: 2
  - Deleting 3 jobs...
  ✓ Deleted all indexing jobs

4. Checking indexed files...
✓ Found 2 indexed files
  - document1.pdf
  - document2.pdf
  - Clearing indexed_at timestamps...
  ✓ Cleared timestamps on 2 files

============================================================
✓ Reset complete!

User can now re-index their documents from scratch.
```

## When to Reset

Reset when you see:
- Jobs stuck at 0% forever
- Failed jobs that won't retry
- Inconsistent state between Supabase and Pinecone
- After fixing memory issues (like now)

## Files Created

1. **backend/reset_indexing.py** - Main reset script (command line)
2. **backend/quick_reset.py** - Interactive reset script (easiest)
3. **backend/RESET_INDEXING_GUIDE.md** - Detailed documentation

## Next Steps

1. **Reset stuck jobs:**
   ```bash
   cd backend
   uv run python quick_reset.py
   ```

2. **Deploy memory fix to Render:**
   ```bash
   git add .
   git commit -m "Add reset scripts + memory optimization"
   git push origin main
   ```

3. **Test re-indexing:**
   - Upload a PDF (50+ pages recommended)
   - Monitor logs for batch processing
   - Verify completion without crashes

4. **Monitor production:**
   - Check Render logs for memory usage
   - Verify jobs complete successfully
   - Adjust batch sizes if needed

## Support

- **Detailed Guide:** `backend/RESET_INDEXING_GUIDE.md`
- **Memory Optimization:** `MEMORY_OPTIMIZATION.md`
- **Deployment:** `RENDER_SETUP.md`

**Ready to reset and re-deploy! 🚀**
