import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/drive_file.dart';
import '../services/drive_service.dart';
import '../models/markdown_note.dart';
import 'markdown_editor_screen.dart';

/// Screen for viewing markdown files from Google Drive
class MarkdownViewerScreen extends StatefulWidget {
  final DriveFile file;

  const MarkdownViewerScreen({super.key, required this.file});

  @override
  State<MarkdownViewerScreen> createState() => _MarkdownViewerScreenState();
}

class _MarkdownViewerScreenState extends State<MarkdownViewerScreen> {
  String? _content;
  bool _isLoading = true;
  String? _error;
  bool _isPreviewMode = true;

  @override
  void initState() {
    super.initState();
    _loadMarkdownContent();
  }

  Future<void> _loadMarkdownContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final driveService = context.read<DriveService>();

      // Download the file content
      final content = await driveService.downloadFileAsString(widget.file.id);

      setState(() {
        _content = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load markdown file: $e';
        _isLoading = false;
      });
    }
  }

  void _editMarkdown() {
    if (_content == null) return;

    // Create a MarkdownNote from the file content
    final note = MarkdownNote.create(
      title: widget.file.name.replaceAll('.md', '').replaceAll('.markdown', ''),
      content: _content!,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkdownEditorScreen(
          existingNote: note,
          driveFile: widget.file, // Pass the drive file for saving back
        ),
      ),
    ).then((_) {
      // Reload content when returning from editor
      _loadMarkdownContent();
    });
  }

  void _toggleView() {
    setState(() {
      _isPreviewMode = !_isPreviewMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name, overflow: TextOverflow.ellipsis),
        elevation: 0,
        actions: [
          if (!_isLoading && _content != null) ...[
            IconButton(
              onPressed: _toggleView,
              icon: Icon(_isPreviewMode ? Icons.edit : Icons.visibility),
              tooltip: _isPreviewMode ? 'Edit' : 'Preview',
            ),
            IconButton(
              onPressed: _editMarkdown,
              icon: const Icon(Icons.edit_note),
              tooltip: 'Edit in Editor',
            ),
          ],
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Text('File Info'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading markdown file...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading File',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadMarkdownContent,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_content == null || _content!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Empty File',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This markdown file appears to be empty.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _editMarkdown,
              icon: const Icon(Icons.edit),
              label: const Text('Edit File'),
            ),
          ],
        ),
      );
    }

    return _isPreviewMode ? _buildPreview() : _buildRawView();
  }

  Widget _buildPreview() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Markdown(
        data: _content!,
        selectable: true,
        styleSheet: _buildMarkdownStyleSheet(theme),
        onTapLink: (text, href, title) {
          // Handle link taps if needed
          if (href != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Link: $href'),
                action: SnackBarAction(
                  label: 'Copy',
                  onPressed: () {
                    // TODO: Copy to clipboard
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildRawView() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: SelectableText(
          _content!,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _loadMarkdownContent();
        break;
      case 'info':
        _showFileInfo();
        break;
    }
  }

  void _showFileInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', widget.file.name),
            _buildInfoRow('Size', _formatFileSize(widget.file.size)),
            _buildInfoRow('Modified', _formatDate(widget.file.modifiedTime)),
            _buildInfoRow('Created', _formatDate(widget.file.createdTime)),
            if (_content != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow('Characters', _content!.length.toString()),
              _buildInfoRow('Lines', _content!.split('\n').length.toString()),
              _buildInfoRow('Words', _getWordCount(_content!).toString()),
            ],
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown';

    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';

    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  int _getWordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }
}
