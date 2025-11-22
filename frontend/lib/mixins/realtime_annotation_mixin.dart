/// Mixin for adding realtime annotation support to PDF viewers
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/realtime_service.dart';
import '../models/annotation.dart';

/// Mixin that adds realtime annotation capabilities to a State class
mixin RealtimeAnnotationMixin<T extends StatefulWidget> on State<T> {
  RealtimeService? _realtimeService;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;
  String? _currentFileId;

  /// Initialize realtime annotation support for a file
  Future<void> initializeRealtimeAnnotations({
    required String fileId,
    required RealtimeService realtimeService,
  }) async {
    _currentFileId = fileId;
    _realtimeService = realtimeService;

    // Subscribe to file channel
    await _realtimeService?.subscribeToFile(fileId);

    // Listen to realtime events
    _realtimeSubscription = _realtimeService?.eventStream.listen((event) {
      if (!mounted) return;

      switch (event.type) {
        case RealtimeEventType.annotationCreated:
          _handleAnnotationCreated(event.data);
          break;
        case RealtimeEventType.annotationUpdated:
          _handleAnnotationUpdated(event.data);
          break;
        case RealtimeEventType.annotationDeleted:
          _handleAnnotationDeleted(event.data);
          break;
        default:
          break;
      }
    });
  }

  /// Handle annotation created event
  void _handleAnnotationCreated(Map<String, dynamic> data) {
    if (!mounted) return;

    try {
      final annotation = _parseAnnotation(data);
      if (annotation == null) return;

      // Show notification
      _showAnnotationNotification(
        '${annotation.authorName ?? "Someone"} added ${annotation.type.toString()} on page ${annotation.pageNumber}',
        annotation,
      );

      // Trigger UI update
      onAnnotationCreated(annotation);
    } catch (e) {
      debugPrint('Error handling annotation created: $e');
    }
  }

  /// Handle annotation updated event
  void _handleAnnotationUpdated(Map<String, dynamic> data) {
    if (!mounted) return;

    try {
      final annotation = _parseAnnotation(data);
      if (annotation == null) return;

      // Show notification
      _showAnnotationNotification(
        '${annotation.authorName ?? "Someone"} updated ${annotation.type.toString()} on page ${annotation.pageNumber}',
        annotation,
      );

      // Trigger UI update
      onAnnotationUpdated(annotation);
    } catch (e) {
      debugPrint('Error handling annotation updated: $e');
    }
  }

  /// Handle annotation deleted event
  void _handleAnnotationDeleted(Map<String, dynamic> data) {
    if (!mounted) return;

    try {
      final annotationId = data['annotation_id'] as String?;
      if (annotationId == null) return;

      // Show notification
      _showAnnotationNotification(
        'An annotation was deleted',
        null,
      );

      // Trigger UI update
      onAnnotationDeleted(annotationId);
    } catch (e) {
      debugPrint('Error handling annotation deleted: $e');
    }
  }

  /// Parse annotation from realtime event data
  PdfAnnotation? _parseAnnotation(Map<String, dynamic> data) {
    try {
      // Parse position data
      final positionData = data['position_data'] as Map<String, dynamic>?;
      Rect? boundingBox;
      if (positionData != null) {
        boundingBox = Rect.fromLTRB(
          (positionData['left'] as num).toDouble(),
          (positionData['top'] as num).toDouble(),
          (positionData['right'] as num).toDouble(),
          (positionData['bottom'] as num).toDouble(),
        );
      }

      // Parse color
      String colorStr = data['color'] as String? ?? '#FFFF00';
      if (colorStr.startsWith('#')) {
        colorStr = colorStr.substring(1);
      }
      if (colorStr.length == 6) {
        colorStr = 'FF$colorStr'; // Add alpha channel
      }
      final colorValue = int.parse(colorStr, radix: 16);

      return PdfAnnotation(
        id: data['id'] as String,
        fileId: data['file_id'] as String,
        pageNumber: data['page_number'] as int,
        type: AnnotationType.fromString(data['annotation_type'] as String),
        content: data['content'] as String?,
        boundingBox: boundingBox,
        color: Color(colorValue),
        createdAt: DateTime.parse(data['created_at'] as String),
        modifiedAt: DateTime.parse(data['updated_at'] as String),
        isSynced: true,
        authorId: data['user_id'] as String?,
        authorName: data['author_name'] as String?,
      );
    } catch (e) {
      debugPrint('Error parsing annotation: $e');
      return null;
    }
  }

  /// Show notification for annotation event
  void _showAnnotationNotification(String message, PdfAnnotation? annotation) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              annotation?.type.icon ?? Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: annotation != null
            ? SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  onAnnotationTapped(annotation);
                },
              )
            : null,
      ),
    );
  }

  /// Cleanup realtime resources
  Future<void> disposeRealtimeAnnotations() async {
    await _realtimeSubscription?.cancel();
    if (_currentFileId != null) {
      await _realtimeService?.unsubscribe('file:$_currentFileId');
    }
    _realtimeSubscription = null;
    _realtimeService = null;
    _currentFileId = null;
  }

  /// Override these methods in your State class to handle annotation events

  /// Called when a new annotation is created by another user
  void onAnnotationCreated(PdfAnnotation annotation) {
    // Override in your State class to update UI
    debugPrint('Annotation created: ${annotation.id}');
  }

  /// Called when an annotation is updated by another user
  void onAnnotationUpdated(PdfAnnotation annotation) {
    // Override in your State class to update UI
    debugPrint('Annotation updated: ${annotation.id}');
  }

  /// Called when an annotation is deleted by another user
  void onAnnotationDeleted(String annotationId) {
    // Override in your State class to update UI
    debugPrint('Annotation deleted: $annotationId');
  }

  /// Called when user taps on an annotation notification
  void onAnnotationTapped(PdfAnnotation annotation) {
    // Override in your State class to navigate to annotation
    debugPrint('Annotation tapped: ${annotation.id}');
  }
}
