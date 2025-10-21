# Implementation Plan — ScholarMate

## Phase 1: Foundation & Authentication (Testable Checkpoint)

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


## Phase 2: Drive Integration & File Browsing (Testable Checkpoint)

- [ ] 3. Implement Google Drive service and file operations
  - [ ] 3.1 Create DriveService with Google Drive API integration
    - Implement createAppFolder() to create ScholarMate folder in Drive
    - Implement listFiles(folderId) to fetch files and folders
    - Implement uploadFile() for PDF and Markdown uploads
    - Implement createFolder(), deleteFile(), renameFile(), moveFile() operations
    - _Requirements: 3.1, 3.2, 3.4, 3.5_
  
  - [ ] 3.2 Build modern file explorer UI
    - Create responsive file browser with tree view for web/desktop
    - Create collapsible folder view for mobile with smooth animations
    - Design colorful file/folder cards with icons, metadata (size, date)
    - Implement pull-to-refresh gesture for mobile
    - Add floating action button (FAB) for upload/create folder with animated menu
    - _Requirements: 3.3, 3.6_
  
  - [ ] 3.3 Implement file upload interface
    - Create file picker dialog supporting PDF and Markdown files
    - Build upload progress indicator with percentage and cancel option
    - Add drag-and-drop support for web/desktop
    - Implement error handling with user-friendly messages
    - _Requirements: 3.5_
  
  - [ ] 3.4 Implement folder operations UI
    - Create folder creation dialog with validation
    - Implement context menu for file/folder operations (rename, move, delete)
    - Add confirmation dialogs for destructive actions
    - Implement breadcrumb navigation for folder hierarchy
    - _Requirements: 3.4_

**Test Checkpoint**: User can browse Drive folders, upload files, create folders, and perform file operations with a modern, responsive UI.

## Phase 3: Offline Foundation & Local Cache (Testable Checkpoint)

- [ ] 4. Implement local caching and offline support
  - [ ] 4.1 Create SQLite database schema and CacheService
    - Initialize sqflite database with tables: files, folders, annotations, sync_queue, cached_pdfs
    - Implement cacheFileMetadata() and getCachedFiles() methods
    - Implement cachePdfBytes() and getCachedPdf() methods
    - Implement cacheAnnotation() and getCachedAnnotations() methods
    - _Requirements: 4.1, 4.2_
  
  - [ ] 4.2 Create ConnectivityService for online/offline detection
    - Implement connectivity monitoring using connectivity_plus package
    - Create isOnline stream for reactive connectivity state
    - _Requirements: 4.3_
  
  - [ ] 4.3 Build SyncManager for offline action queuing
    - Implement queueAction() to store offline operations in sync_queue table
    - Implement processSyncQueue() to sync queued actions when online
    - Create syncStatusStream for UI updates
    - Implement exponential backoff for failed sync attempts
    - _Requirements: 4.5, 4.6_
  
  - [ ] 4.4 Add online/offline indicator to UI
    - Create animated status indicator in app bar (green=online, orange=syncing, gray=offline)
    - Display sync status with pending action count
    - Show cached file indicators (cloud icon with checkmark)
    - Add manual sync trigger button
    - _Requirements: 4.3, 4.4_

**Test Checkpoint**: User can browse cached files offline, perform actions that queue for sync, and see automatic synchronization when connectivity is restored.

## Phase 4: PDF Viewing (Testable Checkpoint)

- [ ] 5. Implement PDF viewer with caching
  - [ ] 5.1 Create PdfViewerManager service
    - Implement loadPdf() to download from Drive or load from cache
    - Integrate syncfusion_flutter_pdfviewer for PDF rendering
    - Implement page navigation methods (jumpToPage, next, previous)
    - _Requirements: 5.1, 5.2, 5.3_
  
  - [ ] 5.2 Build modern PDF viewer screen
    - Create full-screen PDF viewer with gesture controls (pinch-to-zoom, swipe)
    - Design sleek toolbar with navigation controls (page counter, thumbnails)
    - Implement bottom navigation bar with page slider
    - Add search functionality within PDF
    - Implement responsive layout adapting to screen size
    - _Requirements: 5.3, 5.4_
  
  - [ ] 5.3 Implement PDF caching logic
    - Cache PDF bytes in cached_pdfs table on first open
    - Display download progress for large PDFs
    - Show cached indicator for offline-available PDFs
    - Implement cache size management with LRU eviction
    - _Requirements: 5.2, 5.5, 5.6_

