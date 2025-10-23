import 'package:flutter/material.dart';
import '../models/drive_file.dart';

/// Breadcrumb navigation for folder hierarchy
class BreadcrumbNavigation extends StatelessWidget {
  final List<DriveFile> path;
  final Function(DriveFile) onNavigate;

  const BreadcrumbNavigation({
    super.key,
    required this.path,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Home icon
            InkWell(
              onTap: () => onNavigate(path.first),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.home,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ScholarMate',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Path segments
            ...path
                .skip(1)
                .map(
                  (folder) => Row(
                    children: [
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      InkWell(
                        onTap: () => onNavigate(folder),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            folder.name,
                            style: TextStyle(
                              color: folder == path.last
                                  ? Colors.grey[800]
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: folder == path.last
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
