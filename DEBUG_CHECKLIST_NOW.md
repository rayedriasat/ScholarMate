# Debug Checklist - Do This Now

## Step 1: Restart Backend (CRITICAL)
The error message format shows you're running old code.

```bash
# Stop backend (Ctrl+C)
# Then restart:
cd backend
uv run python run.py
```

Wait for: `INFO:     Uvicorn running on http://127.0.0.1:8000`

## Step 2: Hot Reload Frontend
In your Flutter app, press `r` in the terminal or click the hot reload button.

## Step 3: Open Browser Console
Press `F12` to open Developer Tools, go to Console tab.

## Step 4: Try AI Studio Again
1. Go to Notebook Studio
2. Click AI Studio tab
3. Long press "Summarizer" (or any tool)
4. Watch BOTH consoles

## Step 5: Collect Logs

### Frontend Console Should Show:
```
============================================================
🔵 AI STUDIO GENERATION DEBUG
============================================================
🔵 Tool: summary
🔵 User ID: ...
🔵 Folder ID: ...
🔵 Found X files in workspace
   📄 File: filename.pdf, DriveID: 1abc123...
🔵 File IDs with Drive links: X
🔵 Actual file IDs being sent: [1abc123..., 1def456...]
🔵 Calling API for summary generation with X file IDs...
🔵 Generating summary with X files...
🔵 File IDs: [1abc123..., 1def456...]
```

### Backend Terminal Should Show:
```
INFO:     127.0.0.1:XXXXX - "POST /api/notebook-ai/generate-summary HTTP/1.1" 200 OK
Generating summary for user ...
🔍 Retrieving context with file_ids: ['1abc123...', '1def456...']
🔍 Retrieved X chunks
```

## Step 6: Analyze Results

### Scenario A: Frontend shows "DriveID: null"
**Problem:** Files not linked to Drive
**Solution:** 
1. Go to Files tab
2. Delete files
3. Click "Add from Drive"
4. Select files that are already indexed in main app

### Scenario B: Backend shows "Retrieved 0 chunks"
**Problem:** Files not indexed in Pinecone
**Solution:**
1. Go to main app File Explorer
2. Find these files (use the Drive IDs from frontend logs)
3. Check if they're indexed
4. If not, wait for indexing or trigger it manually

### Scenario C: Everything looks good but still fails
**Problem:** Deeper issue
**Solution:** Share the logs (see below)

### Scenario D: It works!
**Problem:** Was just a stale code issue
**Solution:** Celebrate! 🎉

## Step 7: If Still Failing

Share these exact logs:

**Frontend (from browser console):**
```
[Paste the entire debug output from Step 5]
```

**Backend (from terminal):**
```
[Paste the entire output from Step 5]
```

**Error Dialog:**
```
[Paste the full error message]
```

## Quick Verification

Before trying AI Studio, verify Chat still works:
1. Go to Chat tab
2. Send message: "What is this about?"
3. Does it work? ✅ or ❌

If Chat works but AI Studio doesn't, and both show the same file IDs in logs, then we have a backend routing issue.

## Common Mistakes

❌ Not restarting backend after code changes
❌ Not checking browser console
❌ Not checking backend terminal
❌ Trying with files that aren't indexed
❌ Using files without Drive IDs

✅ Restart backend
✅ Check both consoles
✅ Use files that work in Chat
✅ Share complete logs if still failing
