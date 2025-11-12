# Provider Selection Flow Diagram

## How the System Chooses an AI Provider

```
┌─────────────────────────────────────────────────────────────┐
│                    User Makes RAG Query                      │
│  POST /api/ai/chat-rag                                       │
│  {                                                           │
│    "question": "What is quantum computing?",                 │
│    "user_id": "uuid",                                        │
│    "preferred_provider": "openai"  // Optional               │
│  }                                                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              RAGQueryService.query()                         │
│  1. Retrieve context from Pinecone                           │
│  2. Call generate_response_with_provider()                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│         APIKeyService.get_active_provider()                  │
│  Determines which provider to use                            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌──────────┴──────────┐
              │  Preferred Provider  │
              │     Specified?       │
              └──────────┬──────────┘
                         │
         ┌───────────────┴───────────────┐
         │ YES                            │ NO
         ▼                                ▼
┌─────────────────────┐        ┌─────────────────────┐
│ Check if user has   │        │ Get user's highest  │
│ valid key for       │        │ priority validated  │
│ preferred provider  │        │ key (any provider)  │
└──────────┬──────────┘        └──────────┬──────────┘
           │                              │
           ▼                              ▼
    ┌──────────┐                  ┌──────────┐
    │  Found?  │                  │  Found?  │
    └─────┬────┘                  └─────┬────┘
          │                             │
    ┌─────┴─────┐               ┌───────┴───────┐
    │YES        │NO             │YES            │NO
    ▼           ▼               ▼               ▼
┌────────┐  ┌────────┐    ┌────────┐    ┌────────┐
│ Use    │  │ Try    │    │ Use    │    │ Use    │
│ User's │  │ Next   │    │ User's │    │ System │
│ OpenAI │  │ Option │    │ Highest│    │ Default│
│ Key    │  │        │    │ Priority│   │ (GROQ) │
└────┬───┘  └────┬───┘    └────┬───┘    └────┬───┘
     │           │             │             │
     └───────────┴─────────────┴─────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              ProviderFactory.create_provider()               │
│  Creates provider instance with decrypted API key            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Provider.chat(messages)                         │
│  Calls actual AI provider API                                │
│  - GroqProvider → GROQ API                                   │
│  - OpenAIProvider → OpenAI API                               │
│  - AnthropicProvider → Anthropic API                         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Response Generated                              │
│  {                                                           │
│    "content": "Quantum computing is...",                     │
│    "usage": {"total_tokens": 150},                           │
│    "model": "gpt-4o-mini"                                    │
│  }                                                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              APIKeyService.log_usage()                       │
│  Logs to api_usage_logs table:                               │
│  - Provider used                                             │
│  - Tokens consumed                                           │
│  - Estimated cost                                            │
│  - Success/error status                                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Return Response to User                         │
│  {                                                           │
│    "message": "Quantum computing is...",                     │
│    "citations": [...],                                       │
│    "timestamp": "2025-01-15T10:30:00Z"                       │
│  }                                                           │
└───────────────────────────────────────────────��─────────────┘
```

## Priority Examples

### Example 1: User Prefers OpenAI
```
Request: preferred_provider = "openai"
User has: OpenAI key (validated), GROQ key (validated)
Result: ✅ Uses OpenAI (user preference honored)
```

### Example 2: No Preference, Multiple Keys
```
Request: preferred_provider = null
User has: 
  - OpenAI key (priority=10, validated)
  - GROQ key (priority=5, validated)
Result: ✅ Uses OpenAI (highest priority)
```

### Example 3: Preferred Provider Invalid
```
Request: preferred_provider = "anthropic"
User has: 
  - Anthropic key (not validated)
  - OpenAI key (priority=10, validated)
Result: ✅ Uses OpenAI (fallback to highest priority)
```

### Example 4: No User Keys
```
Request: preferred_provider = null
User has: No keys
Result: ✅ Uses System Default (GROQ from env)
```

