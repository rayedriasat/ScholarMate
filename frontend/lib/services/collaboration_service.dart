/// Collaboration service for real-time PDF sessions
library;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/collaboration.dart';
import 'config_service.dart';

class CollaborationService {
  final ConfigService _config;
  final SupabaseClient _supabase;

  // Active session state
  CollaborationSession? _currentSession;
  StreamSubscription? _participantSubscription;

  // Real-time streams
  final _participantUpdatesController =
      StreamController<SessionParticipant>.broadcast();
  final _annotationUpdatesController =
      StreamController<CollaborationAnnotation>.broadcast();

  Stream<SessionParticipant> get participantUpdates =>
      _participantUpdatesController.stream;
  Stream<CollaborationAnnotation> get annotationUpdates =>
      _annotationUpdatesController.stream;

  CollaborationSession? get currentSession => _currentSession;

  CollaborationService(this._config, this._supabase);

  /// Create new collaboration session
  Future<CollaborationSession> createSession({
    required String fileId,
    required String fileName,
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
    SessionRole defaultRole = SessionRole.editor,
  }) async {
    final url = Uri.parse('${_config.backendUrl}/api/collaboration/sessions');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'file_id': fileId,
        'file_name': fileName,
        'owner_id': ownerId,
        'owner_name': ownerName,
        'owner_email': ownerEmail,
        'default_role': defaultRole.name,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create session: ${response.body}');
    }

    final session = CollaborationSession.fromJson(jsonDecode(response.body));
    _currentSession = session;

    // Subscribe to real-time updates
    await _subscribeToSession(session.sessionId);

    return session;
  }

  /// Join existing session
  Future<CollaborationSession> joinSession({
    required String sessionId,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    final url = Uri.parse(
      '${_config.backendUrl}/api/collaboration/sessions/join',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'session_id': sessionId,
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to join session: ${response.body}');
    }

    final session = CollaborationSession.fromJson(jsonDecode(response.body));
    _currentSession = session;

    // Subscribe to real-time updates
    await _subscribeToSession(sessionId);

    return session;
  }

  /// Leave current session
  Future<void> leaveSession(String userId) async {
    if (_currentSession == null) return;

    final url = Uri.parse(
      '${_config.backendUrl}/api/collaboration/sessions/${_currentSession!.sessionId}/leave?user_id=$userId',
    );

    await http.delete(url);

    // Cleanup
    await _participantSubscription?.cancel();
    _currentSession = null;
  }

  /// Update cursor position (throttled)
  Timer? _cursorThrottle;
  Future<void> updateCursor({
    required String userId,
    CursorPosition? position,
  }) async {
    if (_currentSession == null) return;

    // Throttle cursor updates to max 10/sec
    if (_cursorThrottle?.isActive ?? false) return;

    _cursorThrottle = Timer(const Duration(milliseconds: 100), () {});

    final url = Uri.parse(
      '${_config.backendUrl}/api/collaboration/sessions/${_currentSession!.sessionId}/cursor',
    );

    // Fire and forget (don't await)
    http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'session_id': _currentSession!.sessionId,
            'user_id': userId,
            'cursor_position': position?.toJson(),
          }),
        )
        .catchError(
          (_) => http.Response('', 500),
        ); // Ignore errors for cursor updates
  }

  /// Add annotation to session
  Future<void> addAnnotation(CollaborationAnnotation annotation) async {
    if (_currentSession == null) return;

    final url = Uri.parse(
      '${_config.backendUrl}/api/collaboration/sessions/${_currentSession!.sessionId}/annotations',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': _currentSession!.sessionId,
          'annotation': annotation.toJson(),
          'action': 'create', // Required by backend
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add annotation: ${response.body}');
      }
    } catch (e) {
      print('Error adding annotation: $e');
      rethrow;
    }
  }

  /// Get all annotations for current session
  Future<List<CollaborationAnnotation>> getAnnotations() async {
    if (_currentSession == null) return [];

    final url = Uri.parse(
      '${_config.backendUrl}/api/collaboration/sessions/${_currentSession!.sessionId}/annotations',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Failed to get annotations: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final annotations = (data['annotations'] as List)
          .map((a) => CollaborationAnnotation.fromJson(a))
          .toList();

      return annotations;
    } catch (e) {
      print('Error getting annotations: $e');
      return [];
    }
  }

  /// Delete annotation
  Future<void> deleteAnnotation(String annotationId, String userId) async {
    if (_currentSession == null) return;

    final url = Uri.parse(
      '${_config.backendUrl}/api/collaboration/sessions/${_currentSession!.sessionId}/annotations/$annotationId?user_id=$userId',
    );

    try {
      await http.delete(url);
    } catch (e) {
      print('Error deleting annotation: $e');
      rethrow;
    }
  }

  /// Subscribe to Supabase Realtime for session updates
  StreamSubscription? _annotationSubscription;

  Future<void> _subscribeToSession(String sessionId) async {
    // Subscribe to participant changes
    _participantSubscription = _supabase
        .from('session_participants')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .listen((data) {
          if (_currentSession == null) return;

          // Update participants list
          final participants = data
              .map((p) => SessionParticipant.fromJson(p))
              .toList();

          _currentSession = _currentSession!.copyWith(
            participants: participants,
          );

          // Emit individual participant updates
          for (final participant in participants) {
            _participantUpdatesController.add(participant);
          }
        });

    // Subscribe to annotation changes
    _annotationSubscription = _supabase
        .from('collaboration_annotations')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .listen((data) {
          for (final annotationData in data) {
            final annotation = CollaborationAnnotation.fromJson(annotationData);
            _annotationUpdatesController.add(annotation);
          }
        });
  }

  /// Get session by ID
  Future<CollaborationSession> getSession(String sessionId) async {
    final url = Uri.parse(
      '${_config.backendUrl}/api/collaboration/sessions/$sessionId',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to get session: ${response.body}');
    }

    return CollaborationSession.fromJson(jsonDecode(response.body));
  }

  void dispose() {
    _participantSubscription?.cancel();
    _annotationSubscription?.cancel();
    _participantUpdatesController.close();
    _annotationUpdatesController.close();
    _cursorThrottle?.cancel();
  }
}
