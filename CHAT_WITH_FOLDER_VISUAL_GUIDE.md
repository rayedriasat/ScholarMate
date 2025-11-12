# Chat with Folder - Visual Guide

## Feature Location

```
File Explorer Screen
├── Folder View (when folder contains files)
│   ├── [Files and subfolders listed]
│   └── Floating Action Buttons (bottom-right)
│       ├── 📁 "Chat with Folder" button ← NEW!
│       ├── (FAB menu items when expanded)
│       └── ➕ Main FAB button
```

## Button Appearance

**Extended FAB Button:**
- **Icon**: 💬 Chat icon
- **Label**: "Chat with Folder"
- **Color**: Secondary container color (theme-based)
- **Position**: Above the main '+' FAB
- **Visibility**: Only shown when folder contains files

## AI Chat Screen Changes

### Title Bar
```
Before: "AI Chat"
After (folder chat): "AI Chat"
Subtitle: "Chatting with folder: Documents (5 files)"
```

### Empty State
```
┌─────────────────────────────────┐
│         📁 Folder Icon          │
│                                 │
│      Chat with Folder           │
│                                 │
│  Ask questions about files in   │
│         "Documents"             │
│                                 │
│  ℹ️ 5 files automatically       │
│     selected                    │
└─────────────────────────────────┘
```

## User Flow

```
1. User opens File Explorer
   ↓
2. User navigates to a folder (e.g., "Research Papers")
   ↓
3. Folder contains 3 PDFs
   ↓
4. "Chat with Folder" button appears above '+' FAB
   ↓
5. User taps "Chat with Folder"
   ↓
6. AI Chat opens with:
   - Title: "Chatting with folder: Research Papers (3 files)"
   - All 3 PDFs pre-selected in source panel
   - Ready to answer questions about all files
```

## Example Scenarios

### Scenario 1: Research Folder
```
Folder: "Machine Learning Papers"
Files: 
  - paper1.pdf
  - paper2.pdf
  - notes.md

Action: Tap "Chat with Folder"
Result: Chat opens with all 3 files selected
Query: "What are the common themes across these papers?"
```

### Scenario 2: Empty Folder
```
Folder: "New Project"
Files: (none)

Action: "Chat with Folder" button NOT shown
Reason: No files to chat with
```

### Scenario 3: Nested Folders
```
Folder: "Documents/2024/Reports"
Files:
  - Q1_report.pdf
  - Q2_report.pdf
  - subfolder/ (ignored)

Action: Tap "Chat with Folder"
Result: Chat opens with 2 PDFs selected (subfolder ignored)
Query: "Compare the quarterly reports"
```

## Code Integration Points

### File Explorer → AI Chat
```dart
// In file_explorer_screen.dart
_chatWithFolder() {
  final fileIds = _files
    .where((f) => !f.isFolder)
    .map((f) => f.id)
    .toList();
    
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AIChatScreen(
        preselectedFileIds: fileIds,
        folderName: currentFolderName,
      ),
    ),
  );
}
```

### AI Chat Initialization
```dart
// In ai_chat_screen.dart
@override
void initState() {
  super.initState();
  
  // Add all preselected folder files
  if (widget.preselectedFileIds != null) {
    _selectedFileIds.addAll(widget.preselectedFileIds!);
  }
}
```

## Testing Checklist

- [ ] Button appears when folder has files
- [ ] Button hidden when folder is empty
- [ ] Button hidden when folder only has subfolders
- [ ] Tapping button opens AI chat
- [ ] All folder files are pre-selected
- [ ] Folder name displays correctly in title
- [ ] File count displays correctly
- [ ] Back button returns to folder
- [ ] Works with nested folders
- [ ] Works with mixed content (PDFs + Markdown)
- [ ] Respects file type filtering (only PDFs and Markdown)
