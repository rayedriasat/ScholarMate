# Chat with Folder Feature

## Overview
Added "Chat with this Folder" functionality that allows users to open AI chat with all files from the current folder pre-selected.

## Implementation

### Changes Made

#### 1. AI Chat Screen (`frontend/lib/screens/ai_chat_screen.dart`)
- Added `preselectedFileIds` parameter to accept multiple file IDs
- Added `folderName` parameter to display folder context
- Updated `initState()` to handle multiple preselected files
- Updated AppBar title to show folder context
- Updated empty state to display folder-specific messaging
- Updated back button tooltip for folder context

#### 2. File Explorer Screen (`frontend/lib/screens/file_explorer_screen.dart`)
- Added import for `AIChatScreen`
- Added "Chat with Folder" floating action button (extended FAB)
- Button appears above the '+' FAB when folder contains files
- Implemented `_chatWithFolder()` method that:
  - Collects all non-folder files (PDFs and Markdown) from current folder
  - Extracts file IDs
  - Gets current folder name from navigation path
  - Navigates to AI chat with all files preselected

### User Experience

1. **Button Visibility**: The "Chat with Folder" button only appears when the current folder contains files (not just subfolders)

2. **Button Location**: Positioned above the main '+' FAB for easy access

3. **Chat Context**: 
   - Title shows: "Chatting with folder: [FolderName] (X files)"
   - Empty state shows folder icon and folder-specific messaging
   - Info badge displays number of files automatically selected

4. **File Selection**: All PDF and Markdown files in the current folder are automatically added to the chat context

### Usage

1. Navigate to any folder in the File Explorer
2. If the folder contains files, you'll see a "Chat with Folder" button above the '+' button
3. Tap the button to open AI chat with all folder files pre-selected
4. Start asking questions about the files in that folder

### Technical Details

**Supported File Types**: PDFs and Markdown files (folders are excluded)

**Navigation**: Uses standard Flutter navigation with MaterialPageRoute

**State Management**: File IDs are passed as constructor parameters and added to `_selectedFileIds` in `initState()`

**Backward Compatibility**: Existing single-file chat functionality (from PDF viewer) remains unchanged

## Benefits

- Quick access to chat with all documents in a folder
- No need to manually select multiple files
- Clear visual indication of folder context
- Seamless integration with existing chat functionality
- Maintains offline-first architecture
