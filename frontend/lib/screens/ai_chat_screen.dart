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
import 'pdf_viewer_screen.dart';

/// AI Chat screen with RAG and source selection
class AIChatScreen extends StatefulWidget {
  final String? preselectedFileId;
  final String? preselectedFileName;
  final List<String>? preselectedFileIds;
  final String? folderName;
  final bool isEmbedded;
  final VoidCallback? onClose;
  final VoidCallback? onToggleFullscreen;
  final bool? isFullscreen;

  const AIChatScreen({
    super.key,
    this.preselectedFileId,
    this.preselectedFileName,
    this.preselectedFileIds,
    this.folderName,
    this.isEmbedded = false,
    this.onClose,
    this.onToggleFullscreen,
    this.isFullscreen,
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
  double _conversationSidebarWidth = 280;
  bool _isResizingConversationSidebar = false;

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

      // Auto-load the most recent conversation if:
      // 1. There are conversations available
      // 2. No conversation is currently loaded
      // 3. No messages are currently displayed
      // 4. No preselected files were passed (we want to start fresh with those)
      if (conversations.isNotEmpty &&
          _currentConversationId == null &&
          _messages.isEmpty &&
          widget.preselectedFileId == null &&
          widget.preselectedFileIds == null) {
        // Load the most recent conversation (first in the list)
        await _loadConversation(conversations.first.id);
      }
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
      // Preserve context if embedded with a preselected file or folder
      _selectedFileIds.clear();
      if (widget.preselectedFileId != null) {
        _selectedFileIds.add(widget.preselectedFileId!);
      }
      if (widget.preselectedFileIds != null) {
        _selectedFileIds.addAll(widget.preselectedFileIds!);
      }
    });

    // Only load preferences if we don't have preselected files
    if (widget.preselectedFileId == null && widget.preselectedFileIds == null) {
      await _loadSourcePreferences();
    }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    // Auto-hide source panel if screen/panel is too narrow (less than 500px)
    final shouldShowSourcePanel = _showSourcePanel && screenWidth >= 500;

