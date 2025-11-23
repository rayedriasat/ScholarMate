import 'package:flutter/material.dart';
import '../models/drive_file.dart';
import '../theme/app_colors.dart';
import 'ui/glass_container.dart';
import 'ui/modern_button.dart';

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
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_list, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Source Selection',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: onRefresh,
                    tooltip: 'Refresh files',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${selectedFileIds.length} of ${availableFiles.length} selected',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ModernButton(
                      onPressed: onSelectAll,
                      icon: Icons.check_box,
                      label: 'Select All',
                      variant: ModernButtonVariant.outline,
                      height: 36,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ModernButton(
                      onPressed: onClearAll,
                      icon: Icons.clear,
                      label: 'Clear All',
                      variant: ModernButtonVariant.outline,
                      height: 36,
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
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
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
          Icon(
            Icons.folder_open,
            size: 48,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No PDF files found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload PDFs to use as sources',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, DriveFile file, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
        child: CheckboxListTile(
          value: isSelected,
          onChanged: (_) => onToggleFile(file.id),
          title: Text(
            file.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: file.size != null
              ? Text(
                  _formatFileSize(file.size!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                )
              : null,
          secondary: Icon(
            Icons.picture_as_pdf,
            color: isSelected ? AppColors.primary : Colors.white54,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          checkColor: Colors.white,
          activeColor: AppColors.primary,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
        ),
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
