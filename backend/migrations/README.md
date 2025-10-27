# Database Migrations

This folder contains SQL migration files for the ScholarMate Supabase database.

## Applying Migrations

### Option 1: Supabase Dashboard (Recommended)

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy the contents of `001_initial_schema.sql`
4. Paste into the SQL editor
5. Click **Run** to execute

### Option 2: Using the Migration Script

```bash
uv run python migrations/apply_migration.py 001_initial_schema.sql
```

### Option 3: Using Supabase CLI

If you have the Supabase CLI installed:

```bash
supabase db push
```

## Migration Files

- `001_initial_schema.sql` - Initial database schema with all tables, RLS policies, and indexes

## Schema Overview

### Tables

1. **users** - User accounts linked to Google OAuth
2. **encrypted_tokens** - Encrypted OAuth tokens (access, refresh, ID tokens)
3. **files** - File and folder metadata from Google Drive
4. **annotations** - PDF annotations (highlights, comments, etc.)
5. **shares** - File sharing permissions and public links
6. **ingestion_jobs** - Background jobs for OCR and RAG indexing
7. **api_keys** - User-provided AI provider API keys (encrypted)
8. **audit_logs** - Security audit trail

### Security Features

- **Row Level Security (RLS)** enabled on all tables
- Users can only access their own data
- Service role (backend) has full access for operations
- Shared files accessible based on share permissions
- All sensitive data encrypted before storage

### Indexes

Indexes are created on:
- Foreign keys for join performance
- Frequently queried columns (user_id, file_id, etc.)
- Composite indexes for common query patterns
- Unique constraints where needed

## Verifying Migration

After applying the migration, verify the schema:

```sql
-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Check indexes
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public' 
ORDER BY tablename, indexname;
```

## Troubleshooting

If you encounter errors:

1. **UUID extension error**: The migration enables `uuid-ossp` extension. If you get a permission error, enable it manually in the Supabase dashboard under Database > Extensions.

2. **RLS policy errors**: Make sure you're using the service role key when applying migrations, not the anon key.

3. **Duplicate table errors**: If tables already exist, you may need to drop them first or modify the migration to use `CREATE TABLE IF NOT EXISTS`.
