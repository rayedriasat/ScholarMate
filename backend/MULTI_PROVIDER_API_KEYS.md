# Multi-Provider API Key Management

Complete implementation of per-user AI provider API key management with encryption, validation, usage tracking, and automatic fallback.

## Overview

Users can now manage their own API keys for multiple AI providers (GROQ, OpenAI, Anthropic, Cohere, etc.). The system automatically selects the best available provider based on user preferences and validates keys before use.

## Features

### 1. Secure API Key Storage
- **Encryption**: All API keys encrypted using Fernet (AES-256) with server-side secret
- **Database**: Stored in `user_api_keys` table with user isolation
- **Never Exposed**: Raw keys never returned to frontend (only masked versions)

### 2. Multi-Provider Support
- **GROQ**: llama-3.3-70b-versatile (free tier)
- **OpenAI**: gpt-4o-mini, gpt-4o, etc.
- **Anthropic**: Claude 3.5 Sonnet, Claude 3 Opus, etc.
- **Extensible**: Easy to add more providers (Cohere, Google, etc.)

### 3. Key Validation
- **Pre-save Validation**: Test keys with lightweight API calls before storing
- **Validation Status**: Track whether keys are validated and last validation time
- **Error Tracking**: Store validation errors for debugging

### 4. Usage Tracking
- **Comprehensive Logging**: Track every API call with tokens, cost, status
- **Per-Provider Stats**: View usage by provider with success rates
- **Cost Estimation**: Rough cost estimates based on token usage

### 5. Fallback Provider Logic
Priority order for provider selection:
1. User's preferred provider (if specified in request)
2. User's highest priority validated key
3. System default (GROQ from environment)

## Database Schema

### user_api_keys Table
```sql
CREATE TABLE user_api_keys (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    provider TEXT CHECK (provider IN ('groq', 'openai', 'anthropic', 'cohere', 'google', 'openrouter')),
    encrypted_key TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_validated BOOLEAN DEFAULT FALSE,
    validation_error TEXT,
    last_validated_at TIMESTAMPTZ,
    priority INTEGER DEFAULT 0,  -- Higher = preferred
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    UNIQUE(user_id, provider)
);
```

### api_usage_logs Table
```sql
CREATE TABLE api_usage_logs (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    provider TEXT NOT NULL,
    endpoint TEXT NOT NULL,  -- 'chat', 'embedding', 'rag_query'
    request_tokens INTEGER DEFAULT 0,
    response_tokens INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,
    cost_estimate DECIMAL(10, 6) DEFAULT 0,
    status TEXT CHECK (status IN ('success', 'error', 'rate_limit')),
    error_message TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ
);
```

## API Endpoints

### List Supported Providers
```http
GET /api/keys/providers
```

Response:
```json
{
  "providers": [
    {
      "name": "groq",
      "display_name": "GROQ",
      "supports_chat": true,
      "supports_embeddings": false,
      "default_chat_model": "llama-3.3-70b-versatile",
      "api_key_format": "gsk_*",
      "docs_url": "https://console.groq.com/docs"
    },
    ...
  ]
}
```

### Validate API Key
```http
POST /api/keys/validate
Content-Type: application/json

{
  "provider": "openai",
  "api_key": "sk-..."
}
```

Response:
```json
{
  "is_valid": true,
  "provider": "openai",
  "model_info": {
    "model": "gpt-4o-mini",
    "response": "Hi"
  }
}
```

### Create/Update API Key
```http
POST /api/keys/{user_id}?validate=true
Content-Type: application/json

{
  "provider": "openai",
  "api_key": "sk-...",
  "priority": 10
}
```

Response:
```json
{
  "id": "uuid",
  "provider": "openai",
  "is_active": true,
  "is_validated": true,
  "validation_error": null,
  "last_validated_at": "2024-01-15T10:30:00Z",
  "priority": 10,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z",
  "masked_key": "sk-...xyz"
}
```

