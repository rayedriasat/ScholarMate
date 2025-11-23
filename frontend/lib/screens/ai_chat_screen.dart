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
import '../theme/app_colors.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/source_selection_panel.dart';
import '../widgets/conversation_list_sidebar.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../widgets/ui/modern_text_field.dart';
import '../widgets/ui/animated_background.dart';
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

    if (widget.preselectedFileId != null) {
      _selectedFileIds.add(widget.preselectedFileId!);
    }

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
      final files = await driveService.listAllFiles();

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

    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) {
      _showError('Please sign in to use chat');
      return;
    }

    if (_currentConversationId == null && _historyService != null) {
      final title = _historyService!.generateTitle(message);
      _currentConversationId = await _historyService!.createConversation(
        userId: user.id,
        title: title,
        selectedSourceIds: _selectedFileIds,
      );
      await _loadConversations();
    }

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

    if (_currentConversationId != null && _historyService != null) {
      await _historyService!.saveMessage(
        conversationId: _currentConversationId!,
        message: userMessage,
      );
    }

    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 10));

    try {
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
      final messages = await _historyService!.loadMessages(conversationId);
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
    await _loadSourcePreferences();
  }

  Future<void> _deleteConversation(String conversationId) async {
    if (_historyService == null) return;

    try {
      await _historyService!.deleteConversation(conversationId);

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
        backgroundColor: AppColors.surface,
        title: const Text(
          'Clear All Conversations',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete all conversations? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ModernButton(
            label: 'Clear All',
            onPressed: () => Navigator.pop(context, true),
            backgroundColor: Colors.red,
            width: 100,
            height: 36,
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      final pdfManager = context.read<PdfViewerManager>();
      final isCached = await pdfManager.isPdfCached(citation.fileId);

      if (!isCached) {
        if (!mounted) return;
        final connectivityService = context.read<ConnectivityService>();
        if (!connectivityService.isOnline) {
          if (mounted) Navigator.pop(context);
          _showError(
            'PDF not cached and device is offline. Please connect to download the file.',
          );
          return;
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }

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
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showError('Failed to open PDF: $e');
    }
  }

  Future<void> _onSaveAsNote(model.ChatMessage message) async {
    try {
      final authService = context.read<AuthService>();
      final user = authService.currentUser;
      if (user == null) {
        _showError('Please sign in to save notes');
        return;
      }

      final connectivityService = context.read<ConnectivityService>();
      if (!connectivityService.isOnline) {
        _showError('You must be online to save notes to Google Drive');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      final markdownContent = await _chatService.saveChatAsNote(
        message: message,
        userId: user.id,
      );

      if (!mounted) return;

      final driveService = context.read<DriveService>();
      final appFolderId = await driveService.getAppFolderId();

      final files = await driveService.listFiles(appFolderId);
      String? notesFolderId;

      for (final file in files) {
        if (file.isFolder && file.name == 'Notes') {
          notesFolderId = file.id;
          break;
        }
      }

      if (notesFolderId == null) {
        final notesFolder = await driveService.createFolder(
          'Notes',
          appFolderId,
        );
        notesFolderId = notesFolder.id;
      }

      final timestamp = DateTime.now();
      final fileName =
          'AI_Chat_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}.md';

      final bytes = utf8.encode(markdownContent);
      await driveService.uploadFileFromBytes(
        Uint8List.fromList(bytes),
        fileName,
        notesFolderId,
      );

      if (mounted) {
        Navigator.pop(context);
      }

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
      body: Stack(
        children: [
          // Background
          const Positioned.fill(child: AnimatedBackground()),

          Column(
            children: [
              // Custom AppBar
              _buildAppBar(isWideScreen),

              // Main Content
              Expanded(
                child: Row(
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
                                    itemCount:
                                        _messages.length + (_isLoading ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _messages.length) {
                                        return const Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: AppColors.primary,
                                                    ),
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'AI is thinking...',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
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
                            left: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
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
              ),
            ],
          ),
        ],
      ),
      drawer: !isWideScreen
          ? Drawer(
              backgroundColor: AppColors.background,
              child: ConversationListSidebar(
                conversations: _conversations,
                currentConversationId: _currentConversationId,
                onConversationSelected: (id) {
                  _loadConversation(id);
                  Navigator.pop(context);
                },
                onNewConversation: () {
                  _startNewConversation();
                  Navigator.pop(context);
                },
                onDeleteConversation: _deleteConversation,
                onRenameConversation: _renameConversation,
                isLoading: _isLoadingConversations,
              ),
            )
          : null,
    );
  }

  Widget _buildAppBar(bool isWideScreen) {
    return GlassContainer(
      height: 70,
      borderRadius: BorderRadius.zero,
      opacity: 0.1,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SafeArea(
        child: Row(
          children: [
            if (widget.preselectedFileId != null || widget.folderName != null)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            else if (isWideScreen)
              IconButton(
                icon: Icon(
                  _showConversationList ? Icons.close : Icons.menu,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _showConversationList = !_showConversationList;
                  });
                },
              )
            else
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.preselectedFileId != null &&
                    widget.preselectedFileName != null)
                  Text(
                    'Chatting with ${widget.preselectedFileName}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            if (_currentConversationId != null)
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _startNewConversation,
                tooltip: 'New Chat',
              ),
            IconButton(
              icon: Icon(
                _showSourcePanel ? Icons.close : Icons.filter_list,
                color: Colors.white,
              ),
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
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: AppColors.surface,
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
      ),
    );
  }

  void _showSourceSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          opacity: 0.9,
          color: AppColors.background,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
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
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            isFolderChat
                ? 'Chat with Folder'
                : widget.preselectedFileId != null
                ? 'Chat with PDF'
                : 'Start a conversation',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return GlassContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      opacity: 0.1,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedFileIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (widget.preselectedFileId != null &&
                        _selectedFileIds.contains(widget.preselectedFileId) &&
                        widget.preselectedFileName != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          avatar: const Icon(Icons.picture_as_pdf, size: 16),
                          label: Text(
                            widget.preselectedFileName!,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.2,
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () =>
                              _toggleSourceSelection(widget.preselectedFileId!),
                        ),
                      ),
                    if (_selectedFileIds.length > 1 ||
                        (widget.preselectedFileId == null &&
                            _selectedFileIds.isNotEmpty))
                      Chip(
                        label: Text(
                          '${_selectedFileIds.length} source${_selectedFileIds.length == 1 ? '' : 's'} selected',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.2,
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: _clearAllSources,
                      ),
                  ],
                ),
              ),
            ),

          Row(
            children: [
              Expanded(
                child: ModernTextField(
                  controller: _messageController,
                  hintText: 'Ask a question...',
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              ModernButton(
                icon: Icons.send,
                label: '',
                onPressed: _isLoading ? null : _sendMessage,
                isLoading: _isLoading,
                width: 50,
                height: 50,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
