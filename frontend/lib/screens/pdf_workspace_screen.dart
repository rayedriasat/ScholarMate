import 'package:flutter/material.dart';
import '../models/drive_file.dart';
import '../widgets/workspace/workspace_layout.dart';
import '../widgets/workspace/document_tab_manager.dart';
import '../widgets/workspace/workspace_explorer_panel.dart';
import '../widgets/workspace/workspace_ai_chat_panel.dart';
import '../theme/app_colors.dart';

/// VS Code-style document workspace with multi-tab support (PDF and Markdown)
class PdfWorkspaceScreen extends StatefulWidget {
  final DriveFile? initialFile;
  final String? initialFileId;
  final String? initialFileName;
  final int? initialPage;
  final String? searchQuery;
  final String? highlightText;

  const PdfWorkspaceScreen({
    super.key,
    this.initialFile,
    this.initialFileId,
    this.initialFileName,
    this.initialPage,
    this.searchQuery,
    this.highlightText,
  });

  @override
  State<PdfWorkspaceScreen> createState() => _PdfWorkspaceScreenState();
}

class _PdfWorkspaceScreenState extends State<PdfWorkspaceScreen> {
  late DocumentTabManager _tabManager;
  bool _showExplorer = true;
  bool _showAiChat = false;
  double _explorerWidth = 250;
  double _aiChatWidth = 400;

  static const double _minPanelWidth = 200;
  static const double _maxPanelWidthPercent = 0.4;

  @override
  void initState() {
    super.initState();
    _tabManager = DocumentTabManager();

    // Open initial file if provided
    if (widget.initialFile != null ||
        (widget.initialFileId != null && widget.initialFileName != null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openInitialFile();
      });
    }
  }

  @override
  void dispose() {
    _tabManager.dispose();
    super.dispose();
  }

  Future<void> _openInitialFile() async {
    final file =
        widget.initialFile ??
        DriveFile(
          id: widget.initialFileId!,
          name: widget.initialFileName!,
          mimeType: 'application/pdf',
        );

    await _tabManager.openFile(
      context,
      file,
      initialPage: widget.initialPage,
      searchQuery: widget.searchQuery,
      highlightText: widget.highlightText,
    );
  }

  void _toggleExplorer() {
    setState(() {
      _showExplorer = !_showExplorer;
    });
  }

  void _toggleAiChat() {
    setState(() {
      final screenWidth = MediaQuery.of(context).size.width;
      final isWideScreen = screenWidth >= 900;
      
      _showAiChat = !_showAiChat;
      
      // Only close explorer on small screens where space is limited
      if (_showAiChat && !isWideScreen) {
        _showExplorer = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: _tabManager,
        builder: (context, _) {
          return WorkspaceLayout(
            tabManager: _tabManager,
            showExplorer: _showExplorer,
            showAiChat: _showAiChat,
            explorerWidth: _explorerWidth,
            aiChatWidth: _aiChatWidth,
            isWideScreen: isWideScreen,
            onToggleExplorer: _toggleExplorer,
            onToggleAiChat: _toggleAiChat,
            onExplorerResize: (delta) {
              setState(() {
                final maxWidth = screenWidth * _maxPanelWidthPercent;
                _explorerWidth = (_explorerWidth + delta).clamp(
                  _minPanelWidth,
                  maxWidth,
                );
              });
            },
            onAiChatResize: (delta) {
              setState(() {
                final maxWidth = screenWidth * _maxPanelWidthPercent;
                _aiChatWidth = (_aiChatWidth - delta).clamp(
                  _minPanelWidth,
                  maxWidth,
                );
              });
            },
            explorerPanel: WorkspaceExplorerPanel(
              selectedFileId: _tabManager.activeTab?.file.id,
              selectedFile: _tabManager.activeTab?.file,
              onFileSelected: (file) async {
                await _tabManager.openFile(context, file);
                if (!isWideScreen) {
                  setState(() {
                    _showExplorer = false;
                  });
                }
              },
            ),
            aiChatPanel: WorkspaceAiChatPanel(
              currentFile: _tabManager.activeTab?.file,
              onClose: () {
                setState(() {
                  _showAiChat = false;
                });
              },
            ),
          );
        },
      ),
    );
  }
}
