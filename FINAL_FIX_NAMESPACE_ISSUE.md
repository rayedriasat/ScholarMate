# FINAL FIX: Namespace Mismatch Issue

## Root Cause Identified

Your RAG returns 0 results because of **namespace mismatch**:

```
Documents indexed in: user_98c99792_d53f_4297_aba5_eca7bc0bf567
Queries looking in:   user_44b5d16b_fd69_4260_843d_df133c450832
```

**Why:** You have duplicate user records in Supabase for Google ID `111828646872592591995`

## Immediate Solution (Choose One)

### Option A: Use Correct UUID in Frontend (Fastest)

Update your frontend to pass UUID instead of Google ID:
```dart
// Instead of:
user_id: googleUser.id  // "111828646872592591995"

// Use:
user_id: "98c99792-d53f-4297-aba5-eca7bc0bf567"
```

### Option B: Clear Wrong Namespace & Re-index

```bash
# 1. Clear the WRONG namespace (where queries are looking)
curl -X DELETE "http://localhost:8000/api/ingest/clear/44b5d16b-fd69-4260-843d-df133c450832"

# 2. Your documents are already in the CORRECT namespace
# Just update frontend to use correct UUID
```

### Option C: Move Documents to Query Namespace

```bash
# 1. Clear the namespace where queries are looking
curl -X DELETE "http://localhost:8000/api/ingest/clear/44b5d16b-fd69-4260-843d-df133c450832"

# 2. Clear the namespace where documents are stored
curl -X DELETE "http://localhost:8000/api/ingest/clear/98c99792-d53f-4297-aba5-eca7bc0bf567"

# 3. Re-upload PDFs (will use whatever UUID the lookup returns)
```

## Permanent Fix: Clean Supabase

1. **Check for duplicates:**
   - Go to Supabase Dashboard → Table Editor → users
   - Filter: `google_sub = '111828646872592591995'`
   - You'll see 2+ records

2. **Delete wrong duplicate:**
   ```sql
   DELETE FROM users WHERE id = '44b5d16b-fd69-4260-843d-df133c450832';
   ```

3. **Add unique constraint:**
   ```sql
   ALTER TABLE users ADD CONSTRAINT users_google_sub_unique UNIQUE (google_sub);
   ```

## Quick Test

After applying fix, try your AI chat query and check logs for:
```
[NAMESPACE] Query resolved user_id ... to UUID 98c99792-d53f-4297-aba5-eca7bc0bf567
[NAMESPACE] Querying Pinecone namespace: user_98c99792_d53f_4297_aba5_eca7bc0bf567
```

If both show the SAME UUID, it will work!

## Why This Happened

The `_get_or_create_user_uuid()` function has a race condition:
1. First call: User not found → Create user A
2. Second call (before A commits): User not found → Create user B
3. Result: Two users with same `google_sub`

## Files Changed

- `backend/app/services/rag_query_service.py` - Added namespace logging
- `backend/app/services/pinecone_service.py` - Added namespace logging
- Backend restarted with better logging

## Recommended Action

**Use Option A** - it's the fastest. Update your frontend to store and use the Supabase UUID instead of Google ID for all RAG operations.
