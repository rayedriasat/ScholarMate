import 'package:flutter/material.dart';
import '../models/drive_file.dart';
import '../theme/design_tokens.dart';
import 'modern_file_card.dart';

/// Modern file list view with glass cards
/// Displays files in a vertical list with full-width cards
class ModernFileListView extends StatelessWidget {
  final List<DriveFile> files;
  final Set<String> selectedFiles;
  final Function(DriveFile) onFileTap;
  final Function(String) onFileLongPress;
  final Function(DriveFile) onRename;
  final Function(DriveFile) onDelete;
  final Function(DriveFile) onShare;
  final Function(DriveFile)? onReindex;
  final VoidCallback onRefresh;

  const ModernFileListView({
    super.key,
    required this.files,
    required this.selectedFiles,
    required this.onFileTap,
    required this.onFileLongPress,
    required this.onRename,
    required this.onDelete,
    required this.onShare,
    this.onReindex,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(DesignTokens.space4),
        itemCount: files.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: DesignTokens.space3),
        itemBuilder: (context, index) {
          final file = files[index];
          return ModernFileCard(
            file: file,
            isSelected: selectedFiles.contains(file.id),
            isGridView: false,
            onTap: () => onFileTap(file),
            onLongPress: () => onFileLongPress(file.id),
            onRename: () => onRename(file),
            onDelete: () => onDelete(file),
            onShare: () => onShare(file),
            onReindex: file.isPdf && onReindex != null
                ? () => onReindex!(file)
                : null,
          );
        },
      ),
    );
  }
}