    final content = SafeArea(
      child: Column(
        children: [
          // Custom AppBar
          if (!widget.isEmbedded) _buildAppBar(isWideScreen),
          if (widget.isEmbedded) _buildEmbeddedHeader(),

          // Main Content
          Expanded(
            child: Row(
              children: [
                // Main chat area
                Expanded(
                  flex: _showSourcePanel && isWideScreen ? 2 : 1,
                  child: Column(
                    children: [
                      // Messages list with SelectionArea for better text selection
                      Expanded(
                        child: _messages.isEmpty
                            ? _buildEmptyState()
                            : SelectionArea(
                                child: ListView.builder(
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
                                              child: CircularProgressIndicator(
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
                      ),

                      // Input area
                      _buildInputArea(),
                    ],
                  ),
                ),

                // Source selection panel (responsive width)
                if (shouldShowSourcePanel && isWideScreen)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Use flexible width: min 250px, max 300px, or 40% of available space
                      final panelWidth = (constraints.maxWidth * 0.4).clamp(
                        250.0,
                        300.0,
                      );

                      return Container(
                        width: panelWidth,
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
                      );
                    },
                  ),

                // Conversation list sidebar (desktop only, on right side)
                if (_showConversationList && isWideScreen)
                  _buildResizableConversationSidebar(),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      body: content,
      endDrawer: !isWideScreen
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

  Widget _buildEmbeddedHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 20,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          const SizedBox(width: 8),
          Text(
            'AI Chat',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          // Sources button with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  _showSourcePanel ? Icons.folder_open : Icons.folder_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showSourcePanel = !_showSourcePanel;
                  });
                },
                tooltip: 'Select PDFs (${_selectedFileIds.length} selected)',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              if (_selectedFileIds.isNotEmpty)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_selectedFileIds.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: _startNewConversation,
            tooltip: 'New Chat',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          if (widget.onToggleFullscreen != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                widget.isFullscreen == true
                    ? Icons.fullscreen_exit
                    : Icons.fullscreen,
                size: 20,
              ),
              onPressed: widget.onToggleFullscreen,
              tooltip: widget.isFullscreen == true
                  ? 'Exit fullscreen'
                  : 'Fullscreen',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ],
          if (widget.onClose != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: widget.onClose,
              tooltip: 'Close Chat',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isWideScreen) {
    return GlassContainer(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      borderRadius: BorderRadius.zero,
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      color: Theme.of(context).cardColor,
      child: Stack(
        children: [
          // Centered Title
          Center(
            child: Column(
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.preselectedFileId != null &&
                    widget.preselectedFileName != null)
                  Text(
                    'Chatting with ${widget.preselectedFileName}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Left Actions
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.preselectedFileId != null ||
                    widget.folderName != null)
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),

          // Right Actions
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currentConversationId != null)
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: _startNewConversation,
                    tooltip: 'New Chat',
                  ),
                IconButton(
                  icon: Icon(
                    _showSourcePanel ? Icons.close : Icons.filter_list,
                    color: Theme.of(context).iconTheme.color,
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
                // Conversation history button
                if (isWideScreen)
                  IconButton(
                    icon: Icon(
                      _showConversationList ? Icons.close : Icons.history,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConversationList = !_showConversationList;
                      });
                    },
                    tooltip: 'Conversation History',
                  )
                else
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(
                        Icons.history,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                      tooltip: 'Conversation History',
                    ),
                  ),
                if (_conversations.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    color: Theme.of(context).cardColor,
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
        ],
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

  Widget _buildResizableConversationSidebar() {
    return MouseRegion(
      cursor: _isResizingConversationSidebar
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.basic,
      child: Row(
        children: [
          // Resize handle
          GestureDetector(
            onHorizontalDragStart: (_) {
              setState(() {
                _isResizingConversationSidebar = true;
              });
            },
            onHorizontalDragUpdate: (details) {
              setState(() {
                // Subtract the delta to resize from the left (since sidebar is on right)
                _conversationSidebarWidth =
                    (_conversationSidebarWidth - details.delta.dx).clamp(
                      200.0, // Min width
                      500.0, // Max width
                    );
              });
            },
            onHorizontalDragEnd: (_) {
              setState(() {
                _isResizingConversationSidebar = false;
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: Container(
                width: 8,
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    width: 2,
                    height: double.infinity,
                    color: _isResizingConversationSidebar
                        ? AppColors.primary
                        : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
          // Sidebar content
          ConversationListSidebar(
            conversations: _conversations,
            currentConversationId: _currentConversationId,
            onConversationSelected: _loadConversation,
            onNewConversation: _startNewConversation,
            onDeleteConversation: _deleteConversation,
            onRenameConversation: _renameConversation,
            isLoading: _isLoadingConversations,
            width: _conversationSidebarWidth,
          ),
        ],
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
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            isFolderChat
                ? 'Chat with Folder'
                : widget.preselectedFileId != null
                ? 'Chat with PDF'
                : 'Start a conversation',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
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
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;
    return Container(
      padding: EdgeInsets.only(
        left: widget.isEmbedded ? 12 : 16,
        right: widget.isEmbedded ? 12 : 16,
        top: widget.isEmbedded ? 12 : 16,
        bottom: isWideScreen
            ? (widget.isEmbedded ? 12 : 16)
            : 16, // Normal padding - nav bar spacing handled by parent
      ),
      margin: EdgeInsets.only(
        bottom:
            0, // Space for floating nav: 70px height + 24px bottom + 6px spacing
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
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
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          side: BorderSide.none,
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
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        side: BorderSide.none,
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
                width: widget.isEmbedded ? 45 : 50,
                height: widget.isEmbedded ? 45 : 50,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
