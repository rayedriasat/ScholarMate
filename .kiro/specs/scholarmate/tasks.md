# Implementation Plan — ScholarMate

## Phase 1: Foundation & Authentication (Testable Checkpoint) ✅ COMPLETED

- [x] 1. Set up monorepo project structure
  - Create root directory with frontend/ and backend/ folders
  - Initialize Flutter project in frontend/ with proper folder structure (lib/models, lib/services, lib/screens, lib/widgets)
  - Initialize FastAPI project in backend/ with pyproject.toml using uv package manager
  - Create root README.md with setup instructions and architecture overview
  - Create environment template files (frontend.env.template, backend.env.template)
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2. Implement Google OAuth authentication flow
  - [x] 2.1 Set up Google Cloud Console project and OAuth credentials
    - Configure OAuth consent screen with drive.file scope
    - Generate client ID and client secret for web, iOS, and Android
    - _Requirements: 2.1_
  
  - [x] 2.2 Create Flutter AuthService with Google Sign-In
    - Implement signInWithGoogle() method using google_sign_in package
    - Implement signOut() method
    - Implement getAccessToken() and refreshToken() methods
    - Create authStateChanges stream for reactive auth state
    - _Requirements: 2.1, 2.2, 2.5_
  
  - [x] 2.3 Build modern authentication UI screens
    - Create splash screen with animated ScholarMate logo
    - Create login screen with Google Sign-In button (modern gradient design)
    - Implement responsive layout for mobile, tablet, and desktop
    - Add loading states and error handling UI
    - _Requirements: 2.1, 2.6_
  
  - [x] 2.4 Create backend token storage endpoint
    - Implement POST /api/auth/store-tokens endpoint in FastAPI
    - Create EncryptionService for token encryption using AES-256
    - Store encrypted tokens in Supabase encrypted_tokens table
    - _Requirements: 2.3, 2.4_
  
  - [x] 2.5 Display user profile after authentication
    - Create home screen scaffold with user avatar and name in app bar
    - Implement sign-out functionality
    - Add smooth transitions between auth states
    - _Requirements: 2.6_

**Test Checkpoint**: User can sign in with Google, see their profile, and sign out successfully.
✅ **COMPLETED AND VERIFIED**

## Phase 2: Drive Integration & File Browsing (Testable Checkpoint) ✅ COMPLETED

- [x] 3. Implement Google Drive service and file operations
  - [x] 3.1 Create DriveService with Google Drive API integration
    - Implement createAppFolder() to create ScholarMate folder in Drive
    - Implement listFiles(folderId) to fetch files and folders
    - Implement uploadFile() for PDF and Markdown uploads
    - Implement createFolder(), deleteFile(), renameFile(), moveFile() operations
    - _Requirements: 3.1, 3.2, 3.4, 3.5_
  
  - [x] 3.2 Build modern file explorer UI
    - Create responsive file browser with tree view for web/desktop
    - Create collapsible folder view for mobile with smooth animations
    - Design colorful file/folder cards with icons, metadata (size, date)
    - Implement pull-to-refresh gesture for mobile
    - Add floating action button (FAB) for upload/create folder with animated menu
    - _Requirements: 3.3, 3.6_
  
  - [x] 3.3 Implement file upload interface
    - Create file picker dialog supporting PDF and Markdown files
    - Build upload progress indicator with percentage and cancel option
    - Add drag-and-drop support for web/desktop
    - Implement error handling with user-friendly messages
    - _Requirements: 3.5_
  
  - [x] 3.4 Implement folder operations UI
    - Create folder creation dialog with validation
    - Implement context menu for file/folder operations (rename, move, delete)
    - Add confirmation dialogs for destructive actions
    - Implement breadcrumb navigation for folder hierarchy
    - _Requirements: 3.4_

**Test Checkpoint**: User can browse Drive folders, upload files, create folders, and perform file operations with a modern, responsive UI.
✅ **COMPLETED AND VERIFIED** - Works on Android and web, authentication and drive access tokens persist

## Phase 3: Offline Foundation & Local Cache (Testable Checkpoint) ✅ COMPLETED

