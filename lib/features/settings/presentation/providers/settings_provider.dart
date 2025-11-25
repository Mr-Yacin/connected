import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/preferences_service.dart';
import '../../../../services/user_data_service.dart';

/// Provider for PreferencesService
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

/// Provider for UserDataService
final userDataServiceProvider = Provider<UserDataService>((ref) {
  return UserDataService();
});

/// State for settings
class SettingsState {
  final UserPreferences preferences;
  final bool isLoading;
  final String? error;

  SettingsState({
    required this.preferences,
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    UserPreferences? preferences,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Settings provider for managing user preferences and account operations
class SettingsNotifier extends StateNotifier<SettingsState> {
  final PreferencesService _preferencesService;
  final UserDataService _userDataService;

  SettingsNotifier(this._preferencesService, this._userDataService)
      : super(SettingsState(
          preferences: UserPreferences(language: 'ar', isDarkMode: true),
        )) {
    _loadPreferences();
  }

  /// Load user preferences
  Future<void> _loadPreferences() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final preferences = await _preferencesService.getPreferences();
      state = state.copyWith(preferences: preferences, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحميل الإعدادات: $e',
      );
    }
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode() async {
    try {
      final newDarkMode = !state.preferences.isDarkMode;
      await _preferencesService.saveDarkMode(newDarkMode);
      state = state.copyWith(
        preferences: state.preferences.copyWith(isDarkMode: newDarkMode),
      );
    } catch (e) {
      state = state.copyWith(error: 'فشل تغيير الوضع: $e');
    }
  }

  /// Change language
  Future<void> changeLanguage(String language) async {
    try {
      await _preferencesService.saveLanguage(language);
      state = state.copyWith(
        preferences: state.preferences.copyWith(language: language),
      );
    } catch (e) {
      state = state.copyWith(error: 'فشل تغيير اللغة: $e');
    }
  }

  /// Export user data
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final data = await _userDataService.exportUserData(userId);
      state = state.copyWith(isLoading: false);
      return data;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تصدير البيانات: $e',
      );
      rethrow;
    }
  }

  /// Delete user account
  Future<void> deleteAccount(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _userDataService.deleteUserAccount(userId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل حذف الحساب: $e',
      );
      rethrow;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for settings notifier
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final preferencesService = ref.watch(preferencesServiceProvider);
  final userDataService = ref.watch(userDataServiceProvider);
  return SettingsNotifier(preferencesService, userDataService);
});
