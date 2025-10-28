# Requirements Document — ScholarMate

## Introduction

ScholarMate is an offline-first, Google-Drive-backed AI research workspace for managing PDFs and Markdown files. The system enables users to store files in their own Google Drive, work offline with full functionality, annotate PDFs, perform semantic search using RAG, and collaborate in realtime. The architecture uses only free-tier services and follows an incremental development approach where each phase delivers testable, working functionality.

## Glossary

- **ScholarMate_System**: The complete application including Flutter frontend and FastAPI backend
- **Flutter_Client**: The cross-platform mobile/web/desktop application built with Flutter
- **FastAPI_Backend**: The Python backend service handling OCR, RAG indexing, and AI queries
- **Google_Drive_Storage**: User's Google Drive app folder where all files are stored
- **Local_Cache**: Drift database storing offline copies and metadata (works on all platforms including web)
- **Supabase_Metadata_DB**: PostgreSQL database storing user metadata, sharing info, and encrypted tokens
- **ChromaDB_Vector_Store**: Self-hosted vector database for RAG embeddings with per-user collections
- **LangChain_Framework**: Python framework for building LLM applications with document loaders, text splitters, and retrieval chains
- **Annotation**: User-created highlights, underlines, or comments embedded in PDF files
- **RAG_System**: Retrieval-Augmented Generation system for semantic search and AI chat using LangChain
- **Tag**: User-defined label for organizing and categorizing PDFs and notes
- **Sync_Queue**: Local queue of offline actions pending synchronization
- **Viewer_Role**: Read-only permission level for shared content
- **Editor_Role**: Full edit permission level including annotation and resharing rights
- **Realtime_Channel**: Supabase Realtime WebSocket connection for collaboration events

## Requirements

### Requirement 1: Monorepo Project Structure

**User Story:** As a developer, I want a well-organized monorepo structure, so that I can easily navigate between frontend and backend code.

#### Acceptance Criteria

1. THE ScholarMate_System SHALL organize code in a monorepo with frontend/ and backend/ directories
2. THE Flutter_Client SHALL reside in the frontend/ directory with standard Flutter project structure
3. THE FastAPI_Backend SHALL reside in the backend/ directory with pyproject.toml for dependency management
4. THE ScholarMate_System SHALL include a root README documenting the project structure and setup instructions
5. THE ScholarMate_System SHALL include environment template files for configuration

### Requirement 2: Google OAuth Authentication

**User Story:** As a user, I want to sign in with my Google account, so that I can access my Google Drive files securely.

#### Acceptance Criteria

1. WHEN a user initiates sign-in, THE Flutter_Client SHALL redirect to Google OAuth 2.0 authorization with drive.file scope
2. WHEN OAuth authorization succeeds, THE Flutter_Client SHALL receive access and refresh tokens
3. THE Flutter_Client SHALL send the OAuth tokens to FastAPI_Backend for encrypted storage in Supabase_Metadata_DB
4. THE ScholarMate_System SHALL use the Google OAuth sub claim as the unique user identifier
5. WHEN tokens expire, THE ScholarMate_System SHALL automatically refresh using the stored refresh token
6. THE Flutter_Client SHALL display user profile information after successful authentication

### Requirement 3: Basic Google Drive Integration

**User Story:** As a user, I want to browse my ScholarMate folder in Google Drive, so that I can see my stored files.

#### Acceptance Criteria

1. WHEN a user first authenticates, THE Flutter_Client SHALL create a ScholarMate app folder in Google_Drive_Storage
2. THE Flutter_Client SHALL list files and folders within the ScholarMate app folder using Google Drive API
3. THE Flutter_Client SHALL display the folder tree in a modern, colorful UI with tree view for web and collapsible view for mobile
4. WHEN a user creates a folder, THE Flutter_Client SHALL create it directly in Google_Drive_Storage
5. WHEN a user uploads a file, THE Flutter_Client SHALL upload it directly to Google_Drive_Storage
6. THE Flutter_Client SHALL display file metadata including name, size, and modification date

### Requirement 4: Local Cache and Offline Foundation

**User Story:** As a user, I want to access my files offline, so that I can work without an internet connection.

#### Acceptance Criteria

