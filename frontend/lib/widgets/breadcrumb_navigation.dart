import 'package:flutter/material.dart';
import '../models/drive_file.dart';
import '../theme/app_colors.dart';
import 'ui/glass_container.dart';

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

    return GlassContainer(
      width: double.infinity,
      borderRadius: BorderRadius.circular(12),
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isSmallScreen ? 8 : 12,
      ),
      opacity: 0.05,
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
                      const Icon(
                        Icons.home_filled,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      if (!isSmallScreen) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'ScholarMate',
                          style: TextStyle(
                            color: Colors.white,
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
                    color: Colors.white.withValues(alpha: 0.3),
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
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.7),
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
