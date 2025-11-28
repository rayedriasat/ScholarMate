# Subscription System Migration Guide

This guide explains how to apply the subscription system database migration.

## What This Migration Does

The `006_subscription_system.sql` migration:

1. **Extends the `users` table** with subscription fields:
   - `subscription_status` (VARCHAR): 'free' or 'premium' (default: 'free')
   - `subscription_activated_at` (TIMESTAMP): When premium was activated
   - `subscription_expires_at` (TIMESTAMP): When premium expires

2. **Creates the `transactions` table** for payment history:
   - `id` (UUID): Primary key
   - `transaction_id` (VARCHAR): Unique transaction identifier from payment gateway
   - `user_id` (UUID): Reference to users table
   - `payment_method` (VARCHAR): 'bkash', 'debit_card', or 'credit_card'
   - `amount` (DECIMAL): Payment amount
   - `currency` (VARCHAR): Currency code (default: 'BDT')
   - `status` (VARCHAR): 'pending', 'success', or 'failed'
   - `metadata` (JSONB): Additional payment details
   - `created_at` (TIMESTAMP): When transaction was initiated
   - `verified_at` (TIMESTAMP): When transaction was verified

3. **Creates indexes** for performance:
   - User subscription status and expiry
   - Transaction lookups by user, transaction ID, status, and date

4. **Enables Row Level Security** on transactions table (policies commented out for development)

## How to Apply the Migration

### Option 1: Supabase Dashboard (Recommended)

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Open the file `backend/supabase_migrations/006_subscription_system.sql`
4. Copy the entire contents
5. Paste into the SQL Editor
6. Click **Run**
7. Verify success message: "Migration 006_subscription_system completed successfully"

### Option 2: PostgreSQL CLI

If you have `psql` installed:

```bash
# Get your database connection string from Supabase dashboard
# Settings > Database > Connection string (URI)

psql "postgresql://postgres:[YOUR-PASSWORD]@[YOUR-PROJECT-REF].supabase.co:5432/postgres" \
  -f backend/supabase_migrations/006_subscription_system.sql
```

### Option 3: Python Script (Requires psycopg2)

```bash
# Install psycopg2 if not already installed
uv add psycopg2-binary

# Set DATABASE_URL in backend/.env
# Format: postgresql://postgres:[PASSWORD]@[PROJECT-REF].supabase.co:5432/postgres

# Run the migration script
uv run python backend/apply_subscription_migration.py
```

## Verification

After applying the migration, verify it worked:

```sql
-- Check users table has new columns
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND column_name IN ('subscription_status', 'subscription_activated_at', 'subscription_expires_at');

-- Check transactions table exists
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'transactions'
ORDER BY ordinal_position;

-- Check indexes were created
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename IN ('users', 'transactions')
  AND indexname LIKE '%subscription%' OR indexname LIKE '%transaction%';
```

## Rollback (If Needed)

If you need to rollback this migration:

```sql
-- Remove subscription fields from users table
ALTER TABLE users DROP COLUMN IF EXISTS subscription_status;
ALTER TABLE users DROP COLUMN IF EXISTS subscription_activated_at;
ALTER TABLE users DROP COLUMN IF EXISTS subscription_expires_at;

-- Drop transactions table
DROP TABLE IF EXISTS transactions CASCADE;

-- Drop indexes
DROP INDEX IF EXISTS idx_users_subscription_status;
DROP INDEX IF EXISTS idx_users_subscription_expires;
```

## Next Steps

After applying the migration:

1. ✅ Database schema is ready
2. ⏭️ Implement backend payment gateway abstraction layer (Task 2)
3. ⏭️ Implement backend subscription service (Task 3)
4. ⏭️ Create payment API endpoints (Task 4)

## Troubleshooting

### Error: "relation 'users' does not exist"

The users table should already exist from migration `001_complete_schema_clean.sql`. If not, apply that migration first.

### Error: "constraint already exists"

This is safe to ignore. The migration uses `IF NOT EXISTS` clauses to be idempotent.

### Error: "permission denied"

Make sure you're using the `SUPABASE_SERVICE_KEY` (not the anon key) which has admin privileges.

## Migration File Location

```
backend/supabase_migrations/006_subscription_system.sql
```

## Related Requirements

This migration satisfies requirements:
- **5.1**: Subscription status management
- **5.2**: Subscription persistence
- **6.3**: Transaction recording
- **8.4**: Transaction storage with all required fields
