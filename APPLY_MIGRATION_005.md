# Apply Migration 005 - Fix file_id Type

## Problem
The `collaboration_sessions` table has `file_id` as UUID, but Google Drive file IDs are strings like "1abc123xyz", not UUIDs.

## Solution
Run this SQL in Supabase SQL Editor:

1. Go to: https://rqyzgfgdsedvohxyyqho.supabase.co
2. Click **SQL Editor** in left sidebar
3. Click **New Query**
4. Paste and run:

```sql
-- Fix file_id column type to support Google Drive file IDs
ALTER TABLE collaboration_sessions 
ALTER COLUMN file_id TYPE TEXT;

-- Recreate index
DROP INDEX IF EXISTS idx_sessions_file;
CREATE INDEX idx_sessions_file ON collaboration_sessions(file_id);
```

5. Click **Run** (or press Ctrl+Enter)

## Verify
After running, you should see:
- ✓ Success message
- No errors

Then restart your backend and try the collaboration feature again.
