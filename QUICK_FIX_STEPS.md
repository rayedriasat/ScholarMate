# Tags Sync Fix - Quick Steps

## 🚀 3 Steps to Fix

### Step 1: Run Migration on Supabase
```sql
-- Copy content from: backend/supabase_migrations/005_fix_tags_user_id.sql
-- Paste in Supabase SQL Editor
-- Click Run
```

### Step 2: Restart Backend
```bash
cd backend
uv run python run.py
```

### Step 3: Clear App & Restart
```bash
adb shell pm clear com.example.frontend
cd frontend
flutter run
```

## ✅ Success Indicators

**Backend Logs:**
```
✅ INFO: Created tag ... for user 111828646872592591995
✅ 200 responses (not 422)
```

**Supabase Database:**
```sql
SELECT * FROM tags;  -- Should show your tags
```

**App:**
```
✅ Tags appear locally
✅ No error messages
✅ Tags sync across devices
```

## 📋 What Changed

- Backend now accepts Google user IDs (strings) instead of UUIDs
- Database schema updated to VARCHAR for user_id
- Frontend already fixed (AuthService added)

## 🔍 Troubleshooting

**Still 422 errors?** → Migration didn't run, check Supabase
**No tags in DB?** → Backend not connected, check .env
**App crashes?** → Clear app data again

---

**Full details:** See `TAGS_COMPLETE_FIX_SUMMARY.md`
