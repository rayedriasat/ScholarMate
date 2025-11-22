# Advanced Search Feature

## Overview

The Advanced Search system provides multi-dimensional search across file names, PDF content, and markdown documents with intelligent ranking and relevance scoring.

## Features

### Search Dimensions

1. **File Name Search**
   - **Exact Match**: Complete filename matches (highest priority, 100% relevance)
   - **Partial Match**: Query appears within filename (70-95% relevance)
   - **Fuzzy Match**: Individual words match (40-70% relevance)

2. **Content Search** (Semantic)
   - Searches within PDF and document content using vector embeddings
   - Uses Pinecone vector database for semantic similarity
   - Relevance scored 30-80% (below filename matches)

### Result Ranking

Results are automatically ranked by relevance score:
- Exact filename matches: 100%
- Partial filename matches: 70-95%
- Fuzzy filename matches: 40-70%
- Semantic content matches: 30-80%

### Deduplication

When a file matches in multiple ways (e.g., both filename and content), only the highest-scoring match is shown.

## Architecture

### Backend Components

**Search Service** (`backend/app/services/search_service.py`)
- Multi-dimensional search logic
- Filename matching (exact, partial, fuzzy)
- Semantic search via Pinecone
- Result ranking and deduplication

**Search Router** (`backend/app/routers/search.py`)
- REST API endpoint: `POST /api/search/`
- Request validation
- Response formatting

**Search Models** (`backend/app/models/search.py`)
- `SearchRequest`: Query parameters
- `SearchResultItem`: Individual result
- `SearchResponse`: Complete response with metadata

### Frontend Components

**Search Service** (`frontend/lib/services/search_service.dart`)
- API communication
- State management
- Result caching

**Search Screen** (`frontend/lib/screens/advanced_search_screen.dart`)
- Search UI with query input
- Toggle for semantic search
- Ranked results display
- Result cards with metadata

## API Reference

### Search Endpoint

**POST** `/api/search/`

**Request Body:**
```json
{
  "query": "machine learning",
  "user_id": "user-uuid",
  "max_results": 20,
  "include_semantic": true
}
```

**Response:**
```json
{
  "results": [
    {
      "file_id": "file-123",
      "file_name": "Machine Learning Research.pdf",
      "match_type": "exact",
      "relevance_score": 1.0,
      "snippet": "Introduction to machine learning...",
      "page_number": 5,
      "match_context": "content",
      "file_size": 2048576,
      "modified_time": "2024-01-15T10:30:00Z",
      "mime_type": "application/pdf"
    }
  ],
  "total_count": 15,
  "query": "machine learning",
  "search_time_ms": 245
}
```

## Usage

### From File Explorer

1. Open the Files tab
2. Tap the search icon (🔍) in the app bar
3. Enter your search query
4. Toggle "Include content search" for semantic search
5. Tap "Search" or press Enter

### Search Tips

**For Best Results:**
- Use specific keywords for filename searches
- Enable content search for semantic matching
- Use phrases for more precise content matches
- Combine multiple words for fuzzy matching

**Examples:**
- `"research paper"` - Finds files with both words
- `"neural networks"` - Semantic search in content
- `"intro"` - Partial match in filenames
- `"ml ai"` - Fuzzy match for multiple terms

## UI Features

### Result Cards

Each result displays:
- **File icon** based on MIME type
- **File name** (clickable to open)
- **Match type badge** (EXACT, PARTIAL, SEMANTIC, FUZZY)
- **Relevance indicator** (progress bar + percentage)
- **Page number** (for content matches)
- **Snippet** (preview of matched content)
- **File metadata** (size, modified date)

### Match Type Colors

- **Green**: Exact match
- **Blue**: Partial match
- **Purple**: Semantic/content match
- **Orange**: Fuzzy match

### Empty States

- **No query**: Helpful prompt to enter search
- **No results**: Suggestions to try different keywords
- **Error**: Retry button with error message

## Performance

### Search Speed

- Filename search: < 50ms (local)
- Semantic search: 100-500ms (depends on index size)
- Combined search: 200-600ms

### Optimization

- Results limited to 20 by default (configurable)
- Deduplication reduces redundant results
- Caching for repeated queries (frontend)
- Indexed Pinecone queries for fast semantic search

## Testing

### Backend Test

```bash
cd backend
uv run python test_search.py
```

Set `TEST_USER_ID` in `.env` to your user UUID.

### Manual Testing

1. Index some documents first (via Indexing UI)
2. Open Advanced Search
3. Try different query types:
   - Exact filename: `"MyDocument.pdf"`
   - Partial: `"Document"`
   - Semantic: `"what is machine learning"`
   - Fuzzy: `"ml research paper"`

## Configuration

### Backend Environment

No additional configuration needed. Uses existing:
- `PINECONE_API_KEY` - For semantic search
- `SUPABASE_URL` - For file metadata
- `GROQ_API_KEY` - For embeddings

### Frontend

Search is automatically available once backend is running.

## Offline Behavior

**Offline Mode:**
- Filename search works offline (uses local cache)
- Semantic search requires internet (Pinecone API)
- Graceful degradation: shows filename results only

**Sync:**
- Search results reflect locally cached files
- Refreshes when online and synced

## Future Enhancements

Potential improvements:
- [ ] Search filters (file type, date range, size)
- [ ] Search history and suggestions
- [ ] Advanced query syntax (AND, OR, NOT)
- [ ] Tag-based filtering
- [ ] Sort options (relevance, date, name, size)
- [ ] Export search results
- [ ] Saved searches
- [ ] Search within specific folders

## Troubleshooting

### No Results Found

**Check:**
1. Files are indexed (use Indexing UI)
2. User has files in Google Drive
3. Semantic search is enabled for content matches
4. Query spelling is correct

### Slow Search

**Causes:**
- Large document collection (>1000 files)
- Slow network connection
- Pinecone API latency

**Solutions:**
- Reduce `max_results` parameter
- Disable semantic search for faster filename-only search
- Check network connection

### Missing Content Matches

**Ensure:**
1. Documents are indexed (check Indexing UI)
2. Semantic search is enabled
3. Content contains relevant text (not image-only PDFs)
4. Embeddings are synced to Pinecone

## Related Features

- **RAG Chat**: Uses same semantic search for AI responses
- **Indexing**: Required for content search to work
- **File Explorer**: Primary navigation to search
- **PDF Viewer**: Opens search results

## Technical Details

### Search Algorithm

```
1. Normalize query (lowercase, trim)
2. Search filenames:
   - Check exact match → score 1.0
   - Check partial match → score 0.7-0.95
   - Check fuzzy match → score 0.4-0.7
3. If semantic enabled:
   - Generate query embedding
   - Query Pinecone vector DB
   - Convert distance to similarity → score 0.3-0.8
4. Deduplicate by file_id (keep highest score)
5. Sort by relevance (descending)
6. Limit to max_results
```

### Relevance Scoring

**Filename Matches:**
- Position in filename affects score
- Length ratio (query/filename) affects score
- Word boundary matches preferred

**Semantic Matches:**
- Cosine similarity from Pinecone
- Scaled to 0.3-0.8 range
- Always ranked below exact filename matches

## Dependencies

**Backend:**
- `pinecone-client` - Vector search
- `sentence-transformers` - Embeddings
- `supabase` - File metadata

**Frontend:**
- `provider` - State management
- `http` - API calls

## Support

For issues or questions:
1. Check backend logs: `uv run python run.py`
2. Check frontend console for errors
3. Verify indexing status in Indexing UI
4. Test with `backend/test_search.py`
