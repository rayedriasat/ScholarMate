import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/annotation_sync_service.dart';

/// Widget to display annotation sync status
class AnnotationSyncIndicator extends StatelessWidget {
  final String fileId;

  const AnnotationSyncIndicator({super.key, required this.fileId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnnotationSyncService>(
      builder: (context, syncService, child) {
        if (syncService.isSyncing) {
          return _buildSyncingIndicator();
        }

        if (syncService.lastSyncError != null) {
          return _buildErrorIndicator(context, syncService);
        }

        if (syncService.lastSyncTime != null) {
          return _buildSuccessIndicator(syncService);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSyncingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Syncing annotations...',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorIndicator(
    BuildContext context,
    AnnotationSyncService syncService,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Sync failed',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _retrySync(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIndicator(AnnotationSyncService syncService) {
    final lastSync = syncService.lastSyncTime!;
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    String timeAgo;
    if (difference.inMinutes < 1) {
      timeAgo = 'just now';
    } else if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      timeAgo = '${difference.inHours}h ago';
    } else {
      timeAgo = '${difference.inDays}d ago';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            'Synced $timeAgo',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _retrySync(BuildContext context) {
    final syncService = context.read<AnnotationSyncService>();
    syncService.syncOfflineAnnotations(fileId);
  }
}

/// Compact sync status badge for annotation list
class AnnotationSyncBadge extends StatelessWidget {
  final bool isSynced;

  const AnnotationSyncBadge({super.key, required this.isSynced});

  @override
  Widget build(BuildContext context) {
    if (isSynced) {
      return Tooltip(
        message: 'Synced',
        child: Icon(Icons.cloud_done, size: 16, color: Colors.green.shade600),
      );
    } else {
      return Tooltip(
        message: 'Not synced',
        child: Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade600),
      );
    }
  }
}