**Test Checkpoint**: User can open PDFs online and offline, navigate pages smoothly, and see cached PDFs marked with indicators.

## Phase 5: PDF Annotations (Testable Checkpoint)

- [ ] 6. Implement PDF annotation system
  - [ ] 6.1 Create annotation tools in PDF viewer
    - Add annotation toolbar with highlight, underline, and comment tools
    - Implement color picker for annotations (modern color palette)
    - Create text input dialog for comment annotations
    - Implement annotation selection and editing
    - _Requirements: 6.1_
  
  - [ ] 6.2 Implement annotation embedding in PDF
    - Embed annotations directly in PDF bytes using syncfusion PDF library
    - Store annotation metadata in Local_Cache annotations table
    - Generate unique annotation_id for each annotation
    - Track author_id, author_name, timestamps, type, page, bounding_box, content
    - _Requirements: 6.2, 6.3_
  
  - [ ] 6.3 Build annotation list panel
    - Create side panel (desktop) or bottom sheet (mobile) showing all annotations
    - Display annotations grouped by page with author info and timestamps
    - Implement click-to-navigate functionality
    - Add filter options (by author, by type, by date)
    - Design with modern card-based layout
    - _Requirements: 6.4, 6.5_
  
  - [ ] 6.4 Enable offline annotation creation
    - Allow annotation creation while offline
    - Queue annotations in sync_queue for later sync
    - Show sync status indicator for pending annotations
    - _Requirements: 6.6_

**Test Checkpoint**: User can create, view, and navigate annotations in PDFs both online and offline, with annotations persisting locally.


## Phase 6: Backend Infrastructure & Supabase (Testable Checkpoint)

- [ ] 7. Set up FastAPI backend infrastructure
  - [ ] 7.1 Initialize FastAPI project with uv
    - Create pyproject.toml with dependencies (fastapi, uvicorn, supabase, cryptography, langchain, langchain-chroma, langchain-community)
    - Set up project structure (routers/, services/, models/, utils/)
    - Configure CORS for Flutter client requests
    - Implement environment variable loading
    - _Requirements: 10.1, 10.3, 10.4_
  
  - [ ] 7.2 Create health check and documentation endpoints
    - Implement GET /api/health endpoint
    - Enable OpenAPI documentation at /docs
    - Add version endpoint with API version info
    - _Requirements: 10.2, 10.5_
  
  - [ ] 7.3 Implement request logging and error handling
    - Set up structured logging with request IDs
    - Create global exception handlers
    - Log all API requests with timestamps and user context
    - _Requirements: 10.6_

- [ ] 8. Set up Supabase database and RLS policies
  - [ ] 8.1 Create Supabase project and database schema
    - Create tables: users, encrypted_tokens, files, annotations, shares, ingestion_jobs, api_keys, audit_logs
    - Add indexes on frequently queried columns
    - _Requirements: 7.2, 7.6_
  
  - [ ] 8.2 Implement Row Level Security policies
    - Enable RLS on all tables
    - Create policies ensuring users access only their own data
    - Test RLS policies with multiple user contexts
    - _Requirements: 7.3_
  
  - [ ] 8.3 Create EncryptionService for sensitive data
    - Implement encrypt() and decrypt() methods using AES-256
    - Create storeEncryptedToken() and getDecryptedToken() methods
    - Test encryption/decryption with sample tokens
    - _Requirements: 7.4_
  
  - [ ] 8.4 Implement token management endpoints
    - Create POST /api/auth/store-tokens endpoint
    - Create GET /api/auth/refresh-token endpoint
    - Implement BackendDriveService for fetching files using user tokens
    - _Requirements: 7.5_

