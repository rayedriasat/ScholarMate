import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/simple_theme_service.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../widgets/subscription_section.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<SimpleThemeService>(
        builder: (context, themeService, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Subscription'),
              const SizedBox(height: 16),
              const SubscriptionSection(),

              const SizedBox(height: 32),
              _buildSectionHeader('Appearance'),
              const SizedBox(height: 16),
              _buildThemeModeSelector(context, themeService),
              const SizedBox(height: 24),
              _buildAccentColorSelector(context, themeService),

              const SizedBox(height: 32),
              _buildSectionHeader('About'),
              const SizedBox(height: 16),
              _buildAboutSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
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
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Theme Mode',
            style: TextStyle(
              color: Colors.white,
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
    final color = isSelected
        ? AppColors.primary
        : Colors.white.withValues(alpha: 0.1);
    final textColor = isSelected ? Colors.white : Colors.white70;

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
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.1),
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
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Accent Color',
                style: TextStyle(
                  color: Colors.white,
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
                  border: Border.all(color: Colors.white, width: 2),
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
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
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
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  Widget _buildCustomColorButton(
    BuildContext context,
    SimpleThemeService themeService,
  ) {
    return GestureDetector(
      onTap: () => _showColorPicker(context, themeService),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showColorPicker(BuildContext context, SimpleThemeService themeService) {
    Color pickerColor = themeService.accentColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Pick a color',
          style: TextStyle(color: Colors.white),
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

  Widget _buildAboutSection() {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white70),
              SizedBox(width: 12),
              Text(
                'Version',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Spacer(),
              Text('1.0.0', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const Divider(color: Colors.white10, height: 32),
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Colors.white70),
              const SizedBox(width: 12),
              const Text(
                'Terms of Service',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.privacy_tip_outlined, color: Colors.white70),
              const SizedBox(width: 12),
              const Text(
                'Privacy Policy',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
