# File Chat Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER DEVICE                              │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    PDF Viewer Screen                        │ │
│  │                                                              │ │
│  │  ┌──────────────────────┐  ┌──────────────────────────┐   │ │
│  │  │                      │  │   FileChatPanel          │   │ │
│  │  │   PDF Viewer         │  │   (Collapsible)          │   │ │
│  │  │   (Syncfusion)       │  │                          │   │ │
│  │  │                      │  │  💬 Chat & Notes      ✕  │   │ │
│  │  │   [PDF Content]      │  │  ─────────────────────── │   │ │
│  │  │                      │  │  👤 Alice                │   │ │
│  │  │                      │  │  ┌─────────────────┐    │   │ │
│  │  │                      │  │  │ Great paper!    │    │   │ │
│  │  │                      │  │  └─────────────────┘    │   │ │
│  │  │                      │  │           You 👤         │   │ │
│  │  │                      │  │  ┌─────────────────┐    │   │ │
│  │  │                      │  │  │ Thanks!         │    │   │ │
│  │  │                      │  │  └─────────────────┘    │   │ │
│  │  │                      │  │  ─────────────────────── │   │ │
│  │  │                      │  │  [Type message...] [→]  │   │ │
│  │  └──────────────────────┘  └──────────────────────────┘   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              FileChatService (Provider)                     │ │
│  │  • Manages chat state                                       │ │
│  │  • Handles real-time subscriptions                          │ │
│  │  • Syncs online/offline                                     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                          ↕                                        │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Local Database (Drift/SQLite)                  │ │
│  │  • file_chat_threads                                        │ │
│  │  • file_chat_messages (with isSynced flag)                 │ │
│  └────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
                              ↕
                    [Internet Connection]
                              ↕
┌─────────────────────────────────────────────────────────────────┐
│                      SUPABASE CLOUD                              │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              PostgreSQL Database                            │ │
│  │                                                              │ │
│  │  file_chat_threads                                          │ │
│  │  ├─ id (UUID)                                               │ │
│  │  ├─ file_id (TEXT)                                          │ │
│  │  ├─ created_at                                              │ │
│  │  ├─ updated_at                                              │ │
│  │  └─ message_count                                           │ │
│  │                                                              │ │
│  │  file_chat_messages                                         │ │
│  │  ├─ id (UUID)                                               │ │
│  │  ├─ thread_id (FK)                                          │ │
│  │  ├─ file_id (TEXT)                                          │ │
│  │  ├─ user_id (TEXT)                                          │ │
│  │  ├─ user_name (TEXT)                                        │ │
│  │  ├─ content (TEXT)                                          │ │
│  │  └─ timestamp                                               │ │
│  │                                                              │ │
│  │  RLS Policies:                                              │ │
│  │  • Users can only see messages for files they have access  │ │
│  │  • Access checked via file_shares table                    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Realtime (WebSocket)                           │ │
│  │  • Broadcasts new messages instantly                        │ │
│  │  • Per-file channels (file_chat_{fileId})                  │ │
│  │  • Filtered by RLS policies                                │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              ↕
                    [Optional: Backend API]
                              ↕
┌─────────────────────────────────────────────────────────────────┐
│                    FASTAPI BACKEND (Optional)                    │
│                                                                   │
│  /api/file-chat/threads          - Create/get thread            │
│  /api/file-chat/messages         - Send message                 │
│  /api/file-chat/messages/{id}    - Get messages                 │
│  /api/file-chat/access/{id}/{uid} - Check access                │
└─────────────────────────────────────────────────────────────────┘
```

## Message Flow Diagram

### Sending a Message (Online)

```
User Types Message
       ↓
   Click Send
       ↓
FileChatService.sendMessage()
       ↓
   ┌───┴───┐
   │       │
   ↓       ↓
Save to    Sync to
Local DB   Supabase
(instant)  (async)
   ↓       ↓
Update     Insert into
UI         file_chat_messages
   ↓       ↓
Show       Supabase Realtime
Message    broadcasts
   ↓       ↓
   │    Other Users
   │    Receive via
   │    WebSocket
   │       ↓
   │    Save to their
   │    Local DB
   │       ↓
   └────→  Update their UI
```

### Sending a Message (Offline)

```
User Types Message
       ↓
   Click Send
       ↓
FileChatService.sendMessage()
       ↓
Save to Local DB
(isSynced = false)
       ↓
Update UI
(show pending icon)
       ↓
[User goes online]
       ↓
Auto-detect connectivity
       ↓
Sync pending messages
       ↓
Update isSynced = true
       ↓
