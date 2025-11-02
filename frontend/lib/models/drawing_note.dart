import 'dart:ui';
import 'dart:typed_data';

/// Helper function to parse color from either int or string format
Color _parseColor(dynamic colorValue) {
  if (colorValue is int) {
    // Legacy format - direct integer value
    return Color(colorValue);
  } else if (colorValue is String) {
    // New format - hex string
    final cleanHex = colorValue.replaceFirst('0x', '').replaceFirst('#', '');
    return Color(int.parse(cleanHex, radix: 16));
  } else {
    // Fallback to black
    return const Color(0xFF000000);
  }
}

/// Represents a drawing stroke on the canvas
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    'color': color.value,
    'strokeWidth': strokeWidth,
  };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      points: (json['points'] as List)
          .map((p) => Offset(p['x'] as double, p['y'] as double))
          .toList(),
      color: _parseColor(json['color']),
      strokeWidth: json['strokeWidth'] as double,
    );
  }
}

/// Represents a text note on the canvas
class TextNote {
  final String id;
  Offset position;
  String text;
  final Color color;
  final double fontSize;

  TextNote({
    required this.id,
    required this.position,
    required this.text,
    this.color = const Color(0xFF000000),
    this.fontSize = 16.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'position': {'x': position.dx, 'y': position.dy},
    'text': text,
    'color': color.value,
    'fontSize': fontSize,
  };

  factory TextNote.fromJson(Map<String, dynamic> json) {
    return TextNote(
      id: json['id'] as String,
      position: Offset(
        json['position']['x'] as double,
        json['position']['y'] as double,
      ),
      text: json['text'] as String,
      color: _parseColor(json['color']),
      fontSize: json['fontSize'] as double,
    );
  }
}

/// Represents an image on the canvas
class CanvasImage {
  final String id;
  Offset position;
  final Uint8List imageBytes;
  final double width;
  final double height;
  final double scale;

  CanvasImage({
    required this.id,
    required this.position,
    required this.imageBytes,
    required this.width,
    required this.height,
    this.scale = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'position': {'x': position.dx, 'y': position.dy},
    'imageBytes': imageBytes.toList(),
    'width': width,
    'height': height,
    'scale': scale,
  };

  factory CanvasImage.fromJson(Map<String, dynamic> json) {
    return CanvasImage(
      id: json['id'] as String,
      position: Offset(
        json['position']['x'] as double,
        json['position']['y'] as double,
      ),
      imageBytes: Uint8List.fromList((json['imageBytes'] as List).cast<int>()),
      width: json['width'] as double,
      height: json['height'] as double,
      scale: json['scale'] as double? ?? 1.0,
    );
  }
}

/// Represents a single page in a multi-page note
class NotePage {
  final String id;
  final List<DrawingStroke> strokes;
  final List<TextNote> textNotes;
  final List<CanvasImage> images;
  final Color backgroundColor;

  NotePage({
    required this.id,
    List<DrawingStroke>? strokes,
    List<TextNote>? textNotes,
    List<CanvasImage>? images,
    this.backgroundColor = const Color(0xFFFFFFFF),
  }) : strokes = strokes ?? <DrawingStroke>[],
       textNotes = textNotes ?? <TextNote>[],
       images = images ?? <CanvasImage>[];

  Map<String, dynamic> toJson() => {
    'id': id,
    'strokes': strokes.map((s) => s.toJson()).toList(),
    'textNotes': textNotes.map((t) => t.toJson()).toList(),
    'images': images.map((i) => i.toJson()).toList(),
    'backgroundColor': backgroundColor.value,
  };

  factory NotePage.fromJson(Map<String, dynamic> json) {
    return NotePage(
      id: json['id'] as String,
      strokes: (json['strokes'] as List? ?? [])
          .map((s) => DrawingStroke.fromJson(s))
          .toList(),
      textNotes: (json['textNotes'] as List? ?? [])
          .map((t) => TextNote.fromJson(t))
          .toList(),
      images: (json['images'] as List? ?? [])
          .map((i) => CanvasImage.fromJson(i))
          .toList(),
      backgroundColor: _parseColor(json['backgroundColor'] ?? '0xFFFFFFFF'),
    );
  }

  NotePage copyWith({
    String? id,
    List<DrawingStroke>? strokes,
    List<TextNote>? textNotes,
    List<CanvasImage>? images,
    Color? backgroundColor,
  }) {
    return NotePage(
      id: id ?? this.id,
      strokes: strokes ?? this.strokes,
      textNotes: textNotes ?? this.textNotes,
      images: images ?? this.images,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}

/// Represents a complete drawing note with multiple pages
class DrawingNote {
  final String id;
  final String title;
  final List<NotePage> pages;
  final DateTime createdAt;
  final DateTime updatedAt;

  DrawingNote({
    required this.id,
    required this.title,
    List<NotePage>? pages,
    required this.createdAt,
    required this.updatedAt,
  }) : pages = pages ?? [];

  // Legacy support - get strokes from first page
  List<DrawingStroke> get strokes =>
      pages.isNotEmpty ? pages.first.strokes : [];

  // Legacy support - get text notes from first page
  List<TextNote> get textNotes => pages.isNotEmpty ? pages.first.textNotes : [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'pages': pages.map((p) => p.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory DrawingNote.fromJson(Map<String, dynamic> json) {
    // Handle legacy format (single page with strokes/textNotes)
    if (json.containsKey('strokes') || json.containsKey('textNotes')) {
      final legacyPage = NotePage(
        id: 'page_1',
        strokes: (json['strokes'] as List? ?? [])
            .map((s) => DrawingStroke.fromJson(s))
            .toList(),
        textNotes: (json['textNotes'] as List? ?? [])
            .map((t) => TextNote.fromJson(t))
            .toList(),
      );

      return DrawingNote(
        id: json['id'] as String,
        title: json['title'] as String,
        pages: [legacyPage],
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
    }

    // Handle new multi-page format
    return DrawingNote(
      id: json['id'] as String,
      title: json['title'] as String,
      pages: (json['pages'] as List? ?? [])
          .map((p) => NotePage.fromJson(p))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  DrawingNote copyWith({
    String? id,
    String? title,
    List<NotePage>? pages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DrawingNote(
      id: id ?? this.id,
      title: title ?? this.title,
      pages: pages ?? this.pages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
