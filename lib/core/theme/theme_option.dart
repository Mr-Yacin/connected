import 'package:flutter/material.dart';

enum ThemeOption {
  system(0, 'System', 'icons.smartphone'),
  light(1, 'Light', 'light_mode'),
  dark(2, 'Dark', 'dark_mode');

  const ThemeOption(this.value, this.label, this.icon);
  final int value;
  final String label;
  final String icon;

  static ThemeOption fromValue(int value) {
    return ThemeOption.values.firstWhere(
      (option) => option.value == value,
      orElse: () => ThemeOption.system,
    );
  }

  ThemeMode toThemeMode() {
    switch (this) {
      case ThemeOption.system:
        return ThemeMode.system;
      case ThemeOption.light:
        return ThemeMode.light;
      case ThemeOption.dark:
        return ThemeMode.dark;
    }
  }
}
