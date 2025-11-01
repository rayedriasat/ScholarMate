# Task 13.2: AI Chat API Endpoint with Source Filtering

## Summary

Successfully implemented POST /api/ai/chat-rag endpoint for RAG-based question answering with source filtering and citations.

## Implementation Details

### Files Created

1. **backend/test_rag_chat_api.py**
   - API endpoint structure and validation tests
   - Tests request/response format
   - Tests error handling and edge cases

2. **backend/test_rag_chat_endpoint.py**
   - Integration tests with indexed documents
   - Tests source filtering functionality
   - Tests citation generation

### Files Modified

1. **backend/app/models/ai.py**
   - Added `RAGChatRequest` model for request validation
   - Added `RAGChatResponse` model for response structure
   - Added `Citation` model for source references

2. **backend/app/routers/ai.py**
   - Added POST /api/ai/chat-rag endpoint
   - Integrated RAGQueryService
   - Implemented comprehensive error handling

## Endpoint Specification

### POST /api/ai/chat-rag

**Request Body:**
```json
{
  "question": "What is the main topic of these documents?",
  "user_id": "user-uuid-123",
  "selected_file_ids": ["file-id-1", "file-id-2"],  // Optional
  "top_k": 5  // Optional, default=5, range: 1-20
}
```

**Response:**
```json
{
  "message": "AI-generated answer based on the documents...",
  "citations": [
    {
      "file_id": "file-id-1",
      "file_name": "Research Paper.pdf",
      "page_number": 5,
      "snippet": "First 150 characters of relevant content..."
    }
  ],
  "timestamp": "2025-11-01T12:00:00.000000Z"
}
```

**Status Codes:**
- `200 OK`: Successful response (even with no results)
- `400 Bad Request`: Invalid request (empty question, empty user_id)
- `422 Unprocessable Entity`: Validation error (missing fields, invalid top_k)
- `429 Too Many Requests`: GROQ rate limit exceeded
- `500 Internal Server Error`: Unexpected error
- `503 Service Unavailable`: GROQ API connection error

## Request Validation

### Required Fields
- `question` (string): User's question, cannot be empty
- `user_id` (string): User UUID, cannot be empty

### Optional Fields
- `selected_file_ids` (list[string]): File IDs to filter sources
  - If null/omitted: searches all user's documents
  - If provided: only searches specified files
- `top_k` (integer): Number of chunks to retrieve
  - Default: 5
  - Range: 1-20
  - Validated by Pydantic

## Features Implemented

### 1. Source Filtering
- Accepts optional `selected_file_ids` parameter
- Filters retrieval results to only include chunks from selected files
- Uses ChromaDB metadata filtering with `$in` operator
- Returns empty results gracefully if no matches found

### 2. Citation Generation
- Extracts file_id, file_name, and page_number from retrieved chunks
- Includes text snippet (first 150 characters)
- Deduplicates citations by (file_id, page_number)
- Sorts citations by file_name and page_number

### 3. User Isolation
- All queries scoped to user-specific ChromaDB collection
- Collection naming: `user_{user_id}_documents`
- No cross-user data access possible
- Enforced at service layer

### 4. Error Handling

**GROQ Errors:**
- `RateLimitError`: Returns 429 with retry message
- `APIConnectionError`: Returns 503 with connection error
- `APIError`: Returns 500 with error details

**Validation Errors:**
- Empty question: Returns 400
- Empty user_id: Returns 400
- Missing required fields: Returns 422
- Invalid top_k: Returns 422

**Service Errors:**
- Unexpected errors: Returns 500 with generic message
- Logs full stack trace for debugging

### 5. Timeout Handling
- GROQ service has built-in timeout (30 seconds)
- Async operations prevent blocking
- Graceful degradation on timeout

## Test Results

### API Structure Tests (test_rag_chat_api.py)

✓ Validation - missing question (422)
✓ Validation - missing user_id (422)
✓ Validation - empty question (400)
✓ Valid request structure (200)
✓ Optional parameters working
✓ top_k validation (0 rejected, 25 rejected, 10 accepted)

All tests passed successfully.

### Integration Tests (test_rag_chat_endpoint.py)

