# AI Studio Tools - Troubleshooting Guide

## Common Issues and Solutions

### Issue 1: "No files in workspace" Error

**Symptoms:**
- Error message when trying to generate content
- Says "No files with Drive links found"

**Solution:**
1. Go to **Files tab** in the workspace
2. Click **"Add from Drive"** button
3. Select files from your Drive
4. Make sure files are **indexed** (check in main app)
5. Try generation again

**Why this happens:**
- AI tools need indexed files to generate content
- Files must be linked to Drive (have `driveFileId`)
- Empty workspaces can't generate content

---

### Issue 2: "Failed to generate [tool]" Error

**Symptoms:**
- Loading dialog appears then error
- Says "generation failed"

**Possible Causes & Solutions:**

#### A. Files Not Indexed
**Check:**
```
Main App → Files Tab → Look for "Indexed" status
```

**Fix:**
1. Go to main Files screen
2. Find your files
3. Wait for indexing to complete
4. Green "Indexed" badge should appear
5. Try generation again

#### B. API Key Not Configured
**Check:**
```
Settings → API Key Management → Check if key exists
```

**Fix:**
1. Go to Settings
2. Tap "API Key Management"
3. Add API key for any provider:
   - OpenRouter (recommended)
   - OpenAI
   - Claude
   - Gemini
4. Verify key is validated
5. Try generation again

#### C. Backend Not Running
**Check:**
```
Terminal: Should see "Uvicorn running on http://0.0.0.0:8000"
```

**Fix:**
```bash
cd backend
uv run python run.py
```

Wait for:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete
```

#### D. Network Connection
**Check:**
- WiFi/mobile data enabled
- Can access other online features

**Fix:**
1. Check internet connection
2. Try opening a website
3. Reconnect if needed
4. Try generation again

---

### Issue 3: Backend Errors (500, 503, etc.)

**Symptoms:**
- Error mentions status code
- Backend logs show errors

**Solutions:**

#### Check Backend Logs
```bash
# Look for errors in terminal where backend is running
# Common errors:

# 1. Missing API key
ERROR: GROQ_API_KEY is required
→ Add to backend/.env file

# 2. Pinecone error
ERROR: Failed to connect to Pinecone
→ Check PINECONE_API_KEY in .env

# 3. No embeddings found
ERROR: No relevant context found
→ Files not indexed properly
```

#### Restart Backend
```bash
# Stop backend (Ctrl+C)
# Start again
cd backend
uv run python run.py
```

---

### Issue 4: Content Not Displaying Properly

**Symptoms:**
- Generated content shows but looks wrong
- JSON parsing errors
- Missing fields

**Solutions:**

#### A. Corrupted Data
1. Delete the generated item
2. Generate again
3. Should work on retry

#### B. Old Format
1. If using old generated content
2. Delete and regenerate
3. New format will be used

---

### Issue 5: Slow Generation

**Symptoms:**
- Takes longer than 30 seconds
- Seems stuck

**Normal Times:**
- Quiz: 10-20 seconds
- Summary: 15-30 seconds
- Flashcards: 10-20 seconds

**If Slower:**
1. **Large files** - More content = longer time
2. **Many files** - More files = longer time
3. **Slow AI provider** - Try different provider
4. **Network latency** - Check connection speed

**What to do:**
- Wait up to 60 seconds
- Check backend logs for progress
- If timeout, try with fewer files

---

## Debug Mode

### Enable Debug Logging

The app now has detailed debug logging. Check console output:

```
🔵 Starting generation for tool: quiz
🔵 User ID: abc123...
🔵 Found 3 files in workspace
🔵 File IDs with Drive links: 3
🔵 Calling API for quiz generation...
🔵 Generating quiz...
🟢 Quiz API response received
🔵 Saving quiz to database...
🟢 Quiz saved successfully
```

### Error Indicators
```
🔴 Quiz generation error: [details]
🔴 Stack trace: [trace]
```

### How to View Logs

**Android Studio / VS Code:**
- Check Debug Console
- Filter by "🔵" or "🔴"

**Command Line:**
```bash
flutter run
# Watch console output
```

---

## Step-by-Step Verification

### Before Using AI Studio

#### 1. Verify Backend
```bash
cd backend
uv run python run.py

# Should see:
✓ INFO: Application startup complete
✓ INFO: Uvicorn running on http://0.0.0.0:8000
```

#### 2. Verify API Key
```
App → Settings → API Key Management
✓ At least one key configured
✓ Key shows "Validated" status
```

#### 3. Verify Files Indexed
```
App → Files Tab
✓ Upload some PDFs
✓ Wait for indexing
✓ See "Indexed" badge
```

#### 4. Create Workspace
```
Notebook Studio → New Workspace
✓ Give it a name
✓ Create successfully
```

#### 5. Add Files
```
Workspace → Files Tab → Add from Drive
✓ Select indexed files
✓ Files appear in list
✓ File count updates
```

#### 6. Test Chat First
```
Workspace → Chat Tab
✓ Type a question
✓ Get AI response
✓ See citations

