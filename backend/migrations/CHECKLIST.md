# Database Setup Checklist

Use this checklist to track your database setup progress.

## Pre-Migration

- [ ] Supabase project created (free tier)
- [ ] `backend/.env` file exists with credentials
- [ ] `SUPABASE_URL` set in `.env`
- [ ] `SUPABASE_SERVICE_KEY` set in `.env` (not anon key!)
- [ ] `ENCRYPTION_KEY` set in `.env`

## Apply Migration

- [ ] Opened Supabase Dashboard
- [ ] Navigated to SQL Editor
- [ ] Copied `001_initial_schema.sql` contents
- [ ] Pasted into SQL Editor
- [ ] Clicked Run
- [ ] Saw success message

## Verify Schema

- [ ] Ran table verification query
- [ ] Confirmed 8 tables exist:
  - [ ] users
  - [ ] encrypted_tokens
  - [ ] files
  - [ ] annotations
  - [ ] shares
  - [ ] ingestion_jobs
  - [ ] api_keys
  - [ ] audit_logs

## Verify RLS

- [ ] Ran RLS verification query
- [ ] Confirmed all tables have `rowsecurity = true`
- [ ] Checked policies exist for each table

## Verify Indexes

- [ ] Ran index verification query
- [ ] Confirmed multiple indexes per table
- [ ] Verified foreign key indexes exist

## Test Backend

- [ ] Started backend: `uv run python run.py`
- [ ] Health check passes: `curl http://localhost:8000/api/health`
- [ ] Saw "healthy" response

## Run Test Suite

- [ ] Ran: `uv run python backend/test_token_storage.py`
- [ ] Test 1: Database Connection - PASS
- [ ] Test 2: Encryption Service - PASS
- [ ] Test 3: User Creation - PASS
- [ ] Test 4: Token Storage - PASS
- [ ] Test 5: Cleanup - PASS
- [ ] Saw "🎉 All tests passed!"

## Documentation Review

- [ ] Read `DATABASE_SETUP.md` for detailed info
- [ ] Reviewed table schemas
- [ ] Understood RLS policies
- [ ] Noted security best practices

## Ready for Next Phase

- [ ] All tests passing
- [ ] Database schema complete
- [ ] RLS policies enforced
- [ ] Token storage working
- [ ] Ready to implement annotation sync (Phase 7)

---

## Quick Commands

### Start Backend
```bash
cd backend
uv run python run.py
```

### Test Health
```bash
curl http://localhost:8000/api/health
```

### Run Tests
```bash
uv run python backend/test_token_storage.py
```

### View API Docs
Open browser: http://localhost:8000/docs

---

## Troubleshooting

If any checkbox fails, see:
- `DATABASE_SETUP.md` - Comprehensive troubleshooting
- `README.md` - Migration instructions
- `APPLY_MIGRATION.md` - Quick start guide

## Support

Common issues:
1. **Permission denied** - Enable uuid-ossp extension in Supabase
2. **Connection failed** - Check SUPABASE_SERVICE_KEY (not anon key)
3. **Import errors** - Run `uv sync` to install dependencies
4. **Test failures** - Verify migration was applied successfully