**Test Checkpoint**: Backend health checks pass, database is connected with RLS policies enforced, and tokens are stored/retrieved securely.

## Phase 7: Annotation Sync (Testable Checkpoint)

- [ ] 9. Implement annotation synchronization
  - [ ] 9.1 Create annotation sync API endpoints
    - Implement GET /api/annotations/{file_id} to fetch annotations
    - Implement POST /api/annotations/sync for bulk annotation sync
    - Implement PUT /api/annotations/{annotation_id} for updates
    - Implement DELETE /api/annotations/{annotation_id} for deletion
    - _Requirements: 8.1, 8.2_
  
  - [ ] 9.2 Implement conflict resolution logic
    - Apply last-write-wins strategy using timestamp_updated
    - Preserve annotation version history in database
    - Return conflict information to client
    - _Requirements: 8.4_
  
  - [ ] 9.3 Integrate annotation sync in Flutter client
    - Call sync endpoint when creating annotations online
    - Process sync_queue for offline annotations when connectivity restored
    - Fetch latest annotations from backend on file open
    - Update Local_Cache with synced data
    - _Requirements: 8.3, 8.5, 8.6_
  
  - [ ] 9.4 Add sync status indicators to UI
    - Show syncing indicator during annotation sync
    - Display sync errors with retry option
    - Show last sync timestamp in annotation list
    - _Requirements: 8.3_

**Test Checkpoint**: Annotations sync across devices, conflicts are resolved correctly, and sync status is visible to users.

## Phase 8: OCR & Document Scanning (Testable Checkpoint)

- [ ] 10. Implement OCR and document scanning
  - [ ] 10.1 Create camera capture interface in Flutter
    - Integrate camera package for document capture
    - Implement perspective correction using image processing
    - Create multi-page scanning flow with preview
    - Design modern camera UI with capture button and flash controls
    - _Requirements: 11.1, 11.2_
  
  - [ ] 10.2 Build OCR processing service in backend
    - Implement POST /api/ocr/process endpoint
    - Integrate Tesseract or EasyOCR for text extraction
    - Process images and return OCR text
    - Handle OCR errors and timeouts gracefully
    - _Requirements: 11.3, 11.4_
  
  - [ ] 10.3 Create searchable PDF generation
    - Implement PDF creation with embedded OCR text layer
    - Show OCR text preview before saving
    - Upload searchable PDF to Google Drive
    - Update file metadata in cache
    - _Requirements: 11.5, 11.6_
  
  - [ ] 10.4 Design scanning workflow UI
    - Create scan button in file explorer FAB menu
    - Build scanning screen with page counter and retake option
    - Show OCR processing progress
    - Display success confirmation with option to open PDF
    - _Requirements: 11.1, 11.6_

**Test Checkpoint**: User can scan documents with camera, OCR processes images, and searchable PDFs are created and saved to Drive.

## Phase 9: AI Provider Abstraction (Testable Checkpoint)

- [ ] 11. Implement AI model provider system
  - [ ] 11.1 Create AIModelProvider abstract base class
    - Define abstract methods: chat() and embed()
    - Create provider configuration data models
    - _Requirements: 12.1_
  
  - [ ] 11.2 Implement concrete AI provider classes
    - Create OpenRouterProvider implementation
    - Create OpenAIProvider implementation
    - Create ClaudeProvider implementation
    - Create GeminiProvider implementation
    - Create GrokProvider implementation
    - Handle provider-specific API formats and errors
    - _Requirements: 12.2, 12.6_
  
  - [ ] 11.3 Create API key management endpoints
    - Implement POST /api/api-keys to store encrypted user API keys
    - Implement GET /api/api-keys to list configured providers
    - Implement DELETE /api/api-keys/{provider} to remove keys
    - _Requirements: 12.4_
  
  - [ ] 11.4 Build AI settings UI in Flutter
    - Create settings screen with provider selection
    - Add API key input fields for each provider
    - Show provider status (configured/not configured)
    - Implement secure key storage and transmission
    - Design modern settings UI with provider logos
    - _Requirements: 12.3, 12.4_
  
  - [ ] 11.5 Implement provider selection logic
    - Use user-provided API keys when available
    - Fall back to system default provider
    - Handle rate limits and provider errors
    - _Requirements: 12.5, 12.6_