### List User's API Keys
```http
GET /api/keys/{user_id}
```

Response:
```json
{
  "keys": [
    {
      "id": "uuid",
      "provider": "openai",
      "is_active": true,
      "is_validated": true,
      "priority": 10,
      "masked_key": "sk-...xyz",
      ...
    }
  ],
  "total": 1
}
```

### Update Key Status/Priority
```http
PATCH /api/keys/{user_id}/{key_id}
Content-Type: application/json

{
  "is_active": false,
  "priority": 5
}
```

### Delete API Key
```http
DELETE /api/keys/{user_id}/{key_id}
```

### Get Usage Statistics
```http
GET /api/keys/{user_id}/usage/stats?days=30
```

Response:
```json
{
  "stats": [
    {
      "provider": "openai",
      "total_requests": 150,
      "total_tokens": 45000,
      "total_cost": 0.0675,
      "success_rate": 98.67
    }
  ],
  "period_start": "2024-12-15T00:00:00Z",
  "period_end": "2025-01-15T00:00:00Z"
}
```

## RAG Query with Provider Selection

### Enhanced RAG Chat Endpoint
```http
POST /api/ai/chat-rag
Content-Type: application/json

{
  "question": "What is the main finding?",
  "user_id": "uuid",
  "selected_file_ids": ["file1", "file2"],
  "top_k": 5,
  "preferred_provider": "openai"  // NEW: Optional provider preference
}
```

The system will:
1. Try user's preferred provider (if specified and valid)
2. Fall back to highest priority validated key
3. Fall back to system default (GROQ)
4. Log usage for tracking

## Usage Examples

### Python Client Example
```python
import requests

BASE_URL = "http://localhost:8000"
USER_ID = "your-user-uuid"

# 1. List supported providers
response = requests.get(f"{BASE_URL}/api/keys/providers")
providers = response.json()["providers"]
print(f"Supported: {[p['name'] for p in providers]}")

# 2. Validate a key before saving
response = requests.post(
    f"{BASE_URL}/api/keys/validate",
    json={
        "provider": "openai",
        "api_key": "sk-..."
    }
)
validation = response.json()
print(f"Valid: {validation['is_valid']}")

# 3. Save the key
response = requests.post(
    f"{BASE_URL}/api/keys/{USER_ID}",
    json={
        "provider": "openai",
        "api_key": "sk-...",
        "priority": 10
    }
)
key = response.json()
print(f"Saved key: {key['masked_key']}")

# 4. Use RAG with preferred provider
response = requests.post(
    f"{BASE_URL}/api/ai/chat-rag",
    json={
        "question": "What is quantum computing?",
        "user_id": USER_ID,
        "preferred_provider": "openai"
    }
)
answer = response.json()
print(f"Answer: {answer['message']}")

# 5. Check usage stats
response = requests.get(f"{BASE_URL}/api/keys/{USER_ID}/usage/stats?days=7")
stats = response.json()
for stat in stats["stats"]:
    print(f"{stat['provider']}: {stat['total_requests']} requests, ${stat['total_cost']:.4f}")
```

### Flutter/Dart Client Example
```dart
// Add API key
final response = await http.post(
  Uri.parse('$baseUrl/api/keys/$userId'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'provider': 'openai',
    'api_key': 'sk-...',
    'priority': 10,
  }),
);

// RAG query with provider preference
final ragResponse = await http.post(
  Uri.parse('$baseUrl/api/ai/chat-rag'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'question': 'What is the main finding?',
    'user_id': userId,
    'preferred_provider': 'openai',
  }),
);
```

## Installation & Setup

### 1. Install Dependencies
```bash
cd backend
uv add anthropic openai
uv sync
```

### 2. Apply Database Migration
```bash
# Using Supabase CLI
supabase migration new user_api_keys
# Copy contents of backend/migrations/006_user_api_keys.sql
supabase db push

# Or apply directly via SQL editor in Supabase dashboard
```

