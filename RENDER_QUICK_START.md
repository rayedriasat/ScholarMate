# Render Deployment - Quick Start

## 1. Push to GitHub
```bash
git add render.yaml RENDER_DEPLOYMENT.md
git commit -m "Add Render deployment"
git push
```

## 2. Deploy on Render
1. Go to https://dashboard.render.com/
2. Click **New +** → **Blueprint**
3. Connect your repo
4. Click **Apply**

## 3. Add Secrets (in Render dashboard)
```
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_anon_key
SUPABASE_SERVICE_KEY=your_service_key
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
ENCRYPTION_KEY=generate_with_fernet
```

Generate encryption key:
```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

## 4. Update Frontend
Add to Vercel environment variables:
```
BACKEND_URL=https://scholarmate-backend.onrender.com
```

## 5. Test
```bash
curl https://scholarmate-backend.onrender.com/api/health
```

Done! Your backend is live at `https://scholarmate-backend.onrender.com`

**Note:** Free tier spins down after 15 min inactivity. First request takes ~30-60s.
