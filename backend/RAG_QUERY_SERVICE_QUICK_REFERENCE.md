# RAG Query Service - Quick Reference

## Overview

The RAGQueryService provides semantic search and question answering with source filtering and citations using LangChain and GROQ.

## Key Methods

### 1. query() - Main Entry Point

```python
response = await rag_query_service.query(
    question="What is this document about?",
    user_id="user-123",
    selected_file_ids=["file-abc", "file-xyz"],  # Optional
    top_k=5
)
```

**Returns:** `ChatResponse` with message and citations

### 2. retrieve_context() - Get Relevant Chunks

```python
chunks = await rag_query_service.retrieve_context(
    question="What is the main topic?",
    user_id="user-123",
    selected_file_ids=None,  # Optional filtering
    top_k=5
)
```

**Returns:** List of `RetrievedChunk` objects

### 3. generate_response() - Generate AI Answer

```python
response = await rag_query_service.generate_response(
    question="Summarize this",
    context=retrieved_chunks
)
```

**Returns:** `ChatResponse` with answer and citations

### 4. format_citations() - Format Citations

```python
citations = rag_query_service.format_citations(retrieved_chunks)
```

**Returns:** List of `Citation` objects (deduplicated by page)

## Data Structures

### Citation
```python
{
    "file_id": "abc123",
    "file_name": "Research Paper.pdf",
    "page_number": 5,
    "snippet": "First 150 characters of content..."
}
```

### ChatResponse
```python
{
    "message": "AI generated answer...",
    "citations": [Citation, ...],
    "timestamp": "2024-01-01T12:00:00Z"
}
```

### RetrievedChunk
```python
{
    "content": "Full chunk text...",
    "file_id": "abc123",
    "file_name": "Research Paper.pdf",
    "page_number": 5,
    "chunk_index": 2,
    "distance": 0.15
}
```

## Source Filtering

### No Filtering (All Documents)
```python
response = await rag_query_service.query(
    question="What is this about?",
    user_id="user-123",
    selected_file_ids=None  # Query all documents
)
```

### Single File Filtering
```python
response = await rag_query_service.query(
    question="What is in this document?",
    user_id="user-123",
    selected_file_ids=["file-abc"]  # Only this file
)
```

### Multiple File Filtering
```python
response = await rag_query_service.query(
    question="Compare these documents",
    user_id="user-123",
    selected_file_ids=["file-abc", "file-xyz"]  # Multiple files
)
```

## User Isolation

- Each user has their own ChromaDB collection: `user_{user_id}_documents`
- Queries are automatically scoped to user's collection
- No cross-user data access possible
- Enforced at the ChromaDB collection level

## Error Handling

### Empty Results
```python
# Returns friendly message when no relevant context found
response = await rag_query_service.query(
    question="nonexistent topic",
    user_id="user-123"
)
# response.message: "I couldn't find any relevant information..."
# response.citations: []
```

### Invalid File IDs
```python
# Gracefully handles non-existent file IDs
response = await rag_query_service.query(
    question="What is this?",
    user_id="user-123",
    selected_file_ids=["nonexistent-file"]
)
# Returns empty results message
```

## Testing

### Run Basic Tests
```bash
cd backend
uv run python test_rag_query_service.py
```

### Run Comprehensive Tests
```bash
cd backend
uv run python test_rag_query_comprehensive.py
```

## Configuration

### Environment Variables
```bash
GROQ_API_KEY=your_groq_api_key
GROQ_CHAT_MODEL=llama-3.3-70b-versatile
CHROMA_PERSIST_DIR=./chroma_db
```

### Prompt Template
The service uses a custom prompt template that:
- Includes retrieved context with source references
- Instructs AI to answer based only on context
- Requests concise and accurate responses
- Asks for source references when possible

## Performance

### Top-K Values
- `top_k=1`: Fastest, minimal context
- `top_k=5`: Balanced (default)
- `top_k=10`: More context, slower

### Citation Deduplication
- Automatically deduplicates by (file_id, page_number)
- Reduces redundant citations from same page
- Sorted by file_name and page_number

## Integration Points

### ChromaService
- `query_documents()` for semantic search
- Metadata filtering with `where` parameter
- Default embedding function for consistency

### GROQService
- `chat()` for response generation
- Error handling for rate limits
- Token usage logging

### LangChain
- `PromptTemplate` for structured prompts
- `ChatGroq` for GROQ integration
- Compatible with LangChain ecosystem

## Common Patterns

### Basic Q&A
```python
response = await rag_query_service.query(
    question="What is the main topic?",
    user_id=user_id,
    top_k=5
)
print(response.message)
```

### Filtered Q&A
```python
response = await rag_query_service.query(
    question="What does this document say about X?",
    user_id=user_id,
    selected_file_ids=[file_id],
    top_k=3
)
```

### Get Context Only
```python
chunks = await rag_query_service.retrieve_context(
    question="topic",
    user_id=user_id,
    top_k=5
)
for chunk in chunks:
    print(f"{chunk.file_name}, Page {chunk.page_number}")
```

## Logging

The service logs:
- Query requests with user_id
- Context retrieval results
- GROQ API calls and token usage
- Citation generation
- Errors and warnings

Log level: INFO (configurable)

## Next Steps

1. Create API endpoint (Task 13.2)
2. Add chat history support
3. Implement streaming responses
4. Add caching for frequent queries
5. Optimize prompt templates