### 3. Verify ENCRYPTION_KEY
Ensure your `.env` has:
```bash
ENCRYPTION_KEY=your-fernet-key-here  # Generate with: python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

### 4. Restart Backend
```bash
uv run python run.py
```

### 5. Test Endpoints
```bash
# List providers
curl http://localhost:8000/api/keys/providers

# Validate key
curl -X POST http://localhost:8000/api/keys/validate \
  -H "Content-Type: application/json" \
  -d '{"provider": "groq", "api_key": "gsk-..."}'
```

## Architecture

### Service Layer
- **ProviderFactory**: Creates provider instances, manages configurations
- **AIProvider**: Abstract base class for all providers
- **GroqProvider, OpenAIProvider, AnthropicProvider**: Concrete implementations
- **APIKeyService**: CRUD operations for keys, validation, usage logging
- **RAGQueryService**: Enhanced with multi-provider support

### Provider Interface
```python
class AIProvider(ABC):
    @abstractmethod
    async def chat(messages, temperature, max_tokens) -> Dict
    
    @abstractmethod
    async def validate_key() -> Dict
    
    @abstractmethod
    def get_provider_name() -> str
```

### Fallback Logic
```python
async def get_active_provider(user_id, preferred_provider):
    # 1. Try preferred provider
    if preferred_provider and user_has_valid_key(preferred_provider):
        return create_provider(preferred_provider, user_key)
    
    # 2. Try highest priority key
    if user_has_any_valid_keys():
        return create_provider(highest_priority_key)
    
    # 3. System default
    return get_default_provider()  # GROQ from env
```

## Security Considerations

1. **Encryption**: All keys encrypted at rest with Fernet (AES-256)
2. **Never Exposed**: Raw keys never sent to frontend
3. **User Isolation**: RLS policies ensure users only see their own keys
4. **Validation**: Keys tested before storage to prevent invalid keys
5. **Audit Trail**: All usage logged for accountability

## Cost Management

### Estimated Costs (per 1M tokens)
- **GROQ**: $0 (free tier)
- **OpenAI gpt-4o-mini**: ~$1.50
- **Anthropic Claude Sonnet**: ~$3.00

### Usage Tracking
- Real-time token counting
- Cost estimation per request
- Aggregated statistics by provider
- Success rate monitoring

## Troubleshooting

### Key Validation Fails
- Check API key format matches provider requirements
- Verify provider API is accessible
- Check rate limits on provider side

### Provider Not Available
- Ensure key is marked as `is_active=true`
- Verify key is validated (`is_validated=true`)
- Check system default (GROQ) is configured

### Usage Not Logged
- Non-critical: Logging failures don't block requests
- Check Supabase connection
- Verify `api_usage_logs` table exists

## Future Enhancements

1. **More Providers**: Cohere, Google Gemini, Mistral, etc.
2. **Embedding Support**: Multi-provider embeddings
3. **Rate Limiting**: Per-user rate limits
4. **Cost Alerts**: Notify users when approaching limits
5. **Model Selection**: Let users choose specific models per provider
6. **Streaming**: Support streaming responses
7. **Caching**: Cache responses to reduce costs

## Testing

```bash
# Run tests
cd backend
uv run pytest test_api_key_service.py -v
uv run pytest test_provider_service.py -v
uv run pytest test_rag_multi_provider.py -v
```

## Summary

This implementation provides a complete, production-ready multi-provider API key management system with:
- ✅ Secure encrypted storage
- ✅ Key validation before use
- ✅ Usage tracking and cost estimation
- ✅ Automatic fallback logic
- ✅ Support for GROQ, OpenAI, Anthropic
- ✅ Easy to extend with new providers
- ✅ Comprehensive API endpoints
- ✅ Database migrations included

Users can now bring their own API keys, track usage, and the system automatically selects the best available provider for each request.