1. THE Flutter_Client SHALL initialize Local_Cache using Drift database on first launch
2. WHEN the Flutter_Client fetches files from Google_Drive_Storage, THE Flutter_Client SHALL store metadata in Local_Cache
3. THE Flutter_Client SHALL display an online/offline indicator in the UI
4. WHILE offline, THE Flutter_Client SHALL load folder structure from Local_Cache
5. WHEN a user performs actions offline, THE Flutter_Client SHALL queue operations in Sync_Queue
6. WHEN connectivity is restored, THE Flutter_Client SHALL automatically process Sync_Queue and sync with Google_Drive_Storage

### Requirement 5: PDF Viewing

**User Story:** As a user, I want to open and view PDF files, so that I can read my research documents.

#### Acceptance Criteria

1. WHEN a user selects a PDF file, THE Flutter_Client SHALL download it from Google_Drive_Storage if not cached
2. THE Flutter_Client SHALL cache downloaded PDF files in Local_Cache for offline access
3. THE Flutter_Client SHALL render PDF files using syncfusion_flutter_pdfviewer
4. THE Flutter_Client SHALL display a toolbar with navigation controls for the PDF viewer
5. WHILE offline, THE Flutter_Client SHALL open cached PDF files from Local_Cache
6. THE Flutter_Client SHALL display a cached file indicator for offline-available PDFs

### Requirement 6: Basic PDF Annotations

**User Story:** As a user, I want to highlight and annotate PDFs, so that I can mark important sections.

#### Acceptance Criteria

1. WHEN viewing a PDF, THE Flutter_Client SHALL display annotation tools for highlight, underline, and comment
2. WHEN a user creates an annotation, THE Flutter_Client SHALL embed it directly in the PDF bytes
3. THE Flutter_Client SHALL store annotation metadata in Local_Cache with annotation_id, file_id, author_id, author_name, timestamp_created, annotation_type, page_index, bounding_box, and content
4. THE Flutter_Client SHALL display an annotation list panel showing all annotations with author info and timestamps
5. WHEN a user clicks an annotation in the list, THE Flutter_Client SHALL navigate to that page and highlight the annotation
6. WHILE offline, THE Flutter_Client SHALL allow annotation creation and store them locally for later sync

### Requirement 7: Supabase Metadata Database Setup

**User Story:** As a developer, I want a metadata database configured, so that the system can store user data and sharing information.

#### Acceptance Criteria

1. THE FastAPI_Backend SHALL connect to Supabase_Metadata_DB using environment variables
2. THE Supabase_Metadata_DB SHALL include tables for users, files, folders, annotations, shares, ingestions, api_keys, and audit_logs
3. THE Supabase_Metadata_DB SHALL implement Row Level Security policies ensuring users access only their own data
4. THE FastAPI_Backend SHALL encrypt sensitive fields including OAuth tokens and API keys before storage
5. THE FastAPI_Backend SHALL provide API endpoints for storing and retrieving encrypted user tokens
6. THE Supabase_Metadata_DB SHALL include indexes on frequently queried columns for performance

### Requirement 8: Annotation Synchronization

**User Story:** As a user, I want my annotations synced across devices, so that I can access them anywhere.

#### Acceptance Criteria

1. WHEN a user creates an annotation online, THE Flutter_Client SHALL send annotation metadata to FastAPI_Backend
2. THE FastAPI_Backend SHALL store annotation metadata in Supabase_Metadata_DB
3. WHEN the Flutter_Client comes online, THE Flutter_Client SHALL sync queued offline annotations to Supabase_Metadata_DB
4. WHEN annotations conflict, THE ScholarMate_System SHALL apply last-write-wins resolution and preserve history
5. THE Flutter_Client SHALL fetch latest annotations from Supabase_Metadata_DB on file open
6. THE Flutter_Client SHALL update Local_Cache with synced annotation data

### Requirement 9: File Upload and Management

**User Story:** As a user, I want to upload PDF files to my workspace, so that I can build my research library.

#### Acceptance Criteria

