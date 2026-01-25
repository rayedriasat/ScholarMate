import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../models/drive_file.dart';
import '../../services/drive_service.dart';
import '../../theme/app_colors.dart';
import 'dart:convert';
import 'dart:typed_data';

/// Markdown viewer and editor for workspace
class WorkspaceMarkdownEditor extends StatefulWidget {
  final DriveFile file;
  final VoidCallback? onClose;

  const WorkspaceMarkdownEditor({
    super.key,
    required this.file,
    this.onClose,
  });

  @override
  State<WorkspaceMarkdownEditor> createState() =>
      _WorkspaceMarkdownEditorState();
}

class _WorkspaceMarkdownEditorState extends State<WorkspaceMarkdownEditor> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _error;
  String _originalContent = '';
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _loadContent();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasChanges = _controller.text != _originalContent;
    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final driveService = context.read<DriveService>();
      final content = await driveService.downloadFile(widget.file.id);

      if (mounted && content != null) {
        final text = utf8.decode(content);
        setState(() {
          _originalContent = text;
          _controller.text = text;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _error = 'Failed to load file content';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveContent() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final driveService = context.read<DriveService>();
      final content = Uint8List.fromList(utf8.encode(_controller.text));

      await driveService.updateFile(
        widget.file.id,
        content,
        widget.file.name,
      );

      if (mounted) {
        setState(() {
          _originalContent = _controller.text;
          _isSaving = false;
          _isEditing = false;
          _hasUnsavedChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset content if canceling edit
        _controller.text = _originalContent;
        _hasUnsavedChanges = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _buildToolbar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description,
            size: 20,
            color: Colors.blue.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.file.name,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else if (_isEditing) ...[
            if (_isSaving)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: Colors.white.withValues(alpha: 0.7),
                onPressed: _toggleEditMode,
                tooltip: 'Cancel',
              ),
              IconButton(
                icon: const Icon(Icons.save, size: 20),
                color: _hasUnsavedChanges
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.3),
                onPressed: _hasUnsavedChanges ? _saveContent : null,
                tooltip: 'Save',
              ),
            ],
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: Colors.white.withValues(alpha: 0.7),
              onPressed: _toggleEditMode,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              color: Colors.white.withValues(alpha: 0.7),
              onPressed: _loadContent,
              tooltip: 'Refresh',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
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
                color: Colors.red.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading file',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadContent,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isEditing) {
      return _buildEditor();
    } else {
      return _buildViewer();
    }
  }

  Widget _buildEditor() {
    return Container(
      color: AppColors.background,
      child: TextField(
        controller: _controller,
        maxLines: null,
        expands: true,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 14,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          hintText: 'Start typing markdown...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildViewer() {
    return Container(
      color: AppColors.background,
      child: Markdown(
        data: _controller.text,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            height: 1.6,
          ),
          h1: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          h2: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          h3: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          h4: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          h5: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          h6: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          code: TextStyle(
            color: Colors.greenAccent.withValues(alpha: 0.9),
            fontSize: 13,
            fontFamily: 'monospace',
            backgroundColor: Colors.black.withValues(alpha: 0.3),
          ),
          codeblockDecoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          blockquote: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          blockquoteDecoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
            border: Border(
              left: BorderSide(
                color: AppColors.primary,
                width: 4,
              ),
            ),
          ),
          listBullet: TextStyle(
            color: AppColors.primary,
            fontSize: 14,
          ),
          tableHead: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tableBody: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
          ),
          tableBorder: TableBorder.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
          a: const TextStyle(
            color: AppColors.primary,
            decoration: TextDecoration.underline,
          ),
        ),
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}
