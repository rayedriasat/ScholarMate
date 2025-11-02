import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../models/drawing_note.dart';
import '../services/drawing_storage_service.dart';

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

        debugPrint(
          'Adding stroke with ${stroke.points.length} points to page ${_currentPageIndex}',
        );
        _currentPage.strokes.add(stroke);
        debugPrint('Page now has ${_currentPage.strokes.length} strokes');
        debugPrint('Note has ${_note.pages.length} pages');

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
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Text Note'),
          content: TextField(
            controller: textController,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter your text...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  setState(() {
                    final textNote = TextNote(
                      id: const Uuid().v4(),
                      position: position,
                      text: textController.text,
                      color: _currentColor,
                    );
                    debugPrint(
                      'Adding text note "${textNote.text}" to page ${_currentPageIndex}',
                    );
                    _currentPage.textNotes.add(textNote);
                    debugPrint(
                      'Page now has ${_currentPage.textNotes.length} text notes',
                    );
                    _updateNote();
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
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
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController(text: note.text);
        return AlertDialog(
          title: const Text('Edit Text Note'),
          content: TextField(
            controller: textController,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  note.text = textController.text;
                  _updateNote();
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showImageOptions(CanvasImage image) {
    showDialog(
      context: context,
      builder: (context) {
        double scale = image.scale;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Image Options'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Scale: ${(scale * 100).round()}%'),
                  Slider(
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
                ],
              ),
              actions: [
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
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
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _updateNote() {
    // Update the note's title and timestamp without recreating the object
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
        title: const Text('Delete Page'),
        content: Text(
          'Are you sure you want to delete page ${_currentPageIndex + 1}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _clearCurrentPage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Page'),
        content: const Text('Are you sure you want to clear this page?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _currentColor,
            onColorChanged: (color) {
              setState(() {
                _currentColor = color;
              });
            },
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
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
      // Validate note data before saving
      if (_note.pages.isEmpty) {
        throw Exception('Note must have at least one page');
      }

      if (_note.title.trim().isEmpty) {
        _note = _note.copyWith(title: 'Untitled Note');
      }

      _updateNote();

      // Add debug information
      debugPrint('Saving note: ${_note.id} with ${_note.pages.length} pages');
      for (int i = 0; i < _note.pages.length; i++) {
        final page = _note.pages[i];
        debugPrint(
          'Page $i: ${page.strokes.length} strokes, ${page.textNotes.length} text notes, ${page.images.length} images',
        );
      }

      await _storageService.saveNote(_note);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving note: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        String errorMessage = 'Error saving note';
        if (e.toString().contains('TypeError')) {
          errorMessage = 'Data format error - please try creating a new note';
        } else if (e.toString().contains('Connection')) {
          errorMessage = 'Network error - note saved locally only';
        } else {
          errorMessage =
              'Error saving note: ${e.toString().split(':').last.trim()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(label: 'Retry', onPressed: _saveNote),
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

      // Capture each page as an image
      final pageImages = <Uint8List>[];

      for (int i = 0; i < _note.pages.length; i++) {
        // Navigate to the page
        await _pageController.animateToPage(
          i,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );

        // Wait for the page to render
        await Future.delayed(const Duration(milliseconds: 500));

        // Capture the page as image
        final imageBytes = await _screenshotController.capture();
        if (imageBytes != null) {
          pageImages.add(imageBytes);
          debugPrint('Captured page $i as image (${imageBytes.length} bytes)');
        }
      }

      // Navigate back to current page
      await _pageController.animateToPage(
        _currentPageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      if (pageImages.isEmpty) {
        throw Exception('No pages could be captured');
      }

      // Create PDF from images
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
      appBar: AppBar(
        title: SizedBox(
          width: 200,
          child: TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Note title',
            ),
            onChanged: (value) => _updateNote(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _currentPage.strokes.isEmpty ? null : _undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _undoStacks[_currentPageIndex].isEmpty ? null : _redo,
            tooltip: 'Redo',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
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
                    Icon(Icons.clear),
                    SizedBox(width: 8),
                    Text('Clear Page'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_page',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 8),
                    Text('Delete Page'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveNote,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(),
          _buildPageNavigation(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _note.pages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    color: _note.pages[index].backgroundColor,
                    child: GestureDetector(
                      key: _canvasKey,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        painter: EnhancedDrawingPainter(
                          page: _note.pages[index],
                          currentStroke: index == _currentPageIndex
                              ? _currentStroke
                              : [],
                          currentColor: _currentColor,
                          strokeWidth: _strokeWidth,
                          selectedItem: index == _currentPageIndex
                              ? _selectedItem
                              : null,
                          eraserPosition: index == _currentPageIndex
                              ? _eraserPosition
                              : null,
                          isErasing: _currentTool == DrawingTool.eraser,
                          imageCache: _imageCache,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
              icon: Icons.image,
              label: 'Image',
              isSelected: _currentTool == DrawingTool.image,
              onTap: () => setState(() => _currentTool = DrawingTool.image),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              icon: Icons.touch_app,
              label: 'Select',
              isSelected: _currentTool == DrawingTool.select,
              onTap: () => setState(() => _currentTool = DrawingTool.select),
            ),
            const SizedBox(width: 16),
            const VerticalDivider(),
            const SizedBox(width: 16),
            _buildColorButton(),
            const SizedBox(width: 16),
            _buildStrokeWidthSlider(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPageIndex > 0
                ? () {
                    setState(() {
                      _currentPageIndex--;
                      _pageController.animateToPage(
                        _currentPageIndex,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    });
                  }
                : null,
          ),
          Expanded(
            child: Center(
              child: Text(
                'Page ${_currentPageIndex + 1} of ${_note.pages.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPageIndex < _note.pages.length - 1
                ? () {
                    setState(() {
                      _currentPageIndex++;
                      _pageController.animateToPage(
                        _currentPageIndex,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    });
                  }
                : null,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewPage,
            tooltip: 'Add Page',
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer
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
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
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
                border: Border.all(color: Colors.grey, width: 2),
              ),
            ),
            const SizedBox(height: 4),
            const Text('Color', style: TextStyle(fontSize: 12)),
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
        Text(
          'Width: ${_strokeWidth.round()}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class EnhancedDrawingPainter extends CustomPainter {
  final NotePage page;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double strokeWidth;
  final dynamic selectedItem;
  final Offset? eraserPosition;
  final bool isErasing;
  final Map<String, ui.Image> imageCache;

  EnhancedDrawingPainter({
    required this.page,
    required this.currentStroke,
    required this.currentColor,
    required this.strokeWidth,
    this.selectedItem,
    this.eraserPosition,
    this.isErasing = false,
    this.imageCache = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in page.strokes) {
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

    // Draw current stroke
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

    // Draw images
    for (final image in page.images) {
      final imageRect = Rect.fromLTWH(
        image.position.dx,
        image.position.dy,
        image.width * image.scale,
        image.height * image.scale,
      );

      // Draw the actual image if available in cache
      final cachedImage = imageCache[image.id];
      if (cachedImage != null) {
        canvas.drawImageRect(
          cachedImage,
          Rect.fromLTWH(
            0,
            0,
            cachedImage.width.toDouble(),
            cachedImage.height.toDouble(),
          ),
          imageRect,
          Paint(),
        );
      } else {
        // Draw placeholder while image loads
        canvas.drawRect(
          imageRect,
          Paint()
            ..color = Colors.grey.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          imageRect,
          Paint()
            ..color = Colors.grey
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );

        // Draw loading icon
        final iconSize = (imageRect.width * 0.3).clamp(16.0, 48.0);
        final iconRect = Rect.fromCenter(
          center: imageRect.center,
          width: iconSize,
          height: iconSize,
        );

        final textPainter = TextPainter(
          text: const TextSpan(text: '🖼️', style: TextStyle(fontSize: 24)),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(
            iconRect.center.dx - textPainter.width / 2,
            iconRect.center.dy - textPainter.height / 2,
          ),
        );
      }

      // Draw selection box if selected
      if (image == selectedItem) {
        final selectionRect = Rect.fromLTWH(
          image.position.dx - 4,
          image.position.dy - 4,
          (image.width * image.scale) + 8,
          (image.height * image.scale) + 8,
        );
        canvas.drawRect(
          selectionRect,
          Paint()
            ..color = Colors.blue.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          selectionRect,
          Paint()
            ..color = Colors.blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    // Draw text notes
    for (final note in page.textNotes) {
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
      )..layout();

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
            ..color = Colors.blue.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          rect,
          Paint()
            ..color = Colors.blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      textPainter.paint(canvas, note.position);
    }

    // Draw eraser cursor
    if (isErasing && eraserPosition != null) {
      canvas.drawCircle(
        eraserPosition!,
        strokeWidth * 2,
        Paint()
          ..color = Colors.red.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );

      canvas.drawCircle(
        eraserPosition!,
        strokeWidth * 2,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant EnhancedDrawingPainter oldDelegate) {
    return true;
  }
}
