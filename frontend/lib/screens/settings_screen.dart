import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/simple_theme_service.dart';
import '../services/subscription_service.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../widgets/subscription_section.dart';
import 'payment_method_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure subscription status is loaded when settings screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final subscriptionService = context.read<SubscriptionService>();
        debugPrint('Loading subscription status from settings screen...');
        subscriptionService
            .loadSubscriptionStatus()
            .then((_) {
              debugPrint('Subscription status loaded successfully');
              if (mounted) setState(() {}); // Force rebuild
            })
            .catchError((e) {
              debugPrint('Failed to load subscription status in settings: $e');
              if (mounted) setState(() {}); // Force rebuild even on error
            });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: Consumer2<SimpleThemeService, SubscriptionService>(
        builder: (context, themeService, subscriptionService, _) {
          // Show upgrade button unless user is confirmed premium
          final currentStatus = subscriptionService.currentStatus;
          final isPremium = currentStatus?.isPremium ?? false;
          final showUpgrade = !isPremium;

          debugPrint(
            'Settings rebuild: status=$currentStatus, isPremium=$isPremium, showUpgrade=$showUpgrade',
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Upgrade button - ALWAYS SHOW FOR TESTING
              _buildUpgradeButton(context),
              const SizedBox(height: 24),

              _buildSectionHeader(context, 'Subscription'),
              const SizedBox(height: 16),
              const SubscriptionSection(),

              const SizedBox(height: 32),
              _buildSectionHeader(context, 'Appearance'),
              const SizedBox(height: 16),
              _buildThemeModeSelector(context, themeService),
              const SizedBox(height: 24),
              _buildAccentColorSelector(context, themeService),

              const SizedBox(height: 32),
              _buildSectionHeader(context, 'About'),
              const SizedBox(height: 16),
              _buildAboutSection(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUpgradeButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PaymentMethodScreen()),
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
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildThemeModeSelector(
    BuildContext context,
    SimpleThemeService themeService,
  ) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(16),
      border: Border.all(color: Theme.of(context).dividerColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme Mode',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildThemeOption(
                context,
                icon: Icons.brightness_auto,
                label: 'System',
                isSelected: themeService.isSystemMode,
                onTap: themeService.setSystemTheme,
              ),
              const SizedBox(width: 12),
              _buildThemeOption(
                context,
                icon: Icons.light_mode,
                label: 'Light',
                isSelected: themeService.isLightMode,
                onTap: themeService.setLightTheme,
              ),
              const SizedBox(width: 12),
              _buildThemeOption(
                context,
                icon: Icons.dark_mode,
                label: 'Dark',
                isSelected: themeService.isDarkMode,
                onTap: themeService.setDarkTheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? Theme.of(context).primaryColor
        : (isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05));
    final textColor = isSelected
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: textColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccentColorSelector(
    BuildContext context,
    SimpleThemeService themeService,
  ) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(16),
      border: Border.all(color: Theme.of(context).dividerColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Accent Color',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: themeService.accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildColorOption(
                themeService,
                const Color(0xFF6366F1),
              ), // Indigo
              _buildColorOption(themeService, const Color(0xFF3B82F6)), // Blue
              _buildColorOption(
                themeService,
                const Color(0xFF10B981),
              ), // Emerald
              _buildColorOption(themeService, const Color(0xFFF59E0B)), // Amber
              _buildColorOption(themeService, const Color(0xFFEF4444)), // Red
              _buildColorOption(
                themeService,
                const Color(0xFF8B5CF6),
              ), // Violet
              _buildColorOption(themeService, const Color(0xFFEC4899)), // Pink
              _buildCustomColorButton(context, themeService),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(SimpleThemeService themeService, Color color) {
    final isSelected = themeService.accentColor.value == color.value;

    return GestureDetector(
      onTap: () => themeService.setAccentColor(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  width: 3,
                )
              : null,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: color.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
                size: 20,
              )
            : null,
      ),
    );
  }

  Widget _buildCustomColorButton(
    BuildContext context,
    SimpleThemeService themeService,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showColorPicker(context, themeService),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  void _showColorPicker(BuildContext context, SimpleThemeService themeService) {
    Color pickerColor = themeService.accentColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Pick a color',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ModernButton(
            label: 'Select',
            onPressed: () {
              themeService.setAccentColor(pickerColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(16),
      border: Border.all(color: Theme.of(context).dividerColor),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Text(
                'Version',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '1.0.0',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          Divider(color: Theme.of(context).dividerColor, height: 32),
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Text(
                'Terms of Service',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Text(
                'Privacy Policy',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
