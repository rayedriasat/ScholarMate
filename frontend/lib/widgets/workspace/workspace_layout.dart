import 'package:flutter/material.dart';
import 'pdf_tab_manager.dart';
import 'workspace_tab_bar.dart';
import 'workspace_pdf_editor.dart';
import 'workspace_resize_handle.dart';
import '../../theme/app_colors.dart';

/// Main workspace layout with three-panel design
class WorkspaceLayout extends StatelessWidget {
  final PdfTabManager tabManager;
  final bool showExplorer;
  final bool showAiChat;
  final double explorerWidth;
  final double aiChatWidth;
  final bool isWideScreen;
  final VoidCallback onToggleExplorer;
  final VoidCallback onToggleAiChat;
  final ValueChanged<double> onExplorerResize;
  final ValueChanged<double> onAiChatResize;
  final Widget explorerPanel;
  final Widget aiChatPanel;

  const WorkspaceLayout({
    super.key,
    required this.tabManager,
    required this.showExplorer,
    required this.showAiChat,
    required this.explorerWidth,
    required this.aiChatWidth,
    required this.isWideScreen,
    required this.onToggleExplorer,
    required this.onToggleAiChat,
    required this.onExplorerResize,
    required this.onAiChatResize,
    required this.explorerPanel,
    required this.aiChatPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top toolbar
        _buildTopToolbar(context),
        // Main content area
        Expanded(
          child: Row(
            children: [
              // Left explorer panel
              if (isWideScreen && showExplorer) ...[
                SizedBox(width: explorerWidth, child: explorerPanel),
                WorkspaceResizeHandle(
                  onDrag: onExplorerResize,
                  isVertical: true,
                ),
              ],
              // Center PDF editor area
              Expanded(child: _buildCenterArea(context)),
              // Right AI chat panel
              if (isWideScreen && showAiChat) ...[
                WorkspaceResizeHandle(onDrag: onAiChatResize, isVertical: true),
                SizedBox(width: aiChatWidth, child: aiChatPanel),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopToolbar(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back to Library',
          ),
          const SizedBox(width: 8),
          // Explorer toggle
          IconButton(
            icon: Icon(
              showExplorer ? Icons.menu_open : Icons.menu,
              color: Colors.white,
            ),
            onPressed: onToggleExplorer,
            tooltip: 'Toggle Explorer',
          ),
          const SizedBox(width: 8),
          // Title
          Expanded(
            child: Text(
              'PDF Workspace',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // AI Chat toggle
          IconButton(
            icon: Icon(
              showAiChat ? Icons.chat : Icons.chat_bubble_outline,
              color: Colors.white,
            ),
            onPressed: onToggleAiChat,
            tooltip: 'Toggle AI Chat',
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCenterArea(BuildContext context) {
    return Stack(
      children: [
        // Main PDF editor
        Column(
          children: [
            // Tab bar
            WorkspaceTabBar(tabManager: tabManager),
            // PDF viewer
            Expanded(child: WorkspacePdfEditor(tabManager: tabManager)),
          ],
        ),
        // Slide-in panels for mobile
        if (!isWideScreen) ...[
          if (showExplorer)
            _buildSlideInPanel(
              context,
              child: explorerPanel,
              onClose: onToggleExplorer,
              alignment: Alignment.centerLeft,
            ),
          if (showAiChat)
            _buildSlideInPanel(
              context,
              child: aiChatPanel,
              onClose: onToggleAiChat,
              alignment: Alignment.centerRight,
            ),
        ],
      ],
    );
  }

  Widget _buildSlideInPanel(
    BuildContext context, {
    required Widget child,
    required VoidCallback onClose,
    required Alignment alignment,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = (screenWidth * 0.85).clamp(300.0, 400.0);

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: alignment,
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping panel
            child: Container(
              width: panelWidth,
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
