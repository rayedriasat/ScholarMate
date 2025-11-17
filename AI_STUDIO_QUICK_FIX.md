# AI Studio Quick Fix Guide

## Problem
AI Studio tools fail with "No content found in selected files" but Chat works fine.

## Most Likely Cause
Files in your notebook workspace don't have proper Google Drive IDs linked.

## Quick Fix (Try This First)

### Step 1: Check Your Files
1. Open Notebook Studio
2. Go to **Files** tab
3. Look at your files - do you see them listed?

### Step 2: Check Logs
1. Open Developer Console (F12)
2. Go to AI Studio tab
3. Long press any tool (Quiz, Summary, etc.)
4. Look for this in console:
   ```
   🔵 Found X files in workspace
      📄 File: filename.pdf, DriveID: null  ← BAD!
   ```
   or
   ```
   🔵 Found X files in workspace
      📄 File: filename.pdf, DriveID: 1abc123...  ← GOOD!
   ```

### Step 3: If DriveID is null
Your files aren't properly linked to Drive. Here's how to fix:

1. **In Files tab:** Note which files you have
2. **Delete them** (they're not properly linked anyway)
3. **Click "Add from Drive"** button
4. **Select the SAME files** from your Drive
5. **Make sure these files are indexed** in the main app
6. **Try AI Studio again**

### Step 4: If DriveID looks good
The issue is elsewhere. Check:

1. **Are files indexed?**
   - Go to main app File Explorer
   - Find these files
   - Check if they show "Indexed" status
   - If not, wait for indexing to complete

2. **Are you using the right account?**
   - Sign out and sign back in
   - Try again

3. **Is backend running?**
   - Check backend console for errors
   - Make sure it's running on http://localhost:8000

## Detailed Debugging

If quick fix doesn't work, follow the detailed guide in `AI_STUDIO_NO_CONTENT_DEBUG.md`.

## Test After Fix

1. Go to AI Studio tab
2. Long press "Summarizer"
3. Should see:
   ```
   🔵 Found X files in workspace
   🔵 Actual file IDs being sent: [1abc..., 1def...]
   🔵 Calling API for summary generation with X file IDs...
   ```
4. Backend should show:
   ```
   🔍 Retrieving context with file_ids: ['1abc...']
   🔍 Retrieved X chunks  ← Should be > 0
   ```
5. Should succeed!

## Still Not Working?

Share these logs:

**Frontend (from browser console):**
```
🔵 Found X files in workspace
   📄 File: ..., DriveID: ...
🔵 Actual file IDs being sent: [...]
```

**Backend (from terminal):**
```
🔍 Retrieving context with file_ids: [...]
🔍 Retrieved X chunks
```

**Error message:**
```
Full error text from the dialog
```

Then we can dig deeper!
