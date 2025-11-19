# Collaboration Feature - UI Guide

## Where to Find It

### Desktop/Web (Non-Android)

```
┌─────────────────────────────────────────────────────────┐
│ ← document.pdf                                    🟣 🔄 🔊 ✏️ 📑 💾 🔍 📄 ℹ️ │
├─────────────────────────────────────────────────────────┤
│                                                         │
│                    PDF Content Here                     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Purple People Icon (🟣)** = Start Collaboration
- Located in the top toolbar
- First icon after the back button
- Only visible when online

### Android/Mobile

```
┌─────────────────────────────────────────────────────────┐
│ ← document.pdf                                      ⋮   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│                    PDF Content Here                     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

Tap the **three-dot menu (⋮)** → **"Start Collaboration"** (purple icon)

## User Flow

### Starting a Session

1. **Open PDF** → Any PDF in your library
2. **Click People Icon** → Purple icon in toolbar
3. **Session Created** → Collaboration panel appears
4. **Share Link** → Click share icon in panel
5. **Copy Link** → Send to collaborators

### Joining a Session

**Option A: Via Join Screen**
1. Navigate to "Join Collaboration" screen
2. Paste session ID
3. Click "Join Session"
4. Opens collaborative PDF viewer

**Option B: Via Direct Link**
1. Click shared link
2. App opens collaborative viewer
3. Automatically joins session

## Collaboration Panel

```
┌─────────────────────────────────┐
│ 👥 Collaborating (3)      🔗 ✕  │
├─────────────────────────────────┤
│ 🔴 Alice (owner)                │
│ 🔵 Bob (editor)                 │
│ 🟢 Charlie (viewer)             │
└─────────────────────────────────┘
```

- **Color dots** = User identification
- **Roles** = owner/editor/viewer
- **Share icon (🔗)** = Copy session link
- **Close (✕)** = Leave session

## Cursor Indicators

```
┌─────────────────────────────────┐
│                                 │
│     PDF Content                 │
│                                 │
│              ↖️ Alice            │
│                                 │
│                    ↖️ Bob        │
│                                 │
└─────────────────────────────────┘
```

- **Colored pointers** = Other users' cursors
- **Name labels** = User identification
- **Real-time** = Updates as they move

## Annotations

All your existing annotation tools work in collaboration mode:
- **Highlight** = Yellow marker
- **Underline** = Underline text
- **Strikethrough** = Cross out text
- **Comments** = Sticky notes
- **Drawing** = Freehand drawing

Annotations sync instantly to all participants.

## Status Indicators

### Online (Required for Collaboration)
```
🟢 Online
```

### Offline (Collaboration Disabled)
```
🔴 Offline - Cannot collaborate
```

### Syncing
```
🔄 Syncing...
```

## Keyboard Shortcuts (Desktop)

| Action | Shortcut |
|--------|----------|
| Start Collaboration | Click purple icon |
| Leave Session | Click ✕ in panel |
| Share Link | Click 🔗 in panel |
| Next Page | → or Page Down |
| Previous Page | ← or Page Up |

## Mobile Gestures

| Action | Gesture |
|--------|---------|
| Zoom | Pinch |
| Pan | Drag |
| Next Page | Swipe left |
| Previous Page | Swipe right |
| Annotation Menu | Long press |

## Tips

✅ **Do:**
- Share session links via secure channels
- Use descriptive names when joining
- Leave session when done (saves bandwidth)
- Check online status before starting

❌ **Don't:**
- Share session links publicly (anyone can join)
- Keep sessions open indefinitely (auto-expires in 7 days)
- Expect offline collaboration (requires internet)

## Troubleshooting

**"Cannot start collaboration"**
→ Check internet connection (🟢 indicator)

**"Session not found"**
→ Verify session ID is correct
→ Session may have expired (7 days)

**Cursors not showing**
→ Refresh the page
→ Check Supabase Realtime is enabled

**Annotations not syncing**
→ Check internet connection
→ Verify you have editor role (not viewer)

## Navigation

**From File Explorer:**
1. Open PDF
2. Click purple people icon

**From Home Screen:**
1. Recent files → Open PDF
2. Click purple people icon

**Direct Join:**
1. Menu → Join Collaboration
2. Enter session ID
3. Join

## Session Expiry

Sessions automatically expire after **7 days** of inactivity.

To extend:
- Owner must create a new session
- Share new link to participants

## Privacy & Security

- ✅ Row Level Security (RLS) enabled
- ✅ User authentication required
- ✅ Role-based permissions
- ✅ Encrypted connections (HTTPS/WSS)
- ❌ No public sessions (must have link)
- ❌ No anonymous access (must sign in)

## Performance

- **Cursor updates**: 10/second (throttled)
- **Latency**: <100ms (WebSocket)
- **Bandwidth**: ~1KB/sec per user
- **Max users**: 100+ concurrent (free tier)

---

**Quick Start**: Open PDF → Click 🟣 → Share link → Collaborate!
