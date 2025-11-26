# Notebook Studio Web Layout

## Overview

The Notebook Studio now features a **Google NotebookLM-inspired 3-panel resizable layout** for web users, providing a professional research workspace experience.

## Layout Structure

```
┌─────────────────────────────────────────────────────────────┐
│                         Header Bar                          │
│  [← Back] Workspace Name    [Files] [AI Studio] [Edit] [⚙] │
├──────────────┬──────────────────────┬──────────────────────┤
│              │                      │                      │
│   Files      │      AI Chat         │    AI Studio        │
│   Panel      │      Panel           │    Panel            │
│              │                      │                      │
│  • Add files │  • Ask questions     │  • Quiz Generator   │
│  • Browse    │  • RAG responses     │  • Summarizer       │
│  • Manage    │  • Citations         │  • Mind Maps        │
│              │                      │  • Flashcards       │
│              │                      │  • Audio Review     │
│              │                      │                      │
└──────────────┴──────────────────────┴──────────────────────┘
```

## Features

### 1. **Resizable Panels**
- Drag the dividers between panels to adjust widths
- Minimum width: 200px per panel
- Width range: 15% - 50% of screen width
- Smooth drag interaction with visual feedback

### 2. **Collapsible Panels**
- Toggle left panel (Files) visibility
- Toggle right panel (AI Studio) visibility
- Middle panel (Chat) always visible
- Buttons in header for quick access

### 3. **Panel Contents**

#### Left Panel - Files
- Browse workspace files
- Add new notes
- Import from Google Drive
- File management

#### Middle Panel - AI Chat
- RAG-powered Q&A
- Context from workspace files
- Citation support
- Conversation history

#### Right Panel - AI Studio
- Quiz Generator
- Summarizer
- Mind Map Creator
- Flashcard Generator
- Audio Review

## Platform Detection

The layout automatically adapts:
- **Web**: 3-panel resizable layout
- **Mobile/Desktop**: Tab-based layout (existing)

```dart
// Automatic platform detection in NotebookFolderScreen
if (kIsWeb) {
  return NotebookFolderWebScreen(folder: widget.folder);
}
return Scaffold(...); // Tab-based layout
```

## Files Modified

1. **Created**: `frontend/lib/screens/notebook_folder_web_screen.dart`
   - New web-optimized 3-panel layout
   - Resizable dividers with drag support
   - Panel visibility toggles
   - Professional header with controls

2. **Updated**: `frontend/lib/screens/notebook_folder_screen.dart`
   - Added platform detection
   - Routes to web layout when on web
   - Maintains tab layout for mobile/desktop

## Usage

### For Users
1. Open any Notebook Studio workspace on web
2. Drag dividers to resize panels
3. Click sidebar icons in header to show/hide panels
4. Work with files, chat, and AI tools simultaneously

### For Developers
```dart
// The screen automatically detects platform
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NotebookFolderScreen(folder: folder),
  ),
);
```

## Design Inspiration

Inspired by **Google NotebookLM**:
- Clean, professional interface
- Multi-panel workspace
- Resizable sections
- Focus on research workflow
- Minimal distractions

## Technical Details

### State Management
- Panel widths stored as percentages
- Visibility flags for each panel
- Responsive to window resizing

### Constraints
- Minimum panel width: 200px
- Maximum panel width: 50% of screen
- Divider width: 8px
- Header height: 64px

### Styling
- Consistent with Material Design 3
- Theme-aware colors
- Smooth transitions
- Hover effects on dividers

## Future Enhancements

Potential improvements:
- [ ] Save panel layout preferences
- [ ] Keyboard shortcuts for panel toggles
- [ ] Drag-and-drop between panels
- [ ] Full-screen mode for individual panels
- [ ] Split view within panels
- [ ] Custom panel arrangements

## Testing

To test the new layout:
1. Run web version: `flutter run -d chrome`
2. Navigate to Notebook Studio
3. Open any workspace
4. Verify 3-panel layout appears
5. Test resizing by dragging dividers
6. Test panel visibility toggles
7. Verify responsive behavior

## Notes

- Only available on web platform
- Mobile/desktop continue using tab-based layout
- All existing functionality preserved
- No breaking changes to API or data models
