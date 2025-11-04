import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/simple_theme_service.dart';

/// Navigation item model
class NavigationItem {
  final String id;
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Widget screen;

  const NavigationItem({
    required this.id,
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.screen,
  });
}

/// Modern app navigation with responsive layout
/// - Left sidebar for web/desktop
/// - Bottom navigation for mobile
class AppNavigation extends StatefulWidget {
  final List<NavigationItem> items;
  final int initialIndex;
  final Widget? floatingActionButton;
  final Function(int)? onIndexChanged;

  const AppNavigation({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.floatingActionButton,
    this.onIndexChanged,
  });

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  late int _selectedIndex;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _showSettings = false;
    });
    widget.onIndexChanged?.call(index);
  }

  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      body: Row(
        children: [
          // Left sidebar for web/desktop
          if (isWideScreen) _buildSidebar(context),

          // Main content
          Expanded(
            child: _showSettings
                ? _buildSettingsScreen(context)
                : widget.items[_selectedIndex].screen,
          ),
        ],
      ),
      // Bottom navigation for mobile
      bottomNavigationBar: isWideScreen ? null : _buildBottomNav(context),
      floatingActionButton: _showSettings ? null : widget.floatingActionButton,
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          // App logo
          Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Navigate to Files page (index 0)
                    _onItemTapped(0);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (int i = 0; i < widget.items.length; i++)
                  _buildCompactSidebarItem(
                    context,
                    widget.items[i],
                    i == _selectedIndex,
                    () => _onItemTapped(i),
                  ),
              ],
            ),
          ),

          // Settings section at bottom
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildCompactSidebarItem(
              context,
              NavigationItem(
                id: 'settings',
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
                screen: Container(),
              ),
              _showSettings,
              _toggleSettings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSidebarItem(
    BuildContext context,
    NavigationItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Tooltip(
        message: item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.8)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < widget.items.length; i++)
                _buildBottomNavItem(
                  context,
                  widget.items[i],
                  i == _selectedIndex,
                  () => _onItemTapped(i),
                ),
              _buildBottomNavItem(
                context,
                NavigationItem(
                  id: 'settings',
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  screen: Container(),
                ),
                _showSettings,
                _toggleSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context,
    NavigationItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsScreen(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        leading: MediaQuery.of(context).size.width < 600
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showSettings = false),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance section
          _buildSettingsSection(context, 'Appearance', [
            _buildThemeToggle(context),
          ]),

          const SizedBox(height: 24),

          // Account section
          if (user != null)
            _buildSettingsSection(context, 'Account', [
              ListTile(
                leading: user.photoUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(user.photoUrl!),
                      )
                    : CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          user.displayName?.substring(0, 1).toUpperCase() ??
                              user.email.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                title: Text(user.displayName ?? 'User'),
                subtitle: Text(user.email),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _handleSignOut(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = context.watch<SimpleThemeService>();
    final isDark =
        themeService.isDarkMode ||
        (themeService.isSystemMode && theme.brightness == Brightness.dark);

    return Column(
      children: [
        SwitchListTile(
          secondary: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: theme.colorScheme.primary,
          ),
          title: const Text('Dark Mode'),
          subtitle: Text(
            themeService.isSystemMode
                ? 'System default'
                : (isDark ? 'Enabled' : 'Disabled'),
          ),
          value: isDark && !themeService.isSystemMode,
          onChanged: (value) {
            if (value) {
              themeService.setDarkTheme();
            } else {
              themeService.setLightTheme();
            }
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        if (!themeService.isSystemMode) ...[
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.brightness_auto,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Use System Theme'),
            subtitle: const Text('Follow system dark/light mode'),
            onTap: () => themeService.setSystemTheme(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ],
      ],
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
