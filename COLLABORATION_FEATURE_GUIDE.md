# Real-Time PDF Collaboration Feature

## Overview

Real-time collaborative PDF viewing with live annotations and cursor tracking using Supabase Realtime.

## Architecture

**Backend**: FastAPI + Supabase (PostgreSQL + Realtime)
**Frontend**: Flutter + syncfusion_flutter_pdfviewer + Provider
**Real-time**: Supabase Realtime (WebSocket-based, free tier)

## Setup Instructions

### 1. Database Migration

Run the SQL migration in Supabase dashboard:

```bash
# Execute: backend/migrations/004_collaboration_tables.sql
```

This creates:
- `collaboration_sessions` table
- `session_participants` table
- RLS policies for security
- Realtime subscription

### 2. Backend Setup

Already integrated! The collaboration router is added to `main.py`.

Start backend:
```bash
cd backend
uv run python run.py
```

### 3. Frontend Setup

Add Supabase Flutter package (if not already added):
```bash
cd frontend
flutter pub add supabase_flutter
```

Initialize Supabase in `main.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

await Supabase.initialize(
  url: dartDefines['SUPABASE_URL']!,
  anonKey: dartDefines['SUPABASE_ANON_KEY']!,
);
```

Register CollaborationService in Provider:
```dart
MultiProvider(
  providers: [
    // ... existing providers
    Provider(
      create: (context) => CollaborationService(
        context.read<ConfigService>(),
        Supabase.instance.client,
      ),
    ),
  ],
  child: MyApp(),
)
```

## Usage

### Create Collaboration Session

**From PDF Viewer:**
1. Open any PDF in the app
2. Click the **purple "People" icon** in the toolbar (desktop) or overflow menu (Android)
3. Session is created automatically
4. Share link appears in the collaboration panel

**Programmatically:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CollaborativePdfViewerScreen(
      fileId: 'your-file-id',
      fileName: 'document.pdf',
      // sessionId: null (creates new session)
    ),
  ),
);
```

### Join Session via Link

**Option 1: Join Screen**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => JoinCollaborationScreen(
      sessionId: 'session-id-from-link', // Optional pre-fill
    ),
  ),
);
```

**Option 2: Direct Join**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CollaborativePdfViewerScreen(
      fileId: 'your-file-id',
      fileName: 'document.pdf',
      sessionId: 'session-id-from-link',
    ),
  ),
);
```

### Share Link

Tap the share button in the collaboration panel to copy the session link.

## Features

### ✅ Implemented

1. **Session Management**
   - Create collaboration session
   - Generate shareable link
   - Join via link
   - Leave session
   - Auto-expire after 7 days

2. **Real-Time Cursors**
   - See other users' cursor positions
   - Color-coded per user
   - User name labels
   - Throttled updates (10/sec)

3. **Participant Panel**
   - Live participant list
   - User colors and roles
   - Online status

4. **Security**
   - Row Level Security (RLS)
   - User authentication required
   - Role-based permissions (owner/editor/viewer)

### 🔄 Annotations (Extend Existing System)

Your existing annotation system can be extended for real-time sync:

```dart
// In annotation_service.dart, broadcast changes via Supabase
await supabase.from('annotations').insert(annotation);
// Realtime listeners will auto-update all clients
```

## API Endpoints

```
POST   /api/collaboration/sessions          # Create session
POST   /api/collaboration/sessions/join     # Join session
GET    /api/collaboration/sessions/{id}     # Get session
DELETE /api/collaboration/sessions/{id}/leave # Leave
POST   /api/collaboration/sessions/{id}/cursor # Update cursor
```

## Database Schema

```sql
collaboration_sessions
├── session_id (unique)
├── file_id
├── owner_id
├── default_role
└── expires_at

session_participants
├── session_id
├── user_id
├── user_name
├── user_color
├── role
├── cursor_position (JSONB)
└── last_seen
```

## Real-Time Flow

1. User joins session → Supabase inserts participant
2. Supabase Realtime broadcasts to all subscribers
3. Flutter receives update via stream
4. UI updates with new participant/cursor

## Performance

- **Cursor updates**: Throttled to 100ms (10/sec)
- **Participant updates**: Real-time via Supabase
- **Annotations**: Use existing sync system
- **Free tier**: Unlimited connections, 2GB bandwidth/month

## Offline Support

- Sessions require internet (real-time feature)
- Annotations sync when back online (existing system)
- Graceful degradation: Show "offline" indicator

## Testing

1. Open PDF in two browser tabs
2. Create session in tab 1
3. Copy share link
4. Join session in tab 2
5. Move cursor → see it in other tab
6. Add annotation → syncs to other tab

## Next Steps

1. Run database migration
2. Test session creation
3. Test joining via link
4. Extend annotation system for real-time sync
5. Add drawing tools (use existing annotation system)

## Cost

**Free tier limits**:
- Supabase: 500MB database, 2GB bandwidth
- Backend: Deploy on Render free tier
- Frontend: Static hosting (Vercel/Netlify)

Total cost: **$0/month** ✅
