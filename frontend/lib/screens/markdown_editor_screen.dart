import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/markdown_note.dart';
import '../models/drive_file.dart';
import '../services/markdown_storage_service.dart';
import '../services/drive_service.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../theme/app_colors.dart';

/// Markdown editor screen with live preview
class MarkdownEditorScreen extends StatefulWidget {
  final MarkdownNote? existingNote;
  final DriveFile? driveFile; // For editing files from Google Drive

  const MarkdownEditorScreen({super.key, this.existingNote, this.driveFile});

  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen>
    with TickerProviderStateMixin {
  final MarkdownStorageService _storageService = MarkdownStorageService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();

  late TabController _tabController;
  MarkdownNote? _currentNote;
  bool _isModified = false;
  bool _isSaving = false;
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeNote();

    // Listen for changes
    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _initializeNote() {
    if (widget.existingNote != null) {
      _currentNote = widget.existingNote;
      _titleController.text = _currentNote!.title;
      _contentController.text = _currentNote!.content;
    } else {
      _currentNote = MarkdownNote.create(title: 'Untitled Note');
      _titleController.text = _currentNote!.title;
      // Focus on title for new notes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocusNode.requestFocus();
      });
    }
  }

  void _onContentChanged() {
    if (!_isModified) {
      setState(() {
        _isModified = true;
      });
    }
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final title = _titleController.text.trim();
      final content = _contentController.text;

      if (title.isEmpty) {
        _showSnackBar('Please enter a title', isError: true);
        return;
      }

      if (widget.driveFile != null) {
        // Save to Google Drive
        await _saveToDrive(title, content);
      } else {
        // Save as local note
        _currentNote = _currentNote!.copyWith(title: title, content: content);
        await _storageService.saveNote(_currentNote!);
      }

      setState(() {
        _isModified = false;
      });

      _showSnackBar('Note saved successfully');
    } catch (e) {
      _showSnackBar('Failed to save note: $e', isError: true);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _saveToDrive(String title, String content) async {
    final driveService = context.read<DriveService>();

    // Update the file content on Google Drive
    await driveService.updateFileContent(
      widget.driveFile!.id,
      content,
      // Update filename if title changed
      newName: title.endsWith('.md') ? title : '$title.md',
    );
  }

  Future<bool> _onWillPop() async {
    if (!_isModified) return true;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Unsaved Changes',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You have unsaved changes. What would you like to do?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancel'),
          ),
          ModernButton(
            onPressed: () => Navigator.of(context).pop('save'),
            label: 'Save',
            backgroundColor: AppColors.primary,
            width: 80,
            height: 36,
          ),
        ],
      ),
    );

    if (result == 'discard') {
      // User wants to discard changes and leave
      return true;
    } else if (result == 'save') {
      // User wants to save before leaving
      await _saveNote();
      return true;
    } else {
      // User cancelled or dismissed dialog - stay on page
      return false;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _insertMarkdownSyntax(String syntax, {String? placeholder}) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    String newText;
    int newCursorPos;

    if (selection.isValid && !selection.isCollapsed) {
      // Text is selected
      final selectedText = text.substring(selection.start, selection.end);
      final replacement = syntax.replaceAll('{}', selectedText);
      newText = text.replaceRange(selection.start, selection.end, replacement);
      newCursorPos = selection.start + replacement.length;
    } else {
      // No selection
      final insertText = syntax.replaceAll('{}', placeholder ?? '');
      final insertPos = selection.baseOffset >= 0
          ? selection.baseOffset
          : text.length;
      newText =
          text.substring(0, insertPos) + insertText + text.substring(insertPos);

      if (placeholder != null) {
        // Position cursor to select placeholder
        final placeholderStart = insertPos + syntax.indexOf('{}');
        newCursorPos = placeholderStart;
        _contentController.text = newText;
        _contentController.selection = TextSelection(
          baseOffset: placeholderStart,
          extentOffset: placeholderStart + placeholder.length,
        );
        return;
      } else {
        newCursorPos = insertPos + insertText.length;
      }
    }

    _contentController.text = newText;
    _contentController.selection = TextSelection.collapsed(
      offset: newCursorPos,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            widget.existingNote != null ? 'Edit Note' : 'New Note',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (_isModified)
              IconButton(
                onPressed: _isSaving ? null : _saveNote,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.save, color: AppColors.primary),
                tooltip: 'Save',
              ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isPreviewMode = !_isPreviewMode;
                });
              },
              icon: Icon(
                _isPreviewMode ? Icons.edit : Icons.visibility,
                color: Colors.white,
              ),
              tooltip: _isPreviewMode ? 'Edit' : 'Preview',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: AppColors.surface,
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Export', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'stats',
                  child: Row(
                    children: [
                      Icon(Icons.analytics, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Statistics', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: _isPreviewMode
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: _buildMarkdownToolbar(theme),
                ),
        ),
        body: Column(
          children: [
            // Title input
            GlassContainer(
              borderRadius: BorderRadius.zero,
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  hintText: 'Note title...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _contentFocusNode.requestFocus(),
              ),
            ),

            // Content area
            Expanded(child: _isPreviewMode ? _buildPreview() : _buildEditor()),
          ],
        ),
        bottomNavigationBar: _buildBottomInfo(theme),
      ),
    );
  }

  Widget _buildMarkdownToolbar(ThemeData theme) {
    return GlassContainer(
      borderRadius: BorderRadius.zero,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: Border(
        top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildToolbarButton(Icons.format_bold, 'Bold', () {
              _insertMarkdownSyntax('**{}**', placeholder: 'bold text');
            }),
            _buildToolbarButton(Icons.format_italic, 'Italic', () {
              _insertMarkdownSyntax('*{}*', placeholder: 'italic text');
            }),
            _buildToolbarButton(
              Icons.format_strikethrough,
              'Strikethrough',
              () {
                _insertMarkdownSyntax('~~{}~~', placeholder: 'strikethrough');
              },
            ),
            Container(
              height: 24,
              width: 1,
              color: Colors.white24,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            _buildToolbarButton(Icons.title, 'Heading', () {
              _insertMarkdownSyntax('# {}', placeholder: 'Heading');
            }),
            _buildToolbarButton(Icons.format_list_bulleted, 'List', () {
              _insertMarkdownSyntax('- {}', placeholder: 'List item');
            }),
            _buildToolbarButton(
              Icons.format_list_numbered,
              'Numbered List',
              () {
                _insertMarkdownSyntax('1. {}', placeholder: 'List item');
              },
            ),
            Container(
              height: 24,
              width: 1,
              color: Colors.white24,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            _buildToolbarButton(Icons.link, 'Link', () {
              _insertMarkdownSyntax('[{}](url)', placeholder: 'link text');
            }),
            _buildToolbarButton(Icons.code, 'Code', () {
              _insertMarkdownSyntax('`{}`', placeholder: 'code');
            }),
            _buildToolbarButton(Icons.format_quote, 'Quote', () {
              _insertMarkdownSyntax('> {}', placeholder: 'quote');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: Colors.white),
        tooltip: tooltip,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        style: IconButton.styleFrom(
          hoverColor: Colors.white.withValues(alpha: 0.1),
          highlightColor: Colors.white.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _contentController,
        focusNode: _contentFocusNode,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          hintText: 'Write your markdown here...',
          hintStyle: TextStyle(color: Colors.white38),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          color: Colors.white,
          height: 1.5,
        ),
        cursorColor: AppColors.primary,
      ),
    );
  }

  Widget _buildPreview() {
    final theme = Theme.of(context);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(16),
      child: Markdown(
        data: _contentController.text.isEmpty
            ? '*No content to preview*'
            : _contentController.text,
        selectable: true,
        styleSheet: _buildMarkdownStyleSheet(theme),
      ),
    );
  }

  Widget _buildBottomInfo(ThemeData theme) {
    final wordCount = _contentController.text.trim().isEmpty
        ? 0
        : _contentController.text.trim().split(RegExp(r'\s+')).length;
    final charCount = _contentController.text.length;

    return GlassContainer(
      borderRadius: BorderRadius.zero,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      border: Border(
        top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Text(
            '$wordCount words • $charCount characters',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const Spacer(),
          if (_isModified)
            Row(
              children: [
                const Icon(Icons.circle, size: 8, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Modified',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportNote();
        break;
      case 'stats':
        _showStatistics();
        break;
    }
  }

  Future<void> _exportNote() async {
    if (_currentNote == null) return;

    // Save current changes first
    if (_isModified) {
      await _saveNote();
    }

    final exportContent = _storageService.exportNoteAsMarkdown(_currentNote!);

    // Show export dialog with options
    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Export Note to Drive',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export "${_currentNote!.title}" as a markdown file to your Google Drive?',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'The file will be saved in your Drive files section.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ModernButton(
            onPressed: () => Navigator.of(context).pop('export'),
            label: 'Export to Drive',
            icon: Icons.cloud_upload,
            width: 160,
            height: 36,
          ),
        ],
      ),
    );

    if (result == 'export') {
      await _exportToDrive(exportContent);
    }
  }

  Future<void> _exportToDrive(String content) async {
    try {
      setState(() {
        _isSaving = true;
      });

      final driveService = context.read<DriveService>();

      // Get or create the Notes folder (same location as drawing notes)
      final notesFolderId = await _getNotesFolderId(driveService);

      // Create filename with .md extension
      final fileName = _currentNote!.title.endsWith('.md')
          ? _currentNote!.title
          : '${_currentNote!.title}.md';

      // Convert content to bytes
      final contentBytes = utf8.encode(content);

      // Upload to Drive Notes folder
      final driveFile = await driveService.uploadFileFromBytes(
        Uint8List.fromList(contentBytes),
        fileName,
        notesFolderId,
      );

      if (!mounted) return;

      _showSnackBar('Note exported to Drive/Notes: ${driveFile.name}');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to export note: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Get or create the Notes folder in Google Drive (same as drawing notes)
  Future<String> _getNotesFolderId(DriveService driveService) async {
    try {
      final appFolderId = await driveService.getAppFolderId();
      final files = await driveService.listFiles(appFolderId);

      // Look for existing Notes folder
      final notesFolder = files.firstWhere(
        (file) => file.isFolder && file.name == 'Notes',
        orElse: () => DriveFile(
          id: '',
          name: '',
          parentId: '',
          size: 0,
          createdTime: DateTime.now(),
          modifiedTime: DateTime.now(),
        ),
      );

      if (notesFolder.id.isNotEmpty) {
        return notesFolder.id;
      } else {
        // Create Notes folder
        final newFolder = await driveService.createFolder('Notes', appFolderId);
        return newFolder.id;
      }
    } catch (e) {
      debugPrint('Error getting notes folder: $e');
      rethrow;
    }
  }

  void _showStatistics() {
    final wordCount = _currentNote?.wordCount ?? 0;
    final charCount = _currentNote?.characterCount ?? 0;
    final readingTime = _currentNote?.readingTimeMinutes ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Note Statistics',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Words', wordCount.toString()),
            _buildStatRow('Characters', charCount.toString()),
            _buildStatRow('Reading time', '$readingTime min'),
            _buildStatRow('Created', _formatDate(_currentNote?.createdAt)),
            _buildStatRow('Updated', _formatDate(_currentNote?.updatedAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Build a custom markdown style sheet that properly handles dark mode
  MarkdownStyleSheet _buildMarkdownStyleSheet(ThemeData theme) {
    return MarkdownStyleSheet(
      // Text styles with proper colors for dark mode
      p: theme.textTheme.bodyMedium?.copyWith(color: Colors.white, height: 1.6),
      h1: theme.textTheme.headlineLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h2: theme.textTheme.headlineMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h3: theme.textTheme.headlineSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h4: theme.textTheme.titleLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h5: theme.textTheme.titleMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h6: theme.textTheme.titleSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),

      // Code styles with proper dark mode colors
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        color: AppColors.primary,
        backgroundColor: Colors.white.withValues(alpha: 0.1),
      ),
      codeblockDecoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),

      // Blockquote styles
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        color: Colors.white70,
        fontStyle: FontStyle.italic,
        height: 1.6,
      ),
      blockquoteDecoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
      ),

      // List styles
      listBullet: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),

      // Link styles
      a: TextStyle(
        color: AppColors.primary,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.primary.withValues(alpha: 0.6),
      ),

      // Table styles
      tableHead: theme.textTheme.bodyMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      tableBody: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
      tableBorder: TableBorder.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1,
      ),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding: const EdgeInsets.all(12),

      // Horizontal rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
      ),

      // Strong and emphasis
      strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      em: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),

      // Checkbox styles
      checkbox: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),

      // Text alignment
      textAlign: WrapAlignment.start,
    );
  }
}
