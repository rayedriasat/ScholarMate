# Quick Start: Apply Database Migration

## Step 1: Open Supabase Dashboard

1. Go to https://supabase.com/dashboard
2. Select your ScholarMate project
3. Click **SQL Editor** in the left sidebar

## Step 2: Run the Migration

1. Click **New Query** button
2. Open `backend/migrations/001_initial_schema.sql` in your code editor
3. Copy the entire file contents (Ctrl+A, Ctrl+C)
4. Paste into the Supabase SQL Editor
5. Click **Run** button (or press Ctrl+Enter)

## Step 3: Verify Success

You should see a success message. Run this query to verify:

```sql
SELECT table_name FROM information_schema.tables 
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

## Step 4: Test Backend Connection

```bash
cd backend
uv run python test_token_storage.py
```

Expected output:
```
✅ Successfully connected to Supabase
✅ Encrypted test string
✅ Decryption successful
✅ User created/retrieved
✅ Token stored in database
✅ Token retrieved from database
✅ Token decryption successful
🎉 All tests passed!
```

## Troubleshooting

### "permission denied for extension uuid-ossp"

1. Go to **Database** > **Extensions** in Supabase dashboard
2. Search for "uuid-ossp"
3. Click **Enable**
4. Re-run the migration

### "relation already exists"

The migration has already been applied. You can skip this step.

### Backend connection fails

Check your `backend/.env` file has:
```
SUPABASE_URL=https://[your-project].supabase.co
SUPABASE_SERVICE_KEY=eyJ...  # Long JWT token
```

## Next Steps

Once migration is applied and tests pass:

1. ✅ Database schema is ready
2. ✅ RLS policies are enforced
3. ✅ Token storage is working
4. ⏭️ Ready to implement annotation sync (Phase 7)

---

For detailed documentation, see `DATABASE_SETUP.md`
