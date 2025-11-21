# Collaboration Setup - Important!

## ⚠️ Current Limitation

For collaboration to work, **User A must share the PDF file with User B in Google Drive FIRST**.

## Why?

- PDFs are stored in User A's Google Drive
- User B doesn't have access to User A's files by default
- Google Drive permissions are required for User B to view the file

## How to Set Up Collaboration

### Step 1: User A Shares the PDF in Google Drive

1. Go to Google Drive (drive.google.com)
2. Find the PDF file you want to collaborate on
3. Right-click → Share
4. Enter User B's email address
5. Set permission to "Viewer" or "Editor"
6. Click "Send"

### Step 2: User A Creates Collaboration Session

1. Open the PDF in ScholarMate
2. Click purple people icon
3. Click share icon
4. Copy Session ID

### Step 3: User B Joins

1. Check email for Google Drive share notification
2. Open ScholarMate
3. Click "Join Collab" button
4. Paste Session ID
5. Click "Join Session"

## ✅ What Works

- Real-time cursors
- Real-time annotations
- Participant list
- Session management

## 🔧 Future Enhancement

To avoid manual Google Drive sharing, we could:
1. Store PDF temporarily on backend during session
2. Use backend as proxy to serve PDF to participants
3. Implement automatic Drive sharing via API

## Quick Test (Same User)

For testing with the same Google account:
1. Open PDF → Start collaboration
2. Open incognito window → Sign in with SAME account
3. Join session → Works immediately (same Drive access)

## Error Messages

**"File not found 404"** = User B doesn't have access to the file in Google Drive
**"Session not found"** = Invalid Session ID or session expired
**"Not authenticated"** = User needs to sign in with Google
