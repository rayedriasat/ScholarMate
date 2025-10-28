import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:universal_html/html.dart' as html;
import '../services/drive_service.dart';
import '../services/cache_service.dart';

class MarkdownEditorScreen extends StatefulWidget {
  final String? initialContent;
  final String? fileName;
  final String? parentFolderId;
  final String? fileId; // For editing existing files

  const MarkdownEditorScreen({
    super.key,
    this.initialContent,
    this.fileName,
    this.parentFolderId,
    this.fileId,
  });

  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen> {
  late TextEditingController _controller;
  bool _isPreviewMode = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent ?? '');
    _controller.addListener(() {
      if (!_hasUnsavedChanges) {
        setState(() {
          _hasUnsavedChanges = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveMarkdown() async {
    if (_controller.text.isEmpty) {
      _showError('Cannot save empty document');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final fileName =
          widget.fileName ??
          'Document_${DateTime.now().millisecondsSinceEpoch}.md';

      if (kIsWeb) {
        // On web, download the file instead of uploading to Drive
        final bytes = utf8.encode(_controller.text);
        final blob = html.Blob([bytes], 'text/markdown');
        final url = html.Url.createObjectUrlFromBlob(blob);
        // ignore: unused_local_variable
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        setState(() {
          _hasUnsavedChanges = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // On mobile/desktop, upload to Drive
        final driveService = context.read<DriveService>();
        final cacheService = context.read<CacheService>();

        // Create temporary file
        final tempDir = await getTemporaryDirectory();
        final filePath = path.join(tempDir.path, fileName);
        final file = File(filePath);
        await file.writeAsString(_controller.text);

        // Upload to Drive
        final driveFile = await driveService.uploadFile(
          file,
          widget.parentFolderId ?? '',
          customName: fileName,
        );

        // Cache metadata
        await cacheService.cacheFileMetadata(driveFile);

        setState(() {
          _hasUnsavedChanges = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, driveFile);
        }
      }
    } catch (e) {
      _showError('Failed to save: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.fileName ?? 'Markdown Editor'),
          actions: [
            IconButton(
              icon: Icon(_isPreviewMode ? Icons.edit : Icons.visibility),
              onPressed: () {
                setState(() {
                  _isPreviewMode = !_isPreviewMode;
                });
              },
              tooltip: _isPreviewMode ? 'Edit' : 'Preview',
            ),
            if (_hasUnsavedChanges)
              IconButton(
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                onPressed: _isSaving ? null : _saveMarkdown,
                tooltip: 'Save',
              ),
          ],
        ),
        body: _isPreviewMode ? _buildPreview() : _buildEditor(),
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        // Formatting toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildToolbarButton(
                  Icons.format_bold,
                  'Bold',
                  () => _insertMarkdown('**', '**'),
                ),
                _buildToolbarButton(
                  Icons.format_italic,
                  'Italic',
                  () => _insertMarkdown('*', '*'),
                ),
                _buildToolbarButton(
                  Icons.format_strikethrough,
                  'Strikethrough',
                  () => _insertMarkdown('~~', '~~'),
                ),
                const VerticalDivider(),
                _buildToolbarButton(
                  Icons.title,
                  'H1',
                  () => _insertMarkdown('# ', ''),
                ),
                _buildToolbarButton(
                  Icons.title,
                  'H2',
                  () => _insertMarkdown('## ', ''),
                ),
                _buildToolbarButton(
                  Icons.title,
                  'H3',
                  () => _insertMarkdown('### ', ''),
                ),
                const VerticalDivider(),
                _buildToolbarButton(
                  Icons.format_list_bulleted,
                  'List',
                  () => _insertMarkdown('- ', ''),
                ),
                _buildToolbarButton(
                  Icons.format_list_numbered,
                  'Numbered',
                  () => _insertMarkdown('1. ', ''),
                ),
                _buildToolbarButton(
                  Icons.format_quote,
                  'Quote',
                  () => _insertMarkdown('> ', ''),
                ),
                const VerticalDivider(),
                _buildToolbarButton(
                  Icons.link,
                  'Link',
                  () => _insertMarkdown('[', '](url)'),
                ),
                _buildToolbarButton(
                  Icons.code,
                  'Code',
                  () => _insertMarkdown('`', '`'),
                ),
                _buildToolbarButton(
                  Icons.code_off,
                  'Code Block',
                  () => _insertMarkdown('```\n', '\n```'),
                ),
              ],
            ),
          ),
        ),
        // Editor
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Start writing in Markdown...',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Markdown(
        data: _controller.text.isEmpty
            ? '*No content to preview*'
            : _controller.text,
        selectable: true,
      ),
    );
  }

  Widget _buildToolbarButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  void _insertMarkdown(String before, String after) {
    final text = _controller.text;
    final selection = _controller.selection;

    if (selection.start == -1) {
      // No selection, insert at end
      _controller.text = text + before + after;
      _controller.selection = TextSelection.collapsed(
        offset: text.length + before.length,
      );
    } else {
      // Insert around selection
      final selectedText = text.substring(selection.start, selection.end);
      final newText =
          text.substring(0, selection.start) +
          before +
          selectedText +
          after +
          text.substring(selection.end);

      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: selection.start + before.length + selectedText.length,
      );
    }
  }
}
