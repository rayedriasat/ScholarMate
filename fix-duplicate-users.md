# Fix: Duplicate User Records in Supabase

## The Problem

Your logs show TWO different UUIDs for the same Google user:
- **Indexing uses:** `98c99792-d53f-4297-aba5-eca7bc0bf567`
- **Querying uses:** `44b5d16b-fd69-4260-843d-df133c450832`

This happens when:
1. Multiple user records exist in Supabase with same `google_sub`
2. The lookup query returns different records at different times
3. Documents and queries end up in different Pinecone namespaces

## Quick Fix: Use Correct UUID Directly

Your documents are in namespace: `user_98c99792_d53f_4297_aba5_eca7bc0bf567`

**Option 1: Test with correct UUID**
```bash
test-correct-namespace.bat
```

**Option 2: Fix in your app**
Update your frontend to pass the UUID `98c99792-d53f-4297-aba5-eca7bc0bf567` instead of Google ID `111828646872592591995`

## Permanent Fix: Clean Up Supabase

You need to:
1. Check your Supabase `users` table
2. Find all records with `google_sub = '111828646872592591995'`
3. Delete duplicates, keep only `98c99792-d53f-4297-aba5-eca7bc0bf567`
4. Add UNIQUE constraint on `google_sub` column

### SQL to check duplicates:
```sql
SELECT id, google_sub, email, created_at 
FROM users 
WHERE google_sub = '111828646872592591995'
ORDER BY created_at;
```

### SQL to delete wrong duplicate:
```sql
DELETE FROM users 
WHERE id = '44b5d16b-fd69-4260-843d-df133c450832';
```

### SQL to prevent future duplicates:
```sql
ALTER TABLE users 
ADD CONSTRAINT users_google_sub_unique 
UNIQUE (google_sub);
```

## Why This Happened

The `_get_or_create_user_uuid()` function creates a new user if not found. If called multiple times before the first insert completes, it can create duplicates (race condition).

## Verification

After fixing, check logs for:
```
[NAMESPACE] Query resolved user_id 111828646872592591995 to UUID 98c99792-d53f-4297-aba5-eca7bc0bf567
[NAMESPACE] Querying Pinecone namespace: user_98c99792_d53f_4297_aba5_eca7bc0bf567
```

Both should use the SAME UUID!
