import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/simple_theme_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_colors.dart';
import 'ui/glass_container.dart';
import 'ui/animated_background.dart';
import 'api_key_settings_tile.dart';
import '../services/config_service.dart';
import '../screens/settings_screen.dart';
import '../screens/payment_method_screen.dart';
import '../screens/transaction_history_screen.dart';

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
  bool _sidebarCollapsed = false;
  double _sidebarWidth = 250;
  static const double _minSidebarWidth = 60;
  static const double _maxSidebarWidthPercent = 0.6;

  // Global key to access scaffold from anywhere
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Swipe gesture tracking
  double _swipeStartX = 0;
  double _swipeCurrentX = 0;
  static const double _minSwipeDistance =
      100; // Minimum swipe distance to open drawer

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    
    // Load subscription status when navigation is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subscriptionService = context.read<SubscriptionService>();
      subscriptionService.loadSubscriptionStatus().catchError((e) {
        debugPrint('Failed to load subscription status: $e');
      });
    });
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
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true, // Important for floating bottom bar
      drawerEnableOpenDragGesture:
          false, // Disable edge swipe (conflicts with back gesture)
      // Use builder to keep drawer in memory and minimize rebuilds
      drawerScrimColor: Colors.black.withValues(alpha: 0.5),
      drawer: !isWideScreen
          ? Drawer(
              width: 280,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: RepaintBoundary(
                child: GlassContainer(
                  width: 280,
                  height: double.infinity,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  color: Theme.of(context).cardColor,
                  child: _buildNavigationContent(context, false),
                ),
              ),
            )
          : null,
      body: GestureDetector(
        // Swipe right from anywhere to open drawer (mobile only)
        onHorizontalDragStart: !isWideScreen
            ? (details) {
                _swipeStartX = details.globalPosition.dx;
                _swipeCurrentX = details.globalPosition.dx;
              }
            : null,
        onHorizontalDragUpdate: !isWideScreen
            ? (details) {
                _swipeCurrentX = details.globalPosition.dx;
              }
            : null,
        onHorizontalDragEnd: !isWideScreen
            ? (details) {
                // Calculate swipe distance
                final swipeDistance = _swipeCurrentX - _swipeStartX;

                // Only open drawer if:
                // 1. Swiped right (positive distance)
                // 2. Swipe distance is greater than minimum threshold
                // 3. Drawer is not already open
                if (swipeDistance > _minSwipeDistance &&
                    !(_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
                  _scaffoldKey.currentState?.openDrawer();
                }

                // Reset swipe tracking
                _swipeStartX = 0;
                _swipeCurrentX = 0;
              }
            : null,
        child: Stack(
          children: [
            // Global Background
            const Positioned.fill(child: AnimatedBackground()),

            Row(
              children: [
                // Persistent Sidebar for web/desktop
                if (isWideScreen) _buildSidebar(context),

                // Main content area
                Expanded(
                  child: Stack(
                    children: [
                      // Content with safe area padding
                      SafeArea(
                        child: Column(
                          children: [
                            // Main content
                            Expanded(
                              child: _showSettings
                                  ? _buildSettingsScreen(context)
                                  : widget.items[_selectedIndex].screen,
                            ),
                          ],
                        ),
                      ),

                      // Mobile Menu Button
                      if (!isWideScreen)
                        Positioned(
                          top: statusBarHeight + 8,
                          left: 12,
                          child: IconButton(
                            icon: const Icon(Icons.menu),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).cardColor.withValues(alpha: 0.5),
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSurface,
                            ),
                            onPressed: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * _maxSidebarWidthPercent;
    final effectiveWidth = _sidebarCollapsed
        ? _minSidebarWidth
        : _sidebarWidth.clamp(_minSidebarWidth, maxWidth);

    // Auto-collapse if width is too small (less than 150px)
    final shouldShowCollapsed = _sidebarCollapsed || effectiveWidth < 150;

    return Row(
      children: [
        SizedBox(
          width: effectiveWidth,
          child: GlassContainer(
            width: effectiveWidth,
            height: double.infinity,
            borderRadius: BorderRadius.zero,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            color: Theme.of(context).cardColor,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: effectiveWidth,
                child: SizedBox(
                  width: effectiveWidth,
                  child: _buildNavigationContent(context, shouldShowCollapsed),
                ),
              ),
            ),
          ),
        ),
        // Resize handle (always visible unless manually collapsed via button)
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                final newWidth = (_sidebarWidth + details.delta.dx).clamp(
                  _minSidebarWidth,
                  maxWidth,
                );
                _sidebarWidth = newWidth;

                // Auto-expand if dragging wider than threshold
                if (newWidth >= 150 && _sidebarCollapsed) {
                  _sidebarCollapsed = false;
                }
              });
            },
            child: Container(
              width: 8,
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 2,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    NavigationItem item,
    bool isSelected,
    VoidCallback onTap,
    bool forceCollapsed,
  ) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            highlightColor: Theme.of(
              context,
            ).primaryColor.withValues(alpha: 0.1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: forceCollapsed
                  ? const EdgeInsets.all(12)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.15),
                          Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: forceCollapsed
                  ? Center(
                      child: Tooltip(
                        message: item.label,
                        child: Icon(
                          isSelected
                              ? (item.activeIcon ?? item.icon)
                              : item.icon,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                          size: 22,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Icon(
                          isSelected
                              ? (item.activeIcon ?? item.icon)
                              : item.icon,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.85),
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showTransactionHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TransactionHistoryScreen(),
      ),
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
            color: Theme.of(context).primaryColor,
          ),
          title: Text(
            'Dark Mode',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          subtitle: Text(
            themeService.isSystemMode
                ? 'System default'
                : (isDark ? 'Enabled' : 'Disabled'),
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          value: isDark && !themeService.isSystemMode,
          activeThumbColor: Theme.of(context).primaryColor,
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
          Divider(height: 1, color: Theme.of(context).dividerColor),
          ListTile(
            leading: Icon(
              Icons.brightness_auto,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              'Use System Theme',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Follow system dark/light mode',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            onTap: () => themeService.setSystemTheme(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ],
        Divider(height: 1, color: Theme.of(context).dividerColor),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accent Color',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final color in AppColors.accentColors)
                    GestureDetector(
                      onTap: () => themeService.setAccentColor(color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeService.accentColor == color
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            if (themeService.accentColor == color)
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: themeService.accentColor == color
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PaymentMethodScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unlock all premium features',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
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

  Widget _buildSettingsScreen(BuildContext context) {
    final user = context.read<AuthService>().currentUser;

    return Consumer<SubscriptionService>(
      builder: (context, subscriptionService, _) {
        final status = subscriptionService.currentStatus;
        final isPremium = status?.isPremium ?? false;
        final planName = isPremium ? 'Premium' : 'Free Plan';
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              // Upgrade Button (only for free users)
              if (!isPremium) ...[
                _buildUpgradeButton(context),
                const SizedBox(height: 24),
              ],

              // User Profile Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            user?.email.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.email ?? 'User',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Row(
                                children: [
                                  if (isPremium)
                                    Icon(
                                      Icons.workspace_premium,
                                      size: 14,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  if (isPremium) const SizedBox(width: 4),
                                  Text(
                                    planName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isPremium
                                          ? Theme.of(context).primaryColor
                                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      fontWeight: isPremium ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => _handleSignOut(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                    
                    // Premium subscription details
                    if (isPremium && status != null) ...[
                      const SizedBox(height: 16),
                      Divider(color: Theme.of(context).dividerColor),
                      const SizedBox(height: 16),
                      if (status.activatedAt != null)
                        _buildInfoRow(
                          context,
                          'Activated',
                          _formatDate(status.activatedAt!),
                          Icons.check_circle_outline,
                        ),
                      if (status.expiresAt != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          'Valid Until',
                          _formatDate(status.expiresAt!),
                          Icons.event_outlined,
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showTransactionHistory(context),
                          icon: Icon(
                            Icons.receipt_long,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                          label: Text(
                            'View Transaction History',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Appearance Section
              Text(
                'Appearance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: _buildThemeToggle(context),
              ),
              const SizedBox(height: 24),

              // API Keys Section
              Text(
                'API Configuration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    ApiKeySettingsTile(
                      userId: user?.id ?? '',
                      baseUrl: ConfigService().apiBaseUrl,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildNavigationContent(
    BuildContext context,
    bool shouldShowCollapsed,
  ) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: statusBarHeight + 16),
        // App logo and Title with toggle button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: shouldShowCollapsed
              ? Center(
                  child: IconButton(
                    icon: Icon(
                      Icons.menu,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () {
                      setState(() {
                        _sidebarCollapsed = false;
                        if (_sidebarWidth < 150) {
                          _sidebarWidth = 250; // Reset to default width
                        }
                      });
                    },
                    tooltip: 'Expand sidebar',
                  ),
                )
              : Row(
                  children: [
                    if (MediaQuery.of(context).size.width >= 800)
                      IconButton(
                        icon: Icon(
                          Icons.menu_open,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () {
                          setState(() {
                            _sidebarCollapsed = true;
                          });
                        },
                        tooltip: 'Collapse sidebar',
                      ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.school,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ScholarMate',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 32),

        // Navigation items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              if (!shouldShowCollapsed)
                const Padding(
                  padding: EdgeInsets.only(left: 12, bottom: 8),
                  child: Text(
                    'LIBRARY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              for (int i = 0; i < widget.items.length; i++)
                _buildSidebarItem(
                  context,
                  widget.items[i],
                  i == _selectedIndex,
                  () {
                    // Update state immediately
                    _onItemTapped(i);
                    // Then close drawer if open (on mobile)
                    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                      Navigator.of(context).pop();
                    }
                  },
                  shouldShowCollapsed,
                ),
            ],
          ),
        ),

        // Settings section at bottom
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
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
              () {
                // Update state immediately
                _toggleSettings();
                // Then close drawer if open (on mobile)
                if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                  Navigator.of(context).pop();
                }
              },
              shouldShowCollapsed,
            ),
          ),
        ),
      ],
    );
  }
}