1. THE Flutter_Client SHALL provide a file upload interface accepting PDF and Markdown files
2. WHEN a user uploads a file, THE Flutter_Client SHALL upload it directly to Google_Drive_Storage
3. THE Flutter_Client SHALL update Local_Cache with new file metadata after upload
4. THE Flutter_Client SHALL support file operations including rename, move, and delete
5. WHEN a user deletes a file, THE Flutter_Client SHALL move it to Google Drive trash
6. THE Flutter_Client SHALL display upload progress and handle upload errors gracefully

### Requirement 10: Backend Infrastructure Setup

**User Story:** As a developer, I want the backend infrastructure configured, so that I can add AI and OCR features.

#### Acceptance Criteria

1. THE FastAPI_Backend SHALL initialize using uv package manager with pyproject.toml
2. THE FastAPI_Backend SHALL expose RESTful API endpoints with OpenAPI documentation
3. THE FastAPI_Backend SHALL implement CORS configuration allowing Flutter_Client requests
4. THE FastAPI_Backend SHALL use environment variables for all secrets and configuration
5. THE FastAPI_Backend SHALL implement health check endpoints for monitoring
6. THE FastAPI_Backend SHALL log all requests and errors for debugging

### Requirement 11: OCR Processing with Hybrid Online/Offline Mode

**User Story:** As a user, I want to scan documents with my camera and convert them to searchable PDFs or Markdown, so that I can digitize paper documents with high accuracy online or basic OCR offline.

#### Acceptance Criteria

1. THE Flutter_Client SHALL provide camera capture interface for document scanning
2. THE Flutter_Client SHALL perform perspective correction on captured images
3. WHEN a user completes scanning online, THE Flutter_Client SHALL send images to FastAPI_Backend for DeepSeek OCR processing
4. THE FastAPI_Backend SHALL process images using DeepSeek OCR API to extract text with high accuracy and structure preservation
5. WHEN a user completes scanning offline on Android, THE Flutter_Client SHALL use flutter_tesseract_ocr for local OCR processing
6. THE Flutter_Client SHALL create a searchable PDF with embedded OCR text and save to Google_Drive_Storage
7. THE FastAPI_Backend SHALL provide PDF to Markdown conversion using DeepSeek OCR
8. THE Flutter_Client SHALL provide Markdown preview and editor with live rendering and formatting toolbar

### Requirement 12: AI Model Provider Abstraction

**User Story:** As a user, I want to use different AI providers, so that I can choose based on cost and performance.

#### Acceptance Criteria

1. THE FastAPI_Backend SHALL implement an AIModelProvider abstract base class with chat and embed methods
2. THE FastAPI_Backend SHALL provide concrete implementations for OpenRouter, OpenAI, Claude, Gemini, and Grok
3. THE FastAPI_Backend SHALL allow users to configure their preferred provider via API
4. WHEN a user provides an API key, THE FastAPI_Backend SHALL encrypt and store it in Supabase_Metadata_DB
5. THE FastAPI_Backend SHALL use user-provided API keys when available, falling back to system defaults
6. THE FastAPI_Backend SHALL handle provider-specific errors and rate limits gracefully

### Requirement 13: RAG Indexing System with LangChain

**User Story:** As a user, I want my documents automatically indexed in my own vector database, so that I can perform semantic search without seeing other users' content.

#### Acceptance Criteria

1. WHEN a user uploads a PDF, THE Flutter_Client SHALL trigger indexing by calling FastAPI_Backend
2. THE FastAPI_Backend SHALL fetch the file from Google_Drive_Storage using encrypted refresh tokens
3. THE FastAPI_Backend SHALL extract text from PDFs and apply OCR if needed using LangChain document loaders
4. THE FastAPI_Backend SHALL chunk text into semantic segments with overlap using LangChain text splitters
5. THE FastAPI_Backend SHALL generate embeddings using the configured AI provider through LangChain embedding models and store in ChromaDB_Vector_Store
6. THE FastAPI_Backend SHALL create a separate ChromaDB collection for each user to ensure data isolation
7. THE FastAPI_Backend SHALL store chunk metadata including file_id, page_number, and citation mapping in ChromaDB_Vector_Store
8. THE FastAPI_Backend SHALL track indexing job status as pending, processing, completed, or failed in Supabase_Metadata_DB
9. THE Flutter_Client SHALL display indexing status and allow manual re-indexing
10. THE ScholarMate_System SHALL ensure users can only query their own vector database collection

