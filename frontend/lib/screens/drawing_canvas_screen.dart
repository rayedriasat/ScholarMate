import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/drawing_note.dart';
import '../services/drawing_storage_service.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../theme/app_colors.dart';

enum DrawingTool { pen, eraser, text, select }

class DrawingCanvasScreen extends StatefulWidget {
  final DrawingNote? existingNote;

  const DrawingCanvasScreen({super.key, this.existingNote});

  @override
  State<DrawingCanvasScreen> createState() => _DrawingCanvasScreenState();
}

class _DrawingCanvasScreenState extends State<DrawingCanvasScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final ScreenshotController _screenshotController = ScreenshotController();
  final DrawingStorageService _storageService = DrawingStorageService();
  final TextEditingController _titleController = TextEditingController();

  List<DrawingStroke> _strokes = [];
  final List<DrawingStroke> _undoStack = [];
  List<TextNote> _textNotes = [];

  DrawingTool _currentTool = DrawingTool.pen;
  Color _currentColor = Colors.black;
  double _strokeWidth = 3.0;

  List<Offset> _currentStroke = [];
  Offset? _eraserPosition;
  TextNote? _selectedTextNote;
  Offset? _dragOffset;

  bool _isSaving = false;
  String? _noteId;

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _loadExistingNote();
    } else {
      _noteId = const Uuid().v4();
      _titleController.text = 'Untitled Note';
    }
  }

  void _loadExistingNote() {
    final note = widget.existingNote!;
    _noteId = note.id;
    _titleController.text = note.title;
    _strokes = List.from(note.strokes);
    _textNotes = List.from(note.textNotes);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);

    if (_currentTool == DrawingTool.text) {
      _addTextNote(localPosition);
    } else if (_currentTool == DrawingTool.select) {
      _selectTextNote(localPosition);
    } else if (_currentTool == DrawingTool.eraser) {
      setState(() {
        _eraserPosition = localPosition;
        _eraseAtPosition(localPosition);
      });
    } else {
      setState(() {
        _currentStroke = [localPosition];
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);

    if (_currentTool == DrawingTool.select && _selectedTextNote != null) {
      setState(() {
        _selectedTextNote!.position =
            localPosition - (_dragOffset ?? Offset.zero);
      });
    } else if (_currentTool == DrawingTool.eraser) {
      setState(() {
        _eraserPosition = localPosition;
        _eraseAtPosition(localPosition);
      });
    } else if (_currentTool == DrawingTool.pen) {
      setState(() {
        _currentStroke.add(localPosition);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      if (_currentTool == DrawingTool.pen && _currentStroke.isNotEmpty) {
        _strokes.add(
          DrawingStroke(
            points: List.from(_currentStroke),
            color: _currentColor,
            strokeWidth: _strokeWidth,
          ),
        );
        _undoStack.clear();
      }
      _currentStroke = [];
      _eraserPosition = null;
    });
  }

  void _eraseAtPosition(Offset position) {
    _strokes.removeWhere((stroke) {
      return stroke.points.any((point) {
        final distance = (point - position).distance;
        return distance < _strokeWidth * 2;
      });
    });
  }

  void _addTextNote(Offset position) {
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Add Text Note',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter your text...',
              hintStyle: TextStyle(color: Colors.white38),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ModernButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  setState(() {
                    _textNotes.add(
                      TextNote(
                        id: const Uuid().v4(),
                        position: position,
                        text: textController.text,
                        color: _currentColor,
                      ),
                    );
                  });
                }
                Navigator.pop(context);
              },
              label: 'Add',
              width: 80,
              height: 36,
            ),
          ],
        );
      },
    );
  }

  void _selectTextNote(Offset position) {
    for (final note in _textNotes) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: note.text,
          style: TextStyle(fontSize: note.fontSize),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final rect = Rect.fromLTWH(
        note.position.dx,
        note.position.dy,
        textPainter.width,
        textPainter.height,
      );

      if (rect.contains(position)) {
        setState(() {
          _selectedTextNote = note;
          _dragOffset = position - note.position;
        });
        _showTextNoteOptions(note);
        return;
      }
    }
  }

  void _showTextNoteOptions(TextNote note) {
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController(text: note.text);
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Edit Text Note',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _textNotes.remove(note);
                });
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ModernButton(
              onPressed: () {
                setState(() {
                  note.text = textController.text;
                });
                Navigator.pop(context);
              },
              label: 'Save',
              width: 80,
              height: 36,
            ),
          ],
        );
      },
    );
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _undoStack.add(_strokes.removeLast());
      });
    }
  }

  void _redo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        _strokes.add(_undoStack.removeLast());
      });
    }
  }

  void _clearCanvas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Clear Canvas',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to clear everything?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ModernButton(
            onPressed: () {
              setState(() {
                _strokes.clear();
                _textNotes.clear();
                _undoStack.clear();
              });
              Navigator.pop(context);
            },
            label: 'Clear',
            backgroundColor: Colors.red,
            width: 80,
            height: 36,
          ),
        ],
      ),
    );
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Pick a color',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _currentColor,
            onColorChanged: (color) {
              setState(() {
                _currentColor = color;
              });
            },
            labelTypes: const [],
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          ModernButton(
            onPressed: () => Navigator.pop(context),
            label: 'Done',
            width: 80,
            height: 36,
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final page = NotePage(
        id: 'page_1',
        strokes: _strokes,
        textNotes: _textNotes,
      );

      final note = DrawingNote(
        id: _noteId!,
        title: _titleController.text.isEmpty
            ? 'Untitled Note'
            : _titleController.text,
        pages: [page],
        createdAt: widget.existingNote?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _storageService.saveNote(note);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving note: $e')));
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _exportAsPNG() async {
    try {
      final image = await _screenshotController.capture();
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${_titleController.text}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(image);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exported to ${file.path}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting: $e')));
      }
    }
  }

  Future<void> _exportAsPDF() async {
    try {
      final image = await _screenshotController.capture();
      if (image == null) return;

      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(image);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Center(child: pw.Image(pdfImage)),
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${_titleController.text}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF exported to ${file.path}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: GlassContainer(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _titleController,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Note title',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _strokes.isEmpty ? null : _undo,
            tooltip: 'Undo',
            color: Colors.white,
            disabledColor: Colors.white24,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _undoStack.isEmpty ? null : _redo,
            tooltip: 'Redo',
            color: Colors.white,
            disabledColor: Colors.white24,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearCanvas,
            tooltip: 'Clear',
            color: Colors.white,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download, color: Colors.white),
            color: AppColors.surface,
            onSelected: (value) {
              if (value == 'png') {
                _exportAsPNG();
              } else if (value == 'pdf') {
                _exportAsPDF();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'png',
                child: Row(
                  children: [
                    Icon(Icons.image, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Export as PNG',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Export as PDF',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
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
            onPressed: _isSaving ? null : _saveNote,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    color: Colors.white,
                    child: GestureDetector(
                      key: _canvasKey,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        painter: DrawingPainter(
                          strokes: _strokes,
                          currentStroke: _currentStroke,
                          currentColor: _currentColor,
                          strokeWidth: _strokeWidth,
                          textNotes: _textNotes,
                          selectedTextNote: _selectedTextNote,
                          eraserPosition: _eraserPosition,
                          isErasing: _currentTool == DrawingTool.eraser,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return GlassContainer(
      borderRadius: BorderRadius.zero,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      border: Border(
        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildToolButton(
              icon: Icons.edit,
              label: 'Pen',
              isSelected: _currentTool == DrawingTool.pen,
              onTap: () => setState(() => _currentTool = DrawingTool.pen),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              icon: Icons.cleaning_services,
              label: 'Eraser',
              isSelected: _currentTool == DrawingTool.eraser,
              onTap: () => setState(() => _currentTool = DrawingTool.eraser),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              icon: Icons.text_fields,
              label: 'Text',
              isSelected: _currentTool == DrawingTool.text,
              onTap: () => setState(() => _currentTool = DrawingTool.text),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              icon: Icons.touch_app,
              label: 'Select',
              isSelected: _currentTool == DrawingTool.select,
              onTap: () => setState(() => _currentTool = DrawingTool.select),
            ),
            const SizedBox(width: 16),
            Container(height: 24, width: 1, color: Colors.white24),
            const SizedBox(width: 16),
            _buildColorButton(),
            const SizedBox(width: 16),
            _buildStrokeWidthSlider(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.2)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.white70,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? AppColors.primary : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton() {
    return InkWell(
      onTap: _pickColor,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54, width: 2),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Color',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrokeWidthSlider() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 150,
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _strokeWidth,
              min: 1,
              max: 20,
              divisions: 19,
              label: _strokeWidth.round().toString(),
              onChanged: (value) {
                setState(() {
                  _strokeWidth = value;
                });
              },
            ),
          ),
        ),
        Text(
          'Width: ${_strokeWidth.round()}',
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double strokeWidth;
  final List<TextNote> textNotes;
  final TextNote? selectedTextNote;
  final Offset? eraserPosition;
  final bool isErasing;

  DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.strokeWidth,
    required this.textNotes,
    this.selectedTextNote,
    this.eraserPosition,
    this.isErasing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    // Draw current stroke (only for pen tool)
    if (!isErasing && currentStroke.length > 1) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < currentStroke.length - 1; i++) {
        canvas.drawLine(currentStroke[i], currentStroke[i + 1], paint);
      }
    }

    // Draw eraser cursor
    if (isErasing && eraserPosition != null) {
      // Draw outer circle (eraser boundary)
      canvas.drawCircle(
        eraserPosition!,
        strokeWidth * 2,
        Paint()
          ..color = Colors.red.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );

      // Draw eraser icon in the center
      final iconSize = strokeWidth * 2;

      // Draw a simple eraser shape (rectangle with rounded corners)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: eraserPosition!,
            width: iconSize * 0.6,
            height: iconSize * 0.4,
          ),
          const Radius.circular(2),
        ),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: eraserPosition!,
            width: iconSize * 0.6,
            height: iconSize * 0.4,
          ),
          const Radius.circular(2),
        ),
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Draw outer circle border
      canvas.drawCircle(
        eraserPosition!,
        strokeWidth * 2,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Draw text notes
    for (final note in textNotes) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: note.text,
          style: TextStyle(
            color: note.color,
            fontSize: note.fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Draw selection box if selected
      if (note == selectedTextNote) {
        final rect = Rect.fromLTWH(
          note.position.dx - 4,
          note.position.dy - 4,
          textPainter.width + 8,
          textPainter.height + 8,
        );
        canvas.drawRect(
          rect,
          Paint()
            ..color = Colors.blue.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          rect,
          Paint()
            ..color = Colors.blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }

      textPainter.paint(canvas, note.position);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return true;
  }
}
