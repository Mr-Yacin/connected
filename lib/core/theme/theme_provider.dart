import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/storage/preferences_service.dart';

import 'theme_option.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final PreferencesService _preferences;

  ThemeNotifier(this._preferences, Ref ref) : super(ThemeMode.system) {
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    try {
      final savedThemeOption = await _preferences.getThemeOption();
      state = savedThemeOption.toThemeMode();
    } catch (e) {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeOption(ThemeOption option) async {
    try {
      // Update state immediately
      state = option.toThemeMode();

      // Save to preferences asynchronously
      await _preferences.setThemeOption(option);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  ThemeOption getCurrentThemeOption() {
    return _preferences.getThemeOptionSync();
  }

  bool isDarkMode() {
    if (state == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return state == ThemeMode.dark;
  }

  bool isSystemMode() {
    return state == ThemeMode.system;
  }
}

// Provider for SharedPreferences instance - initialized once at app startup
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

// Provider for the preferences service with initialized SharedPreferences
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesService(prefs: prefs);
});

// Provider for the theme notifier
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final preferences = ref.watch(preferencesServiceProvider);
  return ThemeNotifier(preferences, ref);
});

// Provider for the current theme option - watches actual saved preference
final currentThemeOptionProvider = Provider<ThemeOption>((ref) {
  // Watch the theme provider to trigger rebuilds when theme changes
  ref.watch(themeProvider);
  final preferences = ref.watch(preferencesServiceProvider);
  return preferences.getThemeOptionSync();
});
