import 'package:flutter/material.dart';

/// Notes screen for creating and managing markdown notes
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<Note> _notes = [];
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadSampleNotes();
  }

  void _loadSampleNotes() {
    // Sample notes for demonstration
    _notes.addAll([
      Note(
        id: '1',
        title: 'Research Ideas',
        content:
            '# Research Ideas\n\n- Explore AI applications in education\n- Study user behavior patterns\n- Analyze data visualization techniques',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Note(
        id: '2',
        title: 'Meeting Notes',
        content:
            '# Team Meeting - Project Review\n\n## Agenda\n1. Progress update\n2. Challenges discussion\n3. Next steps\n\n## Action Items\n- [ ] Complete user testing\n- [ ] Update documentation\n- [x] Review design mockups',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ]);
  }

  void _createNewNote() {
    // TODO: Navigate to note editor
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note editor will be implemented in a future update'),
      ),
    );
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search functionality coming soon'),
                ),
              );
            },
            tooltip: 'Search notes',
          ),
        ],
      ),
      body: _notes.isEmpty ? _buildEmptyState(context) : _buildNotesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewNote,
        tooltip: 'Create new note',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.1),
                  theme.colorScheme.secondary.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.note_add,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Notes Yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first note to get started\nwith markdown editing and organization',
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
    if (_isGridView) {
      return _buildGridView();
    } else {
      return _buildListView();
    }
  }

  Widget _buildGridView() {
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
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              return _buildNoteCard(_notes[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildNoteListTile(_notes[index]),
        );
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openNote(note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                    onSelected: (value) => _handleNoteAction(note, value),
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
                child: Text(
                  _getPreviewText(note.content),
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
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

  Widget _buildNoteListTile(Note note) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: () => _openNote(note),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.note, color: theme.colorScheme.primary),
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
              _getPreviewText(note.content),
              maxLines: 2,
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
          onSelected: (value) => _handleNoteAction(note, value),
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

  String _getPreviewText(String content) {
    // Remove markdown formatting for preview
    return content
        .replaceAll(RegExp(r'#+ '), '')
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')
        .replaceAll(RegExp(r'- \[ \] '), '☐ ')
        .replaceAll(RegExp(r'- \[x\] '), '☑ ')
        .replaceAll(RegExp(r'^- ', multiLine: true), '• ')
        .trim();
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

  void _openNote(Note note) {
    // TODO: Navigate to note editor
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Opening "${note.title}"...')));
  }

  void _handleNoteAction(Note note, String action) {
    switch (action) {
      case 'edit':
        _openNote(note);
        break;
      case 'delete':
        _showDeleteConfirmation(note);
        break;
    }
  }

  void _showDeleteConfirmation(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteNote(note);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteNote(Note note) {
    setState(() {
      _notes.remove(note);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Note "${note.title}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _notes.add(note);
            });
          },
        ),
      ),
    );
  }
}

/// Note model
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });
}
