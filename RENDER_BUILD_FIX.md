# Fix Render 502 Error - Pre-download HuggingFace Model

## Problem
The HuggingFace sentence-transformers model downloads during first request, blocking the server startup and causing 502 errors.

## Solution
Pre-download the model during the build phase.

## Steps in Render Dashboard

1. Go to https://dashboard.render.com
2. Select your backend service
3. Go to "Settings" tab
4. Find "Build Command" section
5. Update the build command to:

```bash
pip install -r requirements.txt && python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')"
```

Or if using uv:

```bash
uv sync && python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')"
```

6. Click "Save Changes"
7. Manually trigger a redeploy

## What this does
- Downloads the ~80MB model during build (not startup)
- Model is cached in the container
- Server starts immediately without blocking

## Alternative: Use render.yaml

Create `render.yaml` in your repo root:

```yaml
services:
  - type: web
    name: scholarmate-backend
    env: python
    buildCommand: uv sync && python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')"
    startCommand: uvicorn app.main:app --host 0.0.0.0 --port $PORT
    envVars:
      - key: DEBUG
        value: False
      - key: CORS_ORIGINS
        value: https://scholar-mate-nine.vercel.app,http://localhost:3000,http://localhost:8080
```

Then commit and push - Render will auto-detect and use this config.
