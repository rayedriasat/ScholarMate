# File Chat & Notes Feature

## Overview

In-app chat and notes feature linked to individual PDF files. Users with access to a shared file can send and read messages in real-time.

## Core Features

✅ **Per-File Chat Threads**: One chat thread automatically created per PDF file
✅ **Access Control**: Only users with file access can view/send messages
✅ **Real-time Updates**: Instant message delivery via Supabase Realtime
✅ **Offline Support**: Messages cached locally, synced when online
✅ **Collapsible UI**: Small panel on right side of PDF viewer
✅ **Message History**: Full chat history loads when file is opened

## Architecture

### Frontend (Flutter)

**Models**:
- `FileChatMessage` - Message data model with user info, content, timestamp

**Services**:
- `FileChatService` - Manages chat threads, messages, real-time subscriptions
  - Handles online/offline sync
  - Supabase Realtime integration
  - Local database caching

**Widgets**:
- `FileChatPanel` - Collapsible chat UI component
  - Collapsed: 48px width with message count badge
  - Expanded: 320px width with full chat interface
  - Auto-scroll to latest messages
  - Real-time message updates

**Database Tables** (Drift):
- `file_chat_threads` - Thread metadata per file
- `file_chat_messages` - Individual messages with sync status

### Backend (FastAPI)

**Router**: `/api/file-chat`
- `POST /threads` - Create/get thread for file
- `GET /threads/{file_id}` - Get thread by file ID
- `POST /messages` - Send message
- `GET /messages/{file_id}` - Get all messages for file
- `GET /access/{file_id}/{user_id}` - Check user access

**Database Tables** (Supabase PostgreSQL):
- `file_chat_threads` - Thread metadata with message count
- `file_chat_messages` - Messages with user info, timestamp
- RLS policies enforce access control via `file_shares` table
- Realtime enabled for instant message delivery

## Usage

### 1. Add FileChatService to Provider

```dart
// In main.dart or wherever you setup providers
MultiProvider(
  providers: [
    // ... existing providers
    ChangeNotifierProvider(
      create: (context) => FileChatService(
        database: context.read<AppDatabase>(),
        supabase: Supabase.instance.client,
      ),
    ),
  ],
  child: MyApp(),
)
```

### 2. Integrate into PDF Viewer Screen

```dart
// In your PDF viewer screen
Row(
  children: [
    Expanded(
      child: PdfViewer(...), // Your existing PDF viewer
    ),
    FileChatPanel(
      fileId: widget.fileId,
      userId: currentUser.id,
      userName: currentUser.name,
      userPhotoUrl: currentUser.photoUrl,
    ),
  ],
)
```

### 3. Run Database Migration

```bash
# Frontend - Drift will auto-migrate on app start
flutter pub run build_runner build

# Backend - Run SQL migration on Supabase
# Execute backend/migrations/010_file_chat_tables.sql in Supabase SQL Editor
```

## Access Control

Messages are automatically filtered by file access:

1. **File Sharing**: User must have access via `file_shares` table
2. **RLS Policies**: Supabase enforces row-level security
3. **Real-time**: Only authorized users receive message updates
4. **Instant Revocation**: Removing file access immediately blocks chat

## Offline Behavior

**Offline Mode**:
- Messages saved locally with `isSynced = false`
- UI shows pending indicator (clock icon)
- Messages queued for sync

**Online Mode**:
- Pending messages auto-sync to Supabase
- Real-time updates from other users
- Local cache updated

## UI/UX Details

**Collapsed State** (48px width):
- Chat bubble icon
- Message count badge
- Click to expand

**Expanded State** (320px width):
- Header with title and close button
- Scrollable message list
- Message bubbles (different colors for current user vs others)
- User avatars and names
- Timestamp with relative formatting
- Text input with send button
- Auto-scroll to latest messages

**Message Formatting**:
- Current user: Right-aligned, primary color
- Other users: Left-aligned, surface color with avatar
- Timestamps: Relative (e.g., "2m ago", "1h ago")
- Sync status: Clock icon for pending messages

## Testing

### 1. Test Chat Creation
```dart
// Open PDF file
// Chat panel should appear on right side
// Click to expand panel
```

### 2. Test Message Sending
```dart
// Type message in input field
// Press send or Enter
// Message should appear immediately
// Check sync status icon
```

### 3. Test Real-time Updates
```dart
// Open same file on two devices/browsers
// Send message from Device A
// Message should appear on Device B instantly
```

### 4. Test Offline Mode
```dart
// Disable network
// Send messages (should show pending icon)
// Enable network
// Messages should sync automatically
```

### 5. Test Access Control
```dart
// Share file with User B
// User B should see chat
// Revoke access
// User B should lose chat visibility
```

## API Examples

### Create Thread
```bash
curl -X POST http://localhost:8000/api/file-chat/threads \
  -H "Content-Type: application/json" \
  -d '{"file_id": "abc123"}'
```

### Send Message
```bash
curl -X POST http://localhost:8000/api/file-chat/messages \
  -H "Content-Type: application/json" \
  -d '{
    "thread_id": "thread-uuid",
    "file_id": "abc123",
    "user_id": "user-123",
    "user_name": "John Doe",
    "content": "Great paper!"
  }'
```

### Get Messages
```bash
curl http://localhost:8000/api/file-chat/messages/abc123
```

## Database Schema

### file_chat_threads
```sql
id              UUID PRIMARY KEY
file_id         TEXT UNIQUE NOT NULL
created_at      TIMESTAMPTZ NOT NULL
updated_at      TIMESTAMPTZ NOT NULL
message_count   INTEGER DEFAULT 0
```

### file_chat_messages
```sql
id              UUID PRIMARY KEY
thread_id       UUID REFERENCES file_chat_threads
file_id         TEXT NOT NULL
user_id         TEXT NOT NULL
user_name       TEXT NOT NULL
user_photo_url  TEXT
content         TEXT NOT NULL
timestamp       TIMESTAMPTZ NOT NULL
```

## Performance Considerations

- **Indices**: Created on `file_id`, `thread_id`, `timestamp` for fast queries
- **Pagination**: Consider adding pagination for files with 1000+ messages
- **Caching**: Messages cached locally to reduce API calls
- **Real-time**: Supabase Realtime handles message broadcasting efficiently

## Security

- ✅ RLS policies enforce access control
- ✅ Messages only visible to users with file access
- ✅ No direct database access from frontend
- ✅ Backend validates all requests
- ✅ Real-time subscriptions filtered by file access

## Future Enhancements

- [ ] Message editing/deletion
- [ ] File attachments in chat
- [ ] @mentions for specific users
- [ ] Typing indicators
- [ ] Read receipts
- [ ] Message reactions (emoji)
- [ ] Search within chat history
- [ ] Export chat as PDF/Markdown
