# Design Document — ScholarMate

## Overview

ScholarMate is architected as a monorepo containing a Flutter cross-platform client and a FastAPI backend service. The design prioritizes incremental development with testable checkpoints, offline-first functionality, and exclusive use of free-tier services. The system uses Google Drive as the single source of truth for file storage, Supabase for metadata and realtime collaboration, and a self-hosted ChromaDB for vector embeddings.

The architecture follows a clear separation of concerns:
- Flutter client handles all direct Google Drive operations, UI, and local caching
- FastAPI backend handles compute-intensive tasks: OCR, RAG indexing, and AI queries using LangChain
- Supabase provides metadata storage, realtime pub/sub, and encrypted credential storage
- Google Drive provides file storage with built-in sharing and permissions
- LangChain provides model-agnostic RAG implementation with document loaders, text splitters, and retrieval chains

### GROQ AI Integration with LangChain

The system uses GROQ as the AI provider for chat and embeddings, configured via backend environment variables. LangChain serves as the abstraction layer for:
- **Document Processing**: PyPDFLoader for PDF text extraction from Google Drive files
- **Text Chunking**: RecursiveCharacterTextSplitter for semantic segmentation
- **Embeddings**: LangChain GROQ embedding models for vector generation
- **Vector Storage**: Chroma vectorstore integration with per-user collections (user_{user_id}_documents)
- **Retrieval**: LangChain retrievers with metadata filtering for source selection
- **Question Answering**: RetrievalQA chains with custom prompt templates using GROQ

The backend fetches files directly from Google Drive (source of truth) using encrypted user tokens for RAG indexing. All users share the same GROQ API key from backend configuration, with complete data isolation through per-user ChromaDB collections.

## Architecture

