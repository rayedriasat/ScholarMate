import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Panel displaying list of annotations with filtering
class AnnotationListPanel extends StatefulWidget {
  final List<Annotation> annotations;
  final Function(Annotation) onAnnotationTap;
  final Function(Annotation) onAnnotationDelete;

  const AnnotationListPanel({
    super.key,
    required this.annotations,
    required this.onAnnotationTap,
    required this.onAnnotationDelete,
  });

  @override
  State<AnnotationListPanel> createState() => _AnnotationListPanelState();
}

class _AnnotationListPanelState extends State<AnnotationListPanel> {
  String? _filterType;

  List<Annotation> get _filteredAnnotations {
    var filtered = widget.annotations;

    if (_filterType != null && _filterType != 'all') {
      filtered = filtered.where((a) {
        if (_filterType == 'highlight' && a is HighlightAnnotation) return true;
        if (_filterType == 'underline' && a is UnderlineAnnotation) return true;
        if (_filterType == 'strikethrough' && a is StrikethroughAnnotation) {
          return true;
        }
        if (_filterType == 'squiggly' && a is SquigglyAnnotation) return true;
        if (_filterType == 'note' && a is StickyNoteAnnotation) return true;
        return false;
      }).toList();
    }

    return filtered;
  }

  Map<int, List<Annotation>> get _annotationsByPage {
    final map = <int, List<Annotation>>{};
    for (final annotation in _filteredAnnotations) {
      map.putIfAbsent(annotation.pageNumber, () => []).add(annotation);
    }
    return map;
  }

  String _getAnnotationType(Annotation annotation) {
    if (annotation is HighlightAnnotation) return 'Highlight';
    if (annotation is UnderlineAnnotation) return 'Underline';
    if (annotation is StrikethroughAnnotation) return 'Strikethrough';
    if (annotation is SquigglyAnnotation) return 'Squiggly';
    if (annotation is StickyNoteAnnotation) return 'Note';
    return 'Unknown';
  }

  IconData _getAnnotationIcon(Annotation annotation) {
    if (annotation is HighlightAnnotation) return Icons.highlight;
    if (annotation is UnderlineAnnotation) return Icons.format_underlined;
    if (annotation is StrikethroughAnnotation) {
      return Icons.format_strikethrough;
    }
    if (annotation is SquigglyAnnotation) return Icons.waves;
    if (annotation is StickyNoteAnnotation) return Icons.note;
    return Icons.bookmark;
  }

  @override
  Widget build(BuildContext context) {
    final annotationsByPage = _annotationsByPage;
    final sortedPages = annotationsByPage.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bookmark, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Annotations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_filteredAnnotations.length}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Type filter
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _filterType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All types')),
                      DropdownMenuItem(
                        value: 'highlight',
                        child: Row(
                          children: [
                            Icon(Icons.highlight, size: 16),
                            SizedBox(width: 8),
                            Text('Highlight'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'underline',
                        child: Row(
                          children: [
                            Icon(Icons.format_underlined, size: 16),
                            SizedBox(width: 8),
                            Text('Underline'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'strikethrough',
                        child: Row(
                          children: [
                            Icon(Icons.format_strikethrough, size: 16),
                            SizedBox(width: 8),
                            Text('Strikethrough'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'squiggly',
                        child: Row(
                          children: [
                            Icon(Icons.waves, size: 16),
                            SizedBox(width: 8),
                            Text('Squiggly'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'note',
                        child: Row(
                          children: [
                            Icon(Icons.note, size: 16),
                            SizedBox(width: 8),
                            Text('Note'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterType = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Clear filters
                if (_filterType != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _filterType = null;
                      });
                    },
                    tooltip: 'Clear filters',
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Annotation list
          Expanded(
            child: _filteredAnnotations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No annotations yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select text and use the toolbar\nto create annotations',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedPages.length,
                    itemBuilder: (context, index) {
                      final pageNumber = sortedPages[index];
                      final pageAnnotations = annotationsByPage[pageNumber]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Page header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: Colors.grey[200],
                            child: Text(
                              'Page $pageNumber',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          // Annotations for this page
                          ...pageAnnotations.map(
                            (annotation) => _buildAnnotationCard(annotation),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotationCard(Annotation annotation) {
    final type = _getAnnotationType(annotation);
    final icon = _getAnnotationIcon(annotation);

    return InkWell(
      onTap: () => widget.onAnnotationTap(annotation),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: annotation.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: annotation.color),
                      const SizedBox(width: 4),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 12,
                          color: annotation.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _confirmDelete(annotation),
                  tooltip: 'Delete annotation',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            // Author
            if (annotation.author != null && annotation.author!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  annotation.author!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Annotation annotation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Annotation'),
        content: const Text(
          'Are you sure you want to delete this annotation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onAnnotationDelete(annotation);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