- [x] 4. Implement local caching and offline support using Drift
  - [x] 4.1 Create Drift database schema and CacheService
    - Add drift, drift_flutter, and build_runner dependencies to pubspec.yaml
    - Define Drift tables: files, cached_pdfs, annotations, sync_queue
    - Generate Drift database code using build_runner
    - Implement cacheFileMetadata() and getCachedFiles() methods
    - Implement cachePdfBytes() and getCachedPdf() methods
    - Implement cacheAnnotation() and getCachedAnnotations() methods
    - Add cache statistics and management methods
    - _Requirements: 4.1, 4.2_
  
  - [x] 4.2 Create ConnectivityService for online/offline detection
    - Added connectivity_plus dependency to pubspec.yaml
    - Implemented connectivity monitoring using connectivity_plus package
    - Created isOnline stream for reactive connectivity state
    - Added manual connectivity check method
    - _Requirements: 4.3_
  
  - [x] 4.3 Build SyncManager for offline action queuing
    - Implemented queueAction() to store offline operations in sync_queue table
    - Implemented processSyncQueue() to sync queued actions when online
    - Created syncStatusStream for UI updates
    - Implemented exponential backoff for failed sync attempts (max 5 retries)
    - Added support for file, folder, and annotation operations
    - _Requirements: 4.5, 4.6_
  
  - [x] 4.4 Add online/offline indicator to UI
    - Created ConnectivityIndicator widget with animated status (green=online, orange=syncing, gray=offline)
    - Display sync status with pending action count
    - Show cached file indicators (green checkmark on PDF icons)
    - Added manual sync trigger button in status dialog
    - Integrated indicator into HomeScreen app bar
    - _Requirements: 4.3, 4.4_

  - [x] 4.5 Migrate from sqflite to Drift for cross-platform support
    - ✅ Created Drift database schema with tables (Files, CachedPdfs, Annotations, SyncQueue)
    - ✅ Implemented AppDatabase class with type-safe queries
    - ✅ Updated CacheService to use Drift instead of sqflite
    - ✅ Added web support with SQLite WASM (sqlite3_web package)
    - ✅ Created drift_worker.dart for non-blocking web operations
    - ✅ Generated database code with build_runner
    - ✅ Tested on Android and Web platforms
    - ✅ Created DRIFT_MIGRATION.md documentation
    - _Requirements: Cross-platform offline support including web_
    - **Files**: `lib/database/database.dart`, `lib/database/tables.dart`, `lib/database/drift_worker.dart`, `lib/services/cache_service.dart`

**Test Checkpoint**: User can browse cached files offline, perform actions that queue for sync, and see automatic synchronization when connectivity is restored.
✅ **COMPLETED** - Drift database with offline support, connectivity monitoring, sync queue, and UI indicators implemented

## Phase 4: PDF Viewing (Testable Checkpoint) ✅ COMPLETED

- [x] 5. Implement PDF viewer with caching
  - [x] 5.1 Create PdfViewerManager service
    - ✅ Added syncfusion_flutter_pdfviewer dependency to pubspec.yaml
    - ✅ Implemented loadPdf() to download from Drive or load from cache
    - ✅ Integrated syncfusion_flutter_pdfviewer for PDF rendering
    - ✅ Implemented page navigation methods (jumpToPage, next, previous)
    - _Requirements: 5.1, 5.2, 5.3_
    - **Files**: `lib/services/pdf_viewer_manager.dart`
  
  - [x] 5.2 Build modern PDF viewer screen
    - ✅ Created full-screen PDF viewer with gesture controls (pinch-to-zoom, swipe)
    - ✅ Designed sleek toolbar with navigation controls (page counter, go to page)
    - ✅ Implemented bottom navigation bar with page slider
    - ✅ Added search functionality within PDF
    - ✅ Implemented responsive layout adapting to screen size
    - _Requirements: 5.3, 5.4_
    - **Files**: `lib/screens/pdf_viewer_screen.dart`
  
  - [x] 5.3 Implement PDF caching logic
    - ✅ Cache PDF bytes in cached_pdfs table on first open (via DriveService)
    - ✅ Display download progress for large PDFs
    - ✅ Show cached indicator for offline-available PDFs (green badge)
    - ✅ Integrated with existing cache service and LRU eviction
    - _Requirements: 5.2, 5.5, 5.6_
    - **Files**: `lib/services/pdf_viewer_manager.dart`, `lib/services/drive_service.dart`

**Test Checkpoint**: User can open PDFs online and offline, navigate pages smoothly, and see cached PDFs marked with indicators.
✅ **COMPLETED** - PDF viewer with caching, navigation controls, search, and offline support implemented

## Phase 5: PDF Annotations (Testable Checkpoint) ✅ COMPLETED

- [x] 6. Implement PDF annotation system
  - [x] 6.1 Create annotation tools in PDF viewer
    - Add annotation toolbar with highlight, underline, and comment tools
    - Implement color picker for annotations (modern color palette)
    - Create text input dialog for comment annotations
    - Implement annotation selection and editing
    - _Requirements: 6.1_
  
  - [x] 6.2 Implement annotation embedding in PDF
    - Embed annotations directly in PDF bytes using syncfusion PDF library
    - Store annotation metadata in Local_Cache annotations table
    - Generate unique annotation_id for each annotation
    - Track author_id, author_name, timestamps, type, page, bounding_box, content
    - _Requirements: 6.2, 6.3_
  
  - [x] 6.3 Build annotation list panel
    - Create side panel (desktop) or bottom sheet (mobile) showing all annotations
    - Display annotations grouped by page with author info and timestamps
    - Implement click-to-navigate functionality
    - Add filter options (by author, by type, by date)
    - Design with modern card-based layout
    - _Requirements: 6.4, 6.5_
  
  - [x] 6.4 Enable offline annotation creation
    - Allow annotation creation while offline
    - Queue annotations in sync_queue for later sync
    - Show sync status indicator for pending annotations
    - _Requirements: 6.6_

