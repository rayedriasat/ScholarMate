# Add "Share First" Check for Collaboration

## Problem
When users try to start a collaboration session without first sharing the PDF via Gmail/Google Drive permissions, they should see a helpful message.

## Solution

### Option 1: Add Check in Collaborative PDF Viewer

When creating a collaboration session, check if the file has been shared first.

**File: `frontend/lib/screens/collaborative_pdf_viewer_screen.dart`**

In the `_initializeCollaboration()` method, add this check before creating the session:

```dart
Future<void> _initializeCollaboration() async {
  try {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      setState(() {
        _error = 'Not authenticated';
        _isLoading = false;
      });
      return;
    }

    // NEW: Check if file is shared before creating collaboration
    if (widget.sessionId == null) {
      // Only check when creating new session (not joining)
      final sharingService = context.read<SharingService>();
      final shares = await sharingService.getFileShares(widget.fileId);
      
      if (shares.isEmpty) {
        // File is not shared with anyone
        setState(() {
          _error = 'Please share this PDF via Gmail first before starting collaboration';
          _isLoading = false;
        });
        
        // Show helpful dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Share First'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To start a collaboration session, you need to share this PDF with collaborators first.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Steps:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. Go back to the file list'),
                  Text('2. Click the ⋮ menu on the PDF'),
                  Text('3. Select "Share file"'),
                  Text('4. Add collaborators with their Gmail addresses'),
                  Text('5. Then start the collaboration session'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to file list
                  },
                  child: Text('Go Back'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    // TODO: Open sharing dialog directly
                  },
                  child: Text('Share Now'),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    _collaborationService = context.read<CollaborationService>();

    // Rest of existing code...
    if (widget.sessionId != null) {
      // Join existing session
      _session = await _collaborationService!.joinSession(
        // ... existing code
      );
    } else {
      // Create new session
      _session = await _collaborationService!.createSession(
        // ... existing code
      );
    }
    
    // ... rest of existing code
  } catch (e) {
    setState(() {
      _error = e.toString();
      _isLoading = false;
    });
  }
}
```

### Option 2: Add Check in File Explorer Menu

Add a "Start Collaboration" menu option that checks sharing first.

**File: `frontend/lib/widgets/file_context_menu.dart`**

Add a new menu item:

```dart
if (file.isPdf) ...[
  const PopupMenuDivider(),
  PopupMenuItem(
    value: 'start_collaboration',
    child: Row(
      children: [
        const Icon(Icons.people, size: 18),
        const SizedBox(width: 12),
        const Text('Start Collaboration'),
      ],
    ),
  ),
],
```

Then in the file explorer, handle this option:

```dart
case 'start_collaboration':
  _startCollaboration(file);
  break;
```

And add the method:

```dart
Future<void> _startCollaboration(DriveFile file) async {
  // Check if file is shared
  final sharingService = context.read<SharingService>();
  final shares = await sharingService.getFileShares(file.id);
  
  if (shares.isEmpty) {
    // Show message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.share, color: Colors.orange),
            SizedBox(width: 8),
            Text('Share First'),
          ],
        ),
        content: Text(
          'Please share this PDF with collaborators via Gmail before starting a collaboration session.\n\n'
          'Tap "Share Now" to add collaborators.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSharingDialog(file);
            },
            child: Text('Share Now'),
          ),
        ],
      ),
    );
    return;
  }
  
  // File is shared, proceed to create collaboration
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CollaborativePdfViewerScreen(
        fileId: file.id,
        fileName: file.name,
      ),
    ),
  );
}
```

### Option 3: Simple Snackbar Message

If you just want a quick message without blocking:

```dart
// Before creating collaboration
final sharingService = context.read<SharingService>();
final shares = await sharingService.getFileShares(widget.fileId);

if (shares.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.warning, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tip: Share this PDF via Gmail first for better collaboration!',
            ),
          ),
        ],
      ),
      backgroundColor: Colors.orange,
      duration: Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Share',
        textColor: Colors.white,
        onPressed: () {
          // Open sharing dialog
        },
      ),
    ),
  );
}
```

## Recommended Approach

I recommend **Option 1** - Add the check in the collaborative PDF viewer with a helpful dialog. This:
- Blocks collaboration until file is shared
- Provides clear instructions
- Offers quick action to share
- Prevents confusion

## Implementation Steps

1. Add the check in `_initializeCollaboration()`
2. Show the dialog with instructions
3. Provide "Go Back" and "Share Now" buttons
4. Test with unshared and shared PDFs

Would you like me to implement one of these options for you?
