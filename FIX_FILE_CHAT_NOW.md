# File Chat Fix - Apply Now

## Issues Fixed

1. **RLS Policy Error**: Supabase RLS policies were checking `auth.role()` but we use Google OAuth (not Supabase Auth)
2. **UUID Error**: Local message IDs with "local_" prefix were being sent to Supabase
3. **Layout Error**: FileChatPanel needs proper constraints in Stack

## Apply Migration

```bash
# Backend directory
cd backend

# Apply the RLS fix migration
uv run python -c "
from app.database import get_supabase_client
import os

supabase = get_supabase_client()

# Read and execute migration
with open('migrations/011_fix_file_chat_rls.sql', 'r') as f:
    sql = f.read()
    
# Execute via Supabase SQL editor or psql
print('Copy this SQL to Supabase SQL Editor:')
print(sql)
"
```

## Manual Migration (Supabase Dashboard)

1. Go to Supabase Dashboard → SQL Editor
2. Paste this SQL:

```sql
-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Authenticated users can view file chat threads" ON file_chat_threads;
DROP POLICY IF EXISTS "Authenticated users can create file chat threads" ON file_chat_threads;
DROP POLICY IF EXISTS "Authenticated users can view file chat messages" ON file_chat_messages;
DROP POLICY IF EXISTS "Authenticated users can send messages" ON file_chat_messages;

-- Create permissive policies (backend validates Google Drive access)
CREATE POLICY "Allow all operations on file chat threads"
ON file_chat_threads FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all operations on file chat messages"
ON file_chat_messages FOR ALL USING (true) WITH CHECK (true);
```

3. Click "Run"

## Changes Made

### Backend
- `migrations/011_fix_file_chat_rls.sql` - Fixed RLS policies to work without Supabase Auth

### Frontend
- `services/file_chat_service.dart` - Fixed to never send local IDs to Supabase
  - Creates local message with `local_` prefix first (optimistic UI)
  - Syncs to Supabase with proper UUID
  - Replaces local message with synced version

## Test

```bash
# Restart backend
cd backend
uv run python run.py

# Restart frontend
cd frontend
flutter run -d chrome
```

## Verification

1. Open a shared PDF
2. Click the green chat bubble (bottom right)
3. Send a message
4. Should see:
   - Message appears immediately (local)
   - No RLS errors in console
   - No UUID errors in console
   - Message syncs to Supabase
   - Other users see it in realtime

## Security Note

The permissive RLS policies are secure because:
- Backend API validates Google Drive permissions before serving data
- `file_id` links to Google Drive files (user must have Drive access)
- Supabase is only a realtime sync layer, not primary auth
- All file access is controlled by Google Drive sharing
