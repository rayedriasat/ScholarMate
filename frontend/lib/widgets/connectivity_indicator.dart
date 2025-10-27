import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../services/sync_manager.dart';

/// Widget that displays online/offline status and sync progress
class ConnectivityIndicator extends StatelessWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityService = context.watch<ConnectivityService>();
    final syncManager = context.watch<SyncManager>();

    final isOnline = connectivityService.isOnline;
    final syncStatus = syncManager.syncStatus;
    final pendingCount = syncManager.pendingActionCount;

    // Determine color and icon based on status
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (!isOnline) {
      statusColor = Colors.grey;
      statusIcon = Icons.cloud_off;
      statusText = 'Offline';
    } else if (syncStatus == SyncStatus.syncing) {
      statusColor = Colors.orange;
      statusIcon = Icons.sync;
      statusText = 'Syncing';
    } else if (syncStatus == SyncStatus.error) {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
      statusText = 'Sync Error';
    } else if (pendingCount > 0) {
      statusColor = Colors.orange;
      statusIcon = Icons.cloud_upload;
      statusText = '$pendingCount pending';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.cloud_done;
      statusText = 'Online';
    }

    return GestureDetector(
      onTap: () => _showStatusDialog(context, connectivityService, syncManager),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (syncStatus == SyncStatus.syncing)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              )
            else
              Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(
    BuildContext context,
    ConnectivityService connectivityService,
    SyncManager syncManager,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              connectivityService.isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: connectivityService.isOnline ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(connectivityService.isOnline ? 'Online' : 'Offline'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow(
              'Connection',
              connectivityService.isOnline ? 'Connected' : 'Disconnected',
              connectivityService.isOnline ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              'Sync Status',
              _getSyncStatusText(syncManager.syncStatus),
              _getSyncStatusColor(syncManager.syncStatus),
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              'Pending Actions',
              '${syncManager.pendingActionCount}',
              syncManager.pendingActionCount > 0 ? Colors.orange : Colors.green,
            ),
            if (syncManager.lastError != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Last Error:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                syncManager.lastError!,
                style: TextStyle(fontSize: 12, color: Colors.red[600]),
              ),
            ],
          ],
        ),
        actions: [
          if (syncManager.pendingActionCount > 0 &&
              connectivityService.isOnline)
            TextButton.icon(
              onPressed: () {
                syncManager.manualSync();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  String _getSyncStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return 'Idle';
      case SyncStatus.syncing:
        return 'Syncing';
      case SyncStatus.error:
        return 'Error';
    }
  }

  Color _getSyncStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Colors.green;
      case SyncStatus.syncing:
        return Colors.orange;
      case SyncStatus.error:
        return Colors.red;
    }
  }
}