**Test Checkpoint**: User can create, view, and navigate annotations in PDFs both online and offline, with annotations persisting locally.
✅ **COMPLETED** - Annotation toolbar, embedding, list panel, and offline support implemented
**Note**: Annotations display correctly in app and web; Drive may show yellow highlights only (Google Drive limitation)

## Phase 6: Backend Infrastructure & Supabase (Testable Checkpoint) ✅ COMPLETED

- [x] 7. Set up FastAPI backend infrastructure
  - [x] 7.1 Initialize FastAPI project with uv
    - Create pyproject.toml with dependencies (fastapi, uvicorn, supabase, cryptography)
    - Set up project structure (routers/, services/, models/, utils/)
    - Configure CORS for Flutter client requests
    - Implement environment variable loading
    - _Requirements: 10.1, 10.3, 10.4_
  
  - [x] 7.2 Create health check and documentation endpoints
    - Implement GET /api/health endpoint
    - Enable OpenAPI documentation at /docs
    - Add version endpoint with API version info
    - _Requirements: 10.2, 10.5_
  
  - [x] 7.3 Implement request logging and error handling
    - Set up structured logging with request IDs
    - Create global exception handlers
    - Log all API requests with timestamps and user context
    - _Requirements: 10.6_

- [x] 8. Set up Supabase database and RLS policies
  - [x] 8.1 Create Supabase project and database schema
    - Create tables: users, encrypted_tokens, files, annotations, shares, ingestion_jobs, api_keys, audit_logs
    - Add indexes on frequently queried columns
    - _Requirements: 7.2, 7.6_
  
  - [x] 8.2 Implement Row Level Security policies
    - Enable RLS on all tables
    - Create policies ensuring users access only their own data
    - Test RLS policies with multiple user contexts
    - _Requirements: 7.3_
  
  - [x] 8.3 Create EncryptionService for sensitive data
    - Implement encrypt() and decrypt() methods using AES-256
    - Create storeEncryptedToken() and getDecryptedToken() methods
    - Test encryption/decryption with sample tokens
    - _Requirements: 7.4_
  
  - [x] 8.4 Implement token management endpoints
    - Create POST /api/auth/store-tokens endpoint ✅
    - Create GET /api/auth/refresh-token endpoint ✅
    - Implement BackendDriveService for fetching files using user tokens (needed for Phase 10 RAG indexing)
    - _Requirements: 7.5_

**Test Checkpoint**: Backend health checks pass, database is connected with RLS policies enforced, and tokens are stored/retrieved securely.
✅ **COMPLETED** - FastAPI backend with logging, error handling, Supabase database schema, RLS policies, encryption service, and token management endpoints implemented

## Phase 7: Annotation Sync (Testable Checkpoint) ✅ COMPLETED

- [x] 9. Implement annotation synchronization
  - [x] 9.1 Create annotation sync API endpoints
    - Implement GET /api/annotations/{file_id} to fetch annotations ✅
    - Implement POST /api/annotations/sync for bulk annotation sync ✅
    - Implement PUT /api/annotations/{annotation_id} for updates ✅
    - Implement DELETE /api/annotations/{annotation_id} for deletion ✅
    - Implement POST /api/annotations/ for creating annotations ✅
    - _Requirements: 8.1, 8.2_
  
  - [x] 9.2 Implement conflict resolution logic
    - Apply last-write-wins strategy using timestamp_updated ✅
    - Preserve annotation version history in database ✅
    - Return conflict information to client ✅
    - _Requirements: 8.4_
  
  - [x] 9.3 Integrate annotation sync in Flutter client
    - Call sync endpoint when creating annotations online ✅
    - Process sync_queue for offline annotations when connectivity restored ✅
    - Fetch latest annotations from backend on file open ✅
    - Update Local_Cache with synced data ✅
    - _Requirements: 8.3, 8.5, 8.6_
  
  - [x] 9.4 Add sync status indicators to UI
    - Show syncing indicator during annotation sync ✅
    - Display sync errors with retry option ✅
    - Show last sync timestamp in annotation list ✅
    - _Requirements: 8.3_

**Test Checkpoint**: Annotations sync across devices, conflicts are resolved correctly, and sync status is visible to users.
✅ **COMPLETED** - Annotation synchronization with conflict resolution, offline queue processing, and sync status indicators implemented

## Phase 8: OCR & Document Scanning (Testable Checkpoint) ✅ COMPLETED

