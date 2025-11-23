import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/glass_theme.dart';

void main() {
  group('GlassThemeConfig', () {
    test('Default constructor should use correct default values', () {
      final config = GlassThemeConfig(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0.5)],
        ),
      );

      expect(config.blur, equals(10.0));
      expect(config.opacity, equals(0.1));
      expect(config.borderWidth, equals(1.0));
      expect(config.borderColor, equals(const Color(0x33FFFFFF)));
    });

    test('Light theme should have correct configuration', () {
      final config = GlassThemeConfig.light();

      expect(config.blur, equals(10.0));
      expect(config.opacity, equals(0.15));
      expect(config.borderColor, equals(const Color(0x33FFFFFF)));
    });

    test('Dark theme should have correct configuration', () {
      final config = GlassThemeConfig.dark();

      expect(config.blur, equals(10.0));
      expect(config.opacity, equals(0.1));
      expect(config.borderColor, equals(const Color(0x1AFFFFFF)));
    });

    test('Midnight blue theme should have correct configuration', () {
      final config = GlassThemeConfig.midnightBlue();

      expect(config.blur, equals(10.0));
      expect(config.opacity, equals(0.12));
    });

    test('Forest green theme should have correct configuration', () {
      final config = GlassThemeConfig.forestGreen();

      expect(config.blur, equals(10.0));
      expect(config.opacity, equals(0.12));
    });

    test('Sunset orange theme should have correct configuration', () {
      final config = GlassThemeConfig.sunsetOrange();

      expect(config.blur, equals(10.0));
      expect(config.opacity, equals(0.12));
    });

    test('copyWith should preserve unchanged values', () {
      final original = GlassThemeConfig.light();
      final copied = original.copyWith(blur: 15.0);

      expect(copied.blur, equals(15.0));
      expect(copied.opacity, equals(original.opacity));
      expect(copied.borderColor, equals(original.borderColor));
      expect(copied.borderWidth, equals(original.borderWidth));
    });

    test('copyWith should update specified values', () {
      final original = GlassThemeConfig.light();
      final copied = original.copyWith(
        blur: 20.0,
        opacity: 0.2,
        borderWidth: 2.0,
      );

      expect(copied.blur, equals(20.0));
      expect(copied.opacity, equals(0.2));
      expect(copied.borderWidth, equals(2.0));
    });
  });
}
