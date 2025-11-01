# Chat History Quick Reference

## Overview
Chat history allows users to save, load, and manage AI chat conversations with persistent source selection.

## Key Components

### 1. Database Tables

**ChatConversations**
```dart
- id: String (primary key)
- userId: String
- title: String
- createdAt: DateTime
- updatedAt: DateTime
- selectedSourceIds: String (JSON array of file IDs)
```

**ChatMessages**
```dart
- id: String (primary key)
- conversationId: String
- content: String
- isUser: Boolean
- timestamp: DateTime
- citations: String? (JSON array, nullable)
```

### 2. ChatHistoryService

**Location**: `frontend/lib/services/chat_history_service.dart`

**Key Methods**:
```dart
// Create new conversation
Future<String> createConversation({
  required String userId,
  required String title,
  required Set<String> selectedSourceIds,
})

// Load conversations
Future<List<ChatConversation>> getConversations(String userId)

// Save message
Future<void> saveMessage({
  required String conversationId,
  required ChatMessage message,
})

// Load messages
Future<List<ChatMessage>> loadMessages(String conversationId)

// Update conversation
Future<void> updateConversationTitle(String conversationId, String newTitle)
Future<void> updateConversationSources(String conversationId, Set<String> selectedSourceIds)

// Delete conversation
Future<void> deleteConversation(String conversationId)
```

### 3. ConversationListSidebar Widget

**Location**: `frontend/lib/widgets/conversation_list_sidebar.dart`

**Usage**:
```dart
ConversationListSidebar(
  conversations: _conversations,
  currentConversationId: _currentConversationId,
  onConversationSelected: (id) => _loadConversation(id),
  onNewConversation: () => _startNewConversation(),
  onDeleteConversation: (id) => _deleteConversation(id),
  onRenameConversation: (id, title) => _renameConversation(id, title),
  isLoading: _isLoadingConversations,
)
```

## Usage in AI Chat Screen

### Initialize
```dart
ChatHistoryService? _historyService;
List<ChatConversation> _conversations = [];
String? _currentConversationId;

@override
void initState() {
  super.initState();
  _loadConversations();
}

Future<void> _loadConversations() async {
  final database = context.read<AppDatabase>();
  _historyService = ChatHistoryService(database);
  final conversations = await _historyService!.getConversations(userId);
  setState(() => _conversations = conversations);
}
```

### Create Conversation on First Message
```dart
if (_currentConversationId == null && _historyService != null) {
  final title = _historyService!.generateTitle(message);
  _currentConversationId = await _historyService!.createConversation(
    userId: user.id,
    title: title,
    selectedSourceIds: _selectedFileIds,
  );
}
```

### Save Messages
```dart
// Save user message
await _historyService!.saveMessage(
  conversationId: _currentConversationId!,
  message: userMessage,
);

// Save AI response
await _historyService!.saveMessage(
  conversationId: _currentConversationId!,
  message: aiResponse,
);
```

### Load Conversation
```dart
Future<void> _loadConversation(String conversationId) async {
  // Load messages
  final messages = await _historyService!.loadMessages(conversationId);
  
  // Load source selection
  final sourceIds = await _historyService!.getConversationSourceIds(conversationId);
  
  setState(() {
    _currentConversationId = conversationId;
    _messages.clear();
    _messages.addAll(messages);
    _selectedFileIds = sourceIds;
  });
}
```

### Start New Conversation
```dart
Future<void> _startNewConversation() async {
  setState(() {
    _currentConversationId = null;
    _messages.clear();
  });
  await _loadSourcePreferences(); // Load default sources
}
```

## UI Layout

### Desktop (Wide Screen)
```
┌─────────────────────────────────────────────────────────┐
│ [☰] AI Chat Title                    [+] [Filter] [⋮]  │
├──────────┬──────────────────────────────┬───────────────┤
│          │                              │               │
│ Conv.    │   Chat Messages              │  Source       │
│ List     │   (Main Area)                │  Selection    │
│ Sidebar  │                              │  Panel        │
│          │                              │               │
│          │   [Input Area]               │               │
└──────────┴──────────────────────────────┴───────────────┘
```

### Mobile (Narrow Screen)
```
┌─────────────────────────────────┐
│ [☰] AI Chat      [+] [Filter]  │
├─────────────────────────────────┤
│                                 │
│   Chat Messages                 │
│   (Main Area)                   │
│                                 │
│   [Input Area]                  │
└─────────────────────────────────┘

Drawer (when opened):
┌─────────────────┐
│ [New Chat]      │
├─────────────────┤
│ Conversation 1  │
│ Conversation 2  │
│ Conversation 3  │
└─────────────────┘
```

## Data Flow

1. **User sends message** → Auto-create conversation if needed → Save message to DB
2. **AI responds** → Save response with citations to DB → Update conversation timestamp
3. **User selects conversation** → Load messages from DB → Load source selection → Display
4. **User changes sources** → Update conversation sources in DB
5. **User deletes conversation** → Delete all messages → Delete conversation → Refresh list

## Best Practices

1. **Always check for null**: `_currentConversationId` and `_historyService` can be null
2. **Update timestamps**: Call `updateConversationTimestamp()` when adding messages
3. **Handle errors**: Wrap database operations in try-catch blocks
4. **Confirm deletions**: Show confirmation dialog before deleting conversations
5. **Auto-generate titles**: Use first message content for conversation titles
6. **Persist sources**: Save source selection changes to current conversation

## Common Patterns

### Check if in conversation
```dart
if (_currentConversationId != null) {
  // User is in an existing conversation
}
```

### Save message with error handling
```dart
try {
  await _historyService!.saveMessage(
    conversationId: _currentConversationId!,
    message: message,
  );
} catch (e) {
  debugPrint('Failed to save message: $e');
}
```

### Delete with confirmation
```dart
final confirmed = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Delete Conversation'),
    content: const Text('Are you sure?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
    ],
  ),
);

if (confirmed == true) {
  await _historyService!.deleteConversation(conversationId);
}
```
