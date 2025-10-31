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
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isSmallScreen ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Home icon
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onNavigate(path.first),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: isSmallScreen ? 2 : 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.home,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      if (!isSmallScreen) ...[
                        const SizedBox(width: 6),
                        Text(
                          'ScholarMate',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Path segments
            ...path.skip(1).map((folder) {
              final isLast = folder == path.last;
              return Row(
                children: [
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isLast ? null : () => onNavigate(folder),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: isSmallScreen ? 2 : 6,
                        ),
                        child: Text(
                          _truncateName(folder.name, isSmallScreen),
                          style: TextStyle(
                            color: isLast
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.primary,
                            fontWeight: isLast
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Truncate folder names on small screens
  String _truncateName(String name, bool isSmallScreen) {
    if (!isSmallScreen || name.length <= 15) return name;
    return '${name.substring(0, 12)}...';
  }
}
