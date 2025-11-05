import 'package:flutter/material.dart';
import '../models/drive_file.dart';

/// A compact file card widget optimized for grid and compact layouts
class FileCardCompact extends StatelessWidget {
  final DriveFile file;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool showDetails;

  const FileCardCompact({
    super.key,
    required this.file,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // File icon
              _buildFileIcon(context),

              const SizedBox(height: 8),

              // File name
              Text(
                file.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),

              if (showDetails) ...[
                const SizedBox(height: 4),

                // File details
                if (!file.isFolder) ...[
                  Text(
                    file.formattedSize,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                ],

                Text(
                  _formatDate(file.modifiedTime),
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],

              // Shared indicator
              if (file.isShared) ...[
                const SizedBox(height: 4),
                Icon(Icons.people, size: 14, color: Colors.blue[600]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon(BuildContext context) {
    if (file.isFolder) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.folder, color: Colors.blue[700], size: 28),
      );
    }

    Color iconColor;
    IconData iconData;

    if (file.isPdf) {
      iconColor = Colors.red[700]!;
      iconData = Icons.picture_as_pdf;
    } else if (file.isMarkdown) {
      iconColor = Colors.green[700]!;
      iconData = Icons.description;
    } else {
      iconColor = Colors.grey[700]!;
      iconData = Icons.insert_drive_file;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 28),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
