# GROQ API Key Setup Guide

## Getting Your GROQ API Key

1. **Visit GROQ Console**
   - Go to https://console.groq.com/

2. **Sign Up / Log In**
   - Create an account or log in with existing credentials
   - GROQ offers free tier access

3. **Generate API Key**
   - Navigate to "API Keys" section
   - Click "Create API Key"
   - Copy the generated key (it will only be shown once)

4. **Add to Environment**
   - Open `backend/.env`
   - Replace `your_groq_api_key` with your actual key:
   ```env
   GROQ_API_KEY=gsk_your_actual_key_here
   ```

## Testing the Integration

### Option 1: Run Test Script
```bash
cd backend
uv run python test_groq.py
```

### Option 2: Test via API
1. Start backend:
   ```bash
   cd backend
   uv run python run.py
   ```

2. Test connection:
   ```bash
   curl -X POST http://localhost:8000/api/ai/test-groq
   ```

3. Or visit Swagger UI:
   - http://localhost:8000/docs
   - Try the `/api/ai/test-groq` endpoint

## Available Models

GROQ offers several high-performance models:
- `llama-3.3-70b-versatile` (default) - Best for general tasks
- `llama-3.1-70b-versatile` - Alternative large model
- `mixtral-8x7b-32768` - Good for long context
- `gemma2-9b-it` - Smaller, faster model

Update in `backend/.env`:
```env
GROQ_CHAT_MODEL=llama-3.3-70b-versatile
```

## Rate Limits

GROQ free tier includes:
- Generous request limits
- Fast inference speeds
- No credit card required

If you hit rate limits, the API will return a 429 error with retry information.

## Troubleshooting

### "GROQ_API_KEY not found"
- Ensure `backend/.env` exists and contains `GROQ_API_KEY`
- Restart the backend after adding the key

### "Invalid API key"
- Verify the key is correct (starts with `gsk_`)
- Check for extra spaces or quotes in `.env`

### "Connection error"
- Check internet connectivity
- Verify GROQ service status at https://status.groq.com/

## Security Notes

- Never commit `.env` files to version control
- Keep your API key private
- Rotate keys periodically
- Use environment variables in production
