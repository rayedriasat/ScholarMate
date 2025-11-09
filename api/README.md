# Vercel Serverless Functions

This directory contains Vercel serverless functions for the ScholarMate web deployment.

## Functions

### `/api/config` - Configuration Endpoint

**Purpose**: Provides environment variables to the Flutter web app when deployed on Vercel.

**File**: `config.js`

**Method**: `GET`

**Response**:
```json
{
  "GOOGLE_CLIENT_ID": "...",
  "GOOGLE_CLIENT_SECRET": "...",
  "GOOGLE_REDIRECT_URI": "...",
  "API_BASE_URL": "...",
  "SUPABASE_URL": "...",
  "SUPABASE_ANON_KEY": "..."
}
```

**CORS**: Enabled for all origins (can be restricted if needed)

**Security**: 
- Environment variables are read from Vercel's secure storage
- Never exposed in client-side bundle
- Consider adding authentication for production use

## Local Testing

Test the function locally using Vercel CLI:

```bash
# Install Vercel CLI
npm install -g vercel

# Run local dev server
vercel dev

# Test the endpoint
curl http://localhost:3000/api/config
```

## Adding New Functions

To add a new serverless function:

1. Create a new `.js` file in this directory (e.g., `api/hello.js`)
2. Export a default handler function:
   ```javascript
   export default function handler(req, res) {
     res.status(200).json({ message: 'Hello World' });
   }
   ```
3. Access at `/api/hello`

## Environment Variables

Set environment variables in Vercel dashboard:
- Project Settings → Environment Variables
- Add for Production, Preview, and Development environments

## Documentation

See `VERCEL_DEPLOYMENT.md` for complete deployment guide.
