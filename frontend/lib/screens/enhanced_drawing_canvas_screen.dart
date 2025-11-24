import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../models/drawing_note.dart';
import '../services/drawing_storage_service.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../theme/app_colors.dart';

enum DrawingTool { pen, eraser, text, select, image }

class EnhancedDrawingCanvasScreen extends StatefulWidget {
  final DrawingNote? existingNote;

  const EnhancedDrawingCanvasScreen({super.key, this.existingNote});

  @override
  State<EnhancedDrawingCanvasScreen> createState() =>
      _EnhancedDrawingCanvasScreenState();
}

class _EnhancedDrawingCanvasScreenState
    extends State<EnhancedDrawingCanvasScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final ScreenshotController _screenshotController = ScreenshotController();
  final DrawingStorageService _storageService = DrawingStorageService();
  final TextEditingController _titleController = TextEditingController();
  final PageController _pageController = PageController();
  final ImagePicker _imagePicker = ImagePicker();

  late DrawingNote _note;
  int _currentPageIndex = 0;
  final List<List<DrawingStroke>> _undoStacks = [];
  final Map<String, ui.Image> _imageCache = {};

  DrawingTool _currentTool = DrawingTool.pen;
  Color _currentColor = Colors.black;
  double _strokeWidth = 3.0;

  List<Offset> _currentStroke = [];
  Offset? _eraserPosition;
  dynamic _selectedItem; // Can be TextNote or CanvasImage
  Offset? _dragOffset;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeNote();
  }

  void _initializeNote() {
    if (widget.existingNote != null) {
      _note = widget.existingNote!;
      _titleController.text = _note.title;

      // Ensure existing note has at least one page
      if (_note.pages.isEmpty) {
        _note.pages.add(_createNewPage());
      }
    } else {
      _note = DrawingNote(
        id: const Uuid().v4(),
        title: 'Untitled Note',
        pages: [_createNewPage()],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _titleController.text = _note.title;
    }

    // Ensure current page index is valid
    if (_currentPageIndex >= _note.pages.length) {
      _currentPageIndex = 0;
    }

    // Initialize undo stacks for each page
    _undoStacks.clear();
    for (int i = 0; i < _note.pages.length; i++) {
      _undoStacks.add(<DrawingStroke>[]);
    }

    // Load images into cache
    _loadImagesIntoCache();
  }

  Future<void> _loadImagesIntoCache() async {
    for (final page in _note.pages) {
      for (final image in page.images) {
        if (!_imageCache.containsKey(image.id)) {
          try {
            final codec = await ui.instantiateImageCodec(image.imageBytes);
            final frame = await codec.getNextFrame();
            _imageCache[image.id] = frame.image;
          } catch (e) {
            debugPrint('Error loading image ${image.id}: $e');
          }
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  NotePage _createNewPage() {
    return NotePage(
      id: 'page_${const Uuid().v4()}',
      strokes: [],
      textNotes: [],
      images: [],
      backgroundColor: Colors.white,
    );
  }

  NotePage get _currentPage {
    if (_note.pages.isEmpty) {
      // Create a default page if none exist
      _note.pages.add(_createNewPage());
      _undoStacks.add(<DrawingStroke>[]);
    }

    // Ensure current page index is valid
    if (_currentPageIndex >= _note.pages.length) {
      _currentPageIndex = _note.pages.length - 1;
    }
    if (_currentPageIndex < 0) {
      _currentPageIndex = 0;
    }

    return _note.pages[_currentPageIndex];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);

    switch (_currentTool) {
      case DrawingTool.text:
        _addTextNote(localPosition);
        break;
      case DrawingTool.select:
        _selectItem(localPosition);
        break;
      case DrawingTool.eraser:
        setState(() {
          _eraserPosition = localPosition;
          _eraseAtPosition(localPosition);
        });
        break;
      case DrawingTool.image:
        _addImage(localPosition);
        break;
      case DrawingTool.pen:
        setState(() {
          _currentStroke = [localPosition];
        });
        break;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);

    if (_currentTool == DrawingTool.select && _selectedItem != null) {
      setState(() {
        if (_selectedItem is TextNote) {
          (_selectedItem as TextNote).position =
              localPosition - (_dragOffset ?? Offset.zero);
        } else if (_selectedItem is CanvasImage) {
          (_selectedItem as CanvasImage).position =
              localPosition - (_dragOffset ?? Offset.zero);
        }
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
        final stroke = DrawingStroke(
          points: List.from(_currentStroke),
          color: _currentColor,
          strokeWidth: _strokeWidth,
        );

        _currentPage.strokes.add(stroke);
        _undoStacks[_currentPageIndex].clear();
        _updateNote();
      }
      _currentStroke = [];
      _eraserPosition = null;
    });
  }

  void _eraseAtPosition(Offset position) {
    _currentPage.strokes.removeWhere((stroke) {
      return stroke.points.any((point) {
        final distance = (point - position).distance;
        return distance < _strokeWidth * 2;
      });
    });
    _updateNote();
  }

  void _addTextNote(Offset position) {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surface
              : Colors.white,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Text Note',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                maxLines: 3,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Enter your text...',
                  hintStyle: TextStyle(color: Theme.of(context).hintColor),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ModernButton(
                    onPressed: () {
                      if (textController.text.isNotEmpty) {
                        setState(() {
                          final textNote = TextNote(
                            id: const Uuid().v4(),
                            position: position,
                            text: textController.text,
                            color: _currentColor,
                          );
                          _currentPage.textNotes.add(textNote);
                          _updateNote();
                        });
                      }
                      Navigator.pop(context);
                    },
                    label: 'Add',
                    width: 80,
                    height: 36,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addImage(Offset position) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image == null) return;

      final imageBytes = await image.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final imageInfo = frame.image;

      final imageId = const Uuid().v4();

      // Cache the image immediately
      _imageCache[imageId] = imageInfo;

      setState(() {
        _currentPage.images.add(
          CanvasImage(
            id: imageId,
            position: position,
            imageBytes: imageBytes,
            width: imageInfo.width.toDouble(),
            height: imageInfo.height.toDouble(),
            scale: 0.5, // Default scale
          ),
        );
        _updateNote();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding image: $e')));
      }
    }
  }

  void _selectItem(Offset position) {
    // Check text notes first
    for (final note in _currentPage.textNotes) {
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
          _selectedItem = note;
          _dragOffset = position - note.position;
        });
        _showTextNoteOptions(note);
        return;
      }
    }

    // Check images
    for (final image in _currentPage.images) {
      final rect = Rect.fromLTWH(
        image.position.dx,
        image.position.dy,
        image.width * image.scale,
        image.height * image.scale,
      );

      if (rect.contains(position)) {
        setState(() {
          _selectedItem = image;
          _dragOffset = position - image.position;
        });
        _showImageOptions(image);
        return;
      }
    }

    setState(() {
      _selectedItem = null;
    });
  }

  void _showTextNoteOptions(TextNote note) {
    final textController = TextEditingController(text: note.text);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surface
              : Colors.white,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Text Note',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                maxLines: 3,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentPage.textNotes.remove(note);
                        _updateNote();
                      });
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ModernButton(
                        onPressed: () {
                          setState(() {
                            note.text = textController.text;
                            _updateNote();
                          });
                          Navigator.pop(context);
                        },
                        label: 'Save',
                        width: 80,
                        height: 36,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageOptions(CanvasImage image) {
    double scale = image.scale;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surface
              : Colors.white,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Image Options',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Text(
                'Scale: ${(scale * 100).round()}%',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: Theme.of(context).dividerColor,
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: scale,
                  min: 0.1,
                  max: 2.0,
                  divisions: 19,
                  onChanged: (value) {
                    setDialogState(() {
                      scale = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentPage.images.remove(image);
                        _updateNote();
                      });
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ModernButton(
                        onPressed: () {
                          setState(() {
                            final index = _currentPage.images.indexOf(image);
                            if (index >= 0) {
                              _currentPage.images[index] = CanvasImage(
                                id: image.id,
                                position: image.position,
                                imageBytes: image.imageBytes,
                                width: image.width,
                                height: image.height,
                                scale: scale,
                              );
                              _updateNote();
                            }
                          });
                          Navigator.pop(context);
                        },
                        label: 'Apply',
                        width: 80,
                        height: 36,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateNote() {
    final newTitle = _titleController.text.isEmpty
        ? 'Untitled Note'
        : _titleController.text;
    if (_note.title != newTitle) {
      _note = _note.copyWith(title: newTitle, updatedAt: DateTime.now());
    }
  }

  void _undo() {
    if (_currentPage.strokes.isNotEmpty) {
      setState(() {
        _undoStacks[_currentPageIndex].add(_currentPage.strokes.removeLast());
        _updateNote();
      });
    }
  }

  void _redo() {
    if (_undoStacks[_currentPageIndex].isNotEmpty) {
      setState(() {
        _currentPage.strokes.add(_undoStacks[_currentPageIndex].removeLast());
        _updateNote();
      });
    }
  }

  void _addNewPage() {
    setState(() {
      _note.pages.add(_createNewPage());
      _undoStacks.add(<DrawingStroke>[]);
      _currentPageIndex = _note.pages.length - 1;
      _pageController.animateToPage(
        _currentPageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateNote();
    });
  }

  void _deletePage() {
    if (_note.pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the last page')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Page', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete page ${_currentPageIndex + 1}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ModernButton(
            onPressed: () {
              setState(() {
                _note.pages.removeAt(_currentPageIndex);
                _undoStacks.removeAt(_currentPageIndex);
                if (_currentPageIndex >= _note.pages.length) {
                  _currentPageIndex = _note.pages.length - 1;
                }
                _updateNote();
              });
              Navigator.pop(context);
            },
            label: 'Delete',
            backgroundColor: Colors.red,
            width: 80,
            height: 36,
          ),
        ],
      ),
    );
  }

  void _clearCurrentPage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear Page', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to clear this page?',
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
                _currentPage.strokes.clear();
                _currentPage.textNotes.clear();
                _currentPage.images.clear();
                _undoStacks[_currentPageIndex].clear();
                _updateNote();
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surface
            : Colors.white,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pick a Color',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ColorPicker(
              pickerColor: _currentColor,
              onColorChanged: (color) {
                setState(() {
                  _currentColor = color;
                });
              },
              labelTypes: const [],
              pickerAreaHeightPercent: 0.8,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ModernButton(
                onPressed: () => Navigator.pop(context),
                label: 'Done',
                width: 80,
                height: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (_note.pages.isEmpty) {
        throw Exception('Note must have at least one page');
      }

      if (_note.title.trim().isEmpty) {
        _note = _note.copyWith(title: 'Untitled Note');
      }

      _updateNote();

      await _storageService.saveNote(_note);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _exportAsPDF() async {
    setState(() {
      _isSaving = true;
    });

    try {
      _updateNote();

      final pageImages = <Uint8List>[];

      for (int i = 0; i < _note.pages.length; i++) {
        await _pageController.animateToPage(
          i,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );

        await Future.delayed(const Duration(milliseconds: 500));

        final imageBytes = await _screenshotController.capture();
        if (imageBytes != null) {
          pageImages.add(imageBytes);
        }
      }

      await _pageController.animateToPage(
        _currentPageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      if (pageImages.isEmpty) {
        throw Exception('No pages could be captured');
      }

      final driveFile = await _storageService.exportNoteToPDFFromImages(
        _note.title,
        pageImages,
      );

      if (mounted) {
        if (driveFile != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved to Google Drive: ${driveFile.name}'),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Error exporting PDF')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting PDF: $e')));
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface,
                AppColors.surface.withValues(alpha: 0.9),
              ],
            ),
          ),
        ),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _titleController,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Note title',
              hintStyle: TextStyle(color: Colors.white38),
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            onChanged: (value) => _updateNote(),
          ),
        ),
        actions: [
          // Drawing tools
          _buildCompactToolButton(
            icon: Icons.edit_rounded,
            tooltip: 'Pen',
            isSelected: _currentTool == DrawingTool.pen,
            onTap: () => setState(() => _currentTool = DrawingTool.pen),
          ),
          _buildCompactToolButton(
            icon: Icons.auto_fix_high_rounded,
            tooltip: 'Eraser',
            isSelected: _currentTool == DrawingTool.eraser,
            onTap: () => setState(() => _currentTool = DrawingTool.eraser),
          ),
          _buildCompactToolButton(
            icon: Icons.text_fields_rounded,
            tooltip: 'Text',
            isSelected: _currentTool == DrawingTool.text,
            onTap: () => setState(() => _currentTool = DrawingTool.text),
          ),
          _buildCompactToolButton(
            icon: Icons.image_rounded,
            tooltip: 'Image',
            isSelected: _currentTool == DrawingTool.image,
            onTap: () => setState(() => _currentTool = DrawingTool.image),
          ),
          _buildCompactToolButton(
            icon: Icons.touch_app_rounded,
            tooltip: 'Select',
            isSelected: _currentTool == DrawingTool.select,
            onTap: () => setState(() => _currentTool = DrawingTool.select),
          ),
          // Color picker
          IconButton(
            onPressed: _pickColor,
            tooltip: 'Color',
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          // Stroke width
          SizedBox(
            width: 100,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayColor: AppColors.primary.withValues(alpha: 0.2),
                trackHeight: 2,
              ),
              child: Slider(
                value: _strokeWidth,
                min: 1,
                max: 20,
                onChanged: (value) {
                  setState(() {
                    _strokeWidth = value;
                  });
                },
              ),
            ),
          ),
          // Undo/Redo
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _currentPage.strokes.isEmpty ? null : _undo,
            tooltip: 'Undo',
            color: Colors.white,
            disabledColor: Colors.white24,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _undoStacks[_currentPageIndex].isEmpty ? null : _redo,
            tooltip: 'Redo',
            color: Colors.white,
            disabledColor: Colors.white24,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: AppColors.surface,
            onSelected: (value) {
              switch (value) {
                case 'clear_page':
                  _clearCurrentPage();
                  break;
                case 'delete_page':
                  _deletePage();
                  break;
                case 'export_pdf':
                  _exportAsPDF();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_page',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Clear Page', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_page',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Delete Page', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_pdf',
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    color: Colors.white,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _note.pages.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          key: index == _currentPageIndex ? _canvasKey : null,
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          child: CustomPaint(
                            painter: EnhancedDrawingPainter(
                              strokes: _note.pages[index].strokes,
                              currentStroke: _currentStroke,
                              currentColor: _currentColor,
                              strokeWidth: _strokeWidth,
                              textNotes: _note.pages[index].textNotes,
                              images: _note.pages[index].images,
                              imageCache: _imageCache,
                              selectedItem: _selectedItem,
                              eraserPosition: _eraserPosition,
                              isErasing: _currentTool == DrawingTool.eraser,
                            ),
                            size: Size.infinite,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildPageControls(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surface.withValues(alpha: 0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildToolButton(
              icon: Icons.edit_rounded,
              label: 'Pen',
              isSelected: _currentTool == DrawingTool.pen,
              onTap: () => setState(() => _currentTool = DrawingTool.pen),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              icon: Icons.auto_fix_high_rounded,
              label: 'Eraser',
              isSelected: _currentTool == DrawingTool.eraser,
              onTap: () => setState(() => _currentTool = DrawingTool.eraser),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              icon: Icons.text_fields_rounded,
              label: 'Text',
              isSelected: _currentTool == DrawingTool.text,
              onTap: () => setState(() => _currentTool = DrawingTool.text),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              icon: Icons.image_rounded,
              label: 'Image',
              isSelected: _currentTool == DrawingTool.image,
              onTap: () => setState(() => _currentTool = DrawingTool.image),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              icon: Icons.touch_app_rounded,
              label: 'Select',
              isSelected: _currentTool == DrawingTool.select,
              onTap: () => setState(() => _currentTool = DrawingTool.select),
            ),
            Container(
              height: 32,
              width: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white24,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            _buildColorButton(),
            const SizedBox(width: 12),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.7),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 18,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.white60,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton() {
    return GestureDetector(
      onTap: _pickColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _currentColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Color',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrokeWidthSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayColor: AppColors.primary.withValues(alpha: 0.2),
                trackHeight: 2.5,
              ),
              child: Slider(
                value: _strokeWidth,
                min: 1,
                max: 20,
                divisions: 19,
                onChanged: (value) {
                  setState(() {
                    _strokeWidth = value;
                  });
                },
              ),
            ),
          ),
          Text(
            '${_strokeWidth.round()}px',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactToolButton({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.7),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : Colors.white70,
        ),
      ),
    );
  }

  Widget _buildPageControls() {
    return GlassContainer(
      borderRadius: BorderRadius.zero,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      border: Border(
        top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: _currentPageIndex > 0
                ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
          ),
          Text(
            'Page ${_currentPageIndex + 1} of ${_note.pages.length}',
            style: const TextStyle(color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: _currentPageIndex < _note.pages.length - 1
                ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
          ),
          const SizedBox(width: 16),
          ModernButton(
            onPressed: _addNewPage,
            icon: Icons.add,
            label: 'New Page',
            width: 120,
            height: 36,
          ),
        ],
      ),
    );
  }
}

class EnhancedDrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double strokeWidth;
  final List<TextNote> textNotes;
  final List<CanvasImage> images;
  final Map<String, ui.Image> imageCache;
  final dynamic selectedItem;
  final Offset? eraserPosition;
  final bool isErasing;

  EnhancedDrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.strokeWidth,
    required this.textNotes,
    required this.images,
    required this.imageCache,
    this.selectedItem,
    this.eraserPosition,
    this.isErasing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw images first (bottom layer)
    for (final image in images) {
      if (imageCache.containsKey(image.id)) {
        final uiImage = imageCache[image.id]!;
        final srcRect = Rect.fromLTWH(
          0,
          0,
          uiImage.width.toDouble(),
          uiImage.height.toDouble(),
        );
        final dstRect = Rect.fromLTWH(
          image.position.dx,
          image.position.dy,
          image.width * image.scale,
          image.height * image.scale,
        );
        canvas.drawImageRect(uiImage, srcRect, dstRect, Paint());

        // Draw selection box if selected
        if (image == selectedItem) {
          canvas.drawRect(
            dstRect,
            Paint()
              ..color = Colors.blue.withValues(alpha: 0.2)
              ..style = PaintingStyle.fill,
          );
          canvas.drawRect(
            dstRect,
            Paint()
              ..color = Colors.blue
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
    }

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
      if (note == selectedItem) {
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
  bool shouldRepaint(covariant EnhancedDrawingPainter oldDelegate) {
    return true;
  }
}
