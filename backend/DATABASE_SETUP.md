# Supabase Database Setup Guide

This guide walks through setting up the ScholarMate metadata database with tables, Row Level Security (RLS) policies, and indexes.

## Prerequisites

- Supabase project created (free tier)
- `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` in `backend/.env`

## Step 1: Apply Database Schema

### Using Supabase Dashboard (Recommended)

1. Open your Supabase project dashboard
2. Navigate to **SQL Editor** in the left sidebar
3. Click **New Query**
4. Open `backend/migrations/001_initial_schema.sql`
5. Copy the entire contents
6. Paste into the SQL editor
7. Click **Run** (or press Ctrl+Enter)

You should see a success message. The migration creates:
- 8 tables with proper relationships
- Row Level Security policies on all tables
- Indexes for query performance
- Triggers for automatic timestamp updates

### Using psql (Alternative)

If you have PostgreSQL client tools installed:

```bash
# Get your database connection string from Supabase dashboard
# Settings > Database > Connection string > URI

psql "postgresql://postgres:[YOUR-PASSWORD]@[YOUR-PROJECT-REF].supabase.co:5432/postgres" \
  -f backend/migrations/001_initial_schema.sql
```

## Step 2: Verify Schema

Run this query in the SQL Editor to verify all tables were created:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

Expected tables:
- annotations
- api_keys
- audit_logs
- encrypted_tokens
- files
- ingestion_jobs
- shares
- users

## Step 3: Verify RLS Policies

Check that Row Level Security is enabled:

```sql
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;
```

All tables should have `rowsecurity = true`.

View all policies:

```sql
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

## Step 4: Verify Indexes

Check that indexes were created:

```sql
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

## Step 5: Test Backend Connection

Start the backend server:

```bash
cd backend
uv run python run.py
```

Check the health endpoint:

```bash
curl http://localhost:8000/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "scholarmate-backend"
}
```

## Step 6: Test Database Operations

### Test User Creation

The backend should automatically create users when they authenticate. You can test the database connection with a simple query:

```python
# In Python REPL or test script
from app.services.supabase_service import get_supabase_service

service = get_supabase_service()
# This will verify the connection works
print("✅ Supabase connection successful")
```

### Test Token Storage

Test the encryption and token storage:

```bash
# Run the test script
uv run python backend/test_token_storage.py
```

## Database Schema Overview

### Core Tables

#### users
Stores user account information linked to Google OAuth.

```sql
id              UUID PRIMARY KEY
google_sub      TEXT UNIQUE NOT NULL  -- Google OAuth sub claim
email           TEXT NOT NULL
name            TEXT
picture_url     TEXT
created_at      TIMESTAMPTZ
updated_at      TIMESTAMPTZ
```

#### encrypted_tokens
Stores encrypted OAuth tokens (access, refresh, ID tokens).

```sql
id                UUID PRIMARY KEY
user_id           UUID REFERENCES users
token_type        TEXT NOT NULL  -- 'access_token', 'refresh_token', 'id_token'
encrypted_token   TEXT NOT NULL
created_at        TIMESTAMPTZ
updated_at        TIMESTAMPTZ
```

#### files
File and folder metadata from Google Drive.

```sql
id                    UUID PRIMARY KEY
user_id               UUID REFERENCES users
drive_file_id         TEXT NOT NULL
name                  TEXT NOT NULL
mime_type             TEXT NOT NULL
size_bytes            BIGINT
parent_folder_id      UUID REFERENCES files
is_folder             BOOLEAN
is_trashed            BOOLEAN
drive_modified_time   TIMESTAMPTZ
created_at            TIMESTAMPTZ
updated_at            TIMESTAMPTZ
```

#### annotations
PDF annotations (highlights, underlines, comments).

```sql
id                UUID PRIMARY KEY
user_id           UUID REFERENCES users
file_id           UUID REFERENCES files
annotation_type   TEXT NOT NULL  -- 'highlight', 'underline', 'strikethrough', 'comment'
page_number       INTEGER NOT NULL
position_data     JSONB NOT NULL  -- Coordinates, bounds, etc.
content           TEXT  -- Selected text or comment
color             TEXT  -- Hex color code
created_at        TIMESTAMPTZ
updated_at        TIMESTAMPTZ
```

#### shares
File sharing permissions and public links.

