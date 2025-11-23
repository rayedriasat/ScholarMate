import 'package:flutter/material.dart';
import '../models/theme_config.dart';
import 'app_theme.dart';

/// Example demonstrating how to use the theme system
/// This file shows various ways to interact with themes
class ThemeUsageExample extends StatelessWidget {
  const ThemeUsageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme System Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Example 1: Display current theme info
          const _CurrentThemeInfo(),
          const SizedBox(height: 24),

          // Example 2: Theme preset selector
          const _ThemePresetSelector(),
          const SizedBox(height: 24),

          // Example 3: Accent color picker
          const _AccentColorPicker(),
          const SizedBox(height: 24),

          // Example 4: Reset to defaults
          const _ResetThemeButton(),
        ],
      ),
    );
  }
}

/// Widget showing current theme information
class _CurrentThemeInfo extends StatelessWidget {
  const _CurrentThemeInfo();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watchThemeProvider;
    final theme = themeProvider.currentTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Theme',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Name: ${theme.name}'),
            Text('Mode: ${theme.mode.name}'),
            Row(
              children: [
                const Text('Accent Color: '),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.accentColor,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            Text('Is Dark: ${themeProvider.isDark}'),
          ],
        ),
      ),
    );
  }
}

/// Widget for selecting theme presets
class _ThemePresetSelector extends StatelessWidget {
  const _ThemePresetSelector();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watchThemeProvider;
    final currentTheme = themeProvider.currentTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Presets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...ThemeConfig.allPresets.map((preset) {
              final isSelected = preset.id == currentTheme.id;
              return ListTile(
                title: Text(preset.name),
                leading: Radio<String>(
                  value: preset.id,
                  groupValue: currentTheme.id,
                  onChanged: (value) {
                    context.themeProvider.setThemeConfig(preset);
                  },
                ),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: preset.accentColor,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onTap: () {
                  context.themeProvider.setThemeConfig(preset);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Widget for picking accent color
class _AccentColorPicker extends StatelessWidget {
  const _AccentColorPicker();

  static const List<Color> _accentColors = [
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Green
    Color(0xFF14B8A6), // Teal
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watchThemeProvider;
    final currentAccent = themeProvider.accentColor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Accent Color', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _accentColors.map((color) {
                final isSelected = color.toARGB32() == currentAccent.toARGB32();
                return InkWell(
                  onTap: () {
                    context.themeProvider.setAccentColor(color);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.grey,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for resetting theme to defaults
class _ResetThemeButton extends StatelessWidget {
  const _ResetThemeButton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reset Theme', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Reset all theme settings to default values',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                await context.themeProvider.resetToDefaults();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Theme reset to defaults')),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset to Defaults'),
            ),
          ],
        ),
      ),
    );
  }
}
