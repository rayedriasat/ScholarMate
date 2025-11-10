# Deploying ScholarMate Backend to Defang.io (Free Tier)

This guide will help you deploy the ScholarMate FastAPI backend to Defang.io using their free tier.

## Prerequisites

1. **Defang CLI** - Install the Defang CLI:
   ```bash
   # Windows (PowerShell)
   iwr https://s.defang.io/install.ps1 -useb | iex
   
   # macOS/Linux
   curl -fsSL https://s.defang.io/install.sh | sh
   ```

2. **Docker Desktop** - Make sure Docker is installed and running

3. **API Keys** - Gather all your API keys:
   - Supabase credentials (URL, Anon Key, Service Key)
   - Google OAuth credentials (Client ID, Client Secret)
   - Pinecone API Key
   - Groq API Key
   - Encryption Key (generate with: `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`)

## Deployment Steps

### 1. Login to Defang

```bash
cd backend
defang login
```

Follow the prompts to authenticate.

### 2. Set Environment Secrets

You need to set all sensitive environment variables as secrets. Run these commands:

```bash
# Supabase
defang config set SUPABASE_URL your_supabase_url
defang config set SUPABASE_KEY your_supabase_anon_key
defang config set SUPABASE_SERVICE_KEY your_supabase_service_key

# Google OAuth
defang config set GOOGLE_CLIENT_ID your_google_client_id
defang config set GOOGLE_CLIENT_SECRET your_google_client_secret

# Pinecone
defang config set PINECONE_API_KEY your_pinecone_api_key

# Groq
defang config set GROQ_API_KEY your_groq_api_key

# Encryption
defang config set ENCRYPTION_KEY your_encryption_key

# Optional: OpenRouter (if using)
defang config set OPENROUTER_API_KEY your_openrouter_api_key

# Optional: DeepSeek OCR (if using)
defang config set DEEPSEEK_API_KEY your_deepseek_api_key
```

### 3. Deploy to Defang

```bash
defang compose up
```

This will:
- Build your Docker image
- Push it to Defang's registry
- Deploy your service
- Provide you with a public URL

### 4. Get Your Service URL

```bash
defang compose config
```

Look for the endpoint URL. It will be something like:
`https://backend-xxxxx.defang.dev`

### 5. Update CORS Configuration

Once you have your backend URL, update your frontend to point to it. You may also want to update the CORS_ORIGINS in your compose.yaml and redeploy:

```yaml
- CORS_ORIGINS=https://your-frontend-domain.com,https://another-domain.com
```

Then redeploy:
```bash
defang compose up
```

## Useful Commands

### Check Service Status
```bash
defang compose ps
```

### View Logs
```bash
defang compose logs backend
```

### Tail Logs (Follow)
```bash
defang compose logs -f backend
```

### Stop the Service
```bash
defang compose down
```

### Restart the Service
```bash
defang compose restart backend
```

### Delete All Resources
```bash
defang compose down
```

## Free Tier Limitations

The Defang free tier typically includes:
- ~512MB-1GB memory
- Shared CPU
- Limited bandwidth
- Auto-sleep after inactivity (wakes on request)

The backend is configured with memory-optimized settings:
- `EMBEDDING_BATCH_SIZE=3`
- `PDF_PAGE_BATCH_SIZE=2`
- `PINECONE_BATCH_SIZE=25`

These settings ensure the app runs within free tier limits.

## Troubleshooting

### Out of Memory Errors
If you see OOM (Out of Memory) errors, the batch sizes might need to be reduced further:
```bash
defang config set EMBEDDING_BATCH_SIZE 2
defang config set PDF_PAGE_BATCH_SIZE 1
defang compose restart backend
```

### Container Won't Start
1. Check logs: `defang compose logs backend`
2. Verify all required secrets are set: `defang config list`
3. Ensure Docker Desktop is running locally

### Health Check Failing
The service has a health check at `/api/health`. If it's failing:
1. Check if the app is listening on port 8000
2. Review logs for startup errors
3. Ensure all required environment variables are set

### Build Failures
If the Docker build fails:
1. Ensure you're in the `backend` directory
2. Check that all required files are present (requirements.txt, Dockerfile, etc.)
3. Try building locally first: `docker build -t scholarmate-backend .`

## Updating the Deployment

When you make changes to your code:

1. Commit your changes (optional but recommended)
2. Run `defang compose up` again
3. Defang will rebuild and redeploy automatically

## Cost Monitoring

Defang free tier is completely free, but monitor your usage:
```bash
defang status
```

## Support

- Defang Documentation: https://docs.defang.io
- Defang Discord: https://defang.io/discord
- ScholarMate Issues: [Your GitHub repo]

## Next Steps

After deployment:
1. Test the health endpoint: `https://your-backend-url.defang.dev/api/health`
2. Update your Flutter app's API configuration
3. Test all major features (auth, OCR, AI chat, etc.)
4. Set up monitoring and alerts

