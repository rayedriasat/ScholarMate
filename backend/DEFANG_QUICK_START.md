# Quick Start: Deploy to Defang.io

A 5-minute guide to deploy your FastAPI backend to Defang.io free tier.

## 1. Install Defang CLI

**Windows (PowerShell):**
```powershell
iwr https://s.defang.io/install.ps1 -useb | iex
```

**macOS/Linux:**
```bash
curl -fsSL https://s.defang.io/install.sh | sh
```

## 2. Navigate to Backend Directory

```bash
cd backend
```

## 3. Login to Defang

```bash
defang login
```

## 4. Set Required Secrets

```bash
# Generate encryption key first
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

# Set all required secrets
defang config set SUPABASE_URL="https://rqyzgfgdsedvohxyyqho.supabase.co"
defang config set SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxeXpnZmdkc2Vkdm9oeHl5cWhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwNTM5NzQsImV4cCI6MjA3NjYyOTk3NH0.mynXFTLHdzKg7Em2mfKXwNcRMPIsM9yv-7I9aWBkijE"
defang config set SUPABASE_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxeXpnZmdkc2Vkdm9oeHl5cWhvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTA1Mzk3NCwiZXhwIjoyMDc2NjI5OTc0fQ.bblUhTIRO0fjEkpqtHfJtRwWSn5TRZtdLA3Ov9pLopE
"
defang config set GOOGLE_CLIENT_ID="325415234543-menqofjbigrju70tbi7oab4p5ath82lc.apps.googleusercontent.com"
defang config set GOOGLE_CLIENT_SECRET="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"
defang config set PINECONE_API_KEY="pcsk_2in3nJ_EXqnUMyaUjGJfR6FpqLHXvqCgik5bcBENmrYrQ6bHVHXN8aKxUM5QYb9zxEVwJQ"
defang config set GROQ_API_KEY="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"
defang config set ENCRYPTION_KEY="bCEHyCVfwr0YFierwQoeoydXxiheidfajPIP4pDd_dE="

defang config set DEEPSEEK_API_KEY="yourdummykey"

defang config set HUGGINGFACE_TOKEN=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
```

## 5. Deploy!

**Option A: Use the deployment script**
```bash
# Linux/macOS
chmod +x deploy-defang.sh
./deploy-defang.sh

# Windows PowerShell
.\deploy-defang.ps1
```

**Option B: Manual deployment**
```bash
defang compose up
```

## 6. Get Your URL

```bash
defang compose ps
```

Your backend will be available at: `https://backend-xxxxx.defang.dev`

## 7. Test It

```bash
curl https://YOUR_URL.defang.dev/api/health
t5x3lhgha07h3-backend.prod2.defang.dev/api/health
```

You should see:
```json
{"status":"healthy","service":"scholarmate-backend"}
```

## 8. View Logs (Optional)

```bash
defang compose logs backend -f
```

## 9. Update Your Frontend

Update your Flutter app's API configuration to use the new Defang URL.

---

## Common Commands

```bash
# View status
defang compose ps

# View logs
defang compose logs backend

# Follow logs
defang compose logs backend -f

# Restart service
defang compose restart backend

# Stop service
defang compose down

# Redeploy (after code changes)
defang compose up
```

## Troubleshooting

### "defang: command not found"
- Restart your terminal after installation
- Or use the full path: `~/.defang/bin/defang` (Unix) or `$env:USERPROFILE\.defang\bin\defang` (Windows)

### Build fails
- Make sure Docker Desktop is running
- Check you're in the `backend` directory
- Verify all files exist: `ls -la` (Unix) or `dir` (Windows)

### Service won't start
- Check logs: `defang compose logs backend`
- Verify all secrets are set: `defang config list`
- Ensure environment variables are correct

### Out of memory
The free tier has limited memory. If you hit the limit:
```bash
defang config set EMBEDDING_BATCH_SIZE "2"
defang config set PDF_PAGE_BATCH_SIZE "1"
defang compose restart backend
```

---

## Need More Help?

See `DEFANG_DEPLOYMENT.md` for detailed documentation.

