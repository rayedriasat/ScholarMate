import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/design_tokens.dart';
import '../../services/auth_service.dart';
import 'adaptive_navigation.dart';

/// Mobile drawer navigation with slide-in animation
class MobileDrawer extends StatelessWidget {
  final List<AppNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool showSettings;
  final VoidCallback onSettingsTap;

  const MobileDrawer({
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
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header with user info
            _buildDrawerHeader(context, user, accentColor),

            // Navigation items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: DesignTokens.space2),
                children: [
                  for (int i = 0; i < destinations.length; i++)
                    _buildDrawerItem(
                      context,
                      destinations[i],
                      i == selectedIndex,
                      () => onDestinationSelected(i),
                      accentColor,
                    ),

                  Divider(height: DesignTokens.space8),

                  // Settings item
                  _buildDrawerItem(
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

            // Sign out button at bottom
            if (user != null) _buildSignOutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(
    BuildContext context,
    dynamic user,
    Color accentColor,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App logo
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 28),
              ),
              SizedBox(width: DesignTokens.space3),
              const Text(
                'ScholarMate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: DesignTokens.bold,
                ),
              ),
            ],
          ),

          if (user != null) ...[
            SizedBox(height: DesignTokens.space4),
            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.displayName?.substring(0, 1).toUpperCase() ??
                              user.email.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: DesignTokens.semiBold,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: DesignTokens.semiBold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: DesignTokens.space1 / 2),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    AppNavigationDestination destination,
    bool isSelected,
    VoidCallback onTap,
    Color accentColor,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space3,
        vertical: DesignTokens.space1,
      ),
      child: Material(
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
                SizedBox(width: DesignTokens.space4),
                Expanded(
                  child: Text(
                    destination.label,
                    style: TextStyle(
                      color: isSelected
                          ? accentColor
                          : theme.colorScheme.onSurfaceVariant,
                      fontSize: 16,
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
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleSignOut(context),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.space4,
              vertical: DesignTokens.space3,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
            ),
            child: Row(
              children: [
                const Icon(Icons.logout, color: Colors.red, size: 24),
                SizedBox(width: DesignTokens.space4),
                const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: DesignTokens.semiBold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final authService = context.read<AuthService>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        // Close drawer first
        Navigator.of(context).pop();
        // Use force logout to ensure complete cleanup
        await authService.forceLogout();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to sign out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
