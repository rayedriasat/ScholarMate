# Collaboration Annotations Not Saving - DIAGNOSIS & FIX

## Problem
- User B creates highlight → Saves locally ✅
- User A clicks "Refresh" → Shows "Loaded 0 annotations" ❌
- Annotations not persisting to database

## Root Cause
**Migration 006 not run** - The `collaboration_annotations` table doesn't exist in Supabase

## Solution: Run Migration

### Step 1: Open Supabase Dashboard
```
https://supabase.com/dashboard
→ Select project: rqyzgfgdsedvohxyyqho
```

### Step 2: Open SQL Editor
```
Left sidebar → SQL Editor → New Query
```

### Step 3: Copy Migration SQL
Open file: `backend/migrations/006_collaboration_annotations.sql`

Copy the entire contents (should start with):
```sql
-- Collaboration annotations table for real-time annotation syncing

CREATE TABLE IF NOT EXISTS collaboration_annotations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id TEXT NOT NULL REFERENCES collaboration_sessions(session_id) ON DELETE CASCADE,
    ...
```

### Step 4: Paste and Run
```
1. Paste SQL into Supabase SQL Editor
2. Click "Run" button (or Ctrl+Enter)
3. Wait for "Success" message
```

### Step 5: Verify Table Created
```
Left sidebar → Table Editor
→ Should see "collaboration_annotations" table
```

## After Migration

### Test Again:
1. **User B**: Create a highlight
2. **User A**: Click "Refresh to See Latest Annotations"
3. **User A**: Should now see "Loaded 1 annotations from other users"
4. **User A**: Click on annotation in dialog → Jumps to page

## Quick Verification

Check if table exists:
```sql
-- Run in Supabase SQL Editor
SELECT * FROM collaboration_annotations LIMIT 5;
```

If error "relation does not exist" → Migration not run
If returns empty result → Migration run, but no annotations yet

## Backend Logs

Check backend terminal for errors when saving annotations:
```
Look for:
- "Added annotation X to session Y" ✅ (success)
- "Error adding annotation" ❌ (failure)
```

## Common Issues

### Issue 1: "relation does not exist"
**Fix**: Run migration 006

### Issue 2: "foreign key constraint"
**Fix**: Run migration 004 first (creates collaboration_sessions table)

### Issue 3: Annotations save but don't show
**Fix**: Check RLS policies - might be blocking reads

## Migration Order

If starting fresh, run in order:
1. `001_initial_schema.sql` - Base tables
2. `004_collaboration_tables.sql` - Sessions & participants
3. `006_collaboration_annotations.sql` - Annotations

## After Fix

Annotations will:
- ✅ Save to Supabase when created
- ✅ Appear in "Refresh" dialog
- ✅ Persist across sessions
- ✅ Sync via Realtime (notifications)
- ⚠️ Still won't render visually (Syncfusion limitation)

## Summary

**Problem**: Annotations not saving to database
**Cause**: Migration 006 not run
**Fix**: Run migration in Supabase SQL Editor
**Result**: Annotations will persist and show in refresh dialog
