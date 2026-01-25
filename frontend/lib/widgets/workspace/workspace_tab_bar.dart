import 'package:flutter/material.dart';
import 'document_tab_manager.dart';
import '../../theme/app_colors.dart';

/// Tab bar for managing open documents (PDF and Markdown)
class WorkspaceTabBar extends StatelessWidget {
  final DocumentTabManager tabManager;

  const WorkspaceTabBar({super.key, required this.tabManager});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: tabManager,
      builder: (context, _) {
        if (tabManager.tabs.isEmpty) {
          return Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Center(
              child: Text(
                'No documents open',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
          );
        }

        return Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tabManager.tabs.length,
            itemBuilder: (context, index) {
              final tab = tabManager.tabs[index];
              final isActive = index == tabManager.activeTabIndex;

              return _buildTab(
                context,
                tab: tab,
                index: index,
                isActive: isActive,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTab(
    BuildContext context, {
    required DocumentTab tab,
    required int index,
    required bool isActive,
  }) {
    // Determine icon and color based on file type
    IconData icon;
    Color iconColor;
    
    if (tab.isPdf) {
      icon = Icons.picture_as_pdf;
      iconColor = isActive
          ? Colors.red.withValues(alpha: 0.9)
          : Colors.red.withValues(alpha: 0.6);
    } else if (tab.isMarkdown) {
      icon = Icons.description;
      iconColor = isActive
          ? Colors.blue.withValues(alpha: 0.9)
          : Colors.blue.withValues(alpha: 0.6);
    } else {
      icon = Icons.insert_drive_file;
      iconColor = isActive
          ? Colors.white.withValues(alpha: 0.9)
          : Colors.white.withValues(alpha: 0.6);
    }

    return GestureDetector(
      onTap: () => tabManager.setActiveTab(index),
      child: Container(
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
        decoration: BoxDecoration(
          color: isActive ? AppColors.background : Colors.transparent,
          border: Border(
            right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            bottom: isActive
                ? const BorderSide(color: AppColors.primary, width: 2)
                : BorderSide.none,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // File icon
              Icon(
                icon,
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              // File name
              Expanded(
                child: Text(
                  tab.file.name,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              // Close button
              InkWell(
                onTap: () => tabManager.closeTab(index),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
