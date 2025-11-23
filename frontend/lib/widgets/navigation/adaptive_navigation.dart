import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import 'desktop_sidebar.dart';
import 'mobile_bottom_bar.dart';
import 'mobile_drawer.dart';

/// Navigation destination model for adaptive navigation
class AppNavigationDestination {
  final String id;
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Widget screen;

  const AppNavigationDestination({
    required this.id,
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.screen,
  });
}

/// Adaptive navigation wrapper that switches between desktop sidebar
/// and mobile bottom navigation based on screen size
class AdaptiveNavigation extends StatefulWidget {
  final List<AppNavigationDestination> destinations;
  final int initialIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget? floatingActionButton;

  const AdaptiveNavigation({
    super.key,
    required this.destinations,
    this.initialIndex = 0,
    this.onDestinationSelected,
    this.floatingActionButton,
  });

  @override
  State<AdaptiveNavigation> createState() => _AdaptiveNavigationState();
}

class _AdaptiveNavigationState extends State<AdaptiveNavigation> {
  late int _selectedIndex;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _showSettings = false;
    });
    widget.onDestinationSelected?.call(index);
  }

  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= DesignTokens.tabletBreakpoint;
    final isExpanded = width >= 1200;

    // Current screen to display
    final currentScreen = _showSettings
        ? _buildSettingsPlaceholder()
        : widget.destinations[_selectedIndex].screen;

    if (isDesktop) {
      // Desktop: Sidebar navigation
      return Row(
        children: [
          DesktopSidebar(
            destinations: widget.destinations,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            expanded: isExpanded,
            showSettings: _showSettings,
            onSettingsTap: _toggleSettings,
          ),
          Expanded(child: currentScreen),
        ],
      );
    } else {
      // Mobile: Bottom navigation + drawer
      return Scaffold(
        body: currentScreen,
        bottomNavigationBar: MobileBottomBar(
          destinations: widget.destinations,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          showSettings: _showSettings,
          onSettingsTap: _toggleSettings,
        ),
        drawer: MobileDrawer(
          destinations: widget.destinations,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            _onDestinationSelected(index);
            Navigator.of(context).pop(); // Close drawer
          },
          showSettings: _showSettings,
          onSettingsTap: () {
            _toggleSettings();
            Navigator.of(context).pop(); // Close drawer
          },
        ),
        floatingActionButton: _showSettings
            ? null
            : widget.floatingActionButton,
      );
    }
  }

  Widget _buildSettingsPlaceholder() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading:
            MediaQuery.of(context).size.width < DesignTokens.tabletBreakpoint
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showSettings = false),
              )
            : null,
      ),
      body: const Center(child: Text('Settings screen placeholder')),
    );
  }
}
