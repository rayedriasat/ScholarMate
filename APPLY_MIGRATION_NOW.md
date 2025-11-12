# 🚀 Apply Migration Now - 30 Second Guide

## Quick Steps to Complete Setup

### 1. Open Supabase Dashboard (10 seconds)
```
1. Go to: https://supabase.com/dashboard
2. Click on your ScholarMate project
3. Click "SQL Editor" in left sidebar
4. Click "New Query" button
```

### 2. Copy SQL (5 seconds)
```
Open file: backend/migration_to_apply.sql
Select all (Ctrl+A)
Copy (Ctrl+C)
```

### 3. Paste and Run (10 seconds)
```
Paste into SQL Editor (Ctrl+V)
Click "Run" button (or press Ctrl+Enter)
Wait for "Success" message
```

### 4. Verify (5 seconds)
```
Click "Table Editor" in left sidebar
Confirm you see:
  ✅ user_api_keys
  ✅ api_usage_logs
```

## Done! 🎉

Now test it:

```bash
# Start backend
cd backend
uv run python run.py

# Test in another terminal
curl http://localhost:8000/api/keys/providers
```

You should see:
```json
{
  "providers": [
    {"name": "groq", "display_name": "GROQ", ...},
    {"name": "openai", "display_name": "OpenAI", ...},
    {"name": "anthropic", "display_name": "Anthropic (Claude)", ...}
  ]
}
```

## What You Just Created

✅ **user_api_keys** table - Stores encrypted API keys  
✅ **api_usage_logs** table - Tracks all API usage  
✅ **Helper functions** - For queries and statistics

## Next: Use the API

```bash
# Validate a key
curl -X POST http://localhost:8000/api/keys/validate \
  -H "Content-Type: application/json" \
  -d '{"provider": "groq", "api_key": "gsk-YOUR-KEY"}'

# Save a key
curl -X POST http://localhost:8000/api/keys/USER_UUID \
  -H "Content-Type: application/json" \
  -d '{"provider": "groq", "api_key": "gsk-YOUR-KEY", "priority": 10}'

# Use RAG with provider
curl -X POST http://localhost:8000/api/ai/chat-rag \
  -H "Content-Type: application/json" \
  -d '{"question": "What is AI?", "user_id": "USER_UUID", "preferred_provider": "groq"}'
```

## Documentation

- **Full Guide**: `backend/MULTI_PROVIDER_API_KEYS.md`
- **Quick Start**: `backend/API_KEY_MANAGEMENT_QUICK_START.md`
- **API Docs**: http://localhost:8000/docs

---

**That's it!** You now have a production-ready multi-provider API key management system! 🚀