- [x] 10. Implement OCR and document scanning with hybrid online/offline mode
  - [x] 10.1 Create camera capture interface in Flutter
    - Add camera dependency to pubspec.yaml ✅
    - Integrate camera package for document capture ✅
    - Implement perspective correction using image processing ✅ (basic)
    - Create multi-page scanning flow with preview ✅
    - Design modern camera UI with capture button and flash controls ✅
    - _Requirements: 11.1, 11.2_
  
  - [x] 10.2 Build DeepSeek OCR service in backend (online mode)
    - Add DeepSeek OCR dependencies to pyproject.toml ✅
    - Implement POST /api/ocr/process endpoint using DeepSeek OCR API ✅
    - Implement POST /api/ocr/pdf-to-markdown endpoint for PDF conversion ✅
    - Process images and return OCR text with high accuracy ✅
    - Support PDF to Markdown conversion with structure preservation ✅
    - Handle OCR errors and timeouts gracefully ✅
    - _Requirements: 11.3, 11.4_
  
  - [x] 10.3 Implement Flutter Tesseract for offline Android OCR
    - Add flutter_tesseract_ocr dependency to pubspec.yaml ✅
    - Implement offline OCR fallback using flutter_tesseract_ocr ✅
    - Detect online/offline status and route to appropriate OCR service ✅
    - Show OCR mode indicator (DeepSeek/Tesseract) in UI ✅
    - Cache Tesseract language data for offline use ✅
    - _Requirements: 11.3, 11.4_
  
  - [x] 10.4 Create searchable PDF generation
    - Implement PDF creation with embedded OCR text layer ✅
    - Show OCR text preview before saving ✅
    - Upload searchable PDF to Google Drive ✅
    - Update file metadata in cache ✅
    - _Requirements: 11.5, 11.6_
  
  - [x] 10.5 Implement Markdown conversion and editor
    - Add markdown editor dependencies (flutter_markdown) ✅
    - Create Markdown preview screen with live rendering ✅
    - Implement Markdown editor with toolbar (bold, italic, headers, lists, links) ✅
    - Support PDF to Markdown conversion via backend ✅
    - Save Markdown files to Google Drive ✅
    - Cache Markdown files for offline editing ✅
    - _Requirements: 11.7, 11.8_
  
  - [x] 10.6 Design scanning workflow UI
    - Create scan button in file explorer FAB menu ✅
    - Build scanning screen with page counter and retake option ✅
    - Show OCR processing progress with mode indicator ✅
    - Display success confirmation with option to open PDF or convert to Markdown ✅
    - Add "Convert to Markdown" option in PDF context menu ✅ (in OCR preview)
    - _Requirements: 11.1, 11.6_

**Test Checkpoint**: User can scan documents with camera, OCR processes images using DeepSeek (online) or Tesseract (offline), searchable PDFs are created, and PDFs can be converted to Markdown with preview/editing capabilities.
✅ **COMPLETED** - Hybrid OCR with DeepSeek (online) and Tesseract (offline), automatic mode detection, OCR mode indicator, searchable PDF generation, Markdown conversion and editor with formatting toolbar implemented. See TASK_10_HYBRID_OCR_COMPLETE.md for details.

## Phase 9: GROQ AI Integration (Testable Checkpoint)

- [x] 11. Implement GROQ AI service
  - [x] 11.1 Set up GROQ integration in backend
    - Add GROQ SDK dependencies to pyproject.toml (groq, langchain-groq)
    - Add GROQ_API_KEY to backend/.env configuration
    - Create GROQService class with chat() and embed() methods
    - Implement error handling for GROQ API errors and rate limits
    - Add logging for GROQ API usage and errors
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.6_
  
  - [x] 11.2 Test GROQ integration
    - Create test endpoint POST /api/ai/test-groq for testing GROQ connectivity
    - Test chat completion with sample prompts
    - Test embedding generation with sample texts
    - Verify error handling and rate limiting
    - _Requirements: 12.3, 12.4_

**Test Checkpoint**: GROQ API integration works correctly for chat and embeddings, with proper error handling and logging.

✅ **COMPLETED** - GROQ AI service integrated with chat and embedding support, comprehensive error handling, logging, and test endpoints. See TASK_11_GROQ_INTEGRATION.md for details.

## Phase 10: RAG Indexing with LangChain and GROQ (Testable Checkpoint)

