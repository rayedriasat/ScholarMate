# RAG Chat Endpoint - Quick Reference

## Endpoint

**POST /api/ai/chat-rag**

RAG-based question answering with source filtering and citations.

## Request

```json
{
  "question": "What is the main topic?",
  "user_id": "user-uuid",
  "selected_file_ids": ["file-1", "file-2"],  // Optional
  "top_k": 5  // Optional, 1-20, default=5
}
```

## Response

```json
{
  "message": "AI-generated answer...",
  "citations": [
    {
      "file_id": "file-1",
      "file_name": "Document.pdf",
      "page_number": 5,
      "snippet": "Relevant text excerpt..."
    }
  ],
  "timestamp": "2025-11-01T12:00:00Z"
}
```

## Status Codes

- `200` - Success (even with no results)
- `400` - Invalid request (empty question/user_id)
- `422` - Validation error (missing fields, invalid top_k)
- `429` - GROQ rate limit exceeded
- `500` - Internal error
- `503` - GROQ API unavailable

## Examples

### Basic Query
```bash
curl -X POST http://localhost:8000/api/ai/chat-rag \
  -H "Content-Type: application/json" \
  -d '{"question": "What is this about?", "user_id": "user-123"}'
```

### With Source Filtering
```bash
curl -X POST http://localhost:8000/api/ai/chat-rag \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Compare these documents",
    "user_id": "user-123",
    "selected_file_ids": ["file-abc", "file-xyz"],
    "top_k": 10
  }'
```

## Features

✓ Source filtering by file IDs
✓ Citation generation with snippets
✓ User isolation (separate collections)
✓ GROQ error handling
✓ Timeout handling
✓ Empty results handling
✓ Request validation

## Testing

```bash
# API structure tests
cd backend
uv run python test_rag_chat_api.py

# Integration tests (requires indexed docs)
uv run python test_rag_chat_endpoint.py

# Swagger UI
http://localhost:8000/docs
```

## Flutter Integration

```dart
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
  }
  throw Exception('Failed: ${response.body}');
}
```

## Notes

- Requires GROQ_API_KEY in environment
- Uses RAGQueryService from Task 13.1
- All operations are async
- User collections auto-created
- Empty results return friendly message
- Citations deduplicated by page
