import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/indexing_service.dart';

/// Badge showing indexing status for a file
class IndexingStatusBadge extends StatelessWidget {
  final String fileId;
  final bool compact;

  const IndexingStatusBadge({
    super.key,
    required this.fileId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<IndexingService>(
      builder: (context, indexingService, child) {
        final status = indexingService.getFileIndexingStatus(fileId);
        final progress = indexingService.getFileProgress(fileId);

        if (status == 'not_indexed') {
          return _buildBadge(
            context: context,
            icon: Icons.hourglass_empty,
            label: compact ? '' : 'Not indexed',
            color: Colors.grey,
            progress: null,
          );
        } else if (status == 'pending') {
          return _buildBadge(
            context: context,
            icon: Icons.schedule,
            label: compact ? '' : 'Pending',
            color: Colors.orange,
            progress: null,
          );
        } else if (status == 'processing') {
          return _buildBadge(
            context: context,
            icon: Icons.sync,
            label: compact ? '' : '${progress.toStringAsFixed(0)}%',
            color: Colors.blue,
            progress: progress,
            animated: true,
          );
        } else if (status == 'completed') {
          return _buildBadge(
            context: context,
            icon: Icons.check_circle,
            label: compact ? '' : 'Indexed',
            color: Colors.green,
            progress: null,
          );
        } else if (status == 'failed') {
          return _buildBadge(
            context: context,
            icon: Icons.error,
            label: compact ? '' : 'Failed',
            color: Colors.red,
            progress: null,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBadge({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    double? progress,
    bool animated = false,
  }) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: animated
            ? SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  value: progress != null ? progress / 100 : null,
                ),
              )
            : Icon(icon, size: 12, color: color),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (animated)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                value: progress != null ? progress / 100 : null,
              ),
            )
          else
            Icon(icon, size: 14, color: color),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
