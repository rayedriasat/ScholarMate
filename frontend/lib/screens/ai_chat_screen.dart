import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart' as model;
import '../models/drive_file.dart';
import '../services/ai_chat_service.dart';
import '../services/auth_service.dart';
import '../services/drive_service.dart';
import '../services/chat_preference_service.dart';
import '../services/chat_history_service.dart';
import '../services/pdf_viewer_manager.dart';
import '../services/connectivity_service.dart';
import '../database/database.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/source_selection_panel.dart';
import '../widgets/conversation_list_sidebar.dart';
import '../widgets/typing_indicator.dart';
import 'pdf_viewer_screen.dart';

/// AI Chat screen with RAG and source selection
class AIChatScreen extends StatefulWidget {
  final String? preselectedFileId;
  final String? preselectedFileName;
  final List<String>? preselectedFileIds;
  final String? folderName;

  const AIChatScreen({
    super.key,
    this.preselectedFileId,
    this.preselectedFileName,
    this.preselectedFileIds,
    this.folderName,
  });

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final List<model.ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIChatService _chatService = AIChatService();

  bool _isLoading = false;
  bool _showSourcePanel = false;
  bool _showConversationList = false;
  Set<String> _selectedFileIds = {};
  List<DriveFile> _availableFiles = [];
  bool _isLoadingFiles = false;

  // Chat history
  List<ChatConversation> _conversations = [];
  String? _currentConversationId;
  bool _isLoadingConversations = false;
  ChatHistoryService? _historyService;

  @override
  void initState() {
    super.initState();
    _loadAvailableFiles();
    _loadConversations();

    // If a file is preselected, add it to selected files
    if (widget.preselectedFileId != null) {
      _selectedFileIds.add(widget.preselectedFileId!);
    }

    // If multiple files are preselected (folder chat), add them all
    if (widget.preselectedFileIds != null) {
      _selectedFileIds.addAll(widget.preselectedFileIds!);
    }
  }

