import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../services/notebook_service.dart';
import '../widgets/notebook_files_tab.dart';
import '../widgets/notebook_chat_tab.dart';
import '../widgets/notebook_ai_studio_tab.dart';

/// Web-optimized 3-panel resizable layout for Notebook Studio
/// Inspired by Google NotebookLM interface
class NotebookFolderWebScreen extends StatefulWidget {
  final NotebookFolder folder;

  const NotebookFolderWebScreen({super.key, required this.folder});

  @override
  State<NotebookFolderWebScreen> createState() =>
      _NotebookFolderWebScreenState();
}

class _NotebookFolderWebScreenState extends State<NotebookFolderWebScreen> {
  // Panel widths (as percentages of available width)
  double _leftPanelWidth = 0.25; // 25% for files
  double _rightPanelWidth = 0.30; // 30% for AI Studio

  // Panel visibility
  bool _leftPanelVisible = true;
  bool _rightPanelVisible = true;

  // Minimum panel widths in pixels
  static const double _minPanelWidth = 200;
  static const double _dividerWidth = 8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;

                // Calculate actual panel widths with visibility
                double leftWidth = _leftPanelVisible
                    ? (totalWidth * _leftPanelWidth).clamp(
                        _minPanelWidth,
                        totalWidth * 0.4,
                      )
                    : 0;
                double rightWidth = _rightPanelVisible
                    ? (totalWidth * _rightPanelWidth).clamp(
                        _minPanelWidth,
                        totalWidth * 0.4,
                      )
                    : 0;

                // Calculate divider widths
                final leftDividerWidth = _leftPanelVisible ? _dividerWidth : 0;
                final rightDividerWidth = _rightPanelVisible
                    ? _dividerWidth
                    : 0;

                // Middle panel gets remaining space
                final middleWidth =
                    totalWidth -
                    leftWidth -
                    rightWidth -
                    leftDividerWidth -
                    rightDividerWidth;

                return Row(
                  children: [
                    // Left Panel - Files
                    if (_leftPanelVisible) ...[
                      _buildPanel(width: leftWidth, child: _buildFilesPanel()),
                      _buildDivider(
                        onDrag: (delta) {
                          setState(() {
                            final newLeftWidth = leftWidth + delta;
                            _leftPanelWidth = (newLeftWidth / totalWidth).clamp(
                              0.15,
                              0.5,
                            );
                          });
                        },
                      ),
                    ],

                    // Middle Panel - Chat
                    _buildPanel(width: middleWidth, child: _buildChatPanel()),

                    // Right Panel - AI Studio
                    if (_rightPanelVisible) ...[
                      _buildDivider(
                        onDrag: (delta) {
                          setState(() {
                            final newRightWidth = rightWidth - delta;
                            _rightPanelWidth = (newRightWidth / totalWidth)
                                .clamp(0.15, 0.5);
                          });
                        },
                      ),
                      _buildPanel(
                        width: rightWidth,
                        child: _buildAiStudioPanel(),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back to workspaces',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.folder.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.folder.description != null)
                  Text(
                    widget.folder.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editFolder,
            tooltip: 'Edit workspace',
          ),
          const SizedBox(width: 8),
          // Panel visibility toggles
          IconButton(
            icon: Icon(
              _leftPanelVisible
                  ? Icons.view_sidebar
                  : Icons.view_sidebar_outlined,
            ),
            onPressed: () {
              setState(() {
                _leftPanelVisible = !_leftPanelVisible;
              });
            },
            tooltip: _leftPanelVisible ? 'Hide files' : 'Show files',
          ),
          IconButton(
            icon: Icon(
              _rightPanelVisible
                  ? Icons.view_sidebar
                  : Icons.view_sidebar_outlined,
            ),
            onPressed: () {
              setState(() {
                _rightPanelVisible = !_rightPanelVisible;
              });
            },
            tooltip: _rightPanelVisible ? 'Hide AI Studio' : 'Show AI Studio',
          ),
        ],
      ),
    );
  }

  Widget _buildPanel({required double width, required Widget child}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: child,
    );
  }

  Widget _buildDivider({required Function(double) onDrag}) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          onDrag(details.delta.dx);
        },
        child: Container(
          width: _dividerWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            border: Border(
              left: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                width: 1,
              ),
              right: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilesPanel() {
    return Column(
      children: [
        _buildPanelHeader(
          icon: Icons.folder_outlined,
          title: 'Files',
          subtitle: '${widget.folder.fileCount} items',
        ),
        Expanded(child: NotebookFilesTab(folderId: widget.folder.id)),
      ],
    );
  }

  Widget _buildChatPanel() {
    return Column(
      children: [
        _buildPanelHeader(
          icon: Icons.chat_bubble_outline,
          title: 'AI Chat',
          subtitle: 'Ask questions about your files',
        ),
        Expanded(child: NotebookChatTab(folderId: widget.folder.id)),
      ],
    );
  }

  Widget _buildAiStudioPanel() {
    return Column(
      children: [
        _buildPanelHeader(
          icon: Icons.auto_awesome_outlined,
          title: 'AI Studio',
          subtitle: 'Generate content',
        ),
        Expanded(child: NotebookAiStudioTab(folderId: widget.folder.id)),
      ],
    );
  }

  Widget _buildPanelHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editFolder() async {
    final nameController = TextEditingController(text: widget.folder.name);
    final descController = TextEditingController(
      text: widget.folder.description,
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Workspace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Workspace Name'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty && mounted) {
      try {
        final service = context.read<NotebookService>();
        await service.updateFolder(
          folderId: widget.folder.id,
          name: nameController.text,
          description: descController.text.isEmpty ? null : descController.text,
        );
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating workspace: $e')),
          );
        }
      }
    }
  }
}
