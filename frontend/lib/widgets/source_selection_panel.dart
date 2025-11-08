import 'package:flutter/material.dart';
import '../models/drive_file.dart';

/// Panel for selecting source files for AI chat
class SourceSelectionPanel extends StatelessWidget {
  final List<DriveFile> availableFiles;
  final Set<String> selectedFileIds;
  final bool isLoading;
  final Function(String) onToggleFile;
  final VoidCallback onClearAll;
  final VoidCallback onSelectAll;
  final VoidCallback onRefresh;

  const SourceSelectionPanel({
    super.key,
    required this.availableFiles,
    required this.selectedFileIds,
    required this.isLoading,
    required this.onToggleFile,
    required this.onClearAll,
    required this.onSelectAll,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Source Selection',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                    tooltip: 'Refresh files',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${selectedFileIds.length} of ${availableFiles.length} selected',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSelectAll,
                      icon: const Icon(Icons.check_box, size: 18),
                      label: const Text('Select All'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onClearAll,
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear All'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // File list
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : availableFiles.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: availableFiles.length,
                  itemBuilder: (context, index) {
                    final file = availableFiles[index];
                    final isSelected = selectedFileIds.contains(file.id);
                    return _buildFileItem(context, file, isSelected);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No PDF files found',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload PDFs to use as sources',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, DriveFile file, bool isSelected) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : null,
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (_) => onToggleFile(file.id),
        title: Text(
          file.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: file.size != null
            ? Text(
                _formatFileSize(file.size!),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
            : null,
        secondary: Icon(
          Icons.picture_as_pdf,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
