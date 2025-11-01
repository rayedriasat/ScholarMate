# Citation Navigation - Quick Reference

## Overview
Users can click on citation chips in AI chat responses to instantly navigate to the referenced page in the source PDF document.

## User Flow

```
AI Chat Response with Citations
        ↓
User clicks citation chip
        ↓
Loading dialog appears
        ↓
System checks if PDF is cached
        ↓
PDF Viewer opens at referenced page
        ↓
Visual feedback (snackbar + badge)
```

## Key Components

### 1. Citation Model
```dart
class Citation {
  final String fileId;      // Google Drive file ID
  final String fileName;    // Display name
  final int pageNumber;     // Target page (1-indexed)
  final String snippet;     // Text excerpt
}
```

### 2. Citation Chip (ChatMessageBubble)
- Clickable with tap gesture
- Tooltip: "Click to open [filename] at page [number]"
- Visual: PDF icon + filename + page + open icon
- Callback: `onCitationTapped(Citation)`

### 3. Navigation Handler (AIChatScreen)
```dart
void _onCitationTapped(Citation citation) async {
  // 1. Show loading dialog
  // 2. Check if PDF is cached
  // 3. Validate connectivity if download needed
  // 4. Navigate to PDF viewer with initialPage
  // 5. Handle errors gracefully
}
```

### 4. PDF Viewer (PdfViewerScreen)
```dart
PdfViewerScreen({
  String? fileId,
  String? fileName,
  int? initialPage,  // Jump to this page on load
})
```

## Features

✅ **Instant Navigation**: Opens PDF at exact referenced page
✅ **Smart Caching**: Checks cache before downloading
✅ **Offline Support**: Detects offline state and shows helpful error
✅ **Visual Feedback**: Snackbar + badge indicate citation navigation
✅ **Error Handling**: User-friendly messages for all error cases
✅ **Responsive**: Works on mobile, tablet, desktop, and web

## Error Scenarios

| Scenario | Behavior |
|----------|----------|
| PDF cached | Opens instantly |
| PDF not cached + online | Downloads then opens |
| PDF not cached + offline | Shows error: "PDF not cached and device is offline" |
| Navigation fails | Shows error: "Failed to open PDF: [reason]" |

## Visual Indicators

1. **Citation Chip**
   - Blue background with border
   - PDF icon + filename + page number
   - Open icon on right
   - Hover tooltip (desktop/web)

2. **PDF Viewer App Bar**
   - Badge: "From citation" (blue background)
   - Shows current page number

3. **Snackbar Notification**
   - "Navigated to page X from citation"
   - Blue background with bookmark icon
   - 3-second duration

## Code Locations

- **Citation Model**: `frontend/lib/models/chat_message.dart`
- **Citation Chip UI**: `frontend/lib/widgets/chat_message_bubble.dart`
- **Navigation Logic**: `frontend/lib/screens/ai_chat_screen.dart`
- **PDF Viewer**: `frontend/lib/screens/pdf_viewer_screen.dart`

## Testing

### Manual Test Steps:
1. Open AI Chat screen
2. Ask a question that returns citations
3. Click on a citation chip
4. Verify PDF opens at correct page
5. Check for visual feedback (snackbar + badge)
6. Test offline scenario (airplane mode)
7. Test with multiple citations

### Expected Results:
- PDF opens within 1-2 seconds (cached)
- Page navigation is accurate
- Visual feedback is clear
- Errors are user-friendly
- Works across all platforms

## Dependencies

- `syncfusion_flutter_pdfviewer` - PDF rendering and navigation
- `provider` - State management
- `flutter/material.dart` - UI components

## Related Tasks

- Task 13.3: AI Chat UI with citations display
- Task 13.2: RAG chat endpoint with citations
- Task 13.1: RAG query service
- Phase 4: PDF viewing infrastructure

---

**Last Updated**: 2025-11-01
**Status**: ✅ Production Ready