  Future<void> _loadConversations() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingConversations = true;
    });

    try {
      final database = context.read<AppDatabase>();
      _historyService = ChatHistoryService(database);

      final conversations = await _historyService!.getConversations(user.id);

      setState(() {
        _conversations = conversations;
        _isLoadingConversations = false;
      });
    } catch (e) {
      debugPrint('Failed to load conversations: $e');
      setState(() {
        _isLoadingConversations = false;
      });
    }
  }

  Future<void> _loadSourcePreferences() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) return;

    try {
      final database = context.read<AppDatabase>();
      final preferenceService = ChatPreferenceService(database);
      final selectedIds = await preferenceService.loadSelectedSources(user.id);

      setState(() {
        _selectedFileIds = selectedIds;
      });
    } catch (e) {
      debugPrint('Failed to load source preferences: $e');
    }
  }

  Future<void> _saveSourcePreferences() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) return;

    try {
      final database = context.read<AppDatabase>();
      final preferenceService = ChatPreferenceService(database);
      await preferenceService.saveSelectedSources(user.id, _selectedFileIds);
    } catch (e) {
      debugPrint('Failed to save source preferences: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableFiles() async {
    setState(() {
      _isLoadingFiles = true;
    });

    try {
      final driveService = context.read<DriveService>();
      // Use listAllFiles() to get PDFs from all folders recursively
      final files = await driveService.listAllFiles();

      // Filter only PDF files
      setState(() {
        _availableFiles = files
            .where((f) => f.mimeType == 'application/pdf')
            .toList();
        _isLoadingFiles = false;
      });
    } catch (e) {
      debugPrint('Failed to load files: $e');
      setState(() {
        _isLoadingFiles = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Get user ID
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) {
      _showError('Please sign in to use chat');
      return;
    }

    // Create new conversation if needed
    if (_currentConversationId == null && _historyService != null) {
      final title = _historyService!.generateTitle(message);
      _currentConversationId = await _historyService!.createConversation(
        userId: user.id,
        title: title,
        selectedSourceIds: _selectedFileIds,
      );
      await _loadConversations();
    }

    // Add user message
    final messageTime = DateTime.now();
    final userMessage = model.ChatMessage(
      id: '${messageTime.millisecondsSinceEpoch}_user',
      content: message,
      isUser: true,
      timestamp: messageTime,
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isLoading = true;
    });

    // Save user message to history
    if (_currentConversationId != null && _historyService != null) {
      await _historyService!.saveMessage(
        conversationId: _currentConversationId!,
        message: userMessage,
      );
    }

    _scrollToBottom();

    // Small delay to ensure AI response has a later timestamp
    await Future.delayed(const Duration(milliseconds: 10));

    try {
      // Send message to backend
      final aiResponse = await _chatService.sendMessage(
        question: message,
        userId: user.id,
        selectedFileIds: _selectedFileIds.isNotEmpty
            ? _selectedFileIds.toList()
            : null,
      );

      setState(() {
        _messages.add(aiResponse);
        _isLoading = false;
      });

      // Save AI response to history
      if (_currentConversationId != null && _historyService != null) {
        await _historyService!.saveMessage(
          conversationId: _currentConversationId!,
          message: aiResponse,
        );
      }

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError(e.toString());
    }
  }

  Future<void> _loadConversation(String conversationId) async {
    if (_historyService == null) return;

    setState(() {
      _isLoading = true;
      _currentConversationId = conversationId;
    });

    try {
      // Load messages
      final messages = await _historyService!.loadMessages(conversationId);

      // Load source selection for this conversation
      final sourceIds = await _historyService!.getConversationSourceIds(
        conversationId,
      );

      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _selectedFileIds = sourceIds;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Failed to load conversation: $e');
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load conversation');
    }
  }

  Future<void> _startNewConversation() async {
    setState(() {
      _currentConversationId = null;
      _messages.clear();
    });

    // Load default source preferences
    await _loadSourcePreferences();
  }

  Future<void> _deleteConversation(String conversationId) async {
    if (_historyService == null) return;

    try {
      await _historyService!.deleteConversation(conversationId);

      // If we deleted the current conversation, start a new one
      if (_currentConversationId == conversationId) {
        await _startNewConversation();
      }

      await _loadConversations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to delete conversation: $e');
      _showError('Failed to delete conversation');
    }
  }

  Future<void> _renameConversation(
    String conversationId,
    String newTitle,
  ) async {
    if (_historyService == null) return;

    try {
      await _historyService!.updateConversationTitle(conversationId, newTitle);
      await _loadConversations();
    } catch (e) {
      debugPrint('Failed to rename conversation: $e');
      _showError('Failed to rename conversation');
    }
  }

  Future<void> _clearAllConversations() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null || _historyService == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Conversations'),
        content: const Text(
          'Are you sure you want to delete all conversations? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _historyService!.clearAllConversations(user.id);
        await _startNewConversation();
        await _loadConversations();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All conversations cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Failed to clear conversations: $e');
        _showError('Failed to clear conversations');
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _onCitationTapped(model.Citation citation) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Opening PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Check if file is cached, if not download it first
      final pdfManager = context.read<PdfViewerManager>();
      final isCached = await pdfManager.isPdfCached(citation.fileId);

      if (!isCached) {
        // Check if online
        final connectivityService = context.read<ConnectivityService>();
        if (!connectivityService.isOnline) {
          Navigator.pop(context); // Close loading dialog
          _showError(
            'PDF not cached and device is offline. Please connect to download the file.',
          );
          return;
        }
      }

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Navigate to PDF viewer at the specific page
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              fileId: citation.fileId,
              fileName: citation.fileName,
              initialPage: citation.pageNumber,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showError('Failed to open PDF: $e');
    }
  }

  Future<void> _onSaveAsNote(model.ChatMessage message) async {
    try {
      // Get user ID
      final authService = context.read<AuthService>();
      final user = authService.currentUser;
      if (user == null) {
        _showError('Please sign in to save notes');
        return;
      }

      // Check if online
      final connectivityService = context.read<ConnectivityService>();
      if (!connectivityService.isOnline) {
        _showError('You must be online to save notes to Google Drive');
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving note...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Generate markdown content
      final markdownContent = await _chatService.saveChatAsNote(
        message: message,
        userId: user.id,
      );

      // Get or create Notes folder
      final driveService = context.read<DriveService>();
      final appFolderId = await driveService.getAppFolderId();

      // Check if Notes folder exists
      final files = await driveService.listFiles(appFolderId);
      String? notesFolderId;

      for (final file in files) {
        if (file.isFolder && file.name == 'Notes') {
          notesFolderId = file.id;
          break;
        }
      }

      // Create Notes folder if it doesn't exist
      if (notesFolderId == null) {
        final notesFolder = await driveService.createFolder(
          'Notes',
          appFolderId,
        );
        notesFolderId = notesFolder.id;
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now();
      final fileName =
          'AI_Chat_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}.md';

      // Save to Google Drive
      final bytes = utf8.encode(markdownContent);
      await driveService.uploadFileFromBytes(
        Uint8List.fromList(bytes),
        fileName,
        notesFolderId,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Note saved to Notes folder: $fileName')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showError('Failed to save note: $e');
    }
  }

  void _toggleSourceSelection(String fileId) {
    setState(() {
      if (_selectedFileIds.contains(fileId)) {
        _selectedFileIds.remove(fileId);
      } else {
        _selectedFileIds.add(fileId);
      }
    });
    _saveSourcePreferences();
    _updateConversationSources();
  }

  void _clearAllSources() {
    setState(() {
      _selectedFileIds.clear();
    });
    _saveSourcePreferences();
    _updateConversationSources();
  }

  void _selectAllSources() {
    setState(() {
      _selectedFileIds = _availableFiles.map((f) => f.id).toSet();
    });
    _saveSourcePreferences();
    _updateConversationSources();
  }

  Future<void> _updateConversationSources() async {
    if (_currentConversationId != null && _historyService != null) {
      try {
        await _historyService!.updateConversationSources(
          _currentConversationId!,
          _selectedFileIds,
        );
      } catch (e) {
        debugPrint('Failed to update conversation sources: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentConversationId != null
                  ? _conversations
                        .firstWhere(
                          (c) => c.id == _currentConversationId,
                          orElse: () => ChatConversation(
                            id: '',
                            userId: '',
                            title: 'AI Chat',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                            selectedSourceIds: '[]',
                          ),
                        )
                        .title
                  : 'AI Chat',
            ),
            if (widget.preselectedFileId != null &&
                widget.preselectedFileName != null)
              Text(
                'Chatting with ${widget.preselectedFileName}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            if (widget.folderName != null && widget.preselectedFileIds != null)
              Text(
                'Chatting with folder: ${widget.folderName} (${widget.preselectedFileIds!.length} files)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        leading: widget.preselectedFileId != null || widget.folderName != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                tooltip: widget.folderName != null
                    ? 'Back to Folder'
                    : 'Back to PDF',
              )
            : isWideScreen
            ? IconButton(
                icon: Icon(_showConversationList ? Icons.close : Icons.menu),
                onPressed: () {
                  setState(() {
                    _showConversationList = !_showConversationList;
                  });
                },
                tooltip: 'Conversations',
              )
            : null,
        actions: [
          if (widget.preselectedFileId != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back to PDF',
            ),
          if (_currentConversationId != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _startNewConversation,
              tooltip: 'New Chat',
            ),
          IconButton(
            icon: Icon(_showSourcePanel ? Icons.close : Icons.filter_list),
            onPressed: () {
              if (isWideScreen) {
                setState(() {
                  _showSourcePanel = !_showSourcePanel;
                });
              } else {
                _showSourceSelectionBottomSheet();
              }
            },
            tooltip: 'Source Selection',
          ),
          if (_conversations.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear_all') {
                  _clearAllConversations();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Clear All Conversations',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      drawer: !isWideScreen
          ? Drawer(
              child: ConversationListSidebar(
                conversations: _conversations,
                currentConversationId: _currentConversationId,
                onConversationSelected: (id) {
                  _loadConversation(id);
                  Navigator.pop(context); // Close drawer
                },
                onNewConversation: () {
                  _startNewConversation();
                  Navigator.pop(context); // Close drawer
                },
                onDeleteConversation: _deleteConversation,
                onRenameConversation: _renameConversation,
                isLoading: _isLoadingConversations,
              ),
            )
          : null,
      body: Row(
        children: [
          // Conversation list sidebar (desktop only)
          if (_showConversationList && isWideScreen)
            ConversationListSidebar(
              conversations: _conversations,
              currentConversationId: _currentConversationId,
              onConversationSelected: _loadConversation,
              onNewConversation: _startNewConversation,
              onDeleteConversation: _deleteConversation,
              onRenameConversation: _renameConversation,
              isLoading: _isLoadingConversations,
            ),

          // Main chat area
          Expanded(
            flex: _showSourcePanel && isWideScreen ? 2 : 1,
            child: Column(
              children: [
                // Messages list
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length) {
                              return const TypingIndicator();
                            }
                            final message = _messages[index];
                            return ChatMessageBubble(
                              message: message,
                              onCitationTapped: _onCitationTapped,
                              onSaveAsNote: message.isUser
                                  ? null
                                  : () => _onSaveAsNote(message),
                            );
                          },
                        ),
                ),

                // Input area
                _buildInputArea(),
              ],
            ),
          ),

          // Source selection panel (desktop/tablet only)
          if (_showSourcePanel && isWideScreen)
            Container(
              width: 300,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: SourceSelectionPanel(
                availableFiles: _availableFiles,
                selectedFileIds: _selectedFileIds,
                isLoading: _isLoadingFiles,
                onToggleFile: _toggleSourceSelection,
                onClearAll: _clearAllSources,
                onSelectAll: _selectAllSources,
                onRefresh: _loadAvailableFiles,
              ),
            ),
        ],
      ),
    );
  }

  void _showSourceSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SourceSelectionPanel(
                  availableFiles: _availableFiles,
                  selectedFileIds: _selectedFileIds,
                  isLoading: _isLoadingFiles,
                  onToggleFile: (fileId) {
                    setState(() {
                      _toggleSourceSelection(fileId);
                    });
                  },
                  onClearAll: () {
                    setState(() {
                      _clearAllSources();
                    });
                  },
                  onSelectAll: () {
                    setState(() {
                      _selectAllSources();
                    });
                  },
                  onRefresh: _loadAvailableFiles,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasPreselection =
        widget.preselectedFileId != null || widget.folderName != null;
    final isFolderChat = widget.folderName != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFolderChat
                ? Icons.folder
                : widget.preselectedFileId != null
                ? Icons.picture_as_pdf
                : Icons.chat_bubble_outline,
            size: 64,
            color: hasPreselection ? Colors.blue[400] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isFolderChat
                ? 'Chat with Folder'
                : widget.preselectedFileId != null
                ? 'Chat with PDF'
                : 'Start a conversation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: hasPreselection ? Colors.blue[600] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFolderChat && widget.folderName != null
                ? 'Ask questions about files in "${widget.folderName}"'
                : widget.preselectedFileId != null &&
                      widget.preselectedFileName != null
                ? 'Ask questions about "${widget.preselectedFileName}"'
                : 'Ask questions about your documents',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (hasPreselection) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isFolderChat
                        ? '${widget.preselectedFileIds?.length ?? 0} files automatically selected'
                        : 'PDF automatically selected for context',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected sources indicator
          if (_selectedFileIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 4,
                children: [
                  // Show preselected file name if available
                  if (widget.preselectedFileId != null &&
                      _selectedFileIds.contains(widget.preselectedFileId) &&
                      widget.preselectedFileName != null)
                    Chip(
                      avatar: const Icon(Icons.picture_as_pdf, size: 16),
                      label: Text(
                        widget.preselectedFileName!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () =>
                          _toggleSourceSelection(widget.preselectedFileId!),
                    ),
                  // Show general count for other files
                  if (_selectedFileIds.length > 1 ||
                      (widget.preselectedFileId == null &&
                          _selectedFileIds.isNotEmpty))
                    Chip(
                      label: Text(
                        '${_selectedFileIds.length} source${_selectedFileIds.length == 1 ? '' : 's'} selected',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: _clearAllSources,
                    ),
                ],
              ),
            ),

          // Input field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Ask a question...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_isLoading,
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: _isLoading ? null : _sendMessage,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
