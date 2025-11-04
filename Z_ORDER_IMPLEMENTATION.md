# Z-Order System Implementation

## Overview
Implemented a Z-order layering system for the note-taking canvas that ensures intuitive stacking behavior where the most recently added element appears on top.

## Key Changes

### 1. DrawableElement Interface
Created a common interface for all drawable elements:
```dart
abstract class DrawableElement {
  DateTime get createdAt;
}
```

### 2. Creation Timestamps
Added `createdAt` timestamps to all drawable elements:
- **DrawingStroke**: Tracks when each stroke was drawn
- **TextNote**: Tracks when each text note was added
- **CanvasImage**: Tracks when each image was placed

All elements default to `DateTime.now()` if no timestamp is provided, ensuring backward compatibility.

### 3. Z-Order Method
Added `allElementsInZOrder` getter to `NotePage`:
```dart
List<DrawableElement> get allElementsInZOrder {
  final List<DrawableElement> allElements = [
    ...strokes,
    ...textNotes,
    ...images,
  ];
  
  // Sort by creation time - oldest first (bottom), newest last (top)
  allElements.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  
  return allElements;
}
```

### 4. Updated Painter
Refactored `EnhancedDrawingPainter` to:
- Use the z-order system for rendering all elements
- Extract drawing logic into separate methods (`_drawStroke`, `_drawImage`, `_drawTextNote`)
- Render elements in chronological order (oldest to newest)
- Keep current stroke and eraser cursor on top

### 5. Color Serialization Fix
Updated color serialization to use `toARGB32()` instead of deprecated `value` property:
- `DrawingStroke.toJson()`
- `TextNote.toJson()`
- `CanvasImage.toJson()`
- `NotePage.toJson()`

## How It Works

### Layering Behavior
1. **Add Drawing → Add Image**: Image appears on top of drawing
2. **Add Image → Add Drawing**: Drawing appears on top of image
3. **Add Text → Add Image**: Image appears on top of text
4. **Natural Stacking**: Each new element goes on top of previous ones

### Rendering Order
1. Background color
2. All elements sorted by `createdAt` (oldest first)
   - Strokes, images, and text are interleaved based on creation time
3. Current stroke being drawn (always on top)
4. Eraser cursor (always on top)

## User Experience

Users can now create layered compositions where:
- Images can serve as backgrounds for drawings
- Drawings can be added on top of images
- Text can overlay both images and drawings
- The most recent addition is always visible on top
- Natural, intuitive stacking behavior like professional drawing applications

## Backward Compatibility

The implementation maintains backward compatibility:
- Existing notes without timestamps will get `DateTime.now()` on load
- Legacy color format (int) is still supported via `_parseColor` helper
- All existing functionality remains unchanged

## Technical Benefits

1. **Clean Architecture**: Separation of concerns with `DrawableElement` interface
2. **Maintainable**: Drawing logic extracted into dedicated methods
3. **Extensible**: Easy to add new drawable element types
4. **Performant**: Single-pass rendering with sorted elements
5. **Type-Safe**: Proper type checking with interface implementation