- [ ] 12. Implement RAG indexing system with LangChain
  - [x] 12.1 Set up ChromaDB with per-user collections
    - Add ChromaDB dependencies to pyproject.toml (chromadb, langchain, langchain-chroma, langchain-groq)
    - Install and configure ChromaDB (self-hosted)
    - Install LangChain and LangChain-Chroma integration
    - Implement user-specific collection creation (naming: user_{user_id}_documents)
    - Implement ChromaDB client in backend with collection management
    - Create BackendDriveService for fetching files from Google Drive using user's encrypted tokens
    - Test user isolation by verifying separate collections per user
    - _Requirements: 13.2, 13.6, 13.12_
    - **✅ COMPLETED** - ChromaDB service with per-user collections, Drive service for file fetching, comprehensive tests passing. See backend/docs/CHROMADB_IMPLEMENTATION.md
  
  - [x] 12.2 Create RAGIndexer service with LangChain and GROQ






    - Implement indexFile() to start indexing jobs with user_id and file_id
    - Integrate LangChain PyPDFLoader for PDF text extraction
    - Implement extractAndChunkText() using LangChain RecursiveCharacterTextSplitter
    - Configure chunk size (1000) and overlap (200) parameters
    - Implement generateEmbeddings() using LangChain GROQ embedding models
    - Implement storeEmbeddings() to save in user-specific ChromaDB collection with metadata (file_id, page_number, chunk_index)
    - Implement getUserCollection() to get or create user's vector store
    - Ensure Google Drive is the source of truth by fetching files directly from Drive
    - _Requirements: 13.2, 13.3, 13.4, 13.5, 13.6, 13.7_
  
  - [x] 12.3 Create indexing API endpoints





    - Implement POST /api/ingest/start to trigger indexing with user_id and file_id
    - Implement GET /api/ingest/status/{job_id} for status tracking with progress
    - Implement GET /api/ingest/list/{user_id} to list all indexing jobs for user
    - Implement POST /api/ingest/reindex/{file_id} for manual re-indexing
    - Ensure all endpoints enforce user isolation (only access own data)
    - _Requirements: 13.1, 13.10, 13.12_
  
  - [x] 12.4 Implement async job processing with progress tracking




    - Create background task queue for indexing jobs
    - Track job status in ingestion_jobs table (pending, processing, completed, failed)
    - Update progress (chunks_processed, total_chunks, progress_percentage)
    - Handle indexing errors and retries with exponential backoff
    - Store error messages for failed jobs
    - _Requirements: 13.8_
  
  - [x] 12.5 Build indexing status UI in Flutter




    - Show indexing status badge on files (indexed ✓, indexing ⟳, pending ⏳, failed ✗)
    - Create indexing progress panel showing all files with status and percentage
    - Add manual "Reindex" button in file context menu
    - Display indexing errors with details in error dialog
    - Show which files are indexed and which are pending
    - Add "Reindex All" button to reindex all PDFs
    - Update UI in realtime as indexing progresses
    - _Requirements: 13.9, 13.10, 13.11_
  
  - [ ] 12.6 Trigger automatic indexing on upload
    - Call indexing API when user uploads PDF with user_id
    - Show indexing started notification
    - Update UI when indexing completes or fails
    - Fetch file from Google Drive (source of truth) for indexing
    - _Requirements: 13.1_

**Test Checkpoint**: Documents are automatically indexed in user-specific collections after upload using GROQ embeddings, indexing status is tracked and displayed with progress, users cannot access other users' vector data, manual re-indexing works, and Google Drive is the source of truth for all files.

## Phase 11: AI Chat with RAG, Source Selection, and Clickable Citations (Testable Checkpoint)

