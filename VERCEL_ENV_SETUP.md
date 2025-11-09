# Vercel Environment Variables Setup

Quick reference for setting up environment variables in Vercel.

## Required Environment Variables

Copy these to your Vercel project settings:

### Google OAuth
```
GOOGLE_CLIENT_ID=325415234543-menqofjbigrju70tbi7oab4p5ath82lc.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=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
```

### Google Redirect URI
**⚠️ IMPORTANT**: Update this to your actual Vercel deployment URL
```
GOOGLE_REDIRECT_URI=https://your-app-name.vercel.app/auth/callback
```

### Backend API
**⚠️ IMPORTANT**: Update this to your actual backend URL
```
API_BASE_URL=https://your-backend-api.com
```
Or if using the same backend:
```
API_BASE_URL=http://192.168.0.101:8000
```

### Supabase
```
SUPABASE_URL=https://rqyzgfgdsedvohxyyqho.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxeXpnZmdkc2Vkdm9oeHl5cWhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwNTM5NzQsImV4cCI6MjA3NjYyOTk3NH0.mynXFTLHdzKg7Em2mfKXwNcRMPIsM9yv-7I9aWBkijE
```

## How to Add in Vercel Dashboard

1. Go to https://vercel.com/dashboard
2. Select your project
3. Click "Settings" tab
4. Click "Environment Variables" in the sidebar
5. For each variable:
   - Enter the **Name** (e.g., `GOOGLE_CLIENT_ID`)
   - Enter the **Value**
   - Select environments: **Production**, **Preview**, **Development**
   - Click "Add"

## Verification

After deployment, check the browser console:
- Should see: "Detected Vercel environment, fetching config from API..."
- Should see: "Successfully loaded config from Vercel API"

## Testing the API Endpoint

After deployment, test the config endpoint:
```bash
curl https://your-app-name.vercel.app/api/config
```

Should return:
```json
{
  "GOOGLE_CLIENT_ID": "325415234543-...",
  "GOOGLE_CLIENT_SECRET": "GOCSPX-...",
  "GOOGLE_REDIRECT_URI": "https://...",
  "API_BASE_URL": "https://...",
  "SUPABASE_URL": "https://...",
  "SUPABASE_ANON_KEY": "eyJhbGci..."
}
```

## Security Considerations

✅ **Safe to expose via API**:
- `GOOGLE_CLIENT_ID` (public by design)
- `SUPABASE_URL` (public by design)
- `SUPABASE_ANON_KEY` (public, protected by RLS)

⚠️ **Consider additional protection**:
- `GOOGLE_CLIENT_SECRET` - Only needed for server-side OAuth flows
- If concerned, add authentication to the `/api/config` endpoint

## Custom Domain Setup

If using a custom domain (e.g., `scholarmate.com`):

1. Add domain in Vercel dashboard
2. Update `GOOGLE_REDIRECT_URI`:
   ```
   GOOGLE_REDIRECT_URI=https://scholarmate.com/auth/callback
   ```
3. Update detection in `frontend/lib/services/config_service.dart`:
   ```dart
   return hostname.contains('vercel.app') || 
          hostname.contains('scholarmate.com');
   ```
4. Update Google OAuth redirect URIs in Google Cloud Console

## Troubleshooting

### "Could not load configuration" error
- Check that all environment variables are set in Vercel
- Verify the `/api/config` endpoint is accessible
- Check browser console for detailed error messages

### OAuth redirect mismatch
- Ensure `GOOGLE_REDIRECT_URI` matches your deployment URL
- Add the URL to Google Cloud Console authorized redirect URIs

### CORS errors
- The serverless function includes CORS headers
- If issues persist, check browser console for specific CORS errors
