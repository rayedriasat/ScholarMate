import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import 'adaptive_navigation.dart';

/// Desktop sidebar navigation with expandable sections
class DesktopSidebar extends StatelessWidget {
  final List<AppNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool expanded;
  final bool showSettings;
  final VoidCallback onSettingsTap;

  const DesktopSidebar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.expanded = false,
    this.showSettings = false,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Container(
      width: expanded ? 240 : 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          // App logo
          Padding(
            padding: EdgeInsets.all(DesignTokens.space3),
            child: _buildAppLogo(context, accentColor),
          ),

          SizedBox(height: DesignTokens.space2),

          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: DesignTokens.space2),
              children: [
                for (int i = 0; i < destinations.length; i++)
                  _buildNavigationItem(
                    context,
                    destinations[i],
                    i == selectedIndex,
                    () => onDestinationSelected(i),
                    accentColor,
                  ),
              ],
            ),
          ),

          // Settings at bottom
          Padding(
            padding: EdgeInsets.all(DesignTokens.space4),
            child: _buildNavigationItem(
              context,
              AppNavigationDestination(
                id: 'settings',
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
                screen: Container(),
              ),
              showSettings,
              onSettingsTap,
              accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppLogo(BuildContext context, Color accentColor) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onDestinationSelected(0),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXLarge),
        child: Container(
          width: expanded ? double.infinity : 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentColor, theme.colorScheme.secondary],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radiusXLarge),
          ),
          child: expanded
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school, color: Colors.white, size: 24),
                    SizedBox(width: DesignTokens.space2),
                    const Text(
                      'ScholarMate',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: DesignTokens.semiBold,
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Icon(Icons.school, color: Colors.white, size: 24),
                ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    AppNavigationDestination destination,
    bool isSelected,
    VoidCallback onTap,
    Color accentColor,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space3,
        vertical: DesignTokens.space1,
      ),
      child: expanded
          ? _buildExpandedItem(
              context,
              destination,
              isSelected,
              onTap,
              accentColor,
            )
          : _buildCompactItem(
              context,
              destination,
              isSelected,
              onTap,
              accentColor,
            ),
    );
  }

  Widget _buildExpandedItem(
    BuildContext context,
    AppNavigationDestination destination,
    bool isSelected,
    VoidCallback onTap,
    Color accentColor,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        child: AnimatedContainer(
          duration: DesignTokens.hoverDuration,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space3,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? (destination.activeIcon ?? destination.icon)
                    : destination.icon,
                color: isSelected
                    ? accentColor
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Text(
                  destination.label,
                  style: TextStyle(
                    color: isSelected
                        ? accentColor
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: isSelected
                        ? DesignTokens.semiBold
                        : DesignTokens.regular,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactItem(
    BuildContext context,
    AppNavigationDestination destination,
    bool isSelected,
    VoidCallback onTap,
    Color accentColor,
  ) {
    final theme = Theme.of(context);

    return Tooltip(
      message: destination.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXLarge),
          child: AnimatedContainer(
            duration: DesignTokens.hoverDuration,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(DesignTokens.radiusXLarge),
            ),
            child: Icon(
              isSelected
                  ? (destination.activeIcon ?? destination.icon)
                  : destination.icon,
              color: isSelected
                  ? accentColor
                  : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
