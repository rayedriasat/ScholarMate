/// Screen to join collaboration session via link or ID
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/collaboration_service.dart';
import '../services/auth_service.dart';
import 'collaborative_pdf_viewer_screen.dart';

class JoinCollaborationScreen extends StatefulWidget {
  final String? sessionId; // Pre-filled session ID from deep link

  const JoinCollaborationScreen({super.key, this.sessionId});

  @override
  State<JoinCollaborationScreen> createState() =>
      _JoinCollaborationScreenState();
}

class _JoinCollaborationScreenState extends State<JoinCollaborationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sessionIdController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) {
      _sessionIdController.text = widget.sessionId!;
      // Auto-join if session ID provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _joinSession();
      });
    }
  }

  @override
  void dispose() {
    _sessionIdController.dispose();
    super.dispose();
  }

  Future<void> _joinSession() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final user = authService.currentUser;

      if (user == null) {
        throw Exception('Please sign in to join collaboration');
      }

      final collaborationService = context.read<CollaborationService>();
      final session = await collaborationService.getSession(
        _sessionIdController.text.trim(),
      );

      // Navigate to collaborative viewer
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CollaborativePdfViewerScreen(
              fileId: session.fileId,
              fileName: session.fileName,
              sessionId: session.sessionId,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Collaboration')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Icon(
                    Icons.people,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Join Collaboration Session',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    'Enter the session ID to join a collaborative PDF viewing session',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Session ID input
                  TextFormField(
                    controller: _sessionIdController,
                    decoration: const InputDecoration(
                      labelText: 'Session ID',
                      hintText: 'Enter session ID from share link',
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a session ID';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_error != null) const SizedBox(height: 16),

                  // Join button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _joinSession,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(_isLoading ? 'Joining...' : 'Join Session'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info card
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'How it works',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Get the session ID from the person sharing\n'
                            '• Enter it above and click Join\n'
                            '• You\'ll see their cursor and annotations in real-time\n'
                            '• You can add your own annotations too',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
