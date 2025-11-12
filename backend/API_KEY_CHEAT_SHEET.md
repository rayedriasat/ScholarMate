# API Key Management - Cheat Sheet

## Quick Commands

```bash
# Install dependencies
cd backend && uv add anthropic openai && uv sync

# Apply migration (in Supabase SQL editor)
# Run: backend/migrations/006_user_api_keys.sql

# Start backend
cd backend && uv run python run.py

# Test
curl http://localhost:8000/api/keys/providers
```

## API Endpoints

```bash
# List providers
GET /api/keys/providers

# Validate key
POST /api/keys/validate
{"provider": "openai", "api_key": "sk-..."}

# Save key
POST /api/keys/{user_id}
{"provider": "openai", "api_key": "sk-...", "priority": 10}

# List keys
GET /api/keys/{user_id}

# Update key
PATCH /api/keys/{user_id}/{key_id}
{"is_active": false}

# Delete key
DELETE /api/keys/{user_id}/{key_id}

# Usage stats
GET /api/keys/{user_id}/usage/stats?days=30

# RAG with provider
POST /api/ai/chat-rag
{"question": "...", "user_id": "...", "preferred_provider": "openai"}
```

## Python Client

```python
import requests

BASE = "http://localhost:8000"
USER = "your-uuid"

# Add key
requests.post(f"{BASE}/api/keys/{USER}", json={
    "provider": "openai",
    "api_key": "sk-...",
    "priority": 10
})

# RAG query
requests.post(f"{BASE}/api/ai/chat-rag", json={
    "question": "What is AI?",
    "user_id": USER,
    "preferred_provider": "openai"
})

# Check usage
stats = requests.get(f"{BASE}/api/keys/{USER}/usage/stats?days=7").json()
```

## Providers

| Provider | Name | Key Format | Free |
|----------|------|------------|------|
| GROQ | `groq` | `gsk-*` | ✅ |
| OpenAI | `openai` | `sk-*` | ❌ |
| Anthropic | `anthropic` | `sk-ant-*` | ❌ |

## Fallback Logic

1. Preferred provider (if specified)
2. Highest priority key
3. System default (GROQ)

## Database Tables

```sql
-- Keys
user_api_keys (id, user_id, provider, encrypted_key, is_active, is_validated, priority)

-- Usage
api_usage_logs (id, user_id, provider, endpoint, tokens, cost, status)
```

## Environment

```bash
ENCRYPTION_KEY=your-fernet-key  # Required
GROQ_API_KEY=gsk-...           # System default
```

## Files

- Migration: `backend/migrations/006_user_api_keys.sql`
- Models: `backend/app/models/api_keys.py`
- Service: `backend/app/services/api_key_service.py`
- Router: `backend/app/routers/api_keys.py`
- Docs: `backend/MULTI_PROVIDER_API_KEYS.md`

## Common Issues

**Validation fails?** Check key format and provider API access  
**Provider not used?** Ensure `is_active=true` and `is_validated=true`  
**Usage not logged?** Non-critical, check Supabase connection

## Docs

- Full: `backend/MULTI_PROVIDER_API_KEYS.md`
- Quick Start: `backend/API_KEY_MANAGEMENT_QUICK_START.md`
- Swagger: http://localhost:8000/docs