### Requirement 14: AI Chat with RAG and Source Selection

**User Story:** As a user, I want to ask questions about selected documents, so that I can quickly find relevant information from specific sources.

#### Acceptance Criteria

1. THE Flutter_Client SHALL provide a chat interface for asking questions with source selection options
2. THE Flutter_Client SHALL allow users to select or deselect specific files or folders as sources for AI chat
3. WHEN a user submits a question, THE Flutter_Client SHALL send it to FastAPI_Backend with selected source filters
4. THE FastAPI_Backend SHALL use LangChain retrieval chains to generate embeddings and query the user's ChromaDB collection for relevant chunks
5. THE FastAPI_Backend SHALL filter results to only include chunks from user-selected sources
6. THE FastAPI_Backend SHALL construct a prompt with retrieved context using LangChain prompt templates and send to the AI provider
7. THE FastAPI_Backend SHALL return the AI response with citations including file_id and page_number
8. THE Flutter_Client SHALL display citations as clickable links that open the PDF to the referenced page
9. THE Flutter_Client SHALL provide an option to save chat responses as Markdown notes to Google_Drive_Storage
10. THE Flutter_Client SHALL persist source selection preferences for future chat sessions

### Requirement 15: Sharing with Roles

**User Story:** As a user, I want to share files with collaborators, so that we can work together on research.

#### Acceptance Criteria

1. THE Flutter_Client SHALL provide a sharing dialog for adding collaborators by email
2. THE Flutter_Client SHALL support Viewer_Role and Editor_Role permission levels
3. WHEN a user shares a file or folder, THE Flutter_Client SHALL create Google Drive sharing permissions
4. THE Flutter_Client SHALL store sharing metadata in Supabase_Metadata_DB
5. WHERE a folder is shared, THE ScholarMate_System SHALL apply permissions recursively to all contents
6. WHERE a user has Editor_Role, THE Flutter_Client SHALL allow annotation, file operations, and resharing
7. WHERE a user has Viewer_Role, THE Flutter_Client SHALL restrict to read-only access with offline caching

### Requirement 16: Public Link Sharing

**User Story:** As a user, I want to create public view-only links, so that I can share documents with anyone.

#### Acceptance Criteria

1. THE Flutter_Client SHALL provide an option to generate public links for files and folders
2. WHEN a user creates a public link, THE Flutter_Client SHALL configure Google Drive sharing as view-only
3. THE Flutter_Client SHALL display the generated public link for copying
4. WHEN a user accesses a public link, THE Flutter_Client SHALL display content in read-only mode without requiring authentication
5. THE Flutter_Client SHALL allow link creators to revoke public access
6. THE ScholarMate_System SHALL log public link creation and access in audit_logs

### Requirement 17: Realtime Collaboration for Annotations

**User Story:** As a collaborator, I want to see annotations in realtime, so that I can follow along with my team.

#### Acceptance Criteria

1. WHEN a user opens a shared file, THE Flutter_Client SHALL subscribe to Realtime_Channel for that file
2. WHEN a collaborator creates an annotation, THE FastAPI_Backend SHALL broadcast the event via Realtime_Channel
3. THE Flutter_Client SHALL receive annotation events and update the PDF viewer in realtime
4. THE Flutter_Client SHALL display the author name and avatar for each annotation
5. WHEN annotation conflicts occur, THE ScholarMate_System SHALL apply last-write-wins and preserve version history
6. THE Flutter_Client SHALL show typing indicators when collaborators are composing comment annotations

### Requirement 18: Realtime Collaboration for File Operations

**User Story:** As a collaborator, I want to see file changes in realtime, so that my view stays synchronized.

#### Acceptance Criteria

1. WHEN a user opens a shared folder, THE Flutter_Client SHALL subscribe to Realtime_Channel for that folder
2. WHEN a collaborator adds, renames, moves, or deletes a file, THE FastAPI_Backend SHALL broadcast the event via Realtime_Channel
3. THE Flutter_Client SHALL receive file operation events and update the file explorer in realtime
4. WHEN permission changes occur, THE FastAPI_Backend SHALL broadcast permission events via Realtime_Channel
5. THE Flutter_Client SHALL update user permissions in realtime and adjust UI accordingly
6. THE ScholarMate_System SHALL handle concurrent file operations with last-write-wins conflict resolution

