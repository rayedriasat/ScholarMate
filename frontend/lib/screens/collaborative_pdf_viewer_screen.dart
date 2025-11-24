/// Collaborative PDF viewer with real-time annotations and cursors
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/collaboration.dart';
import '../services/collaboration_service.dart';
import '../services/auth_service.dart';
import '../services/drive_service.dart';
import '../services/realtime_service.dart';
import '../services/sharing_service.dart';
import '../widgets/collaboration_panel.dart';
import '../widgets/collaboration_cursor.dart';
import '../widgets/annotation_toolbar.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../theme/app_colors.dart';

// Share Session ID Dialog widget
class ShareSessionDialog extends StatelessWidget {
  final String sessionId;

  const ShareSessionDialog({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Share Session ID',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share this Session ID with others to collaborate:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: SelectableText(
              sessionId,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Others can join by:\n'
            '1. Going to Files → Menu (⋮)\n'
            '2. Selecting "Join Collaboration"\n'
            '3. Entering this Session ID',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ModernButton(
          onPressed: () {
            // Copy to clipboard
            Clipboard.setData(ClipboardData(text: sessionId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Session ID copied to clipboard')),
            );
          },
          icon: Icons.copy,
          label: 'Copy ID',
          width: 120,
          height: 36,
        ),
      ],
    );
  }
}

class CollaborativePdfViewerScreen extends StatefulWidget {
  final String fileId;
  final String fileName;
  final String? sessionId; // If joining existing session
  final Uint8List? pdfBytes; // Optional: PDF bytes if already loaded

  const CollaborativePdfViewerScreen({
    super.key,
    required this.fileId,
    required this.fileName,
    this.sessionId,
    this.pdfBytes,
  });

  @override
  State<CollaborativePdfViewerScreen> createState() =>
      _CollaborativePdfViewerScreenState();
}

