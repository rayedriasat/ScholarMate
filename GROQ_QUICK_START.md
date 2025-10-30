# GROQ Integration - Quick Start Guide

## Setup (One-Time)

1. **Get GROQ API Key**
   - Visit https://console.groq.com/
   - Sign up (free tier available)
   - Generate API key

2. **Configure Backend**
   ```bash
   # Edit backend/.env
   GROQ_API_KEY=gsk_your_actual_key_here
   ```

## Testing

### Option 1: Run Test Script
```bash
cd backend
uv run python test_groq.py
```

Expected output:
```
=== Testing GROQ Connection ===
✓ Connection successful
✓ Model: llama-3.3-70b-versatile
✓ Response: Hello

=== Testing GROQ Chat Completion ===
✓ Chat Response: Paris
✓ Model: llama-3.3-70b-versatile
✓ Tokens Used: 25

=== Testing GROQ Embeddings ===
✓ Generated 2 embeddings
✓ Embedding dimension: 768

Tests Passed: 3/3
```

### Option 2: Test via API

1. **Start Backend**
   ```bash
   cd backend
   uv run python run.py
   ```

2. **Test Connection**
   ```bash
   curl -X POST http://localhost:8000/api/ai/test-groq
   ```

3. **Test Chat**
   ```bash
   curl -X POST http://localhost:8000/api/ai/chat \
     -H "Content-Type: application/json" \
     -d '{
       "messages": [
         {"role": "user", "content": "What is AI?"}
       ],
       "temperature": 0.7,
       "max_tokens": 100
     }'
   ```

4. **View Swagger UI**
   - Open http://localhost:8000/docs
   - Try endpoints interactively

## API Endpoints

### Test Connection
```
POST /api/ai/test-groq
```

### Chat Completion
```
POST /api/ai/chat
Body: {
  "messages": [{"role": "user", "content": "..."}],
  "temperature": 0.7,
  "max_tokens": 100
}
```

### Generate Embeddings
```
POST /api/ai/embed
Body: {
  "texts": ["text1", "text2"]
}
```

## Integration in Code

### Python (Backend)
```python
from app.services.groq_service import get_groq_service

# Get service instance
groq = get_groq_service()

# Chat completion
result = await groq.chat(
    messages=[{"role": "user", "content": "Hello"}],
    temperature=0.7
)
print(result["content"])

# Test connection
status = groq.test_connection()
print(status["status"])
```

### HTTP (Frontend)
```dart
// Test connection
final response = await http.post(
  Uri.parse('http://localhost:8000/api/ai/test-groq'),
);

// Chat completion
final chatResponse = await http.post(
  Uri.parse('http://localhost:8000/api/ai/chat'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'messages': [
      {'role': 'user', 'content': 'What is AI?'}
    ],
    'temperature': 0.7,
  }),
);
```

## Troubleshooting

### "GROQ_API_KEY not found"
- Check `backend/.env` exists
- Verify key is set: `GROQ_API_KEY=gsk_...`
- Restart backend

### "Invalid API key"
- Verify key starts with `gsk_`
- Check for extra spaces/quotes
- Generate new key if needed

### "Rate limit exceeded"
- Wait a few seconds
- GROQ has generous free tier limits
- Check usage at https://console.groq.com/

## Next Steps

- Integrate with RAG system (Task 12)
- Add streaming support for real-time responses
- Implement caching to reduce API calls
- Monitor usage and optimize prompts