**Test Checkpoint**: User can configure different AI providers with custom API keys, and the system uses the selected provider for AI operations.


## Phase 10: RAG Indexing with LangChain (Testable Checkpoint)

- [ ] 12. Implement RAG indexing system with LangChain
  - [ ] 12.1 Set up ChromaDB with per-user collections
    - Install and configure ChromaDB
    - Install LangChain and LangChain-Chroma integration
    - Implement user-specific collection creation (naming: user_{user_id}_documents)
    - Implement ChromaDB client in backend with collection management
    - _Requirements: 13.5, 13.6, 13.10_
  
  - [ ] 12.2 Create RAGIndexer service with LangChain
    - Implement indexFile() to start indexing jobs
    - Integrate LangChain PyPDFLoader for PDF text extraction
    - Implement extractAndChunkText() using LangChain RecursiveCharacterTextSplitter
    - Configure chunk size (1000) and overlap (200) parameters
    - Implement generateEmbeddings() using LangChain embedding models with configured AI provider
    - Implement storeEmbeddings() to save in user-specific ChromaDB collection with metadata
    - Implement getUserCollection() to get or create user's vector store
    - _Requirements: 13.2, 13.3, 13.4, 13.5, 13.6_
  
  - [ ] 12.3 Create indexing API endpoints
    - Implement POST /api/ingest/start to trigger indexing with user_id
    - Implement GET /api/ingest/status/{job_id} for status tracking
    - Implement POST /api/ingest/reindex/{file_id} for manual re-indexing
    - Ensure all endpoints enforce user isolation
    - _Requirements: 13.1, 13.8, 13.10_
  
  - [ ] 12.4 Implement async job processing
    - Create background task queue for indexing jobs
    - Track job status in ingestion_jobs table (pending, processing, completed, failed)
    - Update progress (chunks_processed, total_chunks)
    - Handle indexing errors and retries
    - _Requirements: 13.7_
  
  - [ ] 12.5 Build indexing status UI in Flutter
    - Show indexing status badge on files (indexed, indexing, failed)
    - Create indexing progress indicator with percentage
    - Add manual re-index option in file context menu
    - Display indexing errors with details
    - _Requirements: 13.8_
  
  - [ ] 12.6 Trigger automatic indexing on upload
    - Call indexing API when user uploads PDF
    - Show indexing started notification
    - Update UI when indexing completes
    - _Requirements: 13.1_

**Test Checkpoint**: Documents are automatically indexed in user-specific collections after upload, indexing status is tracked and displayed, users cannot access other users' vector data, and manual re-indexing works.

## Phase 11: AI Chat with RAG and Source Selection (Testable Checkpoint)

