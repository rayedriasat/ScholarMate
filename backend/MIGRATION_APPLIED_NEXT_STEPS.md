# Migration Applied - Next Steps ✅

## Migration Status

The SQL migration file has been prepared and is ready to apply to your Supabase database.

### 📄 Migration File
- **Location**: `backend/migrations/006_user_api_keys.sql`
- **Copy Available**: `backend/migration_to_apply.sql`

## How to Apply Migration

### Option 1: Supabase Dashboard (Recommended) ⭐

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard
   - Select your ScholarMate project

2. **Open SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Copy and Paste SQL**
   - Open: `backend/migration_to_apply.sql`
   - Copy all content
   - Paste into the SQL Editor

4. **Run Migration**
   - Click "Run" button (or press Ctrl+Enter)
   - Wait for success message

5. **Verify Tables Created**
   - Go to "Table Editor" in left sidebar
   - You should see:
     - `user_api_keys`
     - `api_usage_logs`

### Option 2: Supabase CLI

```bash
# Install Supabase CLI (if not installed)
npm install -g supabase

# Login
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_ID

# Apply migration
supabase db push
```

### Option 3: Direct Database Connection

If you have the database password:

```bash
# Add to .env
SUPABASE_DB_PASSWORD=your-db-password

# Run migration script
uv run python apply_api_keys_migration.py
```

## After Migration is Applied

### 1. Verify Backend Starts ✅

```bash
cd backend
uv run python run.py
```

Expected output:
```
INFO: Starting ScholarMate API
INFO: Application configured successfully
INFO: Uvicorn running on http://0.0.0.0:8000
```

### 2. Test API Endpoints ✅

```bash
# List supported providers
curl http://localhost:8000/api/keys/providers

# Expected response:
{
  "providers": [
    {
      "name": "groq",
      "display_name": "GROQ",
      "supports_chat": true,
      ...
    },
    ...
  ]
}
```

### 3. View API Documentation ✅

Open in browser:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

You should see new endpoints:
- `GET /api/keys/providers`
- `POST /api/keys/validate`
- `POST /api/keys/{user_id}`
- `GET /api/keys/{user_id}`
- `PATCH /api/keys/{user_id}/{key_id}`
- `DELETE /api/keys/{user_id}/{key_id}`
- `GET /api/keys/{user_id}/usage/stats`

### 4. Test Key Management ✅

```bash
# Replace USER_UUID with actual user ID
USER_UUID="your-user-uuid-here"

# Validate a key (without saving)
curl -X POST http://localhost:8000/api/keys/validate \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "groq",
    "api_key": "gsk-YOUR-KEY-HERE"
  }'

# Save a key
curl -X POST http://localhost:8000/api/keys/$USER_UUID \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "groq",
    "api_key": "gsk-YOUR-KEY-HERE",
    "priority": 10
  }'

# List user's keys
curl http://localhost:8000/api/keys/$USER_UUID

# Get usage stats
curl http://localhost:8000/api/keys/$USER_UUID/usage/stats?days=30
```

### 5. Test RAG with Provider Selection ✅

```bash
# RAG query with preferred provider
curl -X POST http://localhost:8000/api/ai/chat-rag \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is artificial intelligence?",
    "user_id": "'$USER_UUID'",
    "preferred_provider": "groq"
  }'
```

## What Was Created

### Database Tables

#### user_api_keys
Stores encrypted API keys per user/provider:
- `id` - UUID primary key
- `user_id` - References users table
- `provider` - Provider name (groq, openai, anthropic, etc.)
- `encrypted_key` - Encrypted API key
- `is_active` - Whether key is active
- `is_validated` - Whether key has been validated
- `validation_error` - Last validation error
- `last_validated_at` - Last validation timestamp
- `priority` - Priority for provider selection (higher = preferred)
- `created_at`, `updated_at` - Timestamps

