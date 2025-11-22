/// Dialog for displaying annotation sync conflicts
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dialog to show annotation sync conflicts
class AnnotationConflictDialog extends StatelessWidget {
  final List<dynamic> conflicts;
  final VoidCallback? onRefresh;

  const AnnotationConflictDialog({
    super.key,
    required this.conflicts,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
          const SizedBox(width: 8),
          const Text('Annotation Conflicts'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Some annotations were modified by others while you were offline. '
              'The server version was kept (last-write-wins).',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Conflicts:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: conflicts.length,
                itemBuilder: (context, index) {
                  final conflict = conflicts[index];
                  return _buildConflictItem(conflict);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (onRefresh != null)
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onRefresh!();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildConflictItem(Map<String, dynamic> conflict) {
    final reason = conflict['reason'] as String?;
    final serverUpdated = conflict['server_updated_at'] as String?;
    final clientUpdated = conflict['client_updated_at'] as String?;

    String reasonText = 'Unknown conflict';
    if (reason == 'server_newer') {
      reasonText = 'Server version is newer';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reasonText,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            if (serverUpdated != null || clientUpdated != null) ...[
              const SizedBox(height: 8),
              if (serverUpdated != null)
                Text(
                  'Server: ${_formatTimestamp(serverUpdated)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              if (clientUpdated != null)
                Text(
                  'Your version: ${_formatTimestamp(clientUpdated)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return DateFormat('MMM d, y h:mm a').format(dt);
    } catch (e) {
      return timestamp;
    }
  }
}
