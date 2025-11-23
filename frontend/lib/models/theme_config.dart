import 'package:flutter/material.dart';

/// Theme configuration model for ScholarMate
/// Supports serialization for persistence and sync across devices
class ThemeConfig {
  final String id;
  final String name;
  final ThemeMode mode; // light, dark
  final Color accentColor;
  final String? customBackground; // Optional background image URL

  const ThemeConfig({
    required this.id,
    required this.name,
    required this.mode,
    required this.accentColor,
    this.customBackground,
  });

  /// Convert theme config to JSON for persistence
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mode': mode.name,
    'accentColor': accentColor.toARGB32(),
    'customBackground': customBackground,
  };

  /// Create theme config from JSON
  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      mode: ThemeMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => ThemeMode.light,
      ),
      accentColor: Color(json['accentColor'] as int),
      customBackground: json['customBackground'] as String?,
    );
  }

  /// Create a copy with modified fields
  ThemeConfig copyWith({
    String? id,
    String? name,
    ThemeMode? mode,
    Color? accentColor,
    String? customBackground,
  }) {
    return ThemeConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      accentColor: accentColor ?? this.accentColor,
      customBackground: customBackground ?? this.customBackground,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ThemeConfig &&
        other.id == id &&
        other.name == name &&
        other.mode == mode &&
        other.accentColor.toARGB32() == accentColor.toARGB32() &&
        other.customBackground == customBackground;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      mode,
      accentColor.toARGB32(),
      customBackground,
    );
  }

  @override
  String toString() {
    return 'ThemeConfig(id: $id, name: $name, mode: $mode, accentColor: $accentColor, customBackground: $customBackground)';
  }

  // Predefined theme configurations
  static const ThemeConfig defaultLight = ThemeConfig(
    id: 'light',
    name: 'Light',
    mode: ThemeMode.light,
    accentColor: Color(0xFF06B6D4), // Cyan 500
  );

  static const ThemeConfig defaultDark = ThemeConfig(
    id: 'dark',
    name: 'Dark',
    mode: ThemeMode.dark,
    accentColor: Color(0xFF06B6D4), // Cyan 500
  );

  static const ThemeConfig midnightBlue = ThemeConfig(
    id: 'midnight_blue',
    name: 'Midnight Blue',
    mode: ThemeMode.dark,
    accentColor: Color(0xFF3B82F6), // Blue 500
  );

  static const ThemeConfig forestGreen = ThemeConfig(
    id: 'forest_green',
    name: 'Forest Green',
    mode: ThemeMode.dark,
    accentColor: Color(0xFF22C55E), // Green 500
  );

  static const ThemeConfig sunsetOrange = ThemeConfig(
    id: 'sunset_orange',
    name: 'Sunset Orange',
    mode: ThemeMode.dark,
    accentColor: Color(0xFFFB923C), // Orange 400
  );

  /// Get all predefined theme configurations
  static List<ThemeConfig> get allPresets => [
    defaultLight,
    defaultDark,
    midnightBlue,
    forestGreen,
    sunsetOrange,
  ];
}