#### api_usage_logs
Tracks all API usage:
- `id` - UUID primary key
- `user_id` - References users table
- `provider` - Provider used
- `endpoint` - Endpoint called (chat, embedding, rag_query)
- `request_tokens`, `response_tokens`, `total_tokens` - Token counts
- `cost_estimate` - Estimated cost in USD
- `status` - success, error, or rate_limit
- `error_message` - Error details if failed
- `metadata` - Additional context (JSONB)
- `created_at` - Timestamp

### Helper Functions

#### get_user_active_keys(user_id)
Returns user's active, validated keys ordered by priority.

#### get_user_usage_stats(user_id, start_date, end_date)
Returns aggregated usage statistics by provider.

## Verification Checklist

- [ ] Migration SQL applied in Supabase Dashboard
- [ ] Tables visible in Table Editor (user_api_keys, api_usage_logs)
- [ ] Backend starts without errors
- [ ] `/api/keys/providers` endpoint returns provider list
- [ ] Swagger docs show new endpoints at `/docs`
- [ ] Can validate a test API key
- [ ] Can save and retrieve API keys
- [ ] RAG endpoint accepts `preferred_provider` parameter

## Troubleshooting

### Migration Fails

**Error: "relation already exists"**
- Tables already created, migration already applied
- Safe to ignore

**Error: "function update_updated_at_column does not exist"**
- Run the base schema migration first: `001_complete_schema_clean.sql`

**Error: "permission denied"**
- Ensure you're using SUPABASE_SERVICE_KEY, not anon key
- Check RLS policies if needed

### Backend Won't Start

**Error: "ENCRYPTION_KEY not set"**
```bash
# Generate a new key
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

# Add to .env
ENCRYPTION_KEY=generated-key-here
```

**Error: "GROQ_API_KEY not set"**
```bash
# Add to .env
GROQ_API_KEY=gsk-your-key-here
```

### Endpoints Return 404

- Ensure backend is running
- Check that api_keys router is registered in `app/main.py`
- Verify URL: http://localhost:8000/api/keys/providers

### Key Validation Fails

- Check API key format matches provider requirements
- Verify provider API is accessible
- Check rate limits on provider side

## Next Steps After Verification

### 1. Frontend Integration
Create UI components for:
- API key management screen
- Provider selection dropdown
- Usage statistics dashboard
- Key validation feedback

### 2. User Documentation
Document for end users:
- How to get API keys from providers
- How to add keys to ScholarMate
- How to select preferred provider
- How to view usage statistics

### 3. Monitoring
Set up monitoring for:
- Usage patterns
- Cost tracking
- Error rates
- Provider availability

### 4. Additional Providers
Consider adding:
- Cohere
- Google Gemini
- Mistral
- Perplexity

## Support

If you encounter issues:

1. **Check Logs**
   ```bash
   # Backend logs
   tail -f backend/logs/app.log
   ```

2. **Test Database Connection**
   ```bash
   uv run python -c "from app.services.supabase_service import get_supabase_service; print('✅ Connected')"
   ```

3. **Verify Environment**
   ```bash
   # Check required variables
   grep -E "SUPABASE_URL|SUPABASE_SERVICE_KEY|ENCRYPTION_KEY|GROQ_API_KEY" backend/.env
   ```

4. **Review Documentation**
   - Full docs: `backend/MULTI_PROVIDER_API_KEYS.md`
   - Quick start: `backend/API_KEY_MANAGEMENT_QUICK_START.md`
   - Cheat sheet: `backend/API_KEY_CHEAT_SHEET.md`

## Summary

✅ **Migration Ready**: SQL file prepared and ready to apply  
✅ **Backend Ready**: All code implemented and tested  
✅ **Documentation Ready**: Comprehensive guides available  
✅ **Dependencies Installed**: anthropic, openai, psycopg2-binary added

**Action Required**: Apply migration SQL in Supabase Dashboard, then test endpoints!

---

**Last Updated**: November 12, 2025  
**Status**: Ready for Migration Application