### High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Client                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   UI Layer   │  │ Google Drive │  │    Drift     │     │
│  │              │  │   Service    │  │   Database   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Sync Manager │  │   Realtime   │  │     PDF      │     │
│  │              │  │   Client     │  │   Viewer     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTPS/WebSocket
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    FastAPI Backend                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  API Routes  │  │  OCR Engine  │  │ AI Provider  │     │
│  │              │  │              │  │  Abstraction │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ RAG Indexer  │  │   ChromaDB   │  │  Encryption  │     │
│  │              │  │   Client     │  │   Service    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Supabase   │    │ Google Drive │    │   ChromaDB   │
│  PostgreSQL  │    │     API      │    │   Vector     │
│  + Realtime  │    │              │    │    Store     │
└──────────────┘    └──────────────┘    └──────────────┘
```

### Incremental Development Phases


**Phase 1: Foundation & Authentication (Testable Checkpoint)**
- Monorepo setup with Flutter + FastAPI
- Google OAuth integration
- Basic UI with authentication flow
- Test: User can sign in and see their Google profile

**Phase 2: Drive Integration & File Browsing (Testable Checkpoint)**
- Google Drive API integration
- App folder creation
- File/folder listing UI
- Basic file operations (upload, create folder)
- Test: User can browse Drive, upload files, create folders

**Phase 3: Offline Foundation & Local Cache (Testable Checkpoint)**
- Drift database implementation (works on all platforms including web)
- Online/offline detection
- Metadata caching
- Sync queue for offline actions
- Test: User can browse cached files offline, actions sync when online

**Phase 4: PDF Viewing (Testable Checkpoint)**
- Syncfusion PDF viewer integration
- PDF download and caching
- Basic navigation controls
- Test: User can open and read PDFs online and offline

**Phase 5: PDF Annotations (Testable Checkpoint)**
- Annotation tools (highlight, underline, comment)
- Annotation embedding in PDF
- Annotation list panel
- Local annotation storage
- Test: User can annotate PDFs and see annotations persist

**Phase 6: Backend Infrastructure & Supabase (Testable Checkpoint)**
- FastAPI setup with OpenAPI docs
- Supabase connection and schema
- Token encryption service
- RLS policies
- Test: Backend health checks pass, tokens stored securely

**Phase 7: Annotation Sync (Testable Checkpoint)**
- Annotation sync API endpoints
- Conflict resolution (last-write-wins)
- Cross-device annotation sync
- Test: Annotations sync across devices, conflicts resolve correctly

**Phase 8: OCR & Document Scanning (Testable Checkpoint)**
- Camera integration
- Image capture and cropping
- DeepSeek OCR backend service (online mode)
- Flutter Tesseract OCR (offline Android mode)
- Searchable PDF generation
- PDF to Markdown conversion
- Markdown preview and editor
- Test: User can scan documents, create searchable PDFs, convert to Markdown, and edit Markdown files

**Phase 9: GROQ AI Integration (Testable Checkpoint)**
- GROQ SDK integration in backend
- Chat and embedding methods using GROQ
- Environment variable configuration
- Test: GROQ API works for chat and embeddings

**Phase 10: RAG Indexing with LangChain and GROQ (Testable Checkpoint)**
- ChromaDB setup with per-user collections
- LangChain document loaders and text splitters
- Embedding generation using GROQ
- Backend Drive service to fetch files from Google Drive
- Indexing job tracking with progress
- Indexing status UI with reindex button
- Test: Documents get indexed in user-specific collections, status tracked with progress, reindex works

**Phase 11: AI Chat with RAG, Source Selection, and Clickable Citations (Testable Checkpoint)**
- Chat UI with source selection
- LangChain retrieval chains for RAG pipeline using GROQ
- Source filtering for selected documents
- Citation generation with file_id, file_name, and page_number
- Clickable citations that open PDF viewer at specific page
- Save responses as Markdown
- Test: User can ask questions with selected sources, get cited answers, and click citations to view source pages

**Phase 12: File Organization with Tags (Testable Checkpoint)**
- Tag management UI
- Tag application and filtering
- Tag-based search and sorting
- Tag synchronization
- Test: User can tag files, filter by tags, and tags sync across devices

**Phase 13: Sharing & Permissions (Testable Checkpoint)**
- Sharing dialog UI
- Role-based permissions (Viewer/Editor)
- Google Drive sharing integration
- Sharing metadata storage
- Test: User can share files with roles, permissions enforced

**Phase 14: Public Links (Testable Checkpoint)**
- Public link generation
- View-only access for public links
- Link revocation
- Test: Public links work without authentication

**Phase 15: Realtime Annotations (Testable Checkpoint)**
- Supabase Realtime integration
- Annotation event broadcasting
- Real-time UI updates
- Typing indicators
- Test: Collaborators see annotations in realtime

**Phase 16: Realtime File Operations (Testable Checkpoint)**
- File operation event broadcasting
- Explorer real-time updates
- Permission change events
- Test: File changes appear instantly for collaborators

**Phase 17: Presence & Activity (Testable Checkpoint)**
- Presence broadcasting
- Avatar display
- Page tracking
- Test: Users see who's viewing and what page they're on

**Phase 18: Read Aloud (Testable Checkpoint)**
- TTS integration
- Read-aloud controls
- Auto-page advancement
- Test: User can listen to PDFs with TTS

**Phase 19: Performance & Polish (Testable Checkpoint)**
- Caching optimizations
- Pagination
- Rate limiting
- UI polish
- Test: App performs well with large libraries

## Components and Interfaces

### Flutter Client Components

#### 1. Authentication Service
```dart
class AuthService {
  Future<User> signInWithGoogle();
  Future<void> signOut();
  Future<String> getAccessToken();
  Future<void> refreshToken();
  Stream<AuthState> get authStateChanges;
}
```

#### 2. Google Drive Service
```dart
class DriveService {
  Future<void> createAppFolder();
  Future<List<DriveFile>> listFiles(String folderId);
  Future<DriveFile> uploadFile(File file, String parentId);
  Future<void> createFolder(String name, String parentId);
  Future<void> deleteFile(String fileId);
  Future<void> renameFile(String fileId, String newName);
  Future<void> moveFile(String fileId, String newParentId);
  Future<Uint8List> downloadFile(String fileId);
  Future<void> shareFile(String fileId, String email, String role);
  Future<String> createPublicLink(String fileId);
}
```

#### 3. Local Cache Service
```dart
class CacheService {
  Future<void> initialize();
  Future<void> cacheFileMetadata(DriveFile file);
  Future<List<DriveFile>> getCachedFiles(String folderId);
  Future<void> cachePdfBytes(String fileId, Uint8List bytes);
  Future<Uint8List?> getCachedPdf(String fileId);
  Future<void> cacheAnnotation(Annotation annotation);
  Future<List<Annotation>> getCachedAnnotations(String fileId);
  Future<bool> isFileCached(String fileId);
}
```

#### 4. Sync Manager
```dart
class SyncManager {
  Future<void> queueAction(SyncAction action);
  Future<void> processSyncQueue();
  Stream<SyncStatus> get syncStatusStream;
  Future<void> syncAnnotations(String fileId);
  Future<void> resolveConflicts(List<Conflict> conflicts);
}
```

#### 5. Connectivity Service
```dart
class ConnectivityService {
  Stream<bool> get isOnline;
  Future<bool> checkConnectivity();
}
```

#### 6. PDF Viewer Manager
```dart
class PdfViewerManager {
  Future<void> loadPdf(String fileId);
  Future<void> addAnnotation(AnnotationType type, AnnotationData data);
  Future<void> removeAnnotation(String annotationId);
  Future<List<Annotation>> getAnnotations();
  Future<Uint8List> savePdfWithAnnotations();
  void jumpToPage(int pageNumber);
  void jumpToAnnotation(String annotationId);
  
