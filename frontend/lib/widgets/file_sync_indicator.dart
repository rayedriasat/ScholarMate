import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/file_sync_service.dart';

/// Widget to display file sync status and allow manual refresh
class FileSyncIndicator extends StatelessWidget {
  final String fileId;
  final VoidCallback? onRefresh;

  const FileSyncIndicator({super.key, required this.fileId, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<FileSyncService>(
      builder: (context, syncService, child) {
        final lastSync = syncService.getLastSyncTime(fileId);
        final isSyncing = syncService.isSyncing;

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
              if (isSyncing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade700,
                    ),
                  ),
                )
              else
                Icon(Icons.sync, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              if (lastSync != null)
                Text(
                  _formatLastSync(lastSync),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Text(
                  'Checking for updates...',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(width: 8),
              InkWell(
                onTap: isSyncing ? null : () => _handleRefresh(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSyncing
                        ? Colors.grey.shade400
                        : Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Refresh',
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
      },
    );
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inSeconds < 10) {
      return 'Just checked';
    } else if (difference.inSeconds < 60) {
      return 'Checked ${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return 'Checked ${difference.inMinutes}m ago';
    } else {
      return 'Checked ${difference.inHours}h ago';
    }
  }

  void _handleRefresh(BuildContext context) {
    final syncService = context.read<FileSyncService>();
    syncService.syncFile(fileId).then((success) {
      if (success && onRefresh != null) {
        onRefresh!();
      }
    });
  }
}

/// Compact sync badge for file list
class FileSyncBadge extends StatelessWidget {
  final String fileId;
  final bool showLastSync;

  const FileSyncBadge({
    super.key,
    required this.fileId,
    this.showLastSync = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FileSyncService>(
      builder: (context, syncService, child) {
        final lastSync = syncService.getLastSyncTime(fileId);
        final needsSync = syncService.needsSync(fileId);

        if (syncService.isSyncing) {
          return Tooltip(
            message: 'Syncing...',
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
            ),
          );
        }

        if (needsSync) {
          return Tooltip(
            message: 'Needs sync',
            child: Icon(
              Icons.sync_problem,
              size: 16,
              color: Colors.orange.shade600,
            ),
          );
        }

        if (showLastSync && lastSync != null) {
          return Tooltip(
            message: 'Last synced: ${_formatTime(lastSync)}',
            child: Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.green.shade600,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Floating action button for manual sync
class SyncFloatingActionButton extends StatelessWidget {
  final String fileId;
  final VoidCallback? onSyncComplete;

  const SyncFloatingActionButton({
    super.key,
    required this.fileId,
    this.onSyncComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FileSyncService>(
      builder: (context, syncService, child) {
        final isSyncing = syncService.isSyncing;

        return FloatingActionButton(
          onPressed: isSyncing ? null : () => _handleSync(context),
          tooltip: 'Check for updates',
          child: isSyncing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.sync),
        );
      },
    );
  }

  void _handleSync(BuildContext context) {
    final syncService = context.read<FileSyncService>();
    syncService.syncFile(fileId).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File synced successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        onSyncComplete?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sync file'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }
}
