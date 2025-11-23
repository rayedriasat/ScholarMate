import 'package:flutter/material.dart';
import '../models/drive_file.dart';
import '../theme/design_tokens.dart';
import 'modern_file_card.dart';

/// Modern file grid view with glass cards
/// Responsive grid that adjusts columns based on screen width
class ModernFileGridView extends StatelessWidget {
  final List<DriveFile> files;
  final Set<String> selectedFiles;
  final Function(DriveFile) onFileTap;
  final Function(String) onFileLongPress;
  final Function(DriveFile) onRename;
  final Function(DriveFile) onDelete;
  final Function(DriveFile) onShare;
  final Function(DriveFile)? onReindex;
  final VoidCallback onRefresh;

  const ModernFileGridView({
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive grid columns based on screen width
          final crossAxisCount = _calculateGridColumns(constraints.maxWidth);
          final childAspectRatio = _calculateAspectRatio(constraints.maxWidth);

          return GridView.builder(
            padding: const EdgeInsets.all(DesignTokens.space4),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: DesignTokens.space4,
              mainAxisSpacing: DesignTokens.space4,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ModernFileCard(
                file: file,
                isSelected: selectedFiles.contains(file.id),
                isGridView: true,
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
          );
        },
      ),
    );
  }

  /// Calculate number of grid columns based on screen width
  /// Validates Requirements 5.3: Grid columns increase with screen width
  int _calculateGridColumns(double width) {
    if (width < 600) return 2; // Mobile: 2 columns
    if (width < 900) return 3; // Small tablet: 3 columns
    if (width < 1200) return 4; // Large tablet: 4 columns
    if (width < 1600) return 5; // Small desktop: 5 columns
    return 6; // Large desktop: 6 columns
  }

  /// Calculate aspect ratio for grid items based on screen width
  double _calculateAspectRatio(double width) {
    if (width < 600) return 0.85; // Mobile: taller cards
    if (width < 900) return 0.9; // Tablet: slightly taller
    return 1.0; // Desktop: square-ish cards
  }
}