  // Citation navigation
  Future<void> openPdfFromCitation(String fileId, int pageNumber);
  void highlightCitationArea(int pageNumber);
}
```

#### 7. Realtime Service
```dart
class RealtimeService {
  Future<void> connect();
  Future<void> subscribeToFile(String fileId);
  Future<void> subscribeToFolder(String folderId);
  Future<void> broadcastAnnotation(Annotation annotation);
  Future<void> broadcastFileOperation(FileOperation operation);
  Future<void> broadcastPresence(PresenceData presence);
  Stream<RealtimeEvent> get eventStream;
}
```

#### 8. Tag Management Service
```dart
class TagService {
  Future<void> createTag(String name, String color);
  Future<void> renameTag(String tagId, String newName);
  Future<void> deleteTag(String tagId);
  Future<List<Tag>> getAllTags();
  Future<void> addTagToFile(String fileId, String tagId);
  Future<void> removeTagFromFile(String fileId, String tagId);
  Future<void> bulkTagFiles(List<String> fileIds, List<String> tagIds);
  Future<List<DriveFile>> getFilesByTag(String tagId);
  Future<List<Tag>> getTagsForFile(String fileId);
  Future<Map<String, int>> getTagStatistics();
  Future<void> syncTags();
}
```

#### 9. OCR Service (Flutter Client)
```dart
class OCRService {
  Future<String> processImageOnline(Uint8List imageBytes);
  Future<String> processImageOffline(Uint8List imageBytes);
  Future<String> processImage(Uint8List imageBytes);
  Future<bool> isOnline();
  Future<void> downloadTesseractData();
}
```

#### 10. Markdown Service
```dart
class MarkdownService {
  Future<String> convertPdfToMarkdown(String fileId);
  Future<void> saveMarkdown(String content, String fileName);
  Future<String> loadMarkdown(String fileId);
  String renderMarkdown(String content);
  Future<void> cacheMarkdown(String fileId, String content);
}
```

#### 11. AI Chat Service
```dart
class AIChatService {
  Future<ChatResponse> sendMessage(
    String message, 
    String userId, 
    List<String> selectedFileIds
  );
  Future<void> saveChatAsNote(ChatMessage message);
  Future<List<ChatHistory>> getChatHistory();
  Future<void> clearChat();
  
  // Citation handling
  void onCitationClicked(Citation citation);
  Future<void> openCitationInPdfViewer(Citation citation);
}

class Citation {
  final String fileId;
  final String fileName;
  final int pageNumber;
  final String snippet;
}

class ChatResponse {
  final String message;
  final List<Citation> citations;
  final String timestamp;
}
```

### FastAPI Backend Components

#### 1. API Routes
```python
# Authentication & Token Management
POST /api/auth/store-tokens
GET /api/auth/refresh-token

# OCR
POST /api/ocr/process
POST /api/ocr/pdf-to-markdown

# RAG Indexing
POST /api/ingest/start
GET /api/ingest/status/{job_id}
POST /api/ingest/reindex/{file_id}

# AI Chat
POST /api/ai/chat
POST /api/ai/embed

# Annotations
GET /api/annotations/{file_id}
POST /api/annotations/sync
PUT /api/annotations/{annotation_id}
DELETE /api/annotations/{annotation_id}

# AI Testing
POST /api/ai/test-groq

