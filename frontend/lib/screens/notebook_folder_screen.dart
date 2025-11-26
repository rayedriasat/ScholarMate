import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../services/notebook_service.dart';
import 'dart:convert';
import '../widgets/notebook_files_tab.dart';
import '../widgets/notebook_chat_tab.dart';
import '../widgets/notebook_ai_studio_tab.dart';
import 'notebook_folder_web_screen.dart';
import 'flashcard_view_screen.dart';

/// Detail screen for a single notebook folder
class NotebookFolderScreen extends StatefulWidget {
  final NotebookFolder folder;

  const NotebookFolderScreen({super.key, required this.folder});

  @override
  State<NotebookFolderScreen> createState() => _NotebookFolderScreenState();
}

class _NotebookFolderScreenState extends State<NotebookFolderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Widget? _customChatContent;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleViewContent(String content, String title, String toolType) {
    if (toolType == 'flashcard') {
      try {
        final flashcards = (jsonDecode(content) as List)
            .cast<Map<String, dynamic>>();
        setState(() {
          _customChatContent = FlashcardView(
            flashcards: flashcards,
            onClose: () {
              setState(() {
                _customChatContent = null;
              });
            },
          );
          _tabController.animateTo(1); // Switch to Chat tab
        });
      } catch (e) {
        debugPrint('Error parsing flashcards: $e');
      }
    }
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

    if (result == true && nameController.text.isNotEmpty) {
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

  @override
  Widget build(BuildContext context) {
    // Use web-optimized 3-panel layout on web
    if (kIsWeb) {
      return NotebookFolderWebScreen(folder: widget.folder);
    }

    // Use tab-based layout on mobile
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.folder.name),
            if (widget.folder.description != null)
              Text(
                widget.folder.description!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editFolder,
            tooltip: 'Edit workspace',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.folder), text: 'Files'),
            Tab(icon: Icon(Icons.chat), text: 'Chat'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'AI Studio'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NotebookFilesTab(folderId: widget.folder.id),
          _customChatContent ?? NotebookChatTab(folderId: widget.folder.id),
          NotebookAiStudioTab(
            folderId: widget.folder.id,
            onViewContent: _handleViewContent,
          ),
        ],
      ),
    );
  }
}
