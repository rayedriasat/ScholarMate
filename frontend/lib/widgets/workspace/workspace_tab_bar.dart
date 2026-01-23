import 'package:flutter/material.dart';
import 'pdf_tab_manager.dart';
import '../../theme/app_colors.dart';

/// Tab bar for managing open PDF documents
class WorkspaceTabBar extends StatelessWidget {
  final PdfTabManager tabManager;

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
    required PdfTab tab,
    required int index,
    required bool isActive,
  }) {
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
              // PDF icon
              Icon(
                Icons.picture_as_pdf,
                size: 16,
                color: isActive
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.6),
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