# Tags
GET /api/tags
POST /api/tags
PUT /api/tags/{tag_id}
DELETE /api/tags/{tag_id}
POST /api/tags/apply
DELETE /api/tags/remove
GET /api/tags/statistics

# Health
GET /api/health
```

#### 2. OCR Service with DeepSeek OCR
```python
class OCRService:
    async def process_image_deepseek(self, image_bytes: bytes) -> Dict[str, Any]:
        """Extract text from image using DeepSeek OCR API with structure preservation"""
        
    async def pdf_to_markdown(self, pdf_bytes: bytes) -> str:
        """Convert PDF to Markdown using DeepSeek OCR"""
        
    async def create_searchable_pdf(
        self, 
        images: List[bytes], 
        ocr_texts: List[str]
    ) -> bytes:
        """Create PDF with embedded OCR text"""
```

#### 3. GROQ AI Service
```python
from groq import Groq
from langchain_groq import ChatGroq, GroqEmbeddings

class GROQService:
    def __init__(self):
        self.api_key = os.getenv("GROQ_API_KEY")
        self.client = Groq(api_key=self.api_key)
        self.chat_model = ChatGroq(api_key=self.api_key)
        self.embeddings = GroqEmbeddings(api_key=self.api_key)
    
    async def chat(
        self, 
        prompt: str, 
        context: List[str],
        config: Dict
    ) -> ChatResponse:
        """Generate chat response using GROQ"""
        
    async def embed(
        self, 
        texts: List[str]
    ) -> List[List[float]]:
        """Generate embeddings using GROQ"""
        
    def handle_error(self, error: Exception):
        """Handle GROQ-specific errors and rate limits"""
```

#### 4. RAG Indexing Service with LangChain and GROQ
```python
from langchain.document_loaders import PyPDFLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_groq import GroqEmbeddings
from langchain.vectorstores import Chroma

class RAGIndexer:
    def __init__(self, groq_service: GROQService, drive_service: BackendDriveService):
        self.groq_service = groq_service
        self.drive_service = drive_service
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200
        )
        self.embeddings = GroqEmbeddings(api_key=groq_service.api_key)
    
    async def index_file(
        self, 
        file_id: str, 
        user_id: str
    ) -> str:
        """Start indexing job, fetch file from Google Drive, return job_id"""
        
    async def extract_and_chunk_text(
        self, 
        pdf_bytes: bytes
    ) -> List[Document]:
        """Extract text from PDF and chunk using LangChain"""
        # Use LangChain PyPDFLoader and text splitter
        
    async def generate_embeddings(
        self, 
        documents: List[Document]
    ) -> List[Embedding]:
        """Generate embeddings using GROQ via LangChain"""
        
    async def store_embeddings(
        self, 
        documents: List[Document],
        embeddings: List[Embedding],
        user_id: str,
        file_id: str,
        metadata: Dict
    ):
        """Store in user-specific ChromaDB collection with metadata"""
        # Collection name: f"user_{user_id}_documents"
        # Metadata: file_id, page_number, chunk_index
        
    async def get_user_collection(self, user_id: str) -> Chroma:
        """Get or create user-specific ChromaDB collection"""
        
    async def get_job_status(self, job_id: str) -> JobStatus:
        """Get indexing job status with progress"""
        
    async def update_job_progress(
        self, 
        job_id: str, 
        chunks_processed: int, 
        total_chunks: int
    ):
        """Update indexing job progress"""
```

#### 5. RAG Query Service with LangChain and GROQ
```python
from langchain.chains import RetrievalQA
from langchain.prompts import PromptTemplate
from langchain.vectorstores import Chroma
from langchain_groq import ChatGroq

class RAGQueryService:
    def __init__(self, groq_service: GROQService):
        self.groq_service = groq_service
        self.chat_model = ChatGroq(api_key=groq_service.api_key)
    
    async def query(
        self, 
        question: str,
        user_id: str,
        selected_file_ids: List[str] = None,
        top_k: int = 5
    ) -> QueryResult:
        """Query user's vector store with source filtering using GROQ"""
        
    async def retrieve_context(
        self, 
        question: str,
        user_id: str,
        selected_file_ids: List[str],
        top_k: int
    ) -> List[RetrievedChunk]:
        """Retrieve relevant chunks from user's ChromaDB collection with filtering"""
        # Use LangChain retriever with metadata filtering (file_id)
        
    async def generate_response(
        self, 
        question: str,
        context: List[RetrievedChunk]
    ) -> ChatResponse:
        """Generate AI response with citations using GROQ via LangChain chains"""
        # Use LangChain RetrievalQA chain with custom prompt template
        # Return citations with file_id, file_name, page_number
        
    async def get_user_vectorstore(self, user_id: str) -> Chroma:
        """Get user-specific vector store"""
        
    def format_citations(
        self, 
        retrieved_chunks: List[RetrievedChunk]
    ) -> List[Citation]:
        """Format citations with file_id, file_name, and page_number"""
