/// Collaborative PDF viewer with real-time annotations and cursors
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/collaboration.dart';
import '../services/collaboration_service.dart';
import '../services/auth_service.dart';
import '../widgets/collaboration_panel.dart';
import '../widgets/collaboration_cursor.dart';
import '../widgets/annotation_toolbar.dart';

class CollaborativePdfViewerScreen extends StatefulWidget {
  final String fileId;
  final String fileName;
  final String? sessionId; // If joining existing session
  
  const CollaborativePdfViewerScreen({
    super.key,
    required this.fileId,
    required this.fileName,
    this.sessionId,
  });
  
  @override
  State<CollaborativePdfViewerScreen> createState() => _CollaborativePdfViewerScreenState();
}

class _CollaborativePdfViewerScreenState extends State<CollaborativePdfViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  CollaborationService? _collaborationService;
  CollaborationSession? _session;
  bool _isLoading = true;
  String? _error;
  
  // Track PDF view size for cursor positioning
  Size _pdfViewSize = Size.zero;
  
  @override
  void initState() {
    super.initState();
    _initializeCollaboration();
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
      
      // Listen to participant updates
      _collaborationService!.participantUpdates.listen((participant) {
        if (mounted) {
          setState(() {
            // Update session with new participant data
            final index = _session!.participants.indexWhere((p) => p.userId == participant.userId);
            if (index != -1) {
              final updated = List<SessionParticipant>.from(_session!.participants);
              updated[index] = participant;
              _session = _session!.copyWith(participants: updated);
            }
          });
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
    
    _collaborationService?.updateCursor(
      userId: user.id,
      position: position,
    );
  }
  
  Future<void> _leaveSession() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    
    if (user != null && _collaborationService != null) {
      await _collaborationService!.leaveSession(user.id);
    }
    
    if (mounted) {
      Navigator.pop(context);
    }
  }
  
  void _showShareDialog() {
    if (_session == null) return;
    
    showDialog(
      context: context,
      builder: (context) => ShareLinkDialog(shareLink: _session!.shareLink),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _showShareDialog,
            tooltip: 'Share session',
          ),
        ],
      ),
      body: Column(
        children: [
          // Collaboration panel
          if (_session != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CollaborationPanel(
                session: _session!,
                onLeave: _leaveSession,
                onShare: _showShareDialog,
              ),
            ),
          
          // PDF viewer with cursor overlay
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _pdfViewSize = Size(constraints.maxWidth, constraints.maxHeight);
                
                return MouseRegion(
                  onHover: _onPointerMove,
                  child: Stack(
                    children: [
                      // PDF viewer
                      SfPdfViewer.network(
                        'https://drive.google.com/uc?id=${widget.fileId}',
                        controller: _pdfController,
                      ),
                      
                      // Other users' cursors
                      if (_session != null)
                        ..._session!.participants
                            .where((p) => p.userId != context.read<AuthService>().currentUser?.id)
                            .map((p) => CollaborationCursor(
                                  participant: p,
                                  pdfViewSize: _pdfViewSize,
                                )),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Annotation toolbar
          const AnnotationToolbar(),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }
}