### Requirement 19: Presence and Activity Tracking

**User Story:** As a collaborator, I want to see who else is viewing documents, so that I know who is active.

#### Acceptance Criteria

1. WHEN a user opens a file, THE Flutter_Client SHALL broadcast presence information via Realtime_Channel
2. THE Flutter_Client SHALL display avatars of active collaborators viewing the same file
3. WHEN a user navigates to a different page, THE Flutter_Client SHALL broadcast page tracking information
4. THE Flutter_Client SHALL display which page each collaborator is currently viewing
5. WHEN a user closes a file or goes offline, THE Flutter_Client SHALL broadcast departure event
6. THE Flutter_Client SHALL remove inactive users from presence display after timeout

### Requirement 20: PDF Read Aloud

**User Story:** As a user, I want text-to-speech for PDFs, so that I can listen to documents while multitasking.

#### Acceptance Criteria

1. THE Flutter_Client SHALL integrate flutter_tts for text-to-speech functionality
2. WHEN viewing a PDF, THE Flutter_Client SHALL display read-aloud controls in the toolbar
3. WHEN a user activates read-aloud, THE Flutter_Client SHALL extract text from the current page and speak it
4. THE Flutter_Client SHALL provide controls for play, pause, stop, and speed adjustment
5. THE Flutter_Client SHALL automatically advance to the next page when current page completes
6. THE Flutter_Client SHALL highlight the currently spoken text in the PDF viewer

### Requirement 21: Performance Optimization

**User Story:** As a user with a large library, I want fast performance, so that the app remains responsive.

#### Acceptance Criteria

1. THE Flutter_Client SHALL cache only opened files to minimize storage usage
2. THE FastAPI_Backend SHALL process indexing jobs asynchronously without blocking API requests
3. WHERE a user has a large library, THE FastAPI_Backend SHALL implement incremental indexing with progress tracking
4. THE FastAPI_Backend SHALL implement rate limiting and throttling for embedding generation
5. THE Flutter_Client SHALL implement pagination for large folder listings
6. THE ScholarMate_System SHALL optimize database queries with appropriate indexes and query limits

### Requirement 22: File Organization with Tags

**User Story:** As a user, I want to organize my PDFs and notes with tags, so that I can easily find and filter documents by topic.

#### Acceptance Criteria

1. THE Flutter_Client SHALL allow users to apply multiple tags to PDFs and Markdown notes
2. THE Flutter_Client SHALL provide a tag management interface for creating, renaming, and deleting tags
3. THE Flutter_Client SHALL display tags as colored chips on file cards in the file explorer
4. THE Flutter_Client SHALL provide tag filtering options in the file explorer to show only files with selected tags
5. THE Flutter_Client SHALL support tag-based search combined with filename search
6. THE Flutter_Client SHALL allow sorting files by tag, name, date, or size
7. THE Flutter_Client SHALL store tag metadata in Local_Cache and sync to Supabase_Metadata_DB
8. THE Flutter_Client SHALL support bulk tagging operations for multiple selected files
9. THE Flutter_Client SHALL display tag statistics showing document count per tag
10. THE ScholarMate_System SHALL sync tag changes across devices in realtime

### Requirement 23: Security and Privacy

**User Story:** As a user, I want my data secure and private, so that I can trust the system with sensitive research.

#### Acceptance Criteria

1. THE ScholarMate_System SHALL use HTTPS for all network communication
2. THE FastAPI_Backend SHALL encrypt OAuth tokens and API keys at rest in Supabase_Metadata_DB
3. THE ScholarMate_System SHALL request only drive.file OAuth scope for least-privilege access
4. THE Supabase_Metadata_DB SHALL enforce Row Level Security policies preventing cross-user data access
5. THE FastAPI_Backend SHALL log security-relevant events including sharing, deletion, and indexing in audit_logs
6. THE ScholarMate_System SHALL implement secure token refresh without exposing credentials to the client