```

#### 6. Encryption Service
```python
class EncryptionService:
    def encrypt(self, plaintext: str) -> str:
        """Encrypt sensitive data"""
        
    def decrypt(self, ciphertext: str) -> str:
        """Decrypt sensitive data"""
        
    async def store_encrypted_token(
        self, 
        user_id: str,
        token_type: str,
        token: str
    ):
        """Store encrypted token in Supabase"""
        
    async def get_decrypted_token(
        self, 
        user_id: str,
        token_type: str
    ) -> str:
        """Retrieve and decrypt token"""
```

#### 7. Drive Service (Backend)
```python
class BackendDriveService:
    async def get_file_bytes(
        self, 
        file_id: str,
        user_id: str
    ) -> bytes:
        """Fetch file from Drive using user's refresh token"""
        
    async def refresh_user_token(self, user_id: str) -> str:
        """Refresh access token for user"""
```

## Data Models

### Drift Database Schema (Flutter Client)

```sql
-- Files table
CREATE TABLE files (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    mime_type TEXT,
    size INTEGER,
    parent_id TEXT,
    modified_time INTEGER,
    is_cached INTEGER DEFAULT 0,
    cached_at INTEGER,
    thumbnail_link TEXT
);

-- Folders table
CREATE TABLE folders (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    parent_id TEXT,
    modified_time INTEGER
);

-- Annotations table
CREATE TABLE annotations (
    annotation_id TEXT PRIMARY KEY,
    file_id TEXT NOT NULL,
    author_id TEXT NOT NULL,
    author_name TEXT NOT NULL,
    timestamp_created INTEGER NOT NULL,
    timestamp_updated INTEGER NOT NULL,
    annotation_type TEXT NOT NULL,
    page_index INTEGER NOT NULL,
    bounding_box TEXT NOT NULL,
    content TEXT,
    pdf_embedded_flag INTEGER DEFAULT 0,
    version INTEGER DEFAULT 1,
    sync_status TEXT DEFAULT 'pending',
    FOREIGN KEY (file_id) REFERENCES files(id)
);

-- Sync queue table
CREATE TABLE sync_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_type TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    payload TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    retry_count INTEGER DEFAULT 0,
    status TEXT DEFAULT 'pending'
);

-- Cached PDFs table
CREATE TABLE cached_pdfs (
    file_id TEXT PRIMARY KEY,
    pdf_bytes BLOB NOT NULL,
    cached_at INTEGER NOT NULL,
    file_size INTEGER NOT NULL,
    FOREIGN KEY (file_id) REFERENCES files(id)
);

