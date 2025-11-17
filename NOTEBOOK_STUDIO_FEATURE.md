# Notebook Studio Feature

## Overview
Notebook Studio is a comprehensive workspace feature similar to Google's NotebookLM, designed for organizing research materials, notes, and AI-powered study tools.

## Architecture

### Database Schema
The feature uses 5 new Drift tables:
- `NotebookFolders` - Workspace containers
- `NotebookFiles` - Files within workspaces (PDFs, markdown notes, images)
- `NotebookChats` - AI chat conversations per workspace
- `NotebookChatMessages` - Individual chat messages
- `NotebookAiOutputs` - Generated content from AI Studio tools

### Key Components

#### 1. Notebook Studio Dashboard (`NotebookStudioScreen`)
- Grid view of all user workspaces
- Create, rename, delete workspaces
- Shows file count and last activity per workspace

#### 2. Workspace Detail Screen (`NotebookFolderScreen`)
- Tab-based interface with 3 sections:
  - **Files Tab**: Upload and manage files
  - **Chat Tab**: AI-powered conversations
  - **AI Studio Tab**: Content generation tools

#### 3. Files Tab (`NotebookFilesTab`)
- Create markdown notes
- Upload files (PDF, markdown, images)
- File preview and management
- Supports offline storage

#### 4. Chat Tab (`NotebookChatTab`)
- Context-aware AI chat
- Conversation history stored per workspace
- Access to all files in the workspace
- Placeholder for AI integration (needs backend connection)

#### 5. AI Studio Tab (`NotebookAiStudioTab`)
- **Quiz Generator**: Create practice questions
- **Summarizer**: Generate content summaries
- **Mind Map Generator**: Visual concept mapping
- **Flashcard Creator**: Study flashcards
- **Audio Review**: Text-to-speech conversion
- Long-press tools to generate content
- View and manage generated outputs

### Service Layer

#### NotebookService
Manages all notebook operations:
- CRUD operations for folders, files, chats, and AI outputs
- Offline-first with sync support
- Integrates with existing auth and database services

## Navigation

Added to main navigation bar as "Notebook Studio" with icon `Icons.auto_stories`

## Integration Points

### Existing Services Used:
- `AuthService` - User authentication
- `AppDatabase` - Local storage via Drift
- `ApiService` - Backend API calls (for AI features)
- `CacheService` - Offline data management

### Future Integrations Needed:
1. **AI Chat**: Connect to RAG service for context-aware responses
2. **File Processing**: OCR and content extraction for uploaded files
3. **AI Studio Tools**: Implement actual AI generation logic
4. **Sync**: Cloud synchronization for workspaces
5. **Sharing**: Collaborate on workspaces

## Usage Flow

1. User opens Notebook Studio from navigation
2. Creates a new workspace (e.g., "Research Project")
3. Uploads reference files (PDFs, notes)
4. Uses Chat tab to ask questions about the materials
5. Generates study aids using AI Studio tools
6. Reviews generated quizzes, flashcards, summaries

## Offline Support

- All workspaces, files, and chats stored locally in Drift database
- Works completely offline
- Sync status tracked with `isSynced` flag
- Ready for cloud sync implementation

## Database Migration

Schema version bumped from 6 to 7. Migration automatically creates new tables on app update.

## Dependencies

- `uuid` - Generate unique IDs
- `file_picker` - File upload functionality
- `drift` - Local database
- Existing app dependencies

## Next Steps

1. Implement AI chat backend integration
2. Add file content extraction and indexing
3. Implement actual AI Studio tool generation
4. Add workspace sharing and collaboration
5. Implement cloud sync for workspaces
6. Add export functionality for generated content
7. Implement search across workspaces
8. Add workspace templates

## Files Created/Modified

### New Files:
- `frontend/lib/database/notebook_tables.dart` - Table definitions
- `frontend/lib/services/notebook_service.dart` - Business logic
- `frontend/lib/screens/notebook_studio_screen.dart` - Dashboard
- `frontend/lib/screens/notebook_folder_screen.dart` - Workspace detail
- `frontend/lib/widgets/notebook_files_tab.dart` - Files management
- `frontend/lib/widgets/notebook_chat_tab.dart` - AI chat interface
- `frontend/lib/widgets/notebook_ai_studio_tab.dart` - AI tools

### Modified Files:
- `frontend/lib/database/database.dart` - Added notebook methods
- `frontend/lib/database/tables.dart` - Export notebook tables
- `frontend/lib/main.dart` - Added NotebookService provider
- `frontend/lib/screens/home_screen.dart` - Added navigation item

## Testing

To test the feature:
1. Run the app: `flutter run`
2. Navigate to "Notebook Studio" tab
3. Create a workspace
4. Add files and test chat (placeholder responses)
5. Try AI Studio tools (sample outputs)

## Notes

- AI features currently return placeholder data
- File upload stores metadata only (actual file handling needs implementation)
- Chat responses are placeholders pending backend integration
- All data persists locally and survives app restarts