- [ ] 13. Implement AI chat with semantic search and source filtering
  - [ ] 13.1 Create RAGQueryService with LangChain
    - Implement query() method for end-to-end RAG pipeline with source filtering
    - Integrate LangChain RetrievalQA chain for question answering
    - Implement retrieveContext() to query user's ChromaDB collection with metadata filtering
    - Use LangChain retriever with file_id filtering for selected sources
    - Implement generateResponse() using LangChain prompt templates and chains
    - Extract file_id and page_number for citations from retrieved documents
    - Implement getUserVectorstore() to access user-specific collection
    - _Requirements: 14.3, 14.4, 14.5, 14.6_
  
  - [ ] 13.2 Create AI chat API endpoint with source filtering
    - Implement POST /api/ai/chat endpoint accepting question, user_id, and selected_file_ids
    - Filter retrieval results to only include chunks from selected sources
    - Return AI response with citations array
    - Handle errors and timeouts
    - Ensure user isolation (only query user's own collection)
    - _Requirements: 14.2, 14.3, 14.5_
  
  - [ ] 13.3 Build modern chat interface with source selection in Flutter
    - Create chat screen with message list and input field
    - Add source selection panel showing user's files and folders
    - Implement checkboxes for selecting/deselecting sources
    - Show selected source count in chat input area
    - Design message bubbles (user vs AI) with modern styling
    - Show typing indicator while AI is responding
    - Display citations as clickable chips below AI messages
    - Implement smooth scrolling and animations
    - Make responsive for all screen sizes
    - _Requirements: 14.1, 14.2, 14.8, 14.9_
  
  - [ ] 13.4 Implement source selection persistence
    - Store selected sources in local database
    - Load previous source selection when opening chat
    - Allow "Select All" and "Clear All" options
    - Show visual indicator for selected sources
    - _Requirements: 14.10_
  
  - [ ] 13.5 Implement citation navigation
    - Make citation chips clickable
    - Open PDF to referenced page when citation clicked
    - Highlight referenced section if available
    - _Requirements: 14.8_
  
  - [ ] 13.6 Add save chat response feature
    - Implement "Save as Note" button on AI messages
    - Create Markdown file with chat response
    - Save to Google Drive in Notes folder
    - Show success notification
    - _Requirements: 14.9_
  
  - [ ] 13.7 Add chat history and context
    - Store chat history with source selection in local database
    - Display previous conversations in sidebar
    - Allow continuing previous chats with same source selection
    - Implement clear chat option
    - _Requirements: 14.1_

**Test Checkpoint**: User can ask questions with selected sources, receive AI responses with citations only from selected documents, click citations to view source, persist source preferences, and save responses as notes.

## Phase 11.5: File Organization with Tags (Testable Checkpoint)

- [ ] 13.5. Implement tag management system
  - [ ] 13.5.1 Create tag database schema and service
    - Add tags and file_tags tables to SQLite schema
    - Add tags and file_tags tables to Supabase schema with RLS policies
    - Create TagService in Flutter with CRUD operations
    - Implement tag synchronization between local cache and Supabase
    - _Requirements: 22.7_
  
  - [ ] 13.5.2 Build tag management UI
    - Create tag management screen accessible from settings
    - Implement tag creation dialog with name and color picker
    - Display list of all tags with document counts
    - Add rename and delete options for tags
    - Show confirmation dialog for tag deletion
    - Design with modern card-based layout and color chips
    - _Requirements: 22.2, 22.9_
  
  - [ ] 13.5.3 Implement tag application to files
    - Add "Manage Tags" option to file context menu
    - Create tag selection dialog showing all available tags
    - Allow selecting multiple tags for a file
    - Display selected tags as colored chips on file cards
    - Implement bulk tagging for multiple selected files
    - Show tag application success notification
    - _Requirements: 22.1, 22.3, 22.8_
  
  - [ ] 13.5.4 Add tag filtering and search to file explorer
    - Create tag filter panel in file explorer sidebar
    - Display all tags with document counts
    - Allow selecting multiple tags for filtering (AND/OR logic)
    - Combine tag filtering with filename search
    - Show active filters with clear option
    - Update file list in realtime as filters change
    - _Requirements: 22.4, 22.5_
  
  - [ ] 13.5.5 Implement sorting options
    - Add sort dropdown to file explorer toolbar
    - Implement sorting by: tag, name, date, size
    - Support ascending/descending order
    - Persist sort preference in local storage
    - _Requirements: 22.6_
  
  - [ ] 13.5.6 Add tag statistics and visualization
    - Create tag statistics view showing document count per tag
    - Display tag usage chart or visualization
    - Show most used tags
    - Add quick filter from statistics view
    - _Requirements: 22.9_
  
  - [ ] 13.5.7 Implement realtime tag synchronization
    - Broadcast tag changes via Supabase Realtime
    - Update UI when tags are modified on other devices
    - Handle tag conflicts with last-write-wins
    - Show sync status for tag operations
    - _Requirements: 22.10_

**Test Checkpoint**: User can create and manage tags, apply multiple tags to files, filter and search by tags, sort files by various criteria, see tag statistics, and tags sync across devices in realtime.

## Phase 12: Sharing & Permissions (Testable Checkpoint)

- [ ] 14. Implement file sharing with role-based permissions
  - [ ] 14.1 Create sharing dialog UI
    - Build modern sharing dialog with email input
    - Add role selector (Viewer/Editor) with descriptions
    - Show list of current collaborators with roles
    - Add remove collaborator option
    - Design with modern card-based layout
    - _Requirements: 15.1, 15.2_
  
  - [ ] 14.2 Implement Google Drive sharing integration
    - Create shareFile() method in DriveService
    - Set Google Drive permissions based on role
    - Handle sharing errors gracefully
    - _Requirements: 15.3_
  
  - [ ] 14.3 Store sharing metadata in Supabase
    - Save share records in shares table
    - Track shared_with_email, role, shared_by_user_id
    - Implement recursive folder sharing logic
    - _Requirements: 15.4, 15.5_
  
  - [ ] 14.4 Implement permission enforcement in UI
    - Check user role before showing edit options
    - Disable annotation tools for Viewer role
    - Hide file operation options for Viewer role
    - Show read-only indicator for Viewer role
    - Allow resharing only for Editor role
    - _Requirements: 15.6, 15.7_
  
  - [ ] 14.5 Add shared files view
    - Create "Shared with me" section in file explorer
    - Display shared files with owner information
    - Show role badge on shared files
    - _Requirements: 15.4_

**Test Checkpoint**: User can share files with collaborators, assign roles, and permissions are enforced correctly in the UI.

## Phase 13: Public Link Sharing (Testable Checkpoint)

- [ ] 15. Implement public link sharing
  - [ ] 15.1 Add public link generation to sharing dialog
    - Add "Create public link" toggle in sharing dialog
    - Generate public link using Google Drive API
    - Display link with copy button
    - Show link status (active/revoked)
    - _Requirements: 16.1, 16.2, 16.3_
  
  - [ ] 15.2 Implement public link access
    - Create public view route accepting link parameter
    - Display content in read-only mode without authentication
    - Show "View only" banner
    - Disable all edit operations
    - _Requirements: 16.4_
  
  - [ ] 15.3 Add link revocation feature
    - Implement revoke button in sharing dialog
    - Remove Google Drive public permissions
    - Update UI to show revoked status
    - _Requirements: 16.5_
  
  - [ ] 15.4 Implement audit logging for public links
    - Log public link creation in audit_logs table
    - Log public link access attempts
    - Display access logs to link creator
    - _Requirements: 16.6_

**Test Checkpoint**: User can create public view-only links, anyone can access content via link without authentication, and links can be revoked.


## Phase 14: Realtime Annotations (Testable Checkpoint)

- [ ] 16. Implement realtime annotation collaboration
  - [ ] 16.1 Create RealtimeService in Flutter
    - Integrate Supabase Realtime client
    - Implement connect() and channel subscription methods
    - Implement subscribeToFile() for file-specific channels
    - Create eventStream for reactive updates
    - _Requirements: 17.1_
  
  - [ ] 16.2 Implement annotation broadcasting
    - Broadcast annotation events when user creates/updates/deletes annotations
    - Include annotation metadata and author info in events
    - Handle broadcast errors gracefully
    - _Requirements: 17.2_
  
  - [ ] 16.3 Implement realtime annotation updates in PDF viewer
    - Subscribe to file channel when opening shared PDF
    - Listen for annotation events from collaborators
    - Update PDF viewer with new annotations in realtime
    - Show author name and avatar on annotations
    - _Requirements: 17.2, 17.3, 17.4_
  
  - [ ] 16.4 Implement conflict resolution for concurrent edits
    - Apply last-write-wins using timestamps
    - Preserve version history in database
    - Show conflict notification to users
    - _Requirements: 17.5_
  
  - [ ] 16.5 Add typing indicators for comments
    - Broadcast typing events when user is composing comment
    - Display "User is typing..." indicator in annotation panel
    - Clear indicator after timeout or message sent
    - _Requirements: 17.6_

**Test Checkpoint**: Collaborators see annotations appear in realtime, typing indicators work, and conflicts are resolved automatically.

## Phase 15: Realtime File Operations (Testable Checkpoint)

- [ ] 17. Implement realtime file operation sync
  - [ ] 17.1 Implement folder channel subscriptions
    - Subscribe to folder channels when viewing shared folders
    - Handle multiple active subscriptions
    - Unsubscribe when leaving folder view
    - _Requirements: 18.1_
  
  - [ ] 17.2 Broadcast file operation events
    - Broadcast events for add, rename, move, delete operations
    - Include operation type, file metadata, and actor info
    - Handle broadcast failures with retry
    - _Requirements: 18.2_
  
  - [ ] 17.3 Update file explorer in realtime
    - Listen for file operation events
    - Update file list without full refresh
    - Show smooth animations for file additions/removals
    - Display notification for file changes by collaborators
    - _Requirements: 18.3_
  
  - [ ] 17.4 Implement permission change broadcasting
    - Broadcast events when permissions are modified
    - Include new permission details in event
    - _Requirements: 18.4_
  
  - [ ] 17.5 Handle realtime permission updates
    - Update user permissions in realtime
    - Adjust UI based on new permissions
    - Show notification when permissions change
    - Redirect if access is revoked
    - _Requirements: 18.5_
  
  - [ ] 17.6 Implement concurrent operation conflict resolution
    - Apply last-write-wins for conflicting operations
    - Handle edge cases (delete vs rename)
    - Show conflict resolution result to users
    - _Requirements: 18.6_

**Test Checkpoint**: File operations by collaborators appear instantly, permission changes are reflected in realtime, and conflicts are handled gracefully.

## Phase 16: Presence & Activity (Testable Checkpoint)

- [ ] 18. Implement presence and activity tracking
  - [ ] 18.1 Implement presence broadcasting
    - Broadcast presence when user opens file
    - Include user info (name, avatar, timestamp)
    - Send heartbeat to maintain presence
    - Broadcast departure when closing file
    - _Requirements: 19.1, 19.5_
  
  - [ ] 18.2 Display active collaborators in UI
    - Show avatar stack of active users in PDF viewer toolbar
    - Display user names on hover
    - Update presence list in realtime
    - Remove inactive users after timeout
    - _Requirements: 19.2, 19.6_
  
  - [ ] 18.3 Implement page tracking
    - Broadcast current page number when user navigates
    - Include page info in presence data
    - _Requirements: 19.3_
  
  - [ ] 18.4 Display collaborator page positions
    - Show which page each collaborator is viewing
    - Add page indicator next to user avatars
    - Update page positions in realtime
    - Implement "Jump to user's page" feature
    - _Requirements: 19.4_
  
  - [ ] 18.5 Add presence animations and polish
    - Animate avatar appearance/disappearance
    - Show pulse effect for active users
    - Display "User joined" / "User left" notifications
    - _Requirements: 19.2_

**Test Checkpoint**: Users see who else is viewing documents, which pages they're on, and presence updates in realtime.

## Phase 17: Read Aloud (Testable Checkpoint)

- [ ] 19. Implement text-to-speech for PDFs
  - [ ] 19.1 Integrate flutter_tts package
    - Add flutter_tts dependency
    - Initialize TTS engine with language settings
    - Configure voice and speech rate options
    - _Requirements: 20.1_
  
  - [ ] 19.2 Create read-aloud controls in PDF viewer
    - Add read-aloud button to PDF toolbar
    - Create control panel with play, pause, stop buttons
    - Add speed adjustment slider (0.5x to 2x)
    - Design modern, minimalist control UI
    - _Requirements: 20.2, 20.4_
  
  - [ ] 19.3 Implement text extraction and speech
    - Extract text from current PDF page
    - Send text to TTS engine
    - Handle speech events (start, complete, error)
    - _Requirements: 20.3_
  
  - [ ] 19.4 Implement auto-page advancement
    - Detect when current page speech completes
    - Automatically advance to next page
    - Continue reading until end of document or user stops
    - _Requirements: 20.5_
  
  - [ ] 19.5 Add text highlighting during speech
    - Highlight currently spoken text in PDF viewer
    - Scroll to keep highlighted text visible
    - Clear highlighting when speech stops
    - _Requirements: 20.6_
  
  - [ ] 19.6 Add read-aloud settings
    - Create settings for voice selection
    - Add language selection option
    - Save user preferences
    - _Requirements: 20.4_

**Test Checkpoint**: User can activate read-aloud, listen to PDFs with adjustable speed, see text highlighting, and experience auto-page advancement.

## Phase 18: Performance & Polish (Testable Checkpoint)

- [ ] 20. Optimize performance and polish UI
  - [ ] 20.1 Implement caching optimizations
    - Cache only opened files to minimize storage
    - Implement LRU eviction for cache management
    - Add cache size limit settings
    - Implement background cache cleanup
    - _Requirements: 21.1_
  
  - [ ] 20.2 Optimize backend indexing performance
    - Process indexing jobs asynchronously
    - Implement incremental indexing for large libraries
    - Add progress tracking for long-running jobs
    - Implement rate limiting for embedding generation
    - _Requirements: 21.2, 21.3, 21.4_
  
  - [ ] 20.3 Implement pagination for large folders
    - Add pagination to file listings (50 items per page)
    - Implement infinite scroll for mobile
    - Add page navigation for desktop
    - Optimize database queries with limits
    - _Requirements: 21.5, 21.6_
  
  - [ ] 20.4 Polish UI with animations and transitions
    - Add smooth page transitions between screens
    - Implement skeleton loaders for loading states
    - Add micro-interactions (button press effects, hover states)
    - Ensure consistent spacing and typography
    - _Requirements: UI design requirements_
  
  - [ ] 20.5 Implement responsive design refinements
    - Test and optimize for mobile (phones, tablets)
    - Test and optimize for desktop (various screen sizes)
    - Test and optimize for web browsers
    - Ensure touch targets are appropriately sized (min 44x44)
    - Verify text readability at all sizes
    - _Requirements: UI design requirements_
  
  - [ ] 20.6 Add dark mode support
    - Create dark theme with modern color palette
    - Implement theme toggle in settings
    - Ensure all screens support both themes
    - Save theme preference
    - _Requirements: UI design requirements_
  
  - [ ] 20.7 Implement accessibility features
    - Add semantic labels for screen readers
    - Ensure sufficient color contrast (WCAG AA)
    - Support keyboard navigation for web/desktop
    - Add focus indicators
    - Test with accessibility tools
    - _Requirements: UI design requirements_
  
  - [ ]* 20.8 Perform end-to-end testing
    - Test complete user workflows across all features
    - Test cross-device synchronization scenarios
    - Test collaboration with multiple users
    - Test offline-to-online transitions
    - Test performance with large document libraries
    - _Requirements: All requirements_
  
  - [ ]* 20.9 Create user documentation
    - Write user guide covering all features
    - Create video tutorials for key workflows
    - Document troubleshooting steps
    - Add in-app help tooltips
    - _Requirements: Documentation_

**Test Checkpoint**: App performs well with large libraries, UI is polished and responsive across all devices, and all features work smoothly together.

---

## Notes

- Each phase builds incrementally on previous phases
- Test checkpoints ensure working functionality at each stage
- Optional tasks (marked with *) can be skipped for faster MVP
- UI design emphasizes modern, colorful, responsive interfaces
- All tasks reference specific requirements from requirements.md
- Focus on testable, demonstrable progress at each checkpoint
