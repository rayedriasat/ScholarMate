# Collaboration Sharing Requirement

## Manual File Sharing Required

**Why**: Google Drive API requires special OAuth scopes to programmatically share files. Our app uses `drive.file` scope (app folder only) which doesn't allow modifying permissions.

## How to Share for Collaboration

### User A (Owner) Steps:
1. **Share the PDF via Gmail/Drive FIRST**:
   - Right-click file in Google Drive
   - Click "Share"
   - Add User B's email
   - Set permission: "Viewer" or "Editor"
   - Click "Send"

2. **Then start collaboration**:
   - Open PDF in ScholarMate
   - Click purple collaboration icon (🟣)
   - Copy session ID
   - Send session ID to User B (via chat/email)

### User B (Joiner) Steps:
1. **Accept the Drive share** (check email)
2. **Join collaboration**:
   - Open ScholarMate
   - Files → Menu (⋮) → "Join Collaboration"
   - Enter session ID from User A
   - Click "Join Session"
3. **PDF loads** (now accessible via Drive share)

## Why This Works

- User B has Drive access → Can download PDF
- Session ID links them to same collaboration session
- Both see each other's cursors and annotations in real-time

## Alternative: Public Link Sharing

If you don't want to share via email:

**User A:**
1. Right-click file in Drive → "Share"
2. Click "Change to anyone with the link"
3. Set to "Viewer"
4. Copy link (optional - not needed for ScholarMate)
5. Start collaboration in ScholarMate
6. Share session ID with User B

**User B:**
- File is now accessible to anyone with link
- Join via session ID in ScholarMate
- Works without email sharing

## This is Standard Practice

Most collaboration apps (Google Docs, Figma, etc.) require:
1. File access (via sharing)
2. Session/room ID (to join collaboration)

ScholarMate follows the same pattern.
