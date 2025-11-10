# HuggingFace Token Setup Guide

## Problem
You're getting rate-limited by HuggingFace when trying to download the sentence-transformers model:

```
429 Client Error: Too Many Requests for url: https://huggingface.co/api/models/sentence-transformers/all-MiniLM-L6-v2/...
We had to rate limit your IP. To continue using our service, create a HF account or login to your existing account, and make sure you pass a HF_TOKEN if you're using the API.
```

## Solution
The fix is to authenticate with HuggingFace using a token. I've updated the code to support this.

## Step-by-Step Instructions

### 1. Get a HuggingFace Token

1. Go to [HuggingFace](https://huggingface.co/)
2. Create an account or sign in if you already have one
3. Go to your [Token Settings](https://huggingface.co/settings/tokens)
4. Click **"Create new token"**
5. Choose:
   - **Name**: `ScholarMate`
   - **Type**: `Read` (this is sufficient for downloading models)
6. Click **"Create token"**
7. **IMPORTANT**: Copy the token immediately - you won't be able to see it again!

### 2. Add Token to Your Environment

#### Option A: Local Development (backend/.env file)

1. Navigate to your backend directory:
   ```bash
   cd backend
   ```

2. Create or edit the `.env` file:
   ```bash
   # On Windows PowerShell
   notepad .env
   
   # On Windows Command Prompt
   notepad .env
   
   # On Linux/Mac
   nano .env
   ```

3. Add the following line (replace `your_token_here` with your actual token):
   ```bash
   HUGGINGFACE_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

4. Save the file

#### Option B: Deployment (Render, Vercel, etc.)

1. Go to your deployment platform's dashboard
2. Navigate to your project's environment variables
3. Add a new environment variable:
   - **Key**: `HUGGINGFACE_TOKEN`
   - **Value**: Your HuggingFace token (starts with `hf_`)
4. Save and redeploy your service

### 3. Restart Your Backend Server

After adding the token:

```bash
# Stop your backend server (Ctrl+C if running)

# Restart it
cd backend
python run.py
# or
./start.sh
```

### 4. Verify the Fix

You should now see this in your logs when embeddings are loaded:
```
Using HuggingFace token for authentication
HuggingFace embeddings loaded successfully
```

Instead of the warning:
```
No HuggingFace token found - you may hit rate limits
```

## What Changed

I've updated the following files:

1. **`backend.env.template`** - Added `HUGGINGFACE_TOKEN` configuration
2. **`backend/app/services/rag_indexer.py`** - Updated to use HF token when loading embeddings
3. **`backend/app/services/rag_query_service.py`** - Updated to use HF token when loading embeddings

## Benefits of Using a Token

✅ **No rate limiting** - Authenticated requests have much higher limits
✅ **Access to gated models** - Some models require authentication
✅ **Better performance** - Priority access to HuggingFace's infrastructure
✅ **Free** - Read tokens are completely free

## Alternative: Use Local Model

If you don't want to use HuggingFace tokens, you can use the local model that's already in your repository:

The model is already downloaded at `backend/models/all-MiniLM-L6-v2/`. The code automatically uses this if it exists, so you shouldn't need to download it again. However, the initial connection to HuggingFace to verify the model might still trigger rate limiting.

Using a token is the **recommended solution** as it completely eliminates the rate limiting issue.

## Troubleshooting

### Token Not Working

1. Make sure your token starts with `hf_`
2. Verify there are no spaces before or after the token
3. Check that the token has "Read" permissions
4. Make sure you've restarted your backend server

### Still Getting Rate Limited

1. Wait 10-15 minutes before trying again
2. Clear your pip/HuggingFace cache:
   ```bash
   rm -rf ~/.cache/huggingface/
   ```
3. Verify the token is being loaded:
   - Check your logs for "Using HuggingFace token for authentication"
   - If you see the warning message instead, the token isn't loaded correctly

### Environment Variable Not Loading

1. Make sure your `.env` file is in the `backend/` directory (not the root)
2. Verify the file is named exactly `.env` (not `env.txt` or `.env.txt`)
3. Check for typos in the variable name: `HUGGINGFACE_TOKEN` (not `HUGGING_FACE_TOKEN` or `HF_TOKEN`)

## Security Note

🔒 **NEVER commit your `.env` file or tokens to Git!**

The `.env` file is already in `.gitignore`, but always double-check before committing:

```bash
git status
```

Make sure `.env` doesn't appear in the list of files to be committed.

