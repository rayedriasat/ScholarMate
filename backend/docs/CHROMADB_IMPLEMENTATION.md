# ChromaDB Implementation - Task 12.1

## Overview
This document describes the implementation of ChromaDB with per-user collections for ScholarMate's RAG (Retrieval-Augmented Generation) system.

## Components Implemented

### 1. ChromaDB Service (`app/services/chroma_service.py`)
A comprehensive service for managing vector storage with user isolation.

**Key Features:**
- Per-user collection management with naming convention: `user_{user_id}_documents`
- Persistent storage in `./chroma_db` directory
- Document CRUD operations (add, query, delete)
- File-based document deletion for cleanup
- Collection statistics and management

**Main Methods:**
- `get_or_create_user_collection(user_id)` - Get or create user-specific collection
- `add_documents(user_id, documents, metadatas, ids, embeddings)` - Add documents to collection
- `query_documents(user_id, query_texts, n_results, where)` - Semantic search with optional filters
- `delete_documents_by_file(user_id, file_id)` - Remove all documents from a specific file
- `get_collection_stats(user_id)` - Get collection statistics

### 2. Backend Drive Service (`app/services/drive_service.py`)
Service for fetching files from Google Drive using encrypted user tokens.

**Key Features:**
- Token refresh using stored refresh tokens
- Automatic token expiration handling with retry
- File content and metadata fetching
- Integration with encryption and Supabase services

**Main Methods:**
- `get_access_token(user_id)` - Get valid access token (refreshes if needed)
- `refresh_access_token(user_id)` - Refresh expired access token
- `get_file_bytes(file_id, user_id)` - Download file content from Drive
- `get_file_metadata(file_id, user_id)` - Get file metadata from Drive

## Dependencies Added

```toml
chromadb>=1.3.0          # Vector database
langchain>=1.0.3         # LangChain framework
langchain-chroma>=1.0.0  # ChromaDB integration for LangChain
langchain-groq>=1.0.0    # GROQ integration (already present)
```

## Environment Configuration

Required environment variables in `backend/.env`:

```bash
# ChromaDB
CHROMA_PERSIST_DIR=./chroma_db

# Google OAuth (for Drive access)
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret

# GROQ AI (for embeddings)
GROQ_API_KEY=your_groq_api_key
```

## User Isolation

Each user gets a separate ChromaDB collection:
- Collection naming: `user_{sanitized_user_id}_documents`
- UUID hyphens are replaced with underscores for ChromaDB compatibility
- Collections are completely isolated - users cannot access each other's data
- Metadata includes: `file_id`, `page_number`, `chunk_index`

## Testing

Three comprehensive test suites were created:

### 1. `test_chroma_setup.py`
Tests basic ChromaDB functionality and user isolation:
- Collection creation and naming
- Document addition and retrieval
- User isolation verification
- File-based deletion
- Collection statistics

**Run:** `uv run python test_chroma_setup.py`

### 2. `test_drive_service.py`
Tests Backend Drive Service functionality:
- Token refresh mechanism
- File metadata fetching
- File content downloading
- Error handling

**Run:** `uv run python test_drive_service.py`
**Note:** Requires authenticated user with stored tokens in database

### 3. `test_chroma_integration.py`
Tests complete RAG pipeline integration:
- ChromaDB + GROQ integration
- Semantic search with embeddings
- Source filtering (file-specific queries)
- Collection management
- GROQ API connectivity

**Run:** `uv run python test_chroma_integration.py`

## Test Results

All tests passed successfully:

✅ **ChromaDB Setup Tests:**
- Collection naming format correct
- User isolation working (separate collections per user)
- Document CRUD operations functional
- File-based deletion working
- Collection statistics accurate

✅ **ChromaDB + GROQ Integration Tests:**
- GROQ API connection successful
- Document indexing working
- Semantic search returning relevant results
- Source filtering (file-specific queries) working
- Distance-based ranking functional

## Usage Example

```python
from app.services import get_chroma_service

# Initialize service
chroma_service = get_chroma_service()

# Add documents for a user
chroma_service.add_documents(
    user_id="user-uuid-here",
    documents=["Document text 1", "Document text 2"],
    metadatas=[
        {"file_id": "file1.pdf", "page_number": 1, "chunk_index": 0},
        {"file_id": "file1.pdf", "page_number": 2, "chunk_index": 1}
    ],
    ids=["doc_1", "doc_2"]
)

# Query documents (semantic search)
results = chroma_service.query_documents(
    user_id="user-uuid-here",
    query_texts=["What is machine learning?"],
    n_results=5
)

# Query specific file only (source selection)
results = chroma_service.query_documents(
    user_id="user-uuid-here",
    query_texts=["neural networks"],
    n_results=5,
    where={"file_id": "file1.pdf"}  # Only search in this file
)

# Delete all documents from a file
chroma_service.delete_documents_by_file(
    user_id="user-uuid-here",
    file_id="file1.pdf"
)
```

## Architecture Notes

### Offline-First Compatibility
- ChromaDB runs locally on the backend server
- No external API calls for vector storage
- Fast query performance with local embeddings

### Scalability Considerations
- Each user has a separate collection for data isolation
- Collections are stored in persistent directory
- Automatic collection creation on first use
- Efficient metadata filtering for source selection

### Security
- User data completely isolated in separate collections
- No cross-user data access possible
- Integrates with existing encryption service for tokens
- Row-level security enforced at Supabase level

## Next Steps (Future Tasks)

This implementation satisfies requirements for:
- **13.2** - RAG indexing with ChromaDB
- **13.6** - Source selection (file filtering in queries)
- **13.12** - User-specific vector storage

Future tasks will build on this foundation:
- Task 12.2: Implement PDF text extraction and chunking
- Task 12.3: Create RAG indexing API endpoints
- Task 12.4: Implement semantic search with citations
- Task 12.5: Add source selection UI

## Troubleshooting

### ChromaDB Directory Permissions
If you encounter permission errors, ensure the `CHROMA_PERSIST_DIR` directory is writable:
```bash
mkdir -p ./chroma_db
chmod 755 ./chroma_db
```

### GROQ API Errors
Verify your GROQ API key is valid:
```bash
uv run python -c "from app.services import get_groq_service; print(get_groq_service().test_connection())"
```

### Collection Not Found
Collections are created automatically on first use. If you get "collection not found" errors, ensure you're using `get_or_create_user_collection()` instead of `get_collection()`.

## References

- ChromaDB Documentation: https://docs.trychroma.com/
- LangChain ChromaDB Integration: https://python.langchain.com/docs/integrations/vectorstores/chroma
- GROQ API Documentation: https://console.groq.com/docs