```sql
id                    UUID PRIMARY KEY
file_id               UUID REFERENCES files
owner_id              UUID REFERENCES users
shared_with_user_id   UUID REFERENCES users
share_link            TEXT UNIQUE
permission            TEXT NOT NULL  -- 'viewer', 'editor'
is_public             BOOLEAN
expires_at            TIMESTAMPTZ
created_at            TIMESTAMPTZ
updated_at            TIMESTAMPTZ
```

#### ingestion_jobs
Background jobs for OCR and RAG indexing.

```sql
id                UUID PRIMARY KEY
user_id           UUID REFERENCES users
file_id           UUID REFERENCES files
job_type          TEXT NOT NULL  -- 'ocr', 'rag_indexing'
status            TEXT NOT NULL  -- 'pending', 'processing', 'completed', 'failed'
progress_percent  INTEGER
error_message     TEXT
metadata          JSONB
started_at        TIMESTAMPTZ
completed_at      TIMESTAMPTZ
created_at        TIMESTAMPTZ
updated_at        TIMESTAMPTZ
```

#### api_keys
User-provided AI provider API keys (encrypted).

```sql
id              UUID PRIMARY KEY
user_id         UUID REFERENCES users
provider        TEXT NOT NULL  -- 'openrouter', 'openai', 'anthropic', 'google', 'xai'
encrypted_key   TEXT NOT NULL
is_active       BOOLEAN
created_at      TIMESTAMPTZ
updated_at      TIMESTAMPTZ
```

#### audit_logs
Security audit trail for sensitive operations.

```sql
id              UUID PRIMARY KEY
user_id         UUID REFERENCES users
action          TEXT NOT NULL  -- 'login', 'logout', 'file_access', 'share_created', etc.
resource_type   TEXT  -- 'file', 'annotation', 'share', etc.
resource_id     UUID
ip_address      TEXT
user_agent      TEXT
metadata        JSONB
created_at      TIMESTAMPTZ
```

## Row Level Security (RLS) Policies

All tables have RLS enabled with policies ensuring:

1. **Users can only access their own data**
   - SELECT, INSERT, UPDATE, DELETE policies check `auth.uid() = user_id`

2. **Shared files are accessible based on permissions**
   - Files table has additional SELECT policy for shared files
   - Annotations on shared files are readable by recipients

3. **Service role has full access**
   - Backend operations use service role key
   - All tables have service_all policy for backend operations

4. **Audit logs are write-only for users**
   - Only service role can insert audit logs
   - Users can read their own audit logs

## Performance Indexes

Indexes are created on:

- **Foreign keys**: All `user_id`, `file_id`, etc.
- **Unique constraints**: `google_sub`, `drive_file_id`, `share_link`
- **Composite indexes**: Common query patterns like `(user_id, parent_folder_id)`
- **Filter columns**: `is_trashed`, `is_public`, `status`
- **Timestamp columns**: `created_at` for audit logs

## Security Best Practices

1. **Never use anon key for backend operations** - Always use service role key
2. **Encrypt before storing** - Use EncryptionService for tokens and API keys
3. **Validate user ownership** - RLS policies enforce this, but validate in application too
4. **Log sensitive operations** - Use audit_logs table
5. **Rotate encryption keys** - Plan for key rotation (future enhancement)

## Troubleshooting

### "permission denied for table X"

You're likely using the anon key instead of service role key. Check `backend/.env`:
```bash
SUPABASE_SERVICE_KEY=eyJ...  # Should start with eyJ and be very long
```

### "relation X does not exist"

The migration hasn't been applied. Go back to Step 1.

### "uuid-ossp extension not found"

Enable the extension manually:
1. Go to Supabase Dashboard > Database > Extensions
2. Search for "uuid-ossp"
3. Click Enable

### RLS policies blocking backend operations

Make sure you're using the service role key in backend operations. The service role bypasses RLS.

## Next Steps

After database setup is complete:

1. ✅ Test backend health endpoint
2. ✅ Test user creation via auth endpoints
3. ✅ Test token storage and retrieval
4. ⏭️ Implement file metadata sync
5. ⏭️ Implement annotation storage
6. ⏭️ Implement sharing functionality

## Additional Resources

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Indexes](https://www.postgresql.org/docs/current/indexes.html)
- [Supabase SQL Editor](https://supabase.com/docs/guides/database/overview)
