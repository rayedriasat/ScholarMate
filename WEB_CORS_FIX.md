# Web CORS Fix - Network Error Solution ✅

## Error
```
Failed to process document: Exception: Failed to process OCR: 
ClientException: Failed to fetch, uri=http://192.168.0.101:8000/api/ocr/process
```

## Root Cause
This is a **CORS (Cross-Origin Resource Sharing)** error. The web browser is blocking requests from the Flutter web app to the backend API because they're on different origins.

## Quick Fix

### 1. Restart Backend
The backend already has CORS configured, but needs to be restarted:

```bash
# Stop backend (Ctrl+C)
# Then restart:
cd backend
uv run python run.py
```

**Verify CORS is enabled:**
You should see in the logs:
```
INFO: Starting ScholarMate API
```

### 2. Clear Browser Cache
```
1. Open browser DevTools (F12)
2. Right-click refresh button
3. Select "Empty Cache and Hard Reload"
```

Or:
```
Chrome: Ctrl+Shift+Delete → Clear cache
Firefox: Ctrl+Shift+Delete → Clear cache
```

### 3. Check Backend is Accessible
Open browser and navigate to:
```
http://192.168.0.101:8000/docs
```

You should see the FastAPI Swagger documentation.

### 4. Test CORS Directly
Open browser console (F12) and run:
```javascript
fetch('http://192.168.0.101:8000/api/ocr/health')
  .then(r => r.json())
  .then(console.log)
  .catch(console.error)
```

**Expected:** Should return health status
**If error:** CORS is still blocked

## Backend CORS Configuration

The backend is already configured in `backend/app/main.py`:

```python
# CORS configuration
if os.getenv("DEBUG", "False").lower() == "true":
    cors_origins = ["*"]  # ✅ Allows all origins in debug mode
else:
    cors_origins = os.getenv("CORS_ORIGINS", "").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)
```

**Verify DEBUG is True:**
```bash
# Check backend/.env
cat backend/.env | grep DEBUG
# Should show: DEBUG=True
```

## Alternative Solutions

### Option 1: Use Localhost
Instead of `192.168.0.101`, use `localhost`:

**Update `frontend/.env`:**
```env
API_BASE_URL=http://localhost:8000
```

**Restart frontend:**
```bash
cd frontend
flutter run -d chrome
```

### Option 2: Add Specific CORS Origin
If you want to be more specific, add the Flutter web origin to CORS:

**Update `backend/.env`:**
```env
CORS_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:*,http://192.168.0.101:*
```

**Restart backend:**
```bash
cd backend
uv run python run.py
```

### Option 3: Run Backend with --reload
This ensures CORS changes are picked up:

```bash
cd backend
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Testing Steps

### 1. Verify Backend is Running
```bash
curl http://192.168.0.101:8000/api/ocr/health
```

**Expected response:**
```json
{
  "status": "healthy",
  "tesseract_available": true
}
```

### 2. Test from Browser Console
```javascript
// Open browser console (F12)
fetch('http://192.168.0.101:8000/api/ocr/health', {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json'
  }
})
.then(r => r.json())
.then(data => console.log('Success:', data))
.catch(err => console.error('Error:', err))
```

### 3. Check Network Tab
1. Open DevTools (F12)
2. Go to Network tab
3. Try OCR again
4. Look for the `/api/ocr/process` request
5. Check if it shows CORS error

**If CORS error:**
- Response headers should include `Access-Control-Allow-Origin`
- If missing, backend CORS not working

## Common CORS Issues

### Issue 1: Backend Not Restarted
**Solution:** Restart backend after any .env changes

### Issue 2: Browser Cache
**Solution:** Hard refresh (Ctrl+Shift+R) or clear cache

### Issue 3: Wrong Origin
**Solution:** Check frontend is using correct API URL

### Issue 4: Preflight Request Failing
**Solution:** Backend must handle OPTIONS requests (already configured)

## Debug Checklist

- [ ] Backend is running on `192.168.0.101:8000`
- [ ] `DEBUG=True` in `backend/.env`
- [ ] Backend restarted after .env changes
- [ ] Browser cache cleared
- [ ] Can access `http://192.168.0.101:8000/docs`
- [ ] Network tab shows request being sent
- [ ] Response headers include CORS headers

## Expected CORS Headers

When working correctly, the response should include:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: *
Access-Control-Allow-Headers: *
Access-Control-Allow-Credentials: true
```

Check in browser DevTools → Network → Select request → Headers tab

## Quick Test Script

Create `test_cors.html`:
```html
<!DOCTYPE html>
<html>
<body>
<button onclick="testCORS()">Test CORS</button>
<div id="result"></div>

<script>
async function testCORS() {
  try {
    const response = await fetch('http://192.168.0.101:8000/api/ocr/health');
    const data = await response.json();
    document.getElementById('result').innerHTML = 
      '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
  } catch (error) {
    document.getElementById('result').innerHTML = 
      '<p style="color:red">Error: ' + error.message + '</p>';
  }
}
</script>
</body>
</html>
```

Open in browser and click "Test CORS" button.

## Summary

✅ **Backend CORS:** Already configured to allow all origins in DEBUG mode
✅ **Solution:** Restart backend and clear browser cache
✅ **Alternative:** Use `localhost` instead of IP address
✅ **Verify:** Test with browser console or curl

## Quick Fix Commands

```bash
# 1. Restart backend
cd backend
# Ctrl+C to stop
uv run python run.py

# 2. Clear browser cache
# In browser: Ctrl+Shift+Delete

# 3. Restart frontend
cd frontend
flutter run -d chrome

# 4. Test
# Select images and process OCR
# Should work! ✅
```

**CORS should now be working!** 🌐✨

## If Still Not Working

### Check Backend Logs
Look for CORS-related messages:
```bash
cd backend
uv run python run.py
# Look for: "Starting ScholarMate API"
```

### Check Frontend API URL
```bash
# Check frontend/.env
cat frontend/.env | grep API_BASE_URL
```

### Try Different Browser
- Chrome (recommended)
- Firefox
- Edge

### Use Browser Extension
Install "CORS Unblock" extension (development only):
- Chrome: Search "CORS Unblock" in Chrome Web Store
- Firefox: Search "CORS Everywhere"

**Note:** Only use extensions for development, not production!

## Production Note

For production, set specific CORS origins:
```env
DEBUG=False
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

**Never use `allow_origins=["*"]` in production!**