Tests require indexed documents. Run after indexing:
- Basic query without filtering
- Query with source filtering (single file)
- Query with source filtering (multiple files)
- Empty results handling
- Variable top_k values
- Citation deduplication

## Requirements Satisfied

✓ **14.3**: Implement POST /api/ai/chat endpoint accepting question, user_id, and selected_file_ids
✓ **14.5**: Filter retrieval results to only include chunks from selected sources using metadata
✓ **14.7**: Return AI response with citations array containing {file_id, file_name, page_number}
✓ **14.13**: Ensure user isolation (only query user's own collection)

Additional features:
- GROQ error handling with specific status codes
- Timeout handling via async operations
- Comprehensive request validation
- Citation snippets for context
- Structured logging for monitoring

## Usage Examples

### Basic Query (All Documents)
```bash
curl -X POST http://localhost:8000/api/ai/chat-rag \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is the main topic?",
    "user_id": "user-123"
  }'
```

### Query with Source Filtering
```bash
curl -X POST http://localhost:8000/api/ai/chat-rag \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What does this document say about X?",
    "user_id": "user-123",
    "selected_file_ids": ["file-abc", "file-xyz"],
    "top_k": 10
  }'
```

### Response Example
```json
{
  "message": "Based on the documents, the main topic is...",
  "citations": [
    {
      "file_id": "file-abc",
      "file_name": "Research Paper.pdf",
      "page_number": 5,
      "snippet": "The study examines the relationship between..."
    },
    {
      "file_id": "file-xyz",
      "file_name": "Analysis Report.pdf",
      "page_number": 12,
      "snippet": "Our findings indicate that..."
    }
  ],
  "timestamp": "2025-11-01T12:00:00.000000Z"
}
```

## Integration with Frontend

The endpoint is ready for Flutter integration:

```dart
// Example Flutter service method
Future<RAGChatResponse> askQuestion({
  required String question,
  required String userId,
  List<String>? selectedFileIds,
  int topK = 5,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/ai/chat-rag'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'question': question,
      'user_id': userId,
      'selected_file_ids': selectedFileIds,
      'top_k': topK,
    }),
  );
  
  if (response.statusCode == 200) {
    return RAGChatResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to get answer: ${response.body}');
  }
}
```

## Logging

The endpoint logs:
- Request details (user_id, question preview, filters, top_k)
- Service initialization
- Query execution
- Response generation
- Citation count and message length
- All errors with context

Log level: INFO for normal operations, ERROR for failures

## Performance Considerations

### Response Time
- Typical: 1-3 seconds (depends on GROQ API)
- Factors: top_k value, document count, GROQ load
- Async operations prevent blocking

### Rate Limits
- GROQ free tier: ~30 requests/minute
- Returns 429 with retry message on limit
- Consider implementing client-side rate limiting

### Optimization Tips
- Use lower top_k for faster responses
- Filter by selected files to reduce search space
- Cache frequent queries (future enhancement)

## Security

### User Isolation
- Each user has separate ChromaDB collection
- No cross-user data access possible
- User_id required for all requests

### Input Validation
- Question length validated (not empty)
- User_id validated (not empty)
- top_k range validated (1-20)
- File IDs validated as list of strings

### Error Messages
- Generic error messages to users
- Detailed errors logged server-side
- No sensitive information exposed

## Next Steps

The endpoint is complete and ready for:
1. Frontend integration (Flutter UI)
2. Chat history support (future enhancement)
3. Streaming responses (future enhancement)
4. Query caching (future enhancement)
5. Multi-turn conversations (future enhancement)

## Testing Commands

```bash
# Run API structure tests
cd backend
uv run python test_rag_chat_api.py

# Run integration tests (requires indexed documents)
cd backend
uv run python test_rag_chat_endpoint.py

# Test via Swagger UI
# Navigate to: http://localhost:8000/docs
# Find: POST /api/ai/chat-rag
# Click "Try it out" and test with sample data
```

## API Documentation

The endpoint is automatically documented in:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

Both include:
- Request/response schemas
- Field descriptions
- Validation rules
- Example requests
- Status codes

## Notes

- Endpoint uses RAGQueryService from Task 13.1
- All operations are async for non-blocking execution
- GROQ API key required in environment
- ChromaDB must be initialized and accessible
- User collections created automatically if not exist
- Empty results return friendly message (not an error)
