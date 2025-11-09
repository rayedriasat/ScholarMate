# Reset Indexing Data Guide

## When to Reset

Reset indexing data when you encounter:
- ✗ Stuck jobs showing 0% progress forever
- ✗ Failed indexing jobs that won't retry
- ✗ Corrupted vector data in Pinecone
- ✗ Inconsistent state between Supabase and Pinecone
- ✗ Testing/development cleanup

## What Gets Reset

When you reset a user's indexing data:

1. **Pinecone Namespace** - All vectors deleted
2. **Ingestion Jobs** - All job records deleted
3. **File Timestamps** - `indexed_at` cleared (files marked as not indexed)

**What's NOT affected:**
- ✓ User account data
- ✓ File metadata (name, size, etc.)
- ✓ Google Drive files (source of truth)
- ✓ Annotations, tags, sharing settings

## Reset Methods

### Method 1: Interactive (Easiest)

```bash
cd backend
uv run python quick_reset.py
```

**Features:**
- Interactive menu
- List all users with job status
- Preview before deleting (dry run)
- Confirmation prompt

**Example session:**
```
Options:
1. List all users
2. Reset specific user
3. Exit

Choice (1-3): 1

📋 Users in system:
1. John Doe
   Email: john@example.com
   Google Sub: 111828646872592591995
   UUID: 550e8400-e29b-41d4-a716-446655440000
   Jobs: 5 total (✓2 ⏳1 ⏸0 ✗2)

Choice (1-3): 2
Enter user ID: 111828646872592591995

📋 Preview (dry run):
...

Type 'yes' to confirm: yes
✅ Reset complete!
```

### Method 2: Command Line (Scripting)

```bash
cd backend

# Reset specific user
uv run python reset_indexing.py --user-id <user_id>

# Dry run (preview only)
uv run python reset_indexing.py --user-id <user_id> --dry-run

# Reset ALL users (dangerous!)
uv run python reset_indexing.py --all --confirm
```

**Examples:**

```bash
# Reset by Google sub
uv run python reset_indexing.py --user-id 111828646872592591995

# Reset by UUID
uv run python reset_indexing.py --user-id 550e8400-e29b-41d4-a716-446655440000

# Preview what would be deleted
uv run python reset_indexing.py --user-id 111828646872592591995 --dry-run

# Reset all users (development only!)
uv run python reset_indexing.py --all --confirm
```

## Step-by-Step: Reset Stuck Jobs

### Scenario: User has stuck job at 0%

1. **Identify the user:**
   ```bash
   uv run python quick_reset.py
   # Choose option 1 to list users
   ```

2. **Preview the reset:**
   ```bash
   uv run python reset_indexing.py --user-id <user_id> --dry-run
   ```

3. **Execute the reset:**
   ```bash
   uv run python reset_indexing.py --user-id <user_id>
   ```

4. **Verify in logs:**
   ```
   ✓ Found user: john@example.com
   ✓ Namespace: user_550e8400_e29b_41d4_a716_446655440000
     - Vectors: 150
     - Deleting 150 vectors...
     ✓ Deleted all vectors from namespace
   ✓ Found 3 indexing jobs
     - pending: 1
     - failed: 2
     - Deleting 3 jobs...
     ✓ Deleted all indexing jobs
   ✓ Found 2 indexed files
     - Clearing indexed_at timestamps...
     ✓ Cleared timestamps on 2 files
   
   ✓ Reset complete!
   ```

5. **User can now re-index:**
   - Frontend will show files as "not indexed"
   - User can click "Index" to start fresh

## Troubleshooting

### "User not found"

**Problem:** User ID doesn't exist in database

**Solution:**
- Check the user ID is correct
- Try both Google sub and UUID
- List all users: `uv run python quick_reset.py` → option 1

### "Namespace doesn't exist"

**Problem:** User has no vectors in Pinecone yet

**Solution:** This is OK! The script will skip Pinecone deletion and continue.

### "Failed to delete namespace"

**Problem:** Pinecone API error

**Solution:**
1. Check `PINECONE_API_KEY` in `.env`
2. Check Pinecone dashboard for index status
3. Try again in a few minutes (API rate limit)

### Script hangs or times out

**Problem:** Large namespace with many vectors

**Solution:**
- Wait longer (can take 1-2 minutes for 10k+ vectors)
- Check Pinecone dashboard for deletion progress
- If stuck >5 minutes, restart script

## Production Use

### Before Resetting in Production

1. **Notify the user** - Their indexed data will be deleted
2. **Backup if needed** - Export vectors from Pinecone (optional)
3. **Check job status** - Ensure no active processing jobs
4. **Use dry run first** - Preview what will be deleted

### After Resetting

1. **Verify reset** - Check Pinecone dashboard (vector count = 0)
2. **Test re-indexing** - Upload a small PDF and verify it indexes
3. **Monitor logs** - Watch for errors during re-indexing
4. **Notify user** - Let them know they can re-index

## Automation

### Reset via API (Future Enhancement)

You could add an admin endpoint:

```python
@router.post("/api/admin/reset-user-indexing")
async def reset_user_indexing(user_id: str, admin_key: str):
    """Admin endpoint to reset user indexing data."""
    if admin_key != os.getenv("ADMIN_API_KEY"):
        raise HTTPException(401, "Unauthorized")
    
    # Call reset function
    from reset_indexing import reset_user_indexing
    success = await reset_user_indexing(user_id)
    
    return {"success": success}
```

### Scheduled Cleanup (Future Enhancement)

Clean up old failed jobs automatically:

```python
# Delete failed jobs older than 7 days
DELETE FROM ingestion_jobs 
WHERE status = 'failed' 
AND created_at < NOW() - INTERVAL '7 days';
```

## FAQ

**Q: Will this delete the user's PDF files?**
A: No! Files in Google Drive are never touched. Only indexing metadata is deleted.

**Q: Can the user recover their indexed data?**
A: No, vector data is permanently deleted. They must re-index their PDFs.

**Q: How long does re-indexing take?**
A: Depends on PDF size. ~2-4 minutes per 100 pages with the memory-optimized batch processing.

**Q: Can I reset just one file instead of all files?**
A: Not with these scripts, but you can manually delete from Pinecone:
```python
pinecone_service.delete_documents_by_file(user_id, file_id)
```

**Q: What if I accidentally reset the wrong user?**
A: They'll need to re-index their documents. The process is automatic, just slower.

**Q: Should I reset before deploying the memory fix?**
A: Not necessary, but recommended if you have stuck jobs. The new code will handle future indexing correctly.

## Summary

**Quick Reset (Interactive):**
```bash
uv run python quick_reset.py
```

**Command Line Reset:**
```bash
uv run python reset_indexing.py --user-id <user_id>
```

**Dry Run (Preview):**
```bash
uv run python reset_indexing.py --user-id <user_id> --dry-run
```

**What's Deleted:**
- Pinecone vectors
- Ingestion jobs
- Indexed timestamps

**What's Safe:**
- User data
- File metadata
- Google Drive files

**After Reset:**
User can re-index documents from scratch with the new memory-optimized code!
