import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/indexing_job.dart';
import '../services/indexing_service.dart';
import '../services/drive_service.dart';

/// Panel showing indexing progress for all files
class IndexingProgressPanel extends StatefulWidget {
  const IndexingProgressPanel({super.key});

  @override
  State<IndexingProgressPanel> createState() => _IndexingProgressPanelState();
}

class _IndexingProgressPanelState extends State<IndexingProgressPanel> {
  bool _showOnlyActive = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<IndexingService>(
      builder: (context, indexingService, child) {
        final jobs = _showOnlyActive
            ? indexingService.allJobs.where((job) => job.isActive).toList()
            : indexingService.allJobs;

        return Container(
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Indexing Progress',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${indexingService.activeJobCount} active • ${indexingService.completedJobCount} completed • ${indexingService.failedJobCount} failed',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withValues(alpha: 0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => indexingService.refreshJobs(),
                      tooltip: 'Refresh',
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ],
                ),
              ),

              // Filter toggle
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Show only active'),
                      selected: _showOnlyActive,
                      onSelected: (selected) {
                        setState(() => _showOnlyActive = selected);
                      },
                    ),
                    const Spacer(),
                    if (jobs.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _showReindexAllDialog(context),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Reindex All PDFs'),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Jobs list
              Flexible(
                child: jobs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _showOnlyActive
                                    ? 'No active indexing jobs'
                                    : 'No indexing jobs yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: jobs.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final job = jobs[index];
                          return _IndexingJobTile(job: job);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showReindexAllDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reindex All PDFs'),
        content: const Text(
          'This will reindex all PDF files in your library. This may take some time. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reindex All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _reindexAllPdfs(context);
    }
  }

  Future<void> _reindexAllPdfs(BuildContext context) async {
    try {
      final driveService = context.read<DriveService>();
      final indexingService = context.read<IndexingService>();

      // Get all PDF files
      final allFiles = await driveService.listAllFiles();
      final pdfFileIds = allFiles
          .where((file) => file.isPdf)
          .map((file) => file.id)
          .toList();

      if (pdfFileIds.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No PDF files found')));
        }
        return;
      }

      // Start reindexing
      final jobIds = await indexingService.reindexAllFiles(pdfFileIds);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Started reindexing ${jobIds.length} PDF files'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to reindex files: $e')));
      }
    }
  }
}

class _IndexingJobTile extends StatelessWidget {
  final IndexingJob job;

  const _IndexingJobTile({required this.job});

  @override
  Widget build(BuildContext context) {
    // Get file name from DriveService cache
    final driveService = context.watch<DriveService>();

    return ListTile(
      leading: _buildStatusIcon(),
      title: FutureBuilder<String?>(
        future: driveService.getCachedFileName(job.fileId),
        builder: (context, snapshot) {
          final fileName =
              snapshot.data ?? 'File: ${job.fileId.substring(0, 12)}...';
          return Text(
            fileName,
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(_getStatusText()),
          if (job.isProcessing && job.totalChunks != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: job.progressPercentage / 100,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 4),
            Text(
              '${job.chunksProcessed} / ${job.totalChunks} chunks (${job.progressPercentage.toStringAsFixed(0)}%)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          if (job.isFailed && job.errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              job.errorMessage!,
              style: const TextStyle(fontSize: 12, color: Colors.red),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: job.isFailed
          ? IconButton(
              icon: const Icon(Icons.refresh, color: Colors.orange),
              onPressed: () => _reindexFile(context),
              tooltip: 'Retry',
            )
          : null,
      onTap: job.isFailed ? () => _showErrorDialog(context) : null,
    );
  }

  Widget _buildStatusIcon() {
    if (job.isPending) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.schedule, color: Colors.orange),
      );
    } else if (job.isProcessing) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (job.isCompleted) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_circle, color: Colors.green),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  String _getStatusText() {
    if (job.isPending) {
      return 'Pending • Created ${_formatDate(job.createdAt)}';
    } else if (job.isProcessing) {
      return 'Processing • Started ${_formatDate(job.startedAt ?? job.createdAt)}';
    } else if (job.isCompleted) {
      return 'Completed • ${_formatDate(job.completedAt ?? job.createdAt)}';
    } else {
      return 'Failed • ${_formatDate(job.createdAt)}';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _reindexFile(BuildContext context) async {
    try {
      final indexingService = context.read<IndexingService>();
      await indexingService.reindexFile(fileId: job.fileId);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reindexing started')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to reindex: $e')));
      }
    }
  }

  Future<void> _showErrorDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 12),
            Text('Indexing Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File ID: ${job.fileId}'),
            const SizedBox(height: 8),
            Text('Job ID: ${job.jobId}'),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(job.errorMessage ?? 'Unknown error'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _reindexFile(context);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