### Example 5: All Keys Inactive
```
Request: preferred_provider = null
User has: 
  - OpenAI key (is_active=false)
  - GROQ key (is_active=false)
Result: ✅ Uses System Default (GROQ from env)
```

## Key States

```
┌─────────────────────────────────────────────────────────────┐
│                    API Key Lifecycle                         │
└─────────────────────────────────────────────────────────────┘

1. CREATED
   ├─ is_active: true
   ├─ is_validated: false
   └─ Status: Not usable yet

2. VALIDATED (after validation)
   ├─ is_active: true
   ├─ is_validated: true
   └─ Status: ✅ Usable

3. DEACTIVATED (user disables)
   ├─ is_active: false
   ├─ is_validated: true
   └─ Status: ❌ Not usable

4. INVALID (validation fails)
   ├─ is_active: true
   ├─ is_validated: false
   ├─ validation_error: "Invalid API key"
   └─ Status: ❌ Not usable

5. DELETED
   └─ Status: ❌ Removed from database
```

## Database Query Flow

```sql
-- Get user's active providers (ordered by priority)
SELECT provider, encrypted_key, priority
FROM user_api_keys
WHERE user_id = $1
  AND is_active = true
  AND is_validated = true
ORDER BY priority DESC, created_at ASC;

-- Result example:
-- provider  | encrypted_key | priority
-- openai    | gAAAAAB...    | 10
-- groq      | gAAAAAB...    | 5
-- anthropic | gAAAAAB...    | 0

-- System picks first match or falls back to default
```

## Cost Tracking Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Usage Logging                             │
└─────────────────────────────────────────────────────────────┘

1. API Call Made
   ├─ Provider: openai
   ├─ Endpoint: rag_query
   └─ User: uuid

2. Response Received
   ├─ Prompt tokens: 100
   ├─ Completion tokens: 50
   └─ Total tokens: 150

3. Cost Calculated
   ├─ Rate: $0.0015 per 1K tokens (gpt-4o-mini)
   ├─ Calculation: (150 / 1000) * 0.0015
   └─ Cost: $0.000225

4. Logged to Database
   INSERT INTO api_usage_logs (
     user_id, provider, endpoint,
     request_tokens, response_tokens, total_tokens,
     cost_estimate, status, metadata
   ) VALUES (
     'uuid', 'openai', 'rag_query',
     100, 50, 150,
     0.000225, 'success', '{"model": "gpt-4o-mini"}'
   );

5. Aggregated for Stats
   SELECT provider, 
          COUNT(*) as total_requests,
          SUM(total_tokens) as total_tokens,
          SUM(cost_estimate) as total_cost
   FROM api_usage_logs
   WHERE user_id = 'uuid'
     AND created_at >= NOW() - INTERVAL '30 days'
   GROUP BY provider;
```

## Error Handling Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Error Scenarios                           │
└─────────────────────────────────────────────────────────────┘

Scenario 1: Provider API Error
├─ Try: User's OpenAI key
├─ Error: Rate limit exceeded
├─ Log: status='rate_limit', error_message='...'
└─ Action: Return error to user (no automatic fallback mid-request)

Scenario 2: Invalid Key
├─ Try: User's OpenAI key
├─ Error: Invalid API key
├─ Log: status='error', error_message='Invalid API key'
└─ Action: Mark key as invalid, return error

Scenario 3: Network Error
├─ Try: User's OpenAI key
├─ Error: Connection timeout
├─ Log: status='error', error_message='Connection timeout'
└─ Action: Return error to user

Note: Fallback only happens during provider SELECTION,
      not during API call execution.
```

## Summary

The system provides intelligent provider selection with:
- ✅ User preference honored when possible
- ✅ Automatic fallback to validated keys
- ✅ System default as last resort
- ✅ Complete usage tracking
- ✅ Cost estimation
- ✅ Error logging

This ensures users always get a response while maintaining control over which AI provider is used.
