import 'package:flutter/material.dart';
import '../models/drive_file.dart';

/// Modern breadcrumb navigation for folder hierarchy
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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 0,
        vertical: isSmallScreen ? 4 : 8,
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
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.home_filled,
                        size: 18,
                        color: theme.primaryColor,
                      ),
                      if (!isSmallScreen) ...[
                        const SizedBox(width: 8),
                        Text(
                          'ScholarMate',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isLast ? null : () => onNavigate(folder),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: isSmallScreen ? 4 : 6,
                        ),
                        child: Text(
                          _truncateName(folder.name, isSmallScreen),
                          style: TextStyle(
                            color: isLast
                                ? theme.primaryColor
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                            fontWeight: isLast
                                ? FontWeight.bold
                                : FontWeight.normal,
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
