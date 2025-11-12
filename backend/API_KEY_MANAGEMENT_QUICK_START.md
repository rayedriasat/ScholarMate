# API Key Management - Quick Start

## Setup (5 minutes)

### 1. Install Dependencies
```bash
cd backend
uv add anthropic openai
uv sync
```

### 2. Apply Migration
Run the SQL in `migrations/006_user_api_keys.sql` in your Supabase SQL editor.

### 3. Verify Environment
```bash
# Check .env has ENCRYPTION_KEY
grep ENCRYPTION_KEY backend/.env
```

### 4. Start Backend
```bash
cd backend
uv run python run.py
```

## Quick Test

```bash
# 1. List supported providers
curl http://localhost:8000/api/keys/providers

# 2. Validate a GROQ key
curl -X POST http://localhost:8000/api/keys/validate \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "groq",
    "api_key": "gsk-YOUR-KEY-HERE"
  }'

# 3. Save the key (replace USER_UUID)
curl -X POST http://localhost:8000/api/keys/USER_UUID \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "groq",
    "api_key": "gsk-YOUR-KEY-HERE",
    "priority": 10
  }'

# 4. List user's keys
curl http://localhost:8000/api/keys/USER_UUID

# 5. Use RAG with preferred provider
curl -X POST http://localhost:8000/api/ai/chat-rag \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is AI?",
    "user_id": "USER_UUID",
    "preferred_provider": "groq"
  }'

# 6. Check usage stats
curl http://localhost:8000/api/keys/USER_UUID/usage/stats?days=7
```

## Key Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/keys/providers` | GET | List supported providers |
| `/api/keys/validate` | POST | Validate key without saving |
| `/api/keys/{user_id}` | POST | Create/update key |
| `/api/keys/{user_id}` | GET | List user's keys |
| `/api/keys/{user_id}/{key_id}` | PATCH | Update key status |
| `/api/keys/{user_id}/{key_id}` | DELETE | Delete key |
| `/api/keys/{user_id}/usage/stats` | GET | Get usage statistics |
| `/api/ai/chat-rag` | POST | RAG query (now supports `preferred_provider`) |

## Supported Providers

| Provider | Name | Free Tier | Chat | Embeddings |
|----------|------|-----------|------|------------|
| GROQ | `groq` | ✅ Yes | ✅ | ❌ |
| OpenAI | `openai` | ❌ No | ✅ | ✅ |
| Anthropic | `anthropic` | ❌ No | ✅ | ❌ |

## Provider Selection Logic

1. **Preferred Provider** (if specified in request and valid)
2. **Highest Priority Key** (user's validated keys sorted by priority)
3. **System Default** (GROQ from environment)

## Common Tasks

### Add OpenAI Key
```python
import requests

requests.post(
    "http://localhost:8000/api/keys/USER_UUID",
    json={
        "provider": "openai",
        "api_key": "sk-...",
        "priority": 10
    }
)
```

### Use Specific Provider for RAG
```python
requests.post(
    "http://localhost:8000/api/ai/chat-rag",
    json={
        "question": "What is quantum computing?",
        "user_id": "USER_UUID",
        "preferred_provider": "openai"  # Use OpenAI instead of default
    }
)
```

### Check Usage
```python
response = requests.get(
    "http://localhost:8000/api/keys/USER_UUID/usage/stats?days=30"
)
stats = response.json()
for stat in stats["stats"]:
    print(f"{stat['provider']}: {stat['total_requests']} requests, ${stat['total_cost']:.4f}")
```

## Troubleshooting

**Key validation fails?**
- Check API key format (GROQ: `gsk-*`, OpenAI: `sk-*`, Anthropic: `sk-ant-*`)
- Verify provider API is accessible
- Check rate limits

**Provider not used?**
- Ensure key is active: `is_active=true`
- Verify key is validated: `is_validated=true`
- Check priority (higher = preferred)

**Usage not tracked?**
- Non-critical: Won't block requests
- Check Supabase connection
- Verify migration applied

## Next Steps

1. **Frontend Integration**: Add UI for key management
2. **More Providers**: Add Cohere, Google Gemini, etc.
3. **Cost Alerts**: Notify users when approaching limits
4. **Model Selection**: Let users choose specific models

## Documentation

- Full docs: `backend/MULTI_PROVIDER_API_KEYS.md`
- API docs: http://localhost:8000/docs (Swagger)
- Database schema: `backend/migrations/006_user_api_keys.sql`
