import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/markdown_note.dart';
import '../models/drive_file.dart';
import '../services/markdown_storage_service.dart';
import '../services/drive_service.dart';

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

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to save before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveNote();
              if (mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
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
        appBar: AppBar(
          title: Text(widget.existingNote != null ? 'Edit Note' : 'New Note'),
          elevation: 0,
          actions: [
            if (_isModified)
              IconButton(
                onPressed: _isSaving ? null : _saveNote,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                tooltip: 'Save',
              ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isPreviewMode = !_isPreviewMode;
                });
              },
              icon: Icon(_isPreviewMode ? Icons.edit : Icons.visibility),
              tooltip: _isPreviewMode ? 'Edit' : 'Preview',
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download, size: 20),
                      SizedBox(width: 8),
                      Text('Export'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'stats',
                  child: Row(
                    children: [
                      Icon(Icons.analytics, size: 20),
                      SizedBox(width: 8),
                      Text('Statistics'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: _isPreviewMode
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: _buildMarkdownToolbar(theme),
                ),
        ),
        body: Column(
          children: [
            // Title input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: 'Note title...',
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
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildToolbarButton(Icons.format_bold, 'Bold', () {
            _insertMarkdownSyntax('**{}**', placeholder: 'bold text');
          }),
          _buildToolbarButton(Icons.format_italic, 'Italic', () {
            _insertMarkdownSyntax('*{}*', placeholder: 'italic text');
          }),
          _buildToolbarButton(Icons.format_strikethrough, 'Strikethrough', () {
            _insertMarkdownSyntax('~~{}~~', placeholder: 'strikethrough');
          }),
          const VerticalDivider(),
          _buildToolbarButton(Icons.title, 'Heading', () {
            _insertMarkdownSyntax('# {}', placeholder: 'Heading');
          }),
          _buildToolbarButton(Icons.format_list_bulleted, 'List', () {
            _insertMarkdownSyntax('- {}', placeholder: 'List item');
          }),
          _buildToolbarButton(Icons.format_list_numbered, 'Numbered List', () {
            _insertMarkdownSyntax('1. {}', placeholder: 'List item');
          }),
          const VerticalDivider(),
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
    );
  }

  Widget _buildToolbarButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildEditor() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _contentController,
        focusNode: _contentFocusNode,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: 'Write your markdown here...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          color: theme.colorScheme.onSurface,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final theme = Theme.of(context);

    return Padding(
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$wordCount words • $charCount characters',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (_isModified)
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Modified',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
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

  void _exportNote() {
    if (_currentNote == null) return;

    final exportContent = _storageService.exportNoteAsMarkdown(_currentNote!);

    // For now, just show the export content in a dialog
    // In a real app, you'd use file_picker to save to device
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Note'),
        content: SingleChildScrollView(
          child: SelectableText(
            exportContent,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
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

  void _showStatistics() {
    final wordCount = _currentNote?.wordCount ?? 0;
    final charCount = _currentNote?.characterCount ?? 0;
    final readingTime = _currentNote?.readingTimeMinutes ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note Statistics'),
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
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final isDark = theme.brightness == Brightness.dark;

    return MarkdownStyleSheet(
      // Text styles with proper colors for dark mode
      p: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        height: 1.6,
      ),
      h1: theme.textTheme.headlineLarge?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h2: theme.textTheme.headlineMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h3: theme.textTheme.headlineSmall?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h4: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h5: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h6: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),

      // Code styles with proper dark mode colors
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        color: theme.colorScheme.onSurface,
        backgroundColor: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),

      // Blockquote styles
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
        height: 1.6,
      ),
      blockquoteDecoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 4),
        ),
      ),

      // List styles
      listBullet: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),

      // Link styles
      a: TextStyle(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: theme.colorScheme.primary.withValues(alpha: 0.6),
      ),

      // Table styles
      tableHead: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      tableBody: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      tableBorder: TableBorder.all(
        color: theme.colorScheme.outline.withValues(alpha: 0.3),
        width: 1,
      ),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding: const EdgeInsets.all(12),

      // Horizontal rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),

      // Strong and emphasis
      strong: TextStyle(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      em: TextStyle(
        color: theme.colorScheme.onSurface,
        fontStyle: FontStyle.italic,
      ),

      // Checkbox styles
      checkbox: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),

      // Text alignment
      textAlign: WrapAlignment.start,
    );
  }
}
