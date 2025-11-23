import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import 'adaptive_navigation.dart';

/// Mobile bottom navigation bar with icon tabs
class MobileBottomBar extends StatelessWidget {
  final List<AppNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool showSettings;
  final VoidCallback onSettingsTap;

  const MobileBottomBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.showSettings = false,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: DesignTokens.space2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Navigation destinations
              for (int i = 0; i < destinations.length; i++)
                _buildBottomNavItem(
                  context,
                  destinations[i],
                  i == selectedIndex,
                  () => onDestinationSelected(i),
                  accentColor,
                ),
              // Settings item
              _buildBottomNavItem(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context,
    AppNavigationDestination destination,
    bool isSelected,
    VoidCallback onTap,
    Color accentColor,
  ) {
    final theme = Theme.of(context);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: DesignTokens.space2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with smooth transition animation
                AnimatedContainer(
                  duration: DesignTokens.hoverDuration,
                  curve: Curves.easeOut,
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
                SizedBox(height: DesignTokens.space1),
                // Label with smooth color transition
                AnimatedDefaultTextStyle(
                  duration: DesignTokens.hoverDuration,
                  curve: Curves.easeOut,
                  style: TextStyle(
                    color: isSelected
                        ? accentColor
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? DesignTokens.semiBold
                        : DesignTokens.regular,
                  ),
                  child: Text(destination.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