- [ ] 13. Implement AI chat with semantic search and source filtering using GROQ
  - [ ] 13.1 Create RAGQueryService with LangChain and GROQ
    - Implement query() method for end-to-end RAG pipeline with source filtering
    - Integrate LangChain RetrievalQA chain for question answering using GROQ
    - Implement retrieveContext() to query user's ChromaDB collection with metadata filtering
    - Use LangChain retriever with file_id filtering for selected sources
    - Implement generateResponse() using LangChain prompt templates and GROQ
    - Extract file_id, file_name, and page_number for citations from retrieved documents
    - Implement getUserVectorstore() to access user-specific collection
    - Ensure user isolation (only query user's own collection)
    - _Requirements: 14.3, 14.4, 14.5, 14.6, 14.13_
  
  - [ ] 13.2 Create AI chat API endpoint with source filtering
    - Implement POST /api/ai/chat endpoint accepting question, user_id, and selected_file_ids
    - Filter retrieval results to only include chunks from selected sources using metadata
    - Return AI response with citations array containing {file_id, file_name, page_number}
    - Handle GROQ errors and timeouts gracefully
    - Ensure user isolation (only query user's own collection)
    - _Requirements: 14.3, 14.5, 14.7, 14.13_
  
  - [ ] 13.3 Build modern chat interface with source selection in Flutter
    - Create chat screen with message list and input field
    - Add source selection panel showing user's files and folders
    - Implement checkboxes for selecting/deselecting sources
    - Show selected source count in chat input area
    - Design message bubbles (user vs AI) with modern styling
    - Show typing indicator while AI is responding
    - Display citations as clickable chips below AI messages with file name and page number
    - Implement smooth scrolling and animations
    - Make responsive for all screen sizes
    - _Requirements: 14.1, 14.2, 14.8_
  
  - [ ] 13.4 Implement clickable citations with PDF navigation
    - Make citation chips clickable with tap gesture
    - WHEN user clicks citation, open PDF viewer using syncfusion_flutter_pdfviewer
    - Navigate to the referenced page_number using jumpToPage() method
    - Highlight or indicate the referenced section in the PDF viewer
    - Show citation source info (file name, page) in PDF viewer toolbar
    - Handle errors if file is not cached (download from Google Drive first)
    - _Requirements: 14.8, 14.9, 14.10_
  
  - [ ] 13.5 Implement source selection persistence
    - Store selected sources in local Drift database
    - Load previous source selection when opening chat
    - Allow "Select All" and "Clear All" options
    - Show visual indicator for selected sources
    - _Requirements: 14.12_
  
  - [ ] 13.6 Add save chat response feature
    - Implement "Save as Note" button on AI messages
    - Create Markdown file with chat response and citations
    - Save to Google Drive in Notes folder
    - Show success notification
    - _Requirements: 14.11_
  
  - [ ] 13.7 Add chat history and context
    - Store chat history with source selection in local database
    - Display previous conversations in sidebar
    - Allow continuing previous chats with same source selection
    - Implement clear chat option
    - _Requirements: 14.1_

**Test Checkpoint**: User can ask questions with selected sources using GROQ, receive AI responses with citations only from selected documents, click citations to open PDF viewer at the exact page, persist source preferences, and save responses as notes. All data is isolated per user.

## Phase 12: File Organization with Tags (Testable Checkpoint)

**Note**: Supabase schema already includes tags and file_tags tables with RLS policies (see backend/migrations/001_initial_schema.sql)

- [ ] 14. Implement tag management system
  - [ ] 14.1 Create tag database schema and service
    - Add Tags and FileTags tables to Drift schema (frontend/lib/database/tables.dart)
    - Regenerate Drift database code with build_runner
    - Create TagService in Flutter with CRUD operations (createTag, renameTag, deleteTag, addTagToFile, etc.)
    - Implement tag synchronization between local cache and Supabase
    - _Requirements: 22.7_
  
  - [ ] 14.2 Build tag management UI
    - Create tag management screen accessible from settings
    - Implement tag creation dialog with name and color picker
    - Display list of all tags with document counts
    - Add rename and delete options for tags
    - Show confirmation dialog for tag deletion
    - Design with modern card-based layout and color chips
    - _Requirements: 22.2, 22.9_
  
  - [ ] 14.3 Implement tag application to files
    - Add "Manage Tags" option to file context menu
    - Create tag selection dialog showing all available tags
    - Allow selecting multiple tags for a file
    - Display selected tags as colored chips on file cards
    - Implement bulk tagging for multiple selected files
    - Show tag application success notification
    - _Requirements: 22.1, 22.3, 22.8_
  
  - [ ] 14.4 Add tag filtering and search to file explorer
    - Create tag filter panel in file explorer sidebar
    - Display all tags with document counts
    - Allow selecting multiple tags for filtering (AND/OR logic)
    - Combine tag filtering with filename search
    - Show active filters with clear option
    - Update file list in realtime as filters change
    - _Requirements: 22.4, 22.5_
  
  - [ ] 14.5 Implement sorting options
    - Add sort dropdown to file explorer toolbar
    - Implement sorting by: tag, name, date, size
    - Support ascending/descending order
    - Persist sort preference in local storage
    - _Requirements: 22.6_
  
  - [ ] 14.6 Add tag statistics and visualization
    - Create tag statistics view showing document count per tag
    - Display tag usage chart or visualization
    - Show most used tags
    - Add quick filter from statistics view
    - _Requirements: 22.9_
  
  - [ ] 14.7 Implement realtime tag synchronization
    - Broadcast tag changes via Supabase Realtime
    - Update UI when tags are modified on other devices
    - Handle tag conflicts with last-write-wins
    - Show sync status for tag operations
    - _Requirements: 22.10_

**Test Checkpoint**: User can create and manage tags, apply multiple tags to files, filter and search by tags, sort files by various criteria, see tag statistics, and tags sync across devices in realtime.

## Phase 13: Sharing & Permissions (Testable Checkpoint)

- [ ] 15. Implement file sharing with role-based permissions
  - [ ] 15.1 Create sharing dialog UI
    - Build modern sharing dialog with email input
    - Add role selector (Viewer/Editor) with descriptions
    - Show list of current collaborators with roles
    - Add remove collaborator option
    - Design with modern card-based layout
    - _Requirements: 15.1, 15.2_
  
  - [ ] 15.2 Implement Google Drive sharing integration
    - Create shareFile() method in DriveService
    - Set Google Drive permissions based on role
    - Handle sharing errors gracefully
    - _Requirements: 15.3_
  
  - [ ] 15.3 Store sharing metadata in Supabase
    - Save share records in shares table
    - Track shared_with_email, role, shared_by_user_id
    - Implement recursive folder sharing logic
    - _Requirements: 15.4, 15.5_
  
  - [ ] 15.4 Implement permission enforcement in UI
    - Check user role before showing edit options
    - Disable annotation tools for Viewer role
    - Hide file operation options for Viewer role
    - Show read-only indicator for Viewer role
    - Allow resharing only for Editor role
    - _Requirements: 15.6, 15.7_
  
  - [ ] 15.5 Add shared files view
    - Create "Shared with me" section in file explorer
    - Display shared files with owner information
    - Show role badge on shared files
    - _Requirements: 15.4_

**Test Checkpoint**: User can share files with collaborators, assign roles, and permissions are enforced correctly in the UI.

## Phase 14: Public Link Sharing (Testable Checkpoint)

- [ ] 16. Implement public link sharing
  - [ ] 16.1 Add public link generation to sharing dialog
    - Add "Create public link" toggle in sharing dialog
    - Generate public link using Google Drive API
    - Display link with copy button
    - Show link status (active/revoked)
    - _Requirements: 16.1, 16.2, 16.3_
  
  - [ ] 16.2 Implement public link access
    - Create public view route accepting link parameter
    - Display content in read-only mode without authentication
    - Show "View only" banner
    - Disable all edit operations
    - _Requirements: 16.4_
  
  - [ ] 16.3 Add link revocation feature
    - Implement revoke button in sharing dialog
    - Remove Google Drive public permissions
    - Update UI to show revoked status
    - _Requirements: 16.5_
  
  - [ ] 16.4 Implement audit logging for public links
    - Log public link creation in audit_logs table
    - Log public link access attempts
    - Display access logs to link creator
    - _Requirements: 16.6_

**Test Checkpoint**: User can create public view-only links, anyone can access content via link without authentication, and links can be revoked.

## Phase 15: Realtime Annotations (Testable Checkpoint)

- [ ] 17. Implement realtime annotation collaboration
  - [ ] 17.1 Create RealtimeService in Flutter
    - Add supabase_flutter dependency to pubspec.yaml
    - Integrate Supabase Realtime client
    - Implement connect() and channel subscription methods
    - Implement subscribeToFile() for file-specific channels
    - Create eventStream for reactive updates
    - _Requirements: 17.1_
  
  - [ ] 17.2 Implement annotation broadcasting
    - Broadcast annotation events when user creates/updates/deletes annotations
    - Include annotation metadata and author info in events
    - Handle broadcast errors gracefully
    - _Requirements: 17.2_
  
  - [ ] 17.3 Implement realtime annotation updates in PDF viewer
    - Subscribe to file channel when opening shared PDF
    - Listen for annotation events from collaborators
    - Update PDF viewer with new annotations in realtime
    - Show author name and avatar on annotations
    - _Requirements: 17.2, 17.3, 17.4_
  
  - [ ] 17.4 Implement conflict resolution for concurrent edits
    - Apply last-write-wins using timestamps
    - Preserve version history in database
    - Show conflict notification to users
    - _Requirements: 17.5_
  
  - [ ] 17.5 Add typing indicators for comments
    - Broadcast typing events when user is composing comment
    - Display "User is typing..." indicator in annotation panel
    - Clear indicator after timeout or message sent
    - _Requirements: 17.6_

**Test Checkpoint**: Collaborators see annotations appear in realtime, typing indicators work, and conflicts are resolved automatically.

## Phase 16: Realtime File Operations (Testable Checkpoint)

- [ ] 18. Implement realtime file operation sync
  - [ ] 18.1 Implement folder channel subscriptions
    - Subscribe to folder channels when viewing shared folders
    - Handle multiple active subscriptions
    - Unsubscribe when leaving folder view
    - _Requirements: 18.1_
  
  - [ ] 18.2 Broadcast file operation events
    - Broadcast events for add, rename, move, delete operations
    - Include operation type, file metadata, and actor info
    - Handle broadcast failures with retry
    - _Requirements: 18.2_
  
  - [ ] 18.3 Update file explorer in realtime
    - Listen for file operation events
    - Update file list without full refresh
    - Show smooth animations for file additions/removals
    - Display notification for file changes by collaborators
    - _Requirements: 18.3_
  
  - [ ] 18.4 Implement permission change broadcasting
    - Broadcast events when permissions are modified
    - Include new permission details in event
    - _Requirements: 18.4_
  
  - [ ] 18.5 Handle realtime permission updates
    - Update user permissions in realtime
    - Adjust UI based on new permissions
    - Show notification when permissions change
    - Redirect if access is revoked
    - _Requirements: 18.5_
  
  - [ ] 18.6 Implement concurrent operation conflict resolution
    - Apply last-write-wins for conflicting operations
    - Handle edge cases (delete vs rename)
    - Show conflict resolution result to users
    - _Requirements: 18.6_

**Test Checkpoint**: File operations by collaborators appear instantly, permission changes are reflected in realtime, and conflicts are handled gracefully.

## Phase 17: Presence & Activity (Testable Checkpoint)

- [ ] 19. Implement presence and activity tracking
  - [ ] 19.1 Implement presence broadcasting
    - Broadcast presence when user opens file
    - Include user info (name, avatar, timestamp)
    - Send heartbeat to maintain presence
    - Broadcast departure when closing file
    - _Requirements: 19.1, 19.5_
  
  - [ ] 19.2 Display active collaborators in UI
    - Show avatar stack of active users in PDF viewer toolbar
    - Display user names on hover
    - Update presence list in realtime
    - Remove inactive users after timeout
    - _Requirements: 19.2, 19.6_
  
  - [ ] 19.3 Implement page tracking
    - Broadcast current page number when user navigates
    - Include page info in presence data
    - Show page indicators for collaborators
    - _Requirements: 19.3_
  
  - [ ] 19.4 Add activity feed
    - Create activity feed showing recent actions
    - Display file opens, annotations, comments
    - Show timestamps and user info
    - Filter by file or user
    - _Requirements: 19.4_

**Test Checkpoint**: Users can see who's actively viewing files, what page they're on, and recent activity from collaborators.

## Phase 18: Read Aloud & Performance (Testable Checkpoint)

- [ ] 20. Implement text-to-speech and performance optimizations
  - [ ] 20.1 Implement PDF read aloud feature
    - Add flutter_tts dependency to pubspec.yaml
    - Integrate flutter_tts for text-to-speech functionality
    - Display read-aloud controls in PDF viewer toolbar
    - Extract text from current page and speak it
    - Provide controls for play, pause, stop, and speed adjustment
    - Automatically advance to next page when current page completes
    - Highlight currently spoken text in PDF viewer
    - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5, 20.6_
  
  - [ ] 20.2 Implement performance optimizations
    - Cache only opened files to minimize storage usage
    - Process indexing jobs asynchronously without blocking API requests
    - Implement incremental indexing with progress tracking for large libraries
    - Implement rate limiting and throttling for embedding generation
    - Implement pagination for large folder listings
    - Optimize database queries with appropriate indexes and query limits
    - _Requirements: 21.1, 21.2, 21.3, 21.4, 21.5, 21.6_
  
  - [ ] 20.3 Polish UI and user experience
    - Implement smooth animations and transitions throughout the app
    - Add loading skeletons for better perceived performance
    - Optimize responsive layouts for all screen sizes
    - Implement dark mode support
    - Add keyboard shortcuts for power users
    - Improve error messages and user feedback
    - _Requirements: UI design requirements_
  
  - [ ] 20.4 Implement accessibility features
    - Add semantic labels for screen readers
    - Ensure sufficient color contrast (WCAG AA)
    - Support keyboard navigation for web/desktop
    - Add focus indicators
    - Test with accessibility tools
    - _Requirements: UI design requirements_
  
  - [ ]* 20.5 Perform end-to-end testing
    - Test complete user workflows across all features
    - Test cross-device synchronization scenarios
    - Test collaboration with multiple users
    - Test offline-to-online transitions
    - Test performance with large document libraries
    - _Requirements: All requirements_
  
  - [ ]* 20.6 Create user documentation
    - Write user guide covering all features
    - Create video tutorials for key workflows
    - Document troubleshooting steps
    - Add in-app help tooltips
    - _Requirements: Documentation_

**Test Checkpoint**: App performs well with large libraries, UI is polished and responsive across all devices, read-aloud works smoothly, and all features work together seamlessly.

---

## Notes

- **✅ COMPLETED**: Phases 1-6 are fully implemented and verified
  - Phase 1: Foundation & Authentication
  - Phase 2: Drive Integration & File Browsing
  - Phase 3: Offline Foundation & Local Cache
  - Phase 4: PDF Viewing
  - Phase 5: PDF Annotations
  - Phase 6: Backend Infrastructure & Supabase
- **🔄 NEXT**: Phase 7 - Annotation Synchronization
- Each phase builds incrementally on previous phases
- Test checkpoints ensure working functionality at each stage
- Optional tasks (marked with *) can be skipped for faster MVP
- UI design emphasizes modern, colorful, responsive interfaces
- All tasks reference specific requirements from requirements.md
- Focus on testable, demonstrable progress at each checkpoint

## Current Implementation Status

### ✅ Completed Phases (1-6):
**Phase 1: Foundation & Authentication**
- Google OAuth authentication with token persistence
- Modern splash and login screens
- User profile display with sign-out

**Phase 2: Drive Integration & File Browsing**
- Google Drive API integration (create app folder, list files, upload, CRUD operations)
- Modern responsive file explorer UI with breadcrumb navigation
- File upload with progress indicators and drag-and-drop
- Folder operations (create, rename, delete, move)
- Context menus and confirmation dialogs

**Phase 3: Offline Foundation & Local Cache**
- Drift database with cross-platform support (including web)
- Connectivity monitoring with online/offline detection
- Sync queue for offline operations with exponential backoff
- UI indicators for connectivity and sync status
- Cached file indicators

**Phase 4: PDF Viewing**
- Syncfusion PDF viewer integration
- PDF download and caching
- Page navigation controls and search
- Responsive layout for all screen sizes

**Phase 5: PDF Annotations**
- Annotation toolbar (highlight, underline, strikethrough, squiggly, note)
- Color picker with modern palette
- Annotation embedding in PDF bytes
- Annotation list panel with filtering
- Offline annotation creation with sync queue

**Phase 6: Backend Infrastructure & Supabase**
- FastAPI backend with uv package manager
- Structured logging with request IDs
- Global exception handlers
- Health check and documentation endpoints
- Supabase database schema (8 tables)
- Row Level Security policies
- Encryption service (AES-256)
- Token management endpoints

### 🔄 Next Priority (Phase 7):
**Annotation Synchronization** - The next logical step is to implement annotation sync across devices:
1. Create annotation sync API endpoints (GET, POST, PUT, DELETE)
2. Implement conflict resolution logic (last-write-wins)
3. Integrate sync in Flutter client
4. Add sync status indicators to UI

### 📋 Future Dependencies to Add:

**Frontend (Flutter):**
- `camera` - Document scanning (Phase 8)
- `flutter_tesseract_ocr` - Offline OCR for Android (Phase 8)
- `flutter_markdown` - Markdown preview (Phase 8)
- `markdown_editable_textinput` - Markdown editor (Phase 8)
- `supabase_flutter` - Realtime features (Phase 15+)
- `flutter_tts` - Text-to-speech (Phase 18)

**Backend (FastAPI):**
- DeepSeek OCR SDK - Online OCR with high accuracy (Phase 8)
- `langchain` - RAG implementation (Phase 10)
- `chromadb` - Vector database (Phase 10)