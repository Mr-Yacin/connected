import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/preferences_service.dart';

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

  ThemeMode toThemeMode({Brightness systemBrightness = Brightness.light}) {
    switch (this) {
      case ThemeOption.system:
        return systemBrightness == Brightness.dark 
            ? ThemeMode.dark 
            : ThemeMode.light;
      case ThemeOption.light:
        return ThemeMode.light;
      case ThemeOption.dark:
        return ThemeMode.dark;
    }
  }
}

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final PreferencesService _preferences;
  final Ref _ref;
  late final VoidCallback _platformBrightnessListener;
  
  ThemeNotifier(this._preferences, this._ref) : super(ThemeMode.dark) {
    _initializeTheme();
    _setupPlatformListener();
  }

  Future<void> _initializeTheme() async {
    try {
      final savedThemeOption = await _preferences.getThemeOption();
      final systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      
      state = savedThemeOption.toThemeMode(systemBrightness: systemBrightness);
    } catch (e) {
      state = ThemeMode.dark;
    }
  }

  void _setupPlatformListener() {
    _platformBrightnessListener = () {
      final savedThemeOption = _preferences.getThemeOptionSync();
      if (savedThemeOption == ThemeOption.system) {
        final systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        state = systemBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
      }
    };
    
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = 
        _platformBrightnessListener;
  }

  Future<void> setThemeOption(ThemeOption option) async {
    try {
      await _preferences.setThemeOption(option);
      
      if (option == ThemeOption.system) {
        final systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        state = systemBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
      } else {
        state = option.toThemeMode();
      }
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  ThemeOption getCurrentThemeOption() {
    return _preferences.getThemeOptionSync();
  }

  bool isDarkMode() {
    return state == ThemeMode.dark;
  }

  bool isSystemMode() {
    return getCurrentThemeOption() == ThemeOption.system;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = null;
    super.dispose();
  }
}

// Provider for the preferences service
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

// Provider for the theme notifier
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final preferences = ref.watch(preferencesServiceProvider);
  return ThemeNotifier(preferences, ref);
});

// Provider for the current theme option
final currentThemeOptionProvider = Provider<ThemeOption>((ref) {
  final themeNotifier = ref.watch(themeProvider.notifier);
  return themeNotifier.getCurrentThemeOption();
});

