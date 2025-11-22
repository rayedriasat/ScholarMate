# Advanced Search - Quick Start Guide

## Setup (5 minutes)

### 1. Backend Setup

The search feature uses existing services, no additional setup needed!

**Verify configuration:**
```bash
cd backend
cat .env
```

Ensure these are set:
- `PINECONE_API_KEY` ✓
- `SUPABASE_URL` ✓
- `GROQ_API_KEY` ✓

### 2. Start Backend

```bash
cd backend
uv run python run.py
```

Backend will be available at `http://localhost:8000`

### 3. Frontend Setup

No additional setup needed! Search is automatically available.

**Run frontend:**
```bash
cd frontend
flutter run -d chrome
# or
flutter run -d windows
```

## Using Advanced Search

### Access Search

1. Open ScholarMate app
2. Go to **Files** tab
3. Tap the **🔍 Search** icon in the top bar

### Perform a Search

1. **Enter query** in search box
   - Single word: `"research"`
   - Phrase: `"machine learning"`
   - Multiple words: `"neural networks deep learning"`

2. **Toggle options**
   - ☑️ Include content search (semantic)
   - ☐ Filename only (faster)

3. **Tap Search** or press Enter

### Understanding Results

**Match Types:**
- 🟢 **EXACT** - Perfect filename match (100%)
- 🔵 **PARTIAL** - Query in filename (70-95%)
- 🟣 **SEMANTIC** - Content match (30-80%)
- 🟠 **FUZZY** - Word matches (40-70%)

**Result Card Shows:**
- File name and icon
- Match type badge
- Relevance score (progress bar)
- Page number (for content matches)
- Content snippet
- File size and date

### Open a Result

Tap any result card to open the file in PDF Viewer.

## Search Examples

### Example 1: Find by Filename

**Query:** `"research paper"`

**Result:**
- ✓ "Research Paper 2024.pdf" - EXACT match
- ✓ "My Research Paper.pdf" - PARTIAL match
- ✓ "Paper on Research Methods.pdf" - FUZZY match

### Example 2: Find by Content

**Query:** `"what is machine learning"`

**Enable:** ☑️ Include content search

**Result:**
- ✓ "Introduction to ML.pdf" - Page 5 - SEMANTIC match
- ✓ "Machine Learning Basics.pdf" - Page 1 - SEMANTIC match

### Example 3: Combined Search

**Query:** `"neural"`

**Result:**
- ✓ "Neural Networks.pdf" - PARTIAL (filename)
- ✓ "Deep Learning.pdf" - SEMANTIC (content mentions "neural")

## Tips for Best Results

### Filename Search (Fast)

- Disable "Include content search"
- Use exact or partial filenames
- Great for quick file lookup

**Example:** `"report"` finds all files with "report" in name

### Content Search (Comprehensive)

- Enable "Include content search"
- Use natural language queries
- Searches inside documents

**Example:** `"how does photosynthesis work"` finds relevant content

### Fuzzy Search

- Use multiple keywords
- Finds files matching any word

**Example:** `"ml ai research"` finds files with any of these terms

## Troubleshooting

### No Results Found

**Problem:** Search returns 0 results

**Solutions:**
1. Check if files are indexed (Indexing UI)
2. Try simpler query (single word)
3. Enable content search
4. Verify files exist in Files tab

### Slow Search

**Problem:** Search takes >5 seconds

**Solutions:**
1. Disable content search (filename only)
2. Check internet connection
3. Reduce max results (backend config)

### Content Not Searchable

**Problem:** Semantic search finds nothing

**Solutions:**
1. Index documents first (Indexing UI)
2. Wait for indexing to complete
3. Verify Pinecone API key is valid
4. Check backend logs for errors

## Testing

### Quick Test

1. **Upload a test PDF** with known content
2. **Index it** (Indexing UI → Index All)
3. **Wait** for indexing to complete
4. **Search** for content you know is in the PDF
5. **Verify** result appears with correct page

### Backend Test

```bash
cd backend
uv run python test_search.py
```

Set `TEST_USER_ID` in `.env` first.

## Performance

**Expected Speed:**
- Filename search: < 100ms
- Content search: 200-600ms
- Combined: 300-700ms

**Factors:**
- Number of files
- Network latency
- Pinecone index size

## Next Steps

### Explore Features

- Try different query types
- Compare filename vs content search
- Check relevance scores
- Open results in PDF Viewer

### Advanced Usage

- Search within specific folders (coming soon)
- Use filters (coming soon)
- Save searches (coming soon)

### Related Features

- **RAG Chat**: Ask questions about search results
- **Indexing**: Manage document indexing
- **Tags**: Organize files for easier search

## API Usage (Developers)

### Direct API Call

```bash
curl -X POST http://localhost:8000/api/search/ \
  -H "Content-Type: application/json" \
  -d '{
    "query": "machine learning",
    "user_id": "your-user-uuid",
    "max_results": 20,
    "include_semantic": true
  }'
```

### Response

```json
{
  "results": [...],
  "total_count": 15,
  "query": "machine learning",
  "search_time_ms": 245
}
```

## Support

**Need Help?**
1. Check `ADVANCED_SEARCH_FEATURE.md` for details
2. Review backend logs: `uv run python run.py`
3. Test with `backend/test_search.py`
4. Verify indexing status

**Common Issues:**
- Files not indexed → Use Indexing UI
- No API key → Check `.env` file
- Backend not running → Start with `uv run python run.py`
- Network error → Check internet connection

---

**Ready to search!** 🔍

Open the app, tap the search icon, and start finding your documents.
