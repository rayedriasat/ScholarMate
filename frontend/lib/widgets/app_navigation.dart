import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/simple_theme_service.dart';
import '../theme/app_colors.dart';
import 'ui/glass_container.dart';
import 'api_key_settings_tile.dart';

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
/// - Left glass sidebar for web/desktop
/// - Floating glass bottom bar for mobile
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
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      extendBody: true, // Important for floating bottom bar
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.surfaceGradient,
            ),
          ),

          // Content
          Row(
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

          // Floating Bottom Navigation for mobile
          if (!isWideScreen)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: _buildFloatingBottomNav(context),
            ),
        ],
      ),
      floatingActionButton: _showSettings ? null : widget.floatingActionButton,
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return GlassContainer(
      width: 80,
      height: double.infinity,
      borderRadius: BorderRadius.zero,
      blur: 20,
      opacity: 0.05,
      border: const Border(right: BorderSide(color: Colors.white10, width: 1)),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // App logo
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onItemTapped(0),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.school, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (int i = 0; i < widget.items.length; i++)
                  _buildSidebarItem(
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
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildSidebarItem(
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

  Widget _buildSidebarItem(
    BuildContext context,
    NavigationItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Tooltip(
        message: item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      )
                    : null,
              ),
              child: Icon(
                isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBottomNav(BuildContext context) {
    return GlassContainer(
      height: 72,
      blur: 20,
      opacity: 0.1,
      color: AppColors.surface.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context,
    NavigationItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? (item.activeIcon ?? item.icon) : item.icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsScreen(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: MediaQuery.of(context).size.width < 800
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showSettings = false),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Appearance section
          _buildSettingsSection(context, 'Appearance', [
            _buildThemeToggle(context),
          ]),

          const SizedBox(height: 24),

          // AI & API Keys section
          if (user != null)
            _buildSettingsSection(context, 'AI & API Keys', [
              ApiKeySettingsTile(
                userId: user.id,
                baseUrl: const String.fromEnvironment(
                  'API_BASE_URL',
                  defaultValue: 'http://localhost:8000',
                ),
              ),
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
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user.displayName?.substring(0, 1).toUpperCase() ??
                              user.email.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                title: Text(
                  user.displayName ?? 'User',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  user.email,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              const Divider(color: Colors.white10),
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
              color: AppColors.primary,
            ),
          ),
        ),
        GlassContainer(
          width: double.infinity,
          opacity: 0.05,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    final themeService = context.watch<SimpleThemeService>();
    final isDark = themeService.isDarkMode;

    return Column(
      children: [
        SwitchListTile(
          secondary: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: AppColors.primary,
          ),
          title: const Text('Dark Mode', style: TextStyle(color: Colors.white)),
          subtitle: Text(
            themeService.isSystemMode
                ? 'System default'
                : (isDark ? 'Enabled' : 'Disabled'),
            style: TextStyle(color: AppColors.textSecondary),
          ),
          value: isDark && !themeService.isSystemMode,
          activeColor: AppColors.primary,
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
          const Divider(height: 1, color: Colors.white10),
          ListTile(
            leading: Icon(Icons.brightness_auto, color: AppColors.primary),
            title: const Text(
              'Use System Theme',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Follow system dark/light mode',
              style: TextStyle(color: AppColors.textSecondary),
            ),
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
        backgroundColor: AppColors.surface,
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70),
        ),
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
