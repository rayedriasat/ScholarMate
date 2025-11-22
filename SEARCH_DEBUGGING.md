# Search Debugging Guide

## Current Issues

1. **Exact text from files doesn't show 100% match**
2. **Non-existent text still shows results**

## Root Causes

### Issue 1: Filename Search
- Search is case-insensitive (correct)
- But may not be matching exact filenames properly
- Need to verify actual filenames in database

### Issue 2: Semantic False Positives
- Vector similarity can return "similar" content even if query words don't exist
- Fixed by requiring actual word presence in content

## Fixes Applied

### 1. Stricter Semantic Search
- Now requires at least 50% of query words to actually appear in content
- Ignores short words (≤2 chars) like "a", "is", "to"
- Minimum similarity threshold raised to 0.4 (from 0.3)

### 2. Better Logging
- Shows sample filenames
- Logs result counts by type
- Shows top 3 results with scores

## How to Debug

### Step 1: Check Backend Logs

When you search, look for these log lines:

```
INFO: Search query for user <id>: 'your query' (semantic: True/False)
INFO: Found X files for user
DEBUG: Sample filenames: ['file1.pdf', 'file2.pdf', ...]
INFO: Search completed: Y results (filename: A, semantic: B)
DEBUG: Result 1: filename.pdf (exact, 1.00)
DEBUG: Result 2: another.pdf (partial, 0.85)
```

### Step 2: Test Filename Search Only

1. **Disable semantic search** (uncheck "Include content search")
2. Search for exact filename (without extension)
3. Should show 100% match if file exists

**Example:**
- File: "Research Paper.pdf"
- Query: "research paper" → Should show EXACT match (100%)
- Query: "research" → Should show PARTIAL match (85-95%)

### Step 3: Test Semantic Search

1. **Enable semantic search**
2. Search for text you KNOW is in a document
3. Should show SEMANTIC match with page number

**Important:** Semantic search only works if:
- Documents are indexed (use Indexing UI)
- Text actually exists in the document
- At least 50% of query words are present

### Step 4: Verify Database

Check what files actually exist:

```bash
# In backend terminal
cd backend
uv run python
```

```python
from app.services.supabase_service import get_supabase_service

supabase = get_supabase_service()
# Replace with your user UUID
user_id = "your-uuid-here"

files = supabase.client.table("files").select("name").eq("user_id", user_id).limit(10).execute()
print("Your files:")
for f in files.data:
    print(f"  - {f['name']}")
```

## Common Problems

### Problem: "Exact filename doesn't show 100%"

**Check:**
1. Are you searching with the exact name (case doesn't matter)?
2. Are you including the file extension? (Don't - search without .pdf)
3. Is the file actually in your database?

**Example:**
- ✓ File: "Machine Learning.pdf", Query: "machine learning"
- ✓ File: "ML Research.pdf", Query: "ml research"
- ✗ File: "Machine Learning.pdf", Query: "machine learning.pdf" (don't include extension)

### Problem: "Non-existent text shows results"

**This should now be fixed.** If still happening:

1. Check if semantic search is enabled
2. Verify the text truly doesn't exist (check the PDF)
3. Look at backend logs - does it say the words are present?

**New behavior:**
- Query: "quantum physics" in a file about "machine learning"
- Old: Might show result (false positive)
- New: Won't show result (requires words to be present)

### Problem: "No results for text I know exists"

**Possible causes:**
1. Document not indexed (check Indexing UI)
2. Semantic search disabled
3. Text is in an image (OCR not run)
4. Query words too short (≤2 chars ignored)

**Solutions:**
1. Index the document first
2. Enable "Include content search"
3. Run OCR on the PDF
4. Use longer, more specific words

## Testing Checklist

Test these scenarios:

### Filename Search (Semantic OFF)
- [ ] Exact filename → 100% match
- [ ] Partial filename → 85-95% match
- [ ] Word from filename → 65-85% match
- [ ] Non-existent text → 0 results ✓

### Content Search (Semantic ON)
- [ ] Text that exists → Shows with page number
- [ ] Text that doesn't exist → 0 results ✓
- [ ] Partial words → May show if similar
- [ ] Very short query (1-2 chars) → Limited results

### Edge Cases
- [ ] Empty query → 0 results
- [ ] Special characters → Handled gracefully
- [ ] Very long query → Works
- [ ] Numbers → Works

## Expected Behavior

### Good Search Results

**Query: "research"**
```
Results:
1. Research Paper.pdf (EXACT, 100%) - filename match
2. My Research.pdf (PARTIAL, 90%) - filename match
3. Study on Research Methods.pdf (PARTIAL, 75%) - filename match
4. Introduction.pdf (SEMANTIC, 65%) - content contains "research"
```

**Query: "machine learning"**
```
Results:
1. Machine Learning.pdf (EXACT, 100%) - filename match
2. ML Basics.pdf (SEMANTIC, 70%) - content about ML
3. AI Research.pdf (SEMANTIC, 60%) - mentions ML
```

### Bad Search Results (Should NOT happen)

**Query: "quantum physics"** (when no files mention it)
```
Results: 0 results ✓
```

NOT:
```
Results:
1. Machine Learning.pdf (SEMANTIC, 45%) ✗ WRONG
```

## Still Having Issues?

1. **Restart backend** to ensure latest code is loaded
2. **Check backend logs** for actual search behavior
3. **Verify files exist** in database
4. **Test with semantic search OFF** first
5. **Share backend logs** showing the search query and results

## Quick Fix Commands

```bash
# Restart backend
cd backend
# Stop with Ctrl+C
uv run python run.py

# Check logs
# Look for lines starting with:
# INFO: Search query
# DEBUG: Sample filenames
# INFO: Search completed
```
