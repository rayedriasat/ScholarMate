import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/theme_presets.dart';
import 'package:frontend/theme/design_tokens.dart';

void main() {
  group('ThemePresets', () {
    test('Light theme should have correct brightness', () {
      final theme = ThemePresets.light();
      expect(theme.brightness, equals(Brightness.light));
    });

    test('Dark theme should have correct brightness', () {
      final theme = ThemePresets.dark();
      expect(theme.brightness, equals(Brightness.dark));
    });

    test('Midnight blue theme should have correct brightness', () {
      final theme = ThemePresets.midnightBlue();
      expect(theme.brightness, equals(Brightness.dark));
    });

    test('Forest green theme should have correct brightness', () {
      final theme = ThemePresets.forestGreen();
      expect(theme.brightness, equals(Brightness.dark));
    });

    test('Sunset orange theme should have correct brightness', () {
      final theme = ThemePresets.sunsetOrange();
      expect(theme.brightness, equals(Brightness.dark));
    });

    test('All themes should use Inter font family', () {
      final themes = [
        ThemePresets.light(),
        ThemePresets.dark(),
        ThemePresets.midnightBlue(),
        ThemePresets.forestGreen(),
        ThemePresets.sunsetOrange(),
      ];

      for (final theme in themes) {
        expect(
          theme.textTheme.bodyLarge?.fontFamily,
          equals(DesignTokens.fontFamily),
        );
      }
    });

    test('Light theme should accept custom accent color', () {
      const customAccent = Color(0xFFFF5722);
      final theme = ThemePresets.light(accentColor: customAccent);
      expect(theme.colorScheme.tertiary, equals(customAccent));
    });

    test('Dark theme should accept custom accent color', () {
      const customAccent = Color(0xFFFF5722);
      final theme = ThemePresets.dark(accentColor: customAccent);
      expect(theme.colorScheme.tertiary, equals(customAccent));
    });

    test('All themes should use Material 3', () {
      final themes = [
        ThemePresets.light(),
        ThemePresets.dark(),
        ThemePresets.midnightBlue(),
        ThemePresets.forestGreen(),
        ThemePresets.sunsetOrange(),
      ];

      for (final theme in themes) {
        expect(theme.useMaterial3, isTrue);
      }
    });

    test('Light theme should have correct scaffold background', () {
      final theme = ThemePresets.light();
      expect(theme.scaffoldBackgroundColor, equals(DesignTokens.neutral[50]!));
    });

    test('Dark theme should have correct scaffold background', () {
      final theme = ThemePresets.dark();
      expect(theme.scaffoldBackgroundColor, equals(DesignTokens.neutral[900]!));
    });

    test('All themes should have zero elevation on cards', () {
      final themes = [
        ThemePresets.light(),
        ThemePresets.dark(),
        ThemePresets.midnightBlue(),
        ThemePresets.forestGreen(),
        ThemePresets.sunsetOrange(),
      ];

      for (final theme in themes) {
        expect(theme.cardTheme.elevation, equals(0));
      }
    });

    test('All themes should have rounded card borders', () {
      final themes = [
        ThemePresets.light(),
        ThemePresets.dark(),
        ThemePresets.midnightBlue(),
        ThemePresets.forestGreen(),
        ThemePresets.sunsetOrange(),
      ];

      for (final theme in themes) {
        expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      }
    });
  });
}