Remove pending icon
```

## Access Control Flow

```
User Opens PDF File
       ↓
FileChatService.initializeChat()
       ↓
Check file_shares table
       ↓
   ┌───┴───┐
   │       │
   ↓       ↓
Has      No
Access   Access
   ↓       ↓
Show     Hide
Chat     Chat
Panel    Panel
   ↓
Subscribe to
Realtime Channel
   ↓
Load Message
History
   ↓
Ready to Chat!
```

## Real-time Subscription Flow

```
FileChatService.initializeChat()
       ↓
Create Supabase Channel
(file_chat_{fileId})
       ↓
Subscribe to INSERT events
on file_chat_messages
       ↓
Filter by file_id
       ↓
   [New Message Inserted]
       ↓
Supabase Realtime
broadcasts to subscribers
       ↓
FileChatService receives
via WebSocket
       ↓
_handleRealtimeMessage()
       ↓
Check if message is
from current user
       ↓
   ┌───┴───┐
   │       │
   ↓       ↓
Own     Other
Message  User
   ↓       ↓
Ignore   Save to
(already Local DB
shown)      ↓
         Update UI
            ↓
         Show new
         message
```

## Database Sync Strategy

```
┌─────────────────────────────────────────┐
│         Local Database (Drift)          │
│                                          │
│  Messages with isSynced flag:           │
│  • true  = synced to Supabase           │
│  • false = pending sync                 │
│                                          │
│  On connectivity change:                │
│  1. Detect online status                │
│  2. Query messages where isSynced=false │
│  3. Sync to Supabase                    │
│  4. Update isSynced=true                │
└─────────────────────────────────────────┘
              ↕ (sync)
┌─────────────────────────────────────────┐
│      Supabase Database (PostgreSQL)     │
│                                          │
│  Source of truth for:                   │
│  • All synced messages                  │
│  • Thread metadata                      │
│  • Access control (RLS)                 │
│                                          │
│  Real-time broadcasts:                  │
│  • New messages to all subscribers      │
│  • Filtered by file access              │
└─────────────────────────────────────────┘
```

## Component Hierarchy

```
PdfViewerScreen
├── Row
│   ├── Expanded
│   │   └── PdfViewer (Syncfusion)
│   │       └── [PDF Content]
│   │
│   └── FileChatPanel
│       ├── AnimatedContainer (48px ↔ 320px)
│       │
│       ├── [Collapsed State]
│       │   ├── IconButton (chat icon)
│       │   └── Badge (message count)
│       │
│       └── [Expanded State]
│           ├── Header
│           │   ├── Icon + Title
│           │   └── Close Button
│           │
│           ├── Message List (Scrollable)
│           │   └── ListView.builder
│           │       └── MessageBubble (for each message)
│           │           ├── Avatar (if other user)
│           │           ├── User Name
│           │           ├── Content
│           │           └── Timestamp + Sync Status
│           │
│           └── Input Area
│               ├── TextField
│               └── Send Button
```

## State Management Flow

```
FileChatService (ChangeNotifier)
       ↓
   notifyListeners()
       ↓
FileChatPanel (Consumer)
       ↓
   setState()
       ↓
   Widget Rebuild
       ↓
   UI Updates
```

## Security Layers

```
┌─────────────────────────────────────────┐
│  Layer 1: Frontend Access Check         │
│  • FileChatService.hasAccess()          │
│  • Checks file_shares table             │
│  • Hides UI if no access                │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  Layer 2: Supabase RLS Policies         │
│  • Row-level security on tables         │
│  • Filters queries by file access       │
│  • Enforced at database level           │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  Layer 3: Realtime Subscriptions        │
│  • Filtered by RLS policies             │
│  • Only authorized users receive msgs   │
│  • WebSocket connections secured        │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  Layer 4: Backend API (Optional)        │
│  • Validates all requests               │
│  • Checks user permissions              │
│  • Additional business logic            │
└─────────────────────────────────────────┘
```

## Performance Optimizations

```
1. Local Caching (Drift)
   • Messages cached locally
   • Instant load on file open
   • Reduces API calls

2. Indexed Queries
   • file_id, thread_id, timestamp
   • Fast message retrieval
   • Efficient sorting

3. Optimistic Updates
   • UI updates immediately
   • Sync happens in background
   • Better user experience

4. Lazy Loading
   • Chat only loads when expanded
   • Saves resources
   • Faster initial page load

5. Efficient Real-time
   • Per-file channels
   • Only subscribe to active file
   • Unsubscribe on close
```

This architecture ensures a smooth, secure, and performant chat experience!
