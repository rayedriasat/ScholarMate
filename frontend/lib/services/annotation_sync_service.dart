import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart';
import '../models/annotation.dart';
import '../database/database.dart';
import 'auth_service.dart';
import 'realtime_service.dart';

/// Service for syncing annotations with backend
class AnnotationSyncService extends ChangeNotifier {
  final AppDatabase _database;
  final AuthService _authService;
  final String _baseUrl;
  final RealtimeService? _realtimeService;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastSyncError;

  AnnotationSyncService({
    required AppDatabase database,
    required AuthService authService,
    required String baseUrl,
    RealtimeService? realtimeService,
  }) : _database = database,
       _authService = authService,
       _baseUrl = baseUrl,
       _realtimeService = realtimeService;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastSyncError => _lastSyncError;

  /// Fetch latest annotations from backend for a file
  Future<List<PdfAnnotation>> fetchAnnotations(String fileId) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/annotations/$fileId?user_id=${user.id}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final annotations = (data['annotations'] as List)
            .map((json) => _annotationFromJson(json))
            .toList();

        // Update local cache
        for (final annotation in annotations) {
          await _database.insertAnnotation(
            AnnotationsCompanion.insert(
              id: annotation.id,
              fileId: annotation.fileId,
              pageNumber: annotation.pageNumber,
              annotationType: annotation.type.toString(),
              content: Value(annotation.content),
              position: Value(
                annotation.boundingBox != null
                    ? '${annotation.boundingBox!.left},${annotation.boundingBox!.top},${annotation.boundingBox!.right},${annotation.boundingBox!.bottom}'
                    : null,
              ),
              color: Value('0x${annotation.color.value.toRadixString(16)}'),
              createdAt: annotation.createdAt,
              modifiedAt: annotation.modifiedAt,
              isSynced: const Value(true),
              authorId: Value(annotation.authorId),
              authorName: Value(annotation.authorName),
            ),
          );
        }

        _lastSyncTime = DateTime.now();
        _lastSyncError = null;
        notifyListeners();

