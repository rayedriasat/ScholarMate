# Run Collaboration Database Migration

## Quick Steps

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard
   - Select your project: `rqyzgfgdsedvohxyyqho`

2. **Open SQL Editor**
   - Click "SQL Editor" in left sidebar
   - Click "New Query"

3. **Copy & Paste Migration**
   - Copy the entire contents of `backend/migrations/004_collaboration_tables.sql`
   - Paste into the SQL editor

4. **Run Migration**
   - Click "Run" button (or press Ctrl+Enter)
   - Wait for success message

5. **Verify Tables Created**
   - Go to "Table Editor" in left sidebar
   - You should see:
     - `collaboration_sessions`
     - `session_participants`

## What This Creates

- **2 tables**: Sessions and participants
- **5 indexes**: For fast queries
- **8 RLS policies**: For security
- **1 function**: Cleanup expired sessions
- **Realtime enabled**: For live updates

## Troubleshooting

**"relation already exists"**
→ Tables already created, you're good!

**"permission denied"**
→ Make sure you're using the service role key

**"syntax error"**
→ Copy the entire file, don't modify it

## After Migration

You can now start the backend and frontend:

```bash
# Terminal 1: Backend
cd backend
uv run python run.py

# Terminal 2: Frontend
cd frontend
flutter run -d chrome
```

## Verify It Works

1. Open PDF in app
2. Click purple people icon (🟣)
3. Should see "Collaboration panel"
4. Click share to get link

Done! ✅
