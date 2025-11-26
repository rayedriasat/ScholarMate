import 'package:flutter/material.dart';
import '../models/drawing_note.dart';
import '../models/markdown_note.dart';
import '../services/drawing_storage_service.dart';
import '../services/markdown_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
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
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        color: AppColors.background,
        opacity: 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Create New Note',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildCreateOption(
              icon: Icons.edit_note,
              title: 'Markdown Note',
              subtitle: 'Text-based note with markdown formatting',
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
            const SizedBox(height: 16),
            _buildCreateOption(
              icon: Icons.draw,
              title: 'Drawing Note',
              subtitle: 'Canvas for drawing and handwritten notes',
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

  Widget _buildCreateOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white.withValues(alpha: 0.4),
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
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).disabledColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 10,
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
      body: SafeArea(
        child: Column(
          children: [
            // Custom Toolbar
            _buildToolbar(),
            _buildFilterBar(),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _getFilteredNotes().isEmpty
                  ? _buildEmptyState(context)
                  : _buildNotesList(),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: 0, // 70 (nav height) + 24 (nav bottom) + 19 (overflow buffer)
        ),
        child: ModernButton(
          onPressed: _createNewNote,
          icon: Icons.add,
          label: 'New Note',
          width: 165,
          height: 50,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.secondary.withValues(alpha: 0.2),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(icon, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 16,
            ),
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
    final isWideScreen = MediaQuery.of(context).size.width >= 800;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: isWideScreen
            ? 16
            : 120, // Extra padding for floating bottom nav on mobile
      ),
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
    final isWideScreen = MediaQuery.of(context).size.width >= 800;
    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: isWideScreen
            ? 16
            : 120, // Extra padding for floating bottom nav on mobile
      ),
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
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).cardColor,
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
      ),
      child: InkWell(
        onTap: () => _openMarkdownNote(note),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_note,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildNoteActions(note, true),
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
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                    const Spacer(),
                    Text(
                      '${note.wordCount} words',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _formatDate(note.updatedAt),
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawingNoteCard(DrawingNote note) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).cardColor,
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
      ),
      child: InkWell(
        onTap: () => _openDrawingNote(note),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.draw,
                      color: AppColors.secondary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildNoteActions(note, false),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${note.pages.length} page${note.pages.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 12,
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
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkdownNoteListTile(MarkdownNote note) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white.withValues(alpha: 0.05),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      child: ListTile(
        onTap: () => _openMarkdownNote(note),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.edit_note, color: AppColors.primary),
        ),
        title: Text(
          note.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          note.content.isNotEmpty ? note.content : 'No content',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
        trailing: _buildNoteActions(note, true),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildDrawingNoteListTile(DrawingNote note) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white.withValues(alpha: 0.05),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      child: ListTile(
        onTap: () => _openDrawingNote(note),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.draw, color: AppColors.secondary),
        ),
        title: Text(
          note.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${note.pages.length} page${note.pages.length != 1 ? 's' : ''}',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
        trailing: _buildNoteActions(note, false),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildNoteActions(dynamic note, bool isMarkdown) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: Colors.white.withValues(alpha: 0.6),
      ),
      color: AppColors.surface,
      onSelected: (value) {
        if (isMarkdown) {
          _handleMarkdownNoteAction(note as MarkdownNote, value);
        } else {
          _handleDrawingNoteAction(note as DrawingNote, value);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: Colors.white),
              SizedBox(width: 8),
              Text('Edit', style: TextStyle(color: Colors.white)),
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

  Widget _buildToolbar() {
    return GlassContainer(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      borderRadius: BorderRadius.zero,
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      color: Theme.of(context).cardColor,
      child: Stack(
        children: [
          Center(
            child: Text(
              'Notes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: Icon(
                  _isGridView ? Icons.view_list : Icons.grid_view,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: _toggleView,
                tooltip: _isGridView ? 'List view' : 'Grid view',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTabChip('All', 0, _getTotalNotesCount()),
          const SizedBox(width: 8),
          _buildTabChip('Markdown', 1, _markdownNotes.length),
          const SizedBox(width: 8),
          _buildTabChip('Drawing', 2, _drawingNotes.length),
        ],
      ),
    );
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
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Drawing Note',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${note.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
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
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Markdown Note',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${note.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
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
      _loadNotes();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Note deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting note: $e')));
      }
    }
  }

  Future<void> _deleteMarkdownNote(MarkdownNote note) async {
    try {
      await _markdownStorageService.deleteNote(note.id);
      _loadNotes();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Note deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting note: $e')));
      }
    }
  }
}