If chat works, AI Studio should work too!
```

#### 7. Generate Content
```
Workspace → AI Studio Tab
✓ Long press any tool
✓ Wait for generation
✓ See success message
✓ Content appears in list
```

---

## Common Error Messages

### "No files with Drive links found"
**Meaning:** Workspace has no files OR files don't have Drive IDs
**Fix:** Add files using "Add from Drive" button

### "Failed to generate quiz: ApiException"
**Meaning:** Backend API call failed
**Fix:** Check backend is running, API key configured

### "Failed to generate quiz: No relevant context found"
**Meaning:** Files not indexed or no content extracted
**Fix:** Re-index files in main app

### "Failed to generate quiz: Rate limit exceeded"
**Meaning:** Too many API calls
**Fix:** Wait a few minutes, try again

### "Failed to generate quiz: Network error"
**Meaning:** Can't reach backend
**Fix:** Check internet, verify backend running

---

## Testing Each Tool

### Test Quiz Generator

1. **Setup:**
   - Add 2-3 PDF files to workspace
   - Ensure files are indexed

2. **Generate:**
   - Long press "Quiz Generator"
   - Wait 10-20 seconds
   - Should see success message

3. **Verify:**
   - Quiz appears in list
   - Tap to view
   - Should see 5 questions
   - Each has 4 options
   - Correct answer highlighted
   - Explanation shown

4. **If fails:**
   - Check debug logs
   - Verify files indexed
   - Check API key
   - Try with different files

### Test Summarizer

1. **Setup:**
   - Same as quiz

2. **Generate:**
   - Long press "Summarizer"
   - Wait 15-30 seconds

3. **Verify:**
   - Summary appears in list
   - Tap to view
   - Should see full summary text
   - Should see key points list

4. **If fails:**
   - Same troubleshooting as quiz

### Test Flashcard Creator

1. **Setup:**
   - Same as quiz

2. **Generate:**
   - Long press "Flashcard Creator"
   - Wait 10-20 seconds

3. **Verify:**
   - Flashcards appear in list
   - Tap to view
   - Should see 10 cards
   - Each has front and back
   - Color-coded (blue/green)

4. **If fails:**
   - Same troubleshooting as quiz

---

## Backend Verification

### Test Backend Directly

#### 1. Health Check
```bash
curl http://localhost:8000/api/health
# Should return: {"status":"healthy"}
```

#### 2. Test Quiz Endpoint
```bash
curl -X POST http://localhost:8000/api/notebook-ai/generate-quiz \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user",
    "file_ids": ["file-id-1"],
    "num_questions": 2
  }'
```

**Expected:** JSON with questions array

**If error:** Check backend logs for details

---

## Environment Variables

### Backend .env File

Required variables:
```bash
# AI Provider
GROQ_API_KEY=your_groq_key_here

# Vector Database
PINECONE_API_KEY=your_pinecone_key
PINECONE_INDEX_NAME=your_index_name

# Optional but recommended
HUGGINGFACEHUB_API_TOKEN=your_hf_token

# Database
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key
```

### Verify Environment
```bash
cd backend
cat .env
# Check all required keys are present
```

---

## Getting Help

### Information to Provide

When reporting issues, include:

1. **Error message** (full text)
2. **Debug logs** (console output)
3. **Steps taken** (what you did)
4. **Environment:**
   - Device (Android/iOS/Web/Windows)
   - App version
   - Backend running? (yes/no)
5. **Files:**
   - How many files in workspace?
   - Are they indexed?
6. **API Key:**
   - Provider used?
   - Key validated?

### Where to Check

1. **App Console** - Debug logs
2. **Backend Terminal** - API errors
3. **Network Tab** - API calls (if using browser)
4. **Database** - Check if data saved

---

## Quick Fixes Checklist

Before asking for help, try:

- [ ] Backend is running
- [ ] API key is configured
- [ ] Files are indexed
- [ ] Files added to workspace
- [ ] Internet connection working
- [ ] Tried restarting backend
- [ ] Tried restarting app
- [ ] Checked debug logs
- [ ] Waited full generation time (30+ sec)
- [ ] Tried with different files
- [ ] Tried different tool

---

## Success Indicators

### Everything Working:

```
✅ Backend running (port 8000)
✅ API key validated
✅ Files indexed
✅ Files in workspace
✅ Chat works
✅ Quiz generates (10-20 sec)
✅ Summary generates (15-30 sec)
✅ Flashcards generate (10-20 sec)
✅ Content displays properly
✅ No error messages
```

### If All Above ✅:
**AI Studio is working perfectly!** 🎉

---

## Contact & Support

- Check documentation files
- Review error logs
- Test with minimal setup (1-2 files)
- Try different AI provider
- Restart everything (backend + app)

**Most issues are resolved by:**
1. Ensuring files are indexed
2. Configuring API key
3. Running backend
4. Waiting full generation time
