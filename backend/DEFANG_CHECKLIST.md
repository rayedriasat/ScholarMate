# Defang Deployment Checklist

Use this checklist to ensure you have everything ready before deploying to Defang.io.

## Pre-Deployment Checklist

### 1. Prerequisites
- [ ] Docker Desktop installed and running
- [ ] Defang CLI installed (`defang --version` works)
- [ ] Logged into Defang (`defang whoami` works)

### 2. API Keys & Credentials

#### Required (Must Have)
- [ ] **Supabase URL** - Your Supabase project URL
- [ ] **Supabase Anon Key** - Public API key from Supabase
- [ ] **Supabase Service Key** - Service role key from Supabase (keep secret!)
- [ ] **Google OAuth Client ID** - From Google Cloud Console
- [ ] **Google OAuth Client Secret** - From Google Cloud Console
- [ ] **Pinecone API Key** - From Pinecone dashboard
- [ ] **Groq API Key** - From Groq console (for AI features)
- [ ] **Encryption Key** - Generate with: `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`

#### Optional (Nice to Have)
- [ ] OpenRouter API Key (for additional AI models)
- [ ] DeepSeek API Key (for enhanced OCR)

### 3. Pinecone Setup
- [ ] Pinecone index created with name: `scholarmate`
- [ ] Index dimension set to: `384`
- [ ] Index metric: `cosine` (recommended)
- [ ] Cloud provider: `aws`
- [ ] Region: `us-east-1` (or your preferred region)

### 4. Supabase Setup
- [ ] Database schema applied (tables, RLS policies, etc.)
- [ ] Storage buckets configured (if using file storage)
- [ ] Authentication providers enabled (Google OAuth)

### 5. Files Ready
- [ ] `Dockerfile` exists in backend/
- [ ] `compose.yaml` exists in backend/
- [ ] `requirements.txt` exists in backend/
- [ ] `.dockerignore` exists in backend/
- [ ] `app/` directory with all source code

## Deployment Steps

### Step 1: Set Secrets
```bash
cd backend

# Required secrets
defang config set SUPABASE_URL "your_value"
defang config set SUPABASE_KEY "your_value"
defang config set SUPABASE_SERVICE_KEY "your_value"
defang config set GOOGLE_CLIENT_ID "your_value"
defang config set GOOGLE_CLIENT_SECRET "your_value"
defang config set PINECONE_API_KEY "your_value"
defang config set GROQ_API_KEY "your_value"
defang config set ENCRYPTION_KEY "your_value"

# Optional secrets (if using)
defang config set OPENROUTER_API_KEY "your_value"
defang config set DEEPSEEK_API_KEY "your_value"
```

### Step 2: Verify Secrets
```bash
defang config list
```

### Step 3: Deploy
```bash
# Option A: Use script (recommended)
./deploy-defang.sh          # Linux/macOS
.\deploy-defang.ps1         # Windows

# Option B: Manual
defang compose up
```

### Step 4: Verify Deployment
```bash
# Get service URL
defang compose ps

# Test health endpoint
curl https://YOUR_URL.defang.dev/api/health

# Expected response:
# {"status":"healthy","service":"scholarmate-backend"}
```

### Step 5: Monitor Logs
```bash
defang compose logs backend -f
```

## Post-Deployment Checklist

- [ ] Health endpoint responding correctly
- [ ] Backend URL noted for frontend configuration
- [ ] CORS origins updated if needed (in `compose.yaml`)
- [ ] Test authentication flow
- [ ] Test OCR functionality
- [ ] Test AI chat features
- [ ] Test file upload/storage
- [ ] Monitor memory usage (free tier limits)

## Updating After Changes

When you modify code:

1. Make your changes
2. Commit to git (optional but recommended)
3. Run: `defang compose up`
4. Monitor deployment: `defang compose logs backend -f`

## Rollback Plan

If something goes wrong:

```bash
# Stop current deployment
defang compose down

# Fix issues locally
# Test locally: docker build -t test . && docker run -p 8000:8000 test

# Redeploy
defang compose up
```

## Monitoring & Maintenance

### Check Service Status
```bash
defang compose ps
```

### View Resource Usage
```bash
defang status
```

### Update Configuration
```bash
# Update a secret
defang config set SECRET_NAME new_value

# Restart to apply changes
defang compose restart backend
```

## Free Tier Limits

Keep these in mind:
- **Memory**: ~512MB-1GB (configured in compose.yaml)
- **CPU**: Shared (~0.5 vCPU)
- **Bandwidth**: Limited
- **Sleep**: May auto-sleep after inactivity (wakes on request)
- **Build time**: Limited build minutes per month

## Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| Out of memory | Reduce batch sizes in config |
| Build timeout | Optimize Dockerfile, reduce dependencies |
| Health check fails | Check logs, verify port 8000 |
| 502 Bad Gateway | Service may be starting, wait 60s |
| Can't connect | Check service status with `defang compose ps` |

## Support Resources

- **Defang Docs**: https://docs.defang.io
- **Defang Discord**: https://defang.io/discord
- **Defang CLI Help**: `defang --help`
- **This Project**: See DEFANG_DEPLOYMENT.md for detailed guide

---

## Notes

- Keep your secrets safe! Never commit them to git
- The `.dockerignore` file excludes `.venv` and other unnecessary files
- Deployment typically takes 2-5 minutes
- First request after sleep may take 10-20 seconds
- Free tier is perfect for development/testing, consider paid tier for production

---

**Ready to deploy?** Run `./deploy-defang.sh` (or `.\deploy-defang.ps1` on Windows)