class _CollaborativePdfViewerScreenState
    extends State<CollaborativePdfViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  CollaborationService? _collaborationService;
  CollaborationSession? _session;
  bool _isLoading = true;
  String? _error;
  Uint8List? _pdfBytes; // Store PDF bytes

  // Track PDF view size for cursor positioning
  Size _pdfViewSize = Size.zero;

  // Annotation state
  PdfAnnotationMode _annotationMode = PdfAnnotationMode.none;
  Color _annotationColor = const Color(0xFFFFEB3B); // Yellow

  @override
  void initState() {
    super.initState();
    _initializeCollaboration();
    _initializeRealtime();
  }

  Future<void> _initializeRealtime() async {
    // Add realtime annotation support
    try {
      final realtimeService = context.read<RealtimeService>();
      await realtimeService.subscribeToFile(widget.fileId);

      // Listen to realtime annotation events
      realtimeService.eventStream.listen((event) {
        if (!mounted) return;

        switch (event.type) {
          case RealtimeEventType.annotationCreated:
            _handleRealtimeAnnotationCreated(event.data);
            break;
          case RealtimeEventType.annotationUpdated:
            _handleRealtimeAnnotationUpdated(event.data);
            break;
          case RealtimeEventType.annotationDeleted:
            _handleRealtimeAnnotationDeleted(event.data);
            break;
          default:
            break;
        }
      });
    } catch (e) {
      debugPrint('Error initializing realtime: $e');
    }
  }

  void _handleRealtimeAnnotationCreated(Map<String, dynamic> data) {
    final authorId = data['user_id'] as String?;
    final authService = context.read<AuthService>();

    // Don't show notification for own annotations
    if (authorId == authService.currentUser?.id) return;

    final authorName = data['author_name'] as String? ?? 'Someone';
    final annotationType = data['annotation_type'] as String? ?? 'annotation';
    final pageNumber = data['page_number'] as int? ?? 0;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$authorName added $annotationType on page $pageNumber'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            _pdfController.jumpToPage(pageNumber);
          },
        ),
      ),
    );
  }

  void _handleRealtimeAnnotationUpdated(Map<String, dynamic> data) {
    final authorId = data['user_id'] as String?;
    final authService = context.read<AuthService>();

    if (authorId == authService.currentUser?.id) return;

    final authorName = data['author_name'] as String? ?? 'Someone';
    debugPrint('$authorName updated an annotation');
  }

  void _handleRealtimeAnnotationDeleted(Map<String, dynamic> data) {
    final authorId = data['user_id'] as String?;
    final authService = context.read<AuthService>();

    if (authorId == authService.currentUser?.id) return;

    debugPrint('An annotation was deleted');
  }

  Future<void> _initializeCollaboration() async {
    try {
      final authService = context.read<AuthService>();
      final user = authService.currentUser;

      if (user == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Check if file is shared before creating collaboration (only for new sessions)
      if (widget.sessionId == null) {
        final sharingService = context.read<SharingService>();
        try {
          final collaborators = await sharingService.listCollaborators(
            widget.fileId,
          );

          if (collaborators.isEmpty) {
            // File is not shared with anyone
            setState(() {
              _error = 'Please share this PDF via Gmail first';
              _isLoading = false;
            });

            // Show helpful dialog
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: Row(
                      children: [
                        Icon(Icons.share, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Share First',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'To start a collaboration session, you need to share this PDF with collaborators first.',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Steps:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Go back to the file list',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          '2. Click the ⋮ menu on the PDF',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          '3. Select "Share file"',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          '4. Add collaborators with Gmail addresses',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          '5. Then start the collaboration session',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      ModernButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Go back to file list
                        },
                        icon: Icons.arrow_back,
                        label: 'Go Back to Share',
                        backgroundColor: Colors.orange,
                      ),
                    ],
                  ),
                );
              });
            }
            return;
          }
        } catch (e) {
          debugPrint('Error checking file shares: $e');
          // Continue anyway if we can't check shares
        }
      }

      _collaborationService = context.read<CollaborationService>();

      // Join or create session
      if (widget.sessionId != null) {
        // Join existing session
        _session = await _collaborationService!.joinSession(
          sessionId: widget.sessionId!,
          userId: user.id,
          userName: user.name ?? user.email,
          userEmail: user.email,
        );
      } else {
        // Create new session
        _session = await _collaborationService!.createSession(
          fileId: widget.fileId,
          fileName: widget.fileName,
          ownerId: user.id,
          ownerName: user.name ?? user.email,
          ownerEmail: user.email,
        );
      }

      // Load PDF - use provided bytes or fetch from backend
      if (widget.pdfBytes != null) {
        _pdfBytes = widget.pdfBytes;
      } else {
        await _loadPdfFromDrive();
      }

      // Listen to participant updates
      _collaborationService!.participantUpdates.listen((participant) {
        if (mounted) {
          setState(() {
            // Update session with new participant data
            final index = _session!.participants.indexWhere(
              (p) => p.userId == participant.userId,
            );
            if (index != -1) {
              final updated = List<SessionParticipant>.from(
                _session!.participants,
              );
              updated[index] = participant;
              _session = _session!.copyWith(participants: updated);
            }
          });
        }
      });

      // Listen to annotation updates from other users
      _collaborationService!.annotationUpdates.listen((annotation) {
        if (mounted) {
          // Show snackbar notification when other user adds annotation
          final authService = context.read<AuthService>();
          if (annotation.userId != authService.currentUser?.id) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${annotation.userName} added ${annotation.annotationType} on page ${annotation.pageNumber}',
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );

            // TODO: Render annotation on PDF
            // Syncfusion doesn't support programmatic annotation addition easily
            // For now, users need to refresh or reload to see others' annotations
          }
        }
      });

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPdfFromDrive() async {
    try {
      // For User B joining: Try to load from their Drive cache first
      // If the file was previously opened, it will be in cache
      final driveService = context.read<DriveService>();

      try {
        // Try to download from Drive (will use cache if available)
        _pdfBytes = await driveService.downloadFile(widget.fileId);

        if (_pdfBytes != null && _pdfBytes!.isNotEmpty) {
          return; // Successfully loaded
        }
      } catch (e) {
        debugPrint('Could not load from Drive: $e');
      }

      // Fallback: Use backend proxy endpoint
      final authService = context.read<AuthService>();
      final user = authService.currentUser;

      if (user == null || _session == null) {
        throw Exception('Not authenticated or no session');
      }

      const backendUrl = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8000',
      );

      final url = Uri.parse(
        '$backendUrl/api/collaboration/sessions/${_session!.sessionId}/pdf?user_id=${user.id}',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Failed to load PDF: ${response.statusCode}');
      }

      _pdfBytes = response.bodyBytes;

      if (_pdfBytes == null || _pdfBytes!.isEmpty) {
        throw Exception('PDF data is empty');
      }
    } catch (e) {
      throw Exception('Failed to load PDF: $e');
    }
  }

  void _onPointerMove(PointerEvent details) {
    if (_session == null || _pdfViewSize == Size.zero) return;

    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) return;

    // Normalize cursor position
    final x = details.localPosition.dx / _pdfViewSize.width;
    final y = details.localPosition.dy / _pdfViewSize.height;

    final position = CursorPosition(
      x: x.clamp(0.0, 1.0),
      y: y.clamp(0.0, 1.0),
      pageNumber: _pdfController.pageNumber,
    );

    _collaborationService?.updateCursor(userId: user.id, position: position);
  }

  Future<void> _leaveSession() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;

    if (user != null && _collaborationService != null) {
      await _collaborationService!.leaveSession(user.id);
    }

    // Cleanup realtime subscription
    try {
      final realtimeService = context.read<RealtimeService>();
      realtimeService.unsubscribe('file:${widget.fileId}');
    } catch (e) {
      debugPrint('Error cleaning up realtime: $e');
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showShareDialog() {
    if (_session == null) return;

    showDialog(
      context: context,
      builder: (context) => ShareSessionDialog(sessionId: _session!.sessionId),
    );
  }

  Future<void> _refreshAnnotations() async {
    if (_collaborationService == null) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Refreshing annotations...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Get all annotations from database
      final annotations = await _collaborationService!.getAnnotations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Loaded ${annotations.length} annotations from other users',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Show dialog with annotation list
        if (annotations.isNotEmpty) {
          _showAnnotationsDialog(annotations);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAnnotationsDialog(List<CollaborationAnnotation> annotations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Collaboration Annotations',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: annotations.length,
            itemBuilder: (context, index) {
              final annotation = annotations[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: annotation.userColor,
                  radius: 12,
                ),
                title: Text(
                  annotation.userName,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${annotation.annotationType} on page ${annotation.pageNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                trailing: Text(
                  _formatTime(annotation.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                onTap: () {
                  // Jump to page
                  Navigator.pop(context);
                  _pdfController.jumpToPage(annotation.pageNumber);
                },
              );
            },
          ),
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // Annotation callbacks
  Future<void> _onAnnotationAdded(Annotation annotation) async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null || _collaborationService == null) return;

    // Find participant to get color
    final participant = _session?.participants.firstWhere(
      (p) => p.userId == user.id,
      orElse: () => _session!.participants.first,
    );

    if (participant == null) return;

    // Convert Syncfusion annotation to collaboration annotation
    // Get bounds based on annotation type
    final bounds = _getAnnotationBounds(annotation);

    final collabAnnotation = CollaborationAnnotation(
      id: annotation.hashCode.toString(),
      userId: user.id,
      userName: user.name ?? user.email,
      userColor: participant.userColor,
      annotationType: _getAnnotationType(annotation),
      pageNumber: annotation.pageNumber,
      positionData: {'bounds': bounds},
      color: _annotationColor.value.toRadixString(16),
      createdAt: DateTime.now(),
    );

    try {
      await _collaborationService!.addAnnotation(collabAnnotation);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save annotation: $e')),
        );
      }
    }
  }

  Future<void> _onAnnotationEdited(Annotation annotation) async {
    // For now, treat as add (could implement update later)
    await _onAnnotationAdded(annotation);
  }

  Future<void> _onAnnotationRemoved(Annotation annotation) async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null || _collaborationService == null) return;

    try {
      await _collaborationService!.deleteAnnotation(
        annotation.hashCode.toString(),
        user.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete annotation: $e')),
        );
      }
    }
  }

  String _getAnnotationType(Annotation annotation) {
    if (annotation is HighlightAnnotation) return 'highlight';
    if (annotation is UnderlineAnnotation) return 'underline';
    if (annotation is StrikethroughAnnotation) return 'strikethrough';
    if (annotation is SquigglyAnnotation) return 'squiggly';
    if (annotation is StickyNoteAnnotation) return 'sticky_note';
    return 'unknown';
  }

  Map<String, dynamic> _getAnnotationBounds(Annotation annotation) {
    // Syncfusion annotations don't expose bounds directly
    // Store minimal data - the actual annotation is managed by Syncfusion
    return {
      'annotation_hash': annotation.hashCode,
      'page': annotation.pageNumber,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'Loading...',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Error', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ModernButton(
                onPressed: () => Navigator.pop(context),
                label: 'Go Back',
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.fileName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Collaboration panel with refresh button
          if (_session != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassContainer(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.surface,
                    child: CollaborationPanel(
                      session: _session!,
                      onLeave: _leaveSession,
                      onShare: _showShareDialog,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Refresh annotations button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ModernButton(
                      onPressed: _refreshAnnotations,
                      icon: Icons.refresh,
                      label: 'Refresh to See Latest Annotations',
                      backgroundColor: AppColors.primary,
                      height: 48,
                    ),
                  ),
                ],
              ),
            ),

          // PDF viewer with cursor overlay
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _pdfViewSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return MouseRegion(
                  onHover: _onPointerMove,
                  child: Stack(
                    children: [
                      // PDF viewer
                      if (_pdfBytes != null)
                        SfPdfViewer.memory(
                          _pdfBytes!,
                          controller: _pdfController,
                          onAnnotationAdded: _onAnnotationAdded,
                          onAnnotationEdited: _onAnnotationEdited,
                          onAnnotationRemoved: _onAnnotationRemoved,
                        )
                      else
                        const Center(
                          child: Text(
                            'Loading PDF...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),

                      // Other users' cursors
                      if (_session != null)
                        ..._session!.participants
                            .where(
                              (p) =>
                                  p.userId !=
                                  context.read<AuthService>().currentUser?.id,
                            )
                            .map(
                              (p) => CollaborationCursor(
                                participant: p,
                                pdfViewSize: _pdfViewSize,
                              ),
                            ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Annotation toolbar
          GlassContainer(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            color: AppColors.surface,
            child: AnnotationToolbar(
              selectedMode: _annotationMode,
              selectedColor: _annotationColor,
              onModeChanged: (mode) {
                setState(() {
                  _annotationMode = mode;
                  _pdfController.annotationMode = mode;
                });
              },
              onColorChanged: (color) {
                setState(() {
                  _annotationColor = color;
                  // Note: Syncfusion doesn't support dynamic color change for new annotations easily
                  // We would need to update controller settings
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
