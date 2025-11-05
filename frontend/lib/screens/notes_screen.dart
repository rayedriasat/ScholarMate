import 'package:flutter/material.dart';
import '../models/drawing_note.dart';
import '../models/markdown_note.dart';
import '../services/drawing_storage_service.dart';
import '../services/markdown_storage_service.dart';
import 'enhanced_drawing_canvas_screen.dart';
import 'markdown_editor_screen.dart';

/// Notes screen for creating and managing both drawing and markdown notes
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final DrawingStorageService _drawingStorageService = DrawingStorageService();
  final MarkdownStorageService _markdownStorageService =
      MarkdownStorageService();
  List<DrawingNote> _drawingNotes = [];
  List<MarkdownNote> _markdownNotes = [];
  bool _isGridView = true;
  bool _isLoading = true;
  int _selectedTab = 0; // 0: All, 1: Markdown, 2: Drawing

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final drawingNotes = await _drawingStorageService.loadNotes();
      final markdownNotes = await _markdownStorageService.loadNotes();
      setState(() {
        _drawingNotes = drawingNotes;
        _markdownNotes = markdownNotes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading notes: $e')));
      }
    }
  }

  void _createNewNote() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create New Note',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Markdown Note'),
              subtitle: const Text('Text-based note with markdown formatting'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MarkdownEditorScreen(),
                  ),
                ).then((_) => _loadNotes());
              },
            ),
            ListTile(
              leading: const Icon(Icons.draw),
              title: const Text('Drawing Note'),
              subtitle: const Text('Canvas for drawing and handwritten notes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EnhancedDrawingCanvasScreen(),
                  ),
                ).then((_) => _loadNotes());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  int _getTotalNotesCount() {
    return _drawingNotes.length + _markdownNotes.length;
  }

  List<dynamic> _getFilteredNotes() {
    switch (_selectedTab) {
      case 1: // Markdown only
        return _markdownNotes;
      case 2: // Drawing only
        return _drawingNotes;
      default: // All notes
        final allNotes = <dynamic>[];
        allNotes.addAll(_markdownNotes);
        allNotes.addAll(_drawingNotes);
        // Sort by updated time
        allNotes.sort((a, b) {
          final aTime = a is MarkdownNote
              ? a.updatedAt
              : (a as DrawingNote).updatedAt;
          final bTime = b is MarkdownNote
              ? b.updatedAt
              : (b as DrawingNote).updatedAt;
          return bTime.compareTo(aTime);
        });
        return allNotes;
    }
  }

  Widget _buildTabChip(String label, int index, int count) {
    final theme = Theme.of(context);
    final isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.surface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: _toggleView,
            tooltip: _isGridView ? 'List view' : 'Grid view',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTabChip('All', 0, _getTotalNotesCount()),
                const SizedBox(width: 8),
                _buildTabChip('Markdown', 1, _markdownNotes.length),
                const SizedBox(width: 8),
                _buildTabChip('Drawing', 2, _drawingNotes.length),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _getFilteredNotes().isEmpty
          ? _buildEmptyState(context)
          : _buildNotesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewNote,
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    String title;
    String subtitle;
    IconData icon;

    switch (_selectedTab) {
      case 1:
        title = 'No Markdown Notes Yet';
        subtitle =
            'Create your first markdown note\nWrite, format, and organize your thoughts';
        icon = Icons.edit_note;
        break;
      case 2:
        title = 'No Drawing Notes Yet';
        subtitle =
            'Create your first drawing note\nDraw, add text, and export as PDF';
        icon = Icons.draw;
        break;
      default:
        title = 'No Notes Yet';
        subtitle =
            'Create your first note\nChoose between markdown or drawing notes';
        icon = Icons.note_add;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.1),
                  theme.colorScheme.secondary.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _createNewNote,
            icon: const Icon(Icons.add),
            label: const Text('Create Note'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    final notes = _getFilteredNotes();

    if (_isGridView) {
      return _buildGridView(notes);
    } else {
      return _buildListView(notes);
    }
  }

  Widget _buildGridView(List<dynamic> notes) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 1200
              ? 4
              : constraints.maxWidth > 800
              ? 3
              : constraints.maxWidth > 600
              ? 2
              : 1;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              if (note is MarkdownNote) {
                return _buildMarkdownNoteCard(note);
              } else {
                return _buildDrawingNoteCard(note as DrawingNote);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildListView(List<dynamic> notes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: note is MarkdownNote
              ? _buildMarkdownNoteListTile(note)
              : _buildDrawingNoteListTile(note as DrawingNote),
        );
      },
    );
  }

  Widget _buildMarkdownNoteCard(MarkdownNote note) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openMarkdownNote(note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleMarkdownNoteAction(note, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.content.isNotEmpty) ...[
                      Text(
                        note.content,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                    const Spacer(),
                    Text(
                      '${note.wordCount} words • ${note.characterCount} characters',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _formatDate(note.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawingNoteCard(DrawingNote note) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openDrawingNote(note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.draw, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleDrawingNoteAction(note, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${note.pages.length} page${note.pages.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${note.strokes.length} strokes • ${note.textNotes.length} text notes',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _formatDate(note.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkdownNoteListTile(MarkdownNote note) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: () => _openMarkdownNote(note),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.edit_note, color: theme.colorScheme.primary),
        ),
        title: Text(
          note.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (note.content.isNotEmpty) ...[
              Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              '${note.wordCount} words • ${note.characterCount} characters',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(note.updatedAt),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMarkdownNoteAction(note, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildDrawingNoteListTile(DrawingNote note) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: () => _openDrawingNote(note),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.draw, color: theme.colorScheme.primary),
        ),
        title: Text(
          note.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${note.pages.length} page${note.pages.length != 1 ? 's' : ''} • ${note.strokes.length} strokes • ${note.textNotes.length} text notes',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(note.updatedAt),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleDrawingNoteAction(note, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _openDrawingNote(DrawingNote note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedDrawingCanvasScreen(existingNote: note),
      ),
    ).then((_) => _loadNotes());
  }

  void _openMarkdownNote(MarkdownNote note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkdownEditorScreen(existingNote: note),
      ),
    ).then((_) => _loadNotes());
  }

  void _handleDrawingNoteAction(DrawingNote note, String action) {
    switch (action) {
      case 'edit':
        _openDrawingNote(note);
        break;
      case 'delete':
        _showDrawingNoteDeleteConfirmation(note);
        break;
    }
  }

  void _handleMarkdownNoteAction(MarkdownNote note, String action) {
    switch (action) {
      case 'edit':
        _openMarkdownNote(note);
        break;
      case 'delete':
        _showMarkdownNoteDeleteConfirmation(note);
        break;
    }
  }

  void _showDrawingNoteDeleteConfirmation(DrawingNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Drawing Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteDrawingNote(note);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMarkdownNoteDeleteConfirmation(MarkdownNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Markdown Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteMarkdownNote(note);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDrawingNote(DrawingNote note) async {
    try {
      await _drawingStorageService.deleteNote(note.id);
      await _loadNotes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Drawing note "${note.title}" deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting drawing note: $e')),
        );
      }
    }
  }

  Future<void> _deleteMarkdownNote(MarkdownNote note) async {
    try {
      await _markdownStorageService.deleteNote(note.id);
      await _loadNotes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Markdown note "${note.title}" deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting markdown note: $e')),
        );
      }
    }
  }
}
