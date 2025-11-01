# AI Chat Interface - Quick Reference

## Usage

### Opening the Chat
Navigate to the "AI Assistant" tab in the home screen navigation.

### Selecting Sources
1. Click the filter icon in the app bar
2. Desktop: Side panel opens
3. Mobile: Bottom sheet opens
4. Check/uncheck PDFs to include in search
5. Use "Select All" or "Clear All" for bulk actions

### Asking Questions
1. Type your question in the input field
2. Click send button or press Enter
3. Wait for AI response (typing indicator shows)
4. View response with citations

### Viewing Citations
1. Click any citation chip below AI message
2. PDF viewer opens at the referenced page
3. Navigate back to return to chat

## Key Components

### AIChatScreen
Main chat interface with message list, input, and source selection.

**Location**: `lib/screens/ai_chat_screen.dart`

**Key Methods**:
- `_sendMessage()` - Sends user message to backend
- `_loadAvailableFiles()` - Loads PDF files for source selection
- `_onCitationTapped()` - Handles citation clicks
- `_toggleSourceSelection()` - Toggles file selection

### ChatMessageBubble
Displays individual chat messages with styling and citations.

**Location**: `lib/widgets/chat_message_bubble.dart`

**Props**:
- `message: ChatMessage` - Message to display
- `onCitationTapped: Function(Citation)?` - Citation click handler

### SourceSelectionPanel
File selection panel with checkboxes and controls.

**Location**: `lib/widgets/source_selection_panel.dart`

**Props**:
- `availableFiles: List<DriveFile>` - Available PDF files
- `selectedFileIds: Set<String>` - Currently selected file IDs
- `onToggleFile: Function(String)` - File selection toggle
- `onClearAll: VoidCallback` - Clear all selections
- `onSelectAll: VoidCallback` - Select all files

### AIChatService
Service for making AI chat API calls.

**Location**: `lib/services/ai_chat_service.dart`

**Methods**:
```dart
Future<ChatMessage> sendMessage({
  required String question,
  required String userId,
  List<String>? selectedFileIds,
  int topK = 5,
})
```

## Models

### ChatMessage
```dart
ChatMessage({
  required String id,
  required String content,
  required bool isUser,
  required DateTime timestamp,
  List<Citation>? citations,
  bool isTyping = false,
})
```

### Citation
```dart
Citation({
  required String fileId,
  required String fileName,
  required int pageNumber,
  String snippet = '',
})
```

## API Integration

### Endpoint
`POST /api/ai/chat-rag`

### Request
```json
{
  "question": "What is the main topic?",
  "user_id": "user-uuid",
  "selected_file_ids": ["file-id-1", "file-id-2"],
  "top_k": 5
}
```

### Response
```json
{
  "message": "The main topic is...",
  "citations": [
    {
      "file_id": "file-id-1",
      "file_name": "document.pdf",
      "page_number": 5,
      "snippet": "relevant text..."
    }
  ],
  "timestamp": "2025-11-01T17:30:00Z"
}
```

## Styling

### Colors
- User messages: `theme.primaryColor`
- AI messages: `theme.cardColor`
- Citations: `theme.primaryColor.withOpacity(0.1)` background

### Responsive Breakpoint
- Desktop/Tablet: `width > 600px` - Side panel
- Mobile: `width <= 600px` - Bottom sheet

## Common Tasks

### Add New Message Type
1. Update `ChatMessage` model with new field
2. Update `ChatMessageBubble` to render new type
3. Update JSON serialization

### Customize Citation Display
Edit `_buildCitationChip()` in `chat_message_bubble.dart`

### Change Source Panel Width
Update `width: 300` in `ai_chat_screen.dart`

### Modify Typing Animation
Edit animation parameters in `typing_indicator.dart`

## Troubleshooting

### Citations Not Clickable
- Verify `onCitationTapped` is passed to `ChatMessageBubble`
- Check PDF viewer screen accepts `initialPage` parameter

### Source Panel Not Showing Files
- Verify files are PDFs (`mimeType == 'application/pdf'`)
- Check `_loadAvailableFiles()` is called in `initState()`

### Messages Not Scrolling
- Verify `_scrollController` is attached to ListView
- Check `_scrollToBottom()` is called after adding messages

### API Errors
- Check backend is running on correct port
- Verify `apiBaseUrl` in ConfigService
- Check user authentication token

## Performance Tips

1. **Lazy Loading**: Messages are rendered on-demand in ListView.builder
2. **Debouncing**: Consider debouncing file selection updates
3. **Caching**: Files list is cached until manual refresh
4. **Pagination**: Consider implementing message pagination for long conversations

## Accessibility

- All interactive elements have semantic labels
- Color contrast meets WCAG AA standards
- Keyboard navigation supported on web/desktop
- Screen reader compatible

## Future Enhancements

- [ ] Message history persistence
- [ ] Conversation threads
- [ ] Export chat transcript
- [ ] Voice input
- [ ] Image attachments
- [ ] Code syntax highlighting
- [ ] Markdown rendering in messages
