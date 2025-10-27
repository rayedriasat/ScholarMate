import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drive_file.dart';
import '../services/cache_service.dart';
import 'file_context_menu.dart';

/// A card widget displaying file or folder information
class FileCard extends StatelessWidget {
  final DriveFile file;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRename;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final bool isSelected;

  const FileCard({
    super.key,
    required this.file,
    this.onTap,
    this.onLongPress,
    this.onRename,
    this.onMove,
    this.onDelete,
    this.onShare,
    this.isSelected = false,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and name row
              Row(
                children: [
                  Stack(
                    children: [
                      _buildFileIcon(),
                      if (file.isPdf)
                        FutureBuilder<bool>(
                          future: context.read<CacheService>().isPdfCached(
                            file.id,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.data == true) {
                              return Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!file.isFolder) ...[
                          const SizedBox(height: 4),
                          Text(
                            _getFileTypeLabel(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (file.isShared)
                    Icon(Icons.people, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  FileContextMenu(
                    file: file,
                    onRename: onRename,
                    onMove: onMove,
                    onDelete: onDelete,
                    onShare: onShare,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Metadata row
              Row(
                children: [
                  if (!file.isFolder && file.size != null) ...[
                    Icon(Icons.storage, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      file.formattedSize,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatDate(file.modifiedTime),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
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

  String _getFileTypeLabel() {
    if (file.isPdf) return 'PDF Document';
    if (file.isMarkdown) return 'Markdown File';
    if (file.extension != null) return '${file.extension!.toUpperCase()} File';
    return 'File';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';

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
