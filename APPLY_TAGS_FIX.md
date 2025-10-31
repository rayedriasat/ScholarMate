# Quick Fix Application Guide

## Run This Migration on Supabase

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy and paste the content from `backend/supabase_migrations/005_fix_tags_user_id.sql`
4. Click **Run**

## Restart Backend

```bash
# Stop the current backend (Ctrl+C)
cd backend
uv run python run.py
```

## Test

1. Open the Android app
2. Create a tag
3. Assign it to a file
4. Check backend logs - should see success messages
5. Check Supabase database - tags should appear

## Expected Results

### Before Fix
```
❌ 422 Validation error: UUID parsing failed
❌ Tags only stored locally
❌ No cross-device sync
```

### After Fix
```
✅ 200 Success responses
✅ Tags stored in Supabase
✅ Cross-device sync working
✅ Backend logs show "Created tag..." messages
```

## Verify in Supabase

```sql
-- Check if migration worked
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'tags' AND column_name = 'user_id';
-- Should return: user_id | character varying

-- View your tags
SELECT * FROM tags;

-- View file-tag associations
SELECT * FROM file_tags;
```

## Troubleshooting

**Still getting 422 errors?**
- Make sure you ran the migration
- Restart the backend
- Check backend logs for specific errors

**Tags not appearing in Supabase?**
- Check if user is authenticated (user_id should be visible in logs)
- Verify backend can connect to Supabase (check .env file)
- Look for error messages in backend logs

**RLS policy errors?**
- The migration sets permissive policies
- If you see RLS errors, check if the policies were created correctly
