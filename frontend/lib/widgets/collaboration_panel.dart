/// Collaboration panel showing active participants
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/collaboration.dart';

class CollaborationPanel extends StatelessWidget {
  final CollaborationSession session;
  final VoidCallback onLeave;
  final VoidCallback? onShare;
  
  const CollaborationPanel({
    super.key,
    required this.session,
    required this.onLeave,
    this.onShare,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.people, size: 20),
              const SizedBox(width: 8),
              Text(
                'Collaborating (${session.participants.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (onShare != null)
                IconButton(
                  icon: const Icon(Icons.share, size: 18),
                  onPressed: onShare,
                  tooltip: 'Share link',
                ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onLeave,
                tooltip: 'Leave session',
              ),
            ],
          ),
          const Divider(height: 16),
          // Participants list
          ...session.participants.map((p) => _ParticipantTile(participant: p)),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final SessionParticipant participant;
  
  const _ParticipantTile({required this.participant});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Color indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: participant.userColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // Name
          Expanded(
            child: Text(
              participant.userName,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getRoleColor(participant.role).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              participant.role.name,
              style: TextStyle(
                fontSize: 10,
                color: _getRoleColor(participant.role),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getRoleColor(SessionRole role) {
    switch (role) {
      case SessionRole.owner:
        return Colors.purple;
      case SessionRole.editor:
        return Colors.blue;
      case SessionRole.viewer:
        return Colors.grey;
    }
  }
}

/// Share link dialog
class ShareLinkDialog extends StatelessWidget {
  final String shareLink;
  
  const ShareLinkDialog({super.key, required this.shareLink});
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share Collaboration Link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Anyone with this link can join the session:'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              shareLink,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: shareLink));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link copied to clipboard')),
            );
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy Link'),
        ),
      ],
    );
  }
}