-- Tags table
CREATE TABLE tags (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    color TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- File tags junction table
CREATE TABLE file_tags (
    file_id TEXT NOT NULL,
    tag_id TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (file_id, tag_id),
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);
```

### Supabase PostgreSQL Schema

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    google_sub TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    name TEXT,
    picture_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Encrypted tokens table
CREATE TABLE encrypted_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_type TEXT NOT NULL,
    encrypted_token TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, token_type)
);

-- Files metadata table
CREATE TABLE files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    drive_file_id TEXT NOT NULL,
    name TEXT NOT NULL,
    mime_type TEXT,
    size BIGINT,
    parent_drive_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, drive_file_id)
);

-- Annotations table
CREATE TABLE annotations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    annotation_id TEXT UNIQUE NOT NULL,
    file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES users(id),
    author_name TEXT NOT NULL,
    timestamp_created TIMESTAMPTZ NOT NULL,
    timestamp_updated TIMESTAMPTZ NOT NULL,
    annotation_type TEXT NOT NULL,
    page_index INTEGER NOT NULL,
    bounding_box JSONB NOT NULL,
    content TEXT,
    pdf_embedded_flag BOOLEAN DEFAULT FALSE,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Shares table
CREATE TABLE shares (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    shared_with_email TEXT NOT NULL,
    shared_with_user_id UUID REFERENCES users(id),
    role TEXT NOT NULL CHECK (role IN ('viewer', 'editor')),
    shared_by_user_id UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(file_id, shared_with_email)
);

-- Ingestion jobs table
CREATE TABLE ingestion_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id TEXT UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    error_message TEXT,
    chunks_processed INTEGER DEFAULT 0,
    total_chunks INTEGER,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- API keys table
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL,
    encrypted_key TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, provider)
);

-- Audit logs table
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    metadata JSONB,
    ip_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tags table
CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    color TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, name)
);

-- File tags junction table
CREATE TABLE file_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(file_id, tag_id)
);

-- RLS Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE encrypted_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE files ENABLE ROW LEVEL SECURITY;
ALTER TABLE annotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingestion_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Users can only see their own data
CREATE POLICY users_policy ON users FOR ALL USING (google_sub = current_setting('app.current_user_sub'));
CREATE POLICY tokens_policy ON encrypted_tokens FOR ALL USING (user_id = (SELECT id FROM users WHERE google_sub = current_setting('app.current_user_sub')));
CREATE POLICY files_policy ON files FOR ALL USING (user_id = (SELECT id FROM users WHERE google_sub = current_setting('app.current_user_sub')));
CREATE POLICY annotations_policy ON annotations FOR ALL USING (author_id = (SELECT id FROM users WHERE google_sub = current_setting('app.current_user_sub')));
CREATE POLICY shares_policy ON shares FOR ALL USING (shared_with_user_id = (SELECT id FROM users WHERE google_sub = current_setting('app.current_user_sub')) OR shared_by_user_id = (SELECT id FROM users WHERE google_sub = current_setting('app.current_user_sub')));
CREATE POLICY jobs_policy ON ingestion_jobs FOR ALL USING (user_id = (SELECT id FROM users WHERE google_sub = current_setting('app.current_user_sub')));
CREATE POLICY keys_policy ON api_keys FOR ALL USING (user_id = (SELECT id FROM users WHERE google_sub = current_setting('app.current_user_sub')));
CREATE POLICY logs_policy ON audit_logs FOR SELECT USING (user_id = (SELECT id FROM users WHERE google_sub = current_setting('app.current_user_sub')));
CREATE POLICY tags_policy ON tags FOR ALL USING (user_id = (SELECT id FROM users WHERE google_sub = current_setting('app.current_user_sub')));
CREATE POLICY file_tags_policy ON file_tags FOR ALL USING (
    file_id IN (SELECT id FROM files WHERE user_id = (SELECT id FROM users WHERE google_sub = current_setting('app.current_user_sub')))
);

-- Indexes
CREATE INDEX idx_files_user_id ON files(user_id);
CREATE INDEX idx_files_drive_file_id ON files(drive_file_id);
CREATE INDEX idx_annotations_file_id ON annotations(file_id);
CREATE INDEX idx_annotations_author_id ON annotations(author_id);
CREATE INDEX idx_shares_file_id ON shares(file_id);
CREATE INDEX idx_shares_shared_with_email ON shares(shared_with_email);
CREATE INDEX idx_ingestion_jobs_user_id ON ingestion_jobs(user_id);
CREATE INDEX idx_ingestion_jobs_status ON ingestion_jobs(status);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_tags_user_id ON tags(user_id);
CREATE INDEX idx_file_tags_file_id ON file_tags(file_id);
CREATE INDEX idx_file_tags_tag_id ON file_tags(tag_id);
```

### ChromaDB Collections

```python
# Per-user document chunks collection
# Collection naming: f"user_{user_id}_documents"
collection_schema = {
    "name": "user_{user_id}_documents",
    "metadata": {
        "description": "Embedded document chunks for RAG - user-specific",
        "user_id": "uuid"
    }
}

# Chunk metadata structure
chunk_metadata = {
    "file_id": "uuid",
    "user_id": "uuid",
    "file_name": "string",
    "page_number": "int",
    "chunk_index": "int",
    "total_chunks": "int",
    "char_start": "int",
    "char_end": "int",
    "timestamp": "iso8601"
}

# Note: Each user has their own isolated collection to prevent cross-user data access
# LangChain Chroma vectorstore is used with metadata filtering for source selection
```

## Error Handling

### Flutter Client Error Handling

1. Network Errors
   - Detect offline state and queue operations
   - Show user-friendly offline indicator
   - Retry failed sync operations with exponential backoff
   - Display sync status in UI

2. Authentication Errors
   - Handle token expiration gracefully
   - Automatic token refresh
   - Redirect to login on auth failure
   - Secure token storage

3. Drive API Errors
   - Handle quota exceeded errors
   - Retry with backoff on rate limits
   - Show meaningful error messages
   - Log errors for debugging

4. PDF Errors
   - Handle corrupted PDF files
   - Show error for unsupported formats
   - Graceful degradation if annotations fail
   - Cache validation

5. Sync Conflicts
   - Implement last-write-wins
   - Preserve conflict history
   - Show conflict resolution UI
   - Allow manual conflict resolution

### Backend Error Handling

1. OCR Errors
   - Handle unsupported image formats
   - Timeout for long-running OCR
   - Return partial results on failure
   - Log OCR failures

2. RAG Indexing Errors
   - Track failed indexing jobs
   - Retry with exponential backoff
   - Update job status in database
   - Notify user of failures

3. AI Provider Errors
   - Handle rate limits
   - Fallback to alternative providers
   - Timeout for slow responses
   - Return error messages to client

4. Database Errors
   - Connection pool management
   - Transaction rollback on failure
   - Retry transient errors
   - Log all database errors

5. Encryption Errors
   - Validate encryption keys
   - Handle decryption failures
   - Secure error logging
   - Fail securely

## Testing Strategy

### Unit Testing

**Flutter Client**
- Test each service in isolation with mocks
- Test data models and serialization
- Test UI widgets with widget tests
- Test state management logic
- Coverage target: 80%

**FastAPI Backend**
- Test each endpoint with pytest
- Test service layer logic
- Test encryption/decryption
- Test AI provider implementations
- Coverage target: 80%

### Integration Testing

**Flutter Client**
- Test authentication flow end-to-end
- Test Drive operations with test account
- Test offline sync scenarios
- Test PDF viewing and annotation
- Test realtime collaboration

**FastAPI Backend**
- Test API endpoints with test database
- Test OCR pipeline with sample images
- Test RAG indexing with sample PDFs
- Test AI chat with mock providers
- Test encryption with test keys

### End-to-End Testing

- Test complete user workflows
- Test cross-device synchronization
- Test collaboration scenarios
- Test offline-to-online transitions
- Test performance with large datasets

### Testing Per Phase

Each incremental phase includes specific tests:

**Phase 1**: Auth flow works, user profile displays
**Phase 2**: Files list, upload works, folders created
**Phase 3**: Offline browsing works, sync queue processes
**Phase 4**: PDFs open and render correctly
**Phase 5**: Annotations persist and display
**Phase 6**: Backend health checks pass, DB connected
**Phase 7**: Annotations sync across devices
**Phase 8**: Scanned documents become searchable PDFs
**Phase 9**: GROQ integration works for chat and embeddings
**Phase 10**: Documents get indexed with progress tracking, reindex works
**Phase 11**: Chat returns relevant, cited answers with clickable citations
**Phase 12**: Tags work for organization and filtering
**Phase 13**: Sharing works, permissions enforced
**Phase 14**: Public links accessible without auth
**Phase 15**: Annotations appear in realtime
**Phase 16**: File operations sync in realtime
**Phase 17**: Presence shows active users
**Phase 18**: TTS reads PDFs correctly
**Phase 19**: Performance acceptable with large library

### Performance Testing

- Load testing with large PDF libraries
- Stress testing realtime collaboration
- Memory profiling for mobile devices
- Network performance testing
- Database query optimization

### Security Testing

- Test RLS policies
- Test encryption/decryption
- Test OAuth flow security
- Test API authentication
- Test input validation
- Penetration testing

## Deployment Architecture

### Development Environment

```
┌─────────────────────────────────────────┐
│         Developer Machine               │
│                                         │
│  ┌─────────────┐    ┌─────────────┐   │
│  │   Flutter   │    │   FastAPI   │   │
│  │   (local)   │    │   (local)   │   │
│  └─────────────┘    └─────────────┘   │
│                                         │
│  ┌─────────────┐    ┌─────────────┐   │
│  │    Drift    │    │  ChromaDB   │   │
│  │   (local)   │    │   (local)   │   │
│  └─────────────┘    └─────────────┘   │
└─────────────────────────────────────────┘
           │                │
           │                │
           ▼                ▼
    ┌──────────┐      ┌──────────┐
    │ Supabase │      │  Google  │
    │  (cloud) │      │   Drive  │
    └──────────┘      └──────────┘
```

### Production Environment

```
┌─────────────────────────────────────────┐
│         User Devices                    │
│  (iOS, Android, Web, Desktop)           │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │      Flutter Application        │   │
│  │      with Drift Database        │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
           │                │
           │                │
           ▼                ▼
    ┌──────────┐      ┌──────────┐
    │  Google  │      │ Supabase │
    │   Drive  │      │ Postgres │
    │   API    │      │+Realtime │
    └──────────┘      └──────────┘
                            │
                            │
                            ▼
┌─────────────────────────────────────────┐
│    FastAPI Backend (Free Hosting)       │
│    (Render/Railway/Fly.io)              │
│                                         │
│  ┌─────────────┐    ┌─────────────┐   │
│  │   FastAPI   │    │  ChromaDB   │   │
│  │   Server    │    │   Vector    │   │
│  │             │    │   Store     │   │
│  └─────────────┘    └─────────────┘   │
└─────────────────────────────────────────┘
```

### Environment Variables

**Flutter Client (.env)**
```
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
BACKEND_API_URL=your_backend_url
```

**FastAPI Backend (.env)**
```
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_KEY=your_supabase_service_key
ENCRYPTION_KEY=your_encryption_key
CHROMADB_HOST=localhost
CHROMADB_PORT=8000
GROQ_API_KEY=your_groq_api_key
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
```

## Security Considerations

1. OAuth Token Security
   - Store refresh tokens encrypted in Supabase
   - Never expose tokens in client logs
   - Rotate tokens regularly
   - Use HTTPS for all token transmission

2. Data Encryption
   - Encrypt sensitive data at rest
   - Use AES-256 for encryption
   - Secure key management
   - Encrypt API keys

3. API Security
   - Implement rate limiting
   - Validate all inputs
   - Use CORS properly
   - Implement request signing

4. Database Security
   - Enable RLS on all tables
   - Use parameterized queries
   - Limit connection pool size
   - Regular security audits

5. Client Security
   - Secure local storage
   - Validate server responses
   - Implement certificate pinning
   - Obfuscate sensitive code

## Performance Optimizations

1. Caching Strategy
   - Cache only opened files
   - Implement LRU eviction
   - Compress cached data
   - Background cache cleanup

2. Lazy Loading
   - Paginate file listings
   - Load thumbnails on demand
   - Lazy load PDF pages
   - Stream large files

3. Database Optimization
   - Index frequently queried columns
   - Use connection pooling
   - Implement query caching
   - Optimize N+1 queries

4. Network Optimization
   - Batch API requests
   - Compress request/response
   - Use HTTP/2
   - Implement request deduplication

5. Embedding Generation
   - Batch embedding requests
   - Cache embeddings
   - Use user API keys to avoid rate limits
   - Implement queue for large libraries

## Monitoring and Logging

1. Application Logging
   - Log all errors with context
   - Log authentication events
   - Log sync operations
   - Log API requests

2. Performance Monitoring
   - Track API response times
   - Monitor memory usage
   - Track cache hit rates
   - Monitor sync queue size

3. Error Tracking
   - Centralized error logging
   - Error alerting
   - Error categorization
   - Error trend analysis

4. User Analytics
   - Track feature usage
   - Monitor user engagement
   - Track error rates
   - Performance metrics

## Scalability Considerations

1. Horizontal Scaling
   - Stateless backend design
   - Load balancer ready
   - Shared ChromaDB instance
   - Database connection pooling

2. Vertical Scaling
   - Optimize memory usage
   - Efficient data structures
   - Query optimization
   - Resource monitoring

3. Data Partitioning
   - User-based data isolation
   - Separate ChromaDB collections per user
   - Efficient indexing strategy
   - Archive old data

4. Rate Limiting
   - Per-user rate limits
   - Per-endpoint rate limits
   - Graceful degradation
   - Queue management