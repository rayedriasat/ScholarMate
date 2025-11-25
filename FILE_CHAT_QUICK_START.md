# File Chat & Notes - Quick Start Guide

## 🚀 5-Minute Setup

### Prerequisites
- ✅ Supabase project configured
- ✅ Flutter app with Provider setup
- ✅ User authentication working

### 1. Run Backend Migration (2 min)

Open Supabase SQL Editor and execute:

```bash
# Location: backend/migrations/010_file_chat_tables.sql
```

Or copy-paste this:

```sql
-- Create tables
CREATE TABLE file_chat_threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_id TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    message_count INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE file_chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID NOT NULL REFERENCES file_chat_threads(id) ON DELETE CASCADE,
    file_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    user_photo_url TEXT,
    content TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE file_chat_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE file_chat_messages ENABLE ROW LEVEL SECURITY;

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE file_chat_messages;
```

### 2. Generate Drift Code (1 min)

```bash
cd frontend
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Add Provider (1 min)

```dart
// In your main.dart or app setup
ChangeNotifierProvider(
  create: (context) => FileChatService(
    database: context.read<AppDatabase>(),
    supabase: Supabase.instance.client,
  ),
),
```

### 4. Add to PDF Viewer (1 min)

```dart
// In your PDF viewer screen
Row(
  children: [
    Expanded(child: YourPdfViewer()),
    FileChatPanel(
      fileId: fileId,
      userId: currentUser.id,
      userName: currentUser.name,
      userPhotoUrl: currentUser.photoUrl,
    ),
  ],
)
```

### 5. Test! ✨

1. Open a PDF file
2. Click chat icon on right
3. Send a message
4. Open same file on another device → see real-time update!

## 🎯 That's It!

You now have:
- ✅ Per-file chat threads
- ✅ Real-time messaging
- ✅ Offline support
- ✅ Access control
- ✅ Clean, collapsible UI

## 📱 UI Preview

**Collapsed** (48px):
```
┌──────┐
│  💬  │  ← Click to expand
│  (3) │  ← Message count
└──────┘
```

**Expanded** (320px):
```
┌─────────────────────────┐
│ 💬 Chat & Notes      ✕  │
├─────────────────────────┤
│                         │
│  👤 Alice               │
│  ┌─────────────────┐   │
│  │ Great paper!    │   │
│  │ 2m ago          │   │
│  └─────────────────┘   │
│                         │
│              You 👤     │
│   ┌─────────────────┐  │
│   │ Thanks!         │  │
│   │ Just now        │  │
│   └─────────────────┘  │
│                         │
├─────────────────────────┤
│ [Type message...] [→]  │
└─────────────────────────┘
```

## 🔧 Configuration

### Customize Panel Width

```dart
FileChatPanel(
  // ... existing params
  collapsedWidth: 48,  // Default
  expandedWidth: 320,  // Default
)
```

### Customize Colors

The panel uses your app's theme automatically:
- Primary color for current user messages
- Surface color for other users
- Divider color for borders

## 🐛 Common Issues

**"No messages showing"**
→ Check Supabase RLS policies are set up

**"Real-time not working"**
→ Verify Realtime is enabled in Supabase project settings

**"Build errors"**
→ Run `flutter pub run build_runner build --delete-conflicting-outputs`

**"Access denied"**
→ Ensure user has file access via `file_shares` table

## 📚 Full Documentation

See `FILE_CHAT_FEATURE.md` for complete details.

## 🎨 Customization Examples

### Change Message Bubble Colors

```dart
// In file_chat_panel.dart, modify _buildMessageBubble:
color: isCurrentUser
    ? Colors.blue  // Your custom color
    : Colors.grey[200]
```

### Add Custom Header Actions

```dart
// In _buildHeader():
Row(
  children: [
    // ... existing header
    IconButton(
      icon: Icon(Icons.more_vert),
      onPressed: () {
        // Show options menu
      },
    ),
  ],
)
```

### Add Message Timestamps

Already included! Shows relative time (e.g., "2m ago", "1h ago")

## 🚢 Deployment Checklist

- [ ] Run SQL migration on production Supabase
- [ ] Verify RLS policies are active
- [ ] Enable Realtime in Supabase dashboard
- [ ] Test with multiple users
- [ ] Test offline mode
- [ ] Test access control (share/unshare)

## 💡 Pro Tips

1. **Performance**: Chat panel only loads when expanded
2. **Offline**: Messages queue automatically when offline
3. **Security**: RLS policies enforce access control
4. **Scalability**: Consider pagination for 1000+ messages
5. **UX**: Auto-scrolls to latest message on new message

## 🎉 You're Done!

Your users can now collaborate on PDFs with real-time chat and notes!
