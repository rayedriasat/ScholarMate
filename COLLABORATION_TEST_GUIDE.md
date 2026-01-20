# Collaboration Feature - Test Guide

## How to Test Collaboration

### Setup (One Time)
1. Make sure backend is running: `cd backend && uv run run.py`
2. Make sure frontend is running: `cd frontend && flutter run -d chrome --web-port=8001 --dart-define-from-file=dart_defines.json`

### Test Steps

#### User 1 (Session Owner)
1. Open the app in Chrome: http://localhost:8080
2. Sign in with Google
3. Open any PDF file
4. Click the **purple people icon** (top right) to start collaboration
5. Click the **share icon** in the collaborative viewer
6. You'll see a dialog with:
   - Full share link: `http://localhost:8000/collaborate/[session-id]`
   - Session ID: `[random-string]`
7. **Copy the Session ID** (the short code, not the full link)

#### User 2 (Joining User)
1. Open the app in a **different browser** (Edge/Firefox) or **incognito window**
2. Sign in with a **different Google account**
3. Navigate to: http://localhost:8080/#/join-collaboration
   - OR manually add a route to the app to show the join screen
4. Paste the **Session ID** from User 1
5. Click **Join Session**

### What You Should See

**User 1 (Owner):**
- Your name in the collaboration panel
- Your cursor movements
- Your annotations

**User 2 (Joined):**
- Both users in the collaboration panel
- User 1's cursor moving in real-time (different color)
- User 1's annotations appearing live
- Can add their own annotations

### Current Limitation

The app doesn't have a route handler for `/collaborate/{session_id}` links yet. For now, users must:
1. Copy the **Session ID** (not the full link)
2. Manually navigate to the join screen
3. Paste the Session ID

### Quick Fix: Add Join Button to Home Screen

To make testing easier, add a "Join Collaboration" button to your home screen that navigates to `JoinCollaborationScreen`.

### Troubleshooting

**"Not authenticated" error:**
- Make sure both users are signed in with Google

**"Session not found" error:**
- Check that the Session ID is correct
- Make sure User 1's session is still active

**No cursor/annotations showing:**
- Check browser console for errors
- Verify backend is running and accessible
- Check Supabase Realtime is enabled for `session_participants` table

### Testing Checklist

- [ ] User 1 can create a session
- [ ] Share dialog shows link and session ID
- [ ] User 2 can join with session ID
- [ ] Both users appear in collaboration panel
- [ ] Cursors show in real-time (different colors)
- [ ] Annotations sync between users
- [ ] User can leave session
- [ ] Session expires after 7 days (check database)