        return annotations;
      } else {
        throw Exception('Failed to fetch annotations: ${response.statusCode}');
      }
    } catch (e) {
      _lastSyncError = e.toString();
      notifyListeners();
      debugPrint('Error fetching annotations: $e');
      rethrow;
    }
  }

  /// Sync offline annotations to backend
  Future<Map<String, dynamic>> syncOfflineAnnotations(String fileId) async {
    if (_isSyncing) {
      return {'success': false, 'message': 'Sync already in progress'};
    }

    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get unsynced annotations for this file
      final unsyncedAnnotations = await _database.getUnsyncedAnnotations();
      final fileAnnotations = unsyncedAnnotations
          .where((a) => a.fileId == fileId)
          .toList();

      if (fileAnnotations.isEmpty) {
        _isSyncing = false;
        notifyListeners();
        return {
          'success': true,
          'synced_count': 0,
          'message': 'No annotations to sync',
        };
      }

      // Convert to JSON format
      final annotationsJson = fileAnnotations.map((a) {
        return {
          'id': a.id,
          'file_id': fileId,
          'annotation_type': a.annotationType,
          'page_number': a.pageNumber,
          'position_data': _parsePositionData(a.position),
          'content': a.content,
          'color': a.color,
          'created_at': a.createdAt.toIso8601String(),
          'updated_at': a.modifiedAt.toIso8601String(),
        };
      }).toList();

      // Send sync request
      final response = await http.post(
        Uri.parse(
          '$_baseUrl/api/annotations/sync?user_id=${user.id}&file_id=$fileId',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'annotations': annotationsJson}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        // Mark synced annotations as synced in local database
        for (final annotation in fileAnnotations) {
          await _database.markAnnotationSynced(annotation.id);
        }

        // Check for conflicts
        final conflicts = result['conflicts'] as List?;
        if (conflicts != null && conflicts.isNotEmpty) {
          // Store conflicts for UI to display
          result['has_conflicts'] = true;
          result['conflict_details'] = conflicts;
          debugPrint('Sync completed with ${conflicts.length} conflicts');
        }

        _lastSyncTime = DateTime.now();
        _lastSyncError = null;
        _isSyncing = false;
        notifyListeners();

        return result;
      } else {
        throw Exception('Failed to sync annotations: ${response.statusCode}');
      }
    } catch (e) {
      _lastSyncError = e.toString();
      _isSyncing = false;
      notifyListeners();
      debugPrint('Error syncing annotations: $e');
      rethrow;
    }
  }

  /// Create annotation online (immediate sync)
  Future<PdfAnnotation?> createAnnotationOnline({
    required String fileId,
    required int pageNumber,
    required AnnotationType type,
    required Rect boundingBox,
    required Color color,
    String? content,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final annotationData = {
        'file_id': fileId,
        'annotation_type': type.toString(),
        'page_number': pageNumber,
        'position_data': {
          'left': boundingBox.left,
          'top': boundingBox.top,
          'right': boundingBox.right,
          'bottom': boundingBox.bottom,
        },
        'content': content,
        'color': '#${color.value.toRadixString(16).substring(2)}',
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/api/annotations/?user_id=${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(annotationData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final annotation = _annotationFromJson(data);

        // Update local cache
        await _database.insertAnnotation(
          AnnotationsCompanion.insert(
            id: annotation.id,
            fileId: annotation.fileId,
            pageNumber: annotation.pageNumber,
            annotationType: annotation.type.toString(),
            content: Value(annotation.content),
            position: Value(
              annotation.boundingBox != null
                  ? '${annotation.boundingBox!.left},${annotation.boundingBox!.top},${annotation.boundingBox!.right},${annotation.boundingBox!.bottom}'
                  : null,
            ),
            color: Value('0x${annotation.color.value.toRadixString(16)}'),
            createdAt: annotation.createdAt,
            modifiedAt: annotation.modifiedAt,
            isSynced: const Value(true),
            authorId: Value(user.id),
            authorName: Value(user.displayName),
          ),
        );

        // Broadcast annotation event (Supabase Realtime will handle this automatically)
        // This is just for explicit error handling
        try {
          await _realtimeService?.broadcastAnnotation(annotation, 'create');
        } catch (e) {
          debugPrint('Error broadcasting annotation: $e');
          // Don't fail the operation if broadcast fails
        }

        notifyListeners();
        return annotation;
      } else {
        throw Exception('Failed to create annotation: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating annotation online: $e');
      return null;
    }
  }

  /// Update annotation online
  Future<bool> updateAnnotationOnline(PdfAnnotation annotation) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final updateData = {
        'annotation_type': annotation.type.toString(),
        'page_number': annotation.pageNumber,
        'position_data': annotation.boundingBox != null
            ? {
                'left': annotation.boundingBox!.left,
                'top': annotation.boundingBox!.top,
                'right': annotation.boundingBox!.right,
                'bottom': annotation.boundingBox!.bottom,
              }
            : null,
        'content': annotation.content,
        'color': '#${annotation.color.value.toRadixString(16).substring(2)}',
      };

      final response = await http.put(
        Uri.parse(
          '$_baseUrl/api/annotations/${annotation.id}?user_id=${user.id}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        // Update local cache
        await _database.updateAnnotation(
          AnnotationsCompanion.insert(
            id: annotation.id,
            fileId: annotation.fileId,
            pageNumber: annotation.pageNumber,
            annotationType: annotation.type.toString(),
            content: Value(annotation.content),
            position: Value(
              annotation.boundingBox != null
                  ? '${annotation.boundingBox!.left},${annotation.boundingBox!.top},${annotation.boundingBox!.right},${annotation.boundingBox!.bottom}'
                  : null,
            ),
            color: Value('0x${annotation.color.value.toRadixString(16)}'),
            createdAt: annotation.createdAt,
            modifiedAt: DateTime.now(),
            isSynced: const Value(true),
          ),
        );

        // Broadcast annotation update event
        try {
          await _realtimeService?.broadcastAnnotation(annotation, 'update');
        } catch (e) {
          debugPrint('Error broadcasting annotation update: $e');
          // Don't fail the operation if broadcast fails
        }

        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to update annotation: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating annotation online: $e');
      return false;
    }
  }

  /// Delete annotation online
  Future<bool> deleteAnnotationOnline(String annotationId) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/annotations/$annotationId?user_id=${user.id}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204) {
        // Delete from local cache
        await _database.deleteAnnotation(annotationId);

        // Broadcast annotation delete event
        // Note: We can't pass the full annotation object since it's deleted
        // The realtime service will handle this through Postgres changes
        try {
          // The Supabase Realtime will automatically broadcast the delete event
          // when the annotation is deleted from the database
        } catch (e) {
          debugPrint('Error broadcasting annotation delete: $e');
          // Don't fail the operation if broadcast fails
        }

        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to delete annotation: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting annotation online: $e');
      return false;
    }
  }

  /// Parse position data from string format
  Map<String, double>? _parsePositionData(String? position) {
    if (position == null) return null;

    try {
      final parts = position.split(',');
      if (parts.length == 4) {
        return {
          'left': double.parse(parts[0]),
          'top': double.parse(parts[1]),
          'right': double.parse(parts[2]),
          'bottom': double.parse(parts[3]),
        };
      }
    } catch (e) {
      debugPrint('Error parsing position data: $e');
    }
    return null;
  }

  /// Convert JSON to PdfAnnotation
  PdfAnnotation _annotationFromJson(Map<String, dynamic> json) {
    final positionData = json['position_data'] as Map<String, dynamic>?;
    Rect? boundingBox;
    if (positionData != null) {
      boundingBox = Rect.fromLTRB(
        (positionData['left'] as num).toDouble(),
        (positionData['top'] as num).toDouble(),
        (positionData['right'] as num).toDouble(),
        (positionData['bottom'] as num).toDouble(),
      );
    }

    // Parse color from hex string
    String colorStr = json['color'] as String? ?? '#FFFF00';
    if (colorStr.startsWith('#')) {
      colorStr = colorStr.substring(1);
    }
    if (colorStr.length == 6) {
      colorStr = 'FF$colorStr'; // Add alpha channel
    }
    final colorValue = int.parse(colorStr, radix: 16);

    return PdfAnnotation(
      id: json['id'] as String,
      fileId: json['file_id'] as String,
      pageNumber: json['page_number'] as int,
      type: AnnotationType.fromString(json['annotation_type'] as String),
      content: json['content'] as String?,
      boundingBox: boundingBox,
      color: Color(colorValue),
      createdAt: DateTime.parse(json['created_at'] as String),
      modifiedAt: DateTime.parse(json['updated_at'] as String),
      isSynced: true,
      authorId: json['user_id'] as String?,
      authorName: null, // Not provided by backend
    );
  }
}
