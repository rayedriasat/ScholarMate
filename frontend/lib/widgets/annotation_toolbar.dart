import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Toolbar for annotation tools with color picker
class AnnotationToolbar extends StatefulWidget {
  final PdfAnnotationMode selectedMode;
  final Color selectedColor;
  final Function(PdfAnnotationMode) onModeChanged;
  final Function(Color) onColorChanged;

  const AnnotationToolbar({
    super.key,
    required this.selectedMode,
    required this.selectedColor,
    required this.onModeChanged,
    required this.onColorChanged,
  });

  @override
  State<AnnotationToolbar> createState() => _AnnotationToolbarState();
}

class _AnnotationToolbarState extends State<AnnotationToolbar> {
  static const List<Color> _annotationColors = [
    Color(0xFFFFEB3B), // Yellow
    Color(0xFFFF9800), // Orange
    Color(0xFFF44336), // Red
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF2196F3), // Blue
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
  ];

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _annotationColors.map((color) {
            final isSelected = color.value == widget.selectedColor.value;
            return InkWell(
              onTap: () {
                widget.onColorChanged(color);
                Navigator.pop(context);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Highlight
          _buildToolButton(
            icon: Icons.highlight,
            label: 'Highlight',
            mode: PdfAnnotationMode.highlight,
            isSelected: widget.selectedMode == PdfAnnotationMode.highlight,
          ),

          // Underline
          _buildToolButton(
            icon: Icons.format_underlined,
            label: 'Underline',
            mode: PdfAnnotationMode.underline,
            isSelected: widget.selectedMode == PdfAnnotationMode.underline,
          ),

          // Strikethrough
          _buildToolButton(
            icon: Icons.format_strikethrough,
            label: 'Strike',
            mode: PdfAnnotationMode.strikethrough,
            isSelected: widget.selectedMode == PdfAnnotationMode.strikethrough,
          ),

          // Squiggly
          _buildToolButton(
            icon: Icons.waves,
            label: 'Squiggly',
            mode: PdfAnnotationMode.squiggly,
            isSelected: widget.selectedMode == PdfAnnotationMode.squiggly,
          ),

          const VerticalDivider(),

          // Sticky Note
          _buildToolButton(
            icon: Icons.note_add,
            label: 'Note',
            mode: PdfAnnotationMode.stickyNote,
            isSelected: widget.selectedMode == PdfAnnotationMode.stickyNote,
          ),

          const VerticalDivider(),

          // Color picker
          IconButton(
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: widget.selectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[400]!),
              ),
            ),
            onPressed: _showColorPicker,
            tooltip: 'Choose Color',
          ),

          const Spacer(),

          // Clear selection
          if (widget.selectedMode != PdfAnnotationMode.none)
            TextButton.icon(
              onPressed: () => widget.onModeChanged(PdfAnnotationMode.none),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required PdfAnnotationMode mode,
    required bool isSelected,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () {
          widget.onModeChanged(isSelected ? PdfAnnotationMode.none : mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? widget.selectedColor.withValues(alpha: 0.3)
                : null,
            borderRadius: BorderRadius.circular(4),
            border: isSelected
                ? Border.all(color: widget.selectedColor, width: 2)
                : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? widget.selectedColor : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
