# Database Migrations

This directory contains SQL migration files for setting up the ScholarMate database schema.

## Running Migrations

### Option 1: Using Supabase Dashboard (Recommended)

1. Go to your Supabase project dashboard: https://supabase.com/dashboard
2. Navigate to the **SQL Editor** section
3. Click **New Query**
4. Copy and paste the contents of `001_create_users_and_tokens_tables.sql`
5. Click **Run** to execute the migration

### Option 2: Using Supabase CLI

If you have the Supabase CLI installed:

```bash
# Link to your project (first time only)
supabase link --project-ref your-project-ref

# Run the migration
supabase db push
```

### Option 3: Using psql

If you have direct database access:

```bash
psql "postgresql://postgres:[YOUR-PASSWORD]@[YOUR-HOST]:5432/postgres" -f 001_create_users_and_tokens_tables.sql
```

## Migration Files

- `001_create_users_and_tokens_tables.sql` - Creates the initial schema:
  - `users` table - Stores user information from Google OAuth
  - `encrypted_tokens` table - Stores encrypted OAuth tokens
  - Indexes for performance
  - Row Level Security (RLS) policies
  - Triggers for automatic timestamp updates

## Verifying Migration

After running the migration, you can verify it worked by running this query in the SQL Editor:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'encrypted_tokens');
```

You should see both tables listed.
