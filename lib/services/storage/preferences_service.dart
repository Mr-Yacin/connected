import 'package:shared_preferences/shared_preferences.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/theme/theme_option.dart';
import '../monitoring/error_logging_service.dart';

/// User preferences model
class UserPreferences {
  final String language;
  final bool isDarkMode;

  UserPreferences({required this.language, required this.isDarkMode});

  Map<String, dynamic> toJson() {
    return {'language': language, 'isDarkMode': isDarkMode};
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      language: json['language'] as String? ?? 'ar',
      isDarkMode: json['isDarkMode'] as bool? ?? true,
    );
  }

  UserPreferences copyWith({String? language, bool? isDarkMode}) {
    return UserPreferences(
      language: language ?? this.language,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserPreferences &&
        other.language == language &&
        other.isDarkMode == isDarkMode;
  }

  @override
  int get hashCode => Object.hash(language, isDarkMode);
}

/// Service for managing user preferences (language, theme, etc.)
class PreferencesService {
  static const String _languageKey = 'user_language';
  static const String _darkModeKey = 'user_dark_mode';
  static const String _themeOptionKey = 'theme_option';

  final SharedPreferences? _prefs;

  PreferencesService({SharedPreferences? prefs}) : _prefs = prefs;

  /// Get SharedPreferences instance
  Future<SharedPreferences> get _preferences async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Save user preferences
  Future<void> savePreferences(UserPreferences preferences) async {
    try {
      final prefs = await _preferences;

      await prefs.setString(_languageKey, preferences.language);
      await prefs.setBool(_darkModeKey, preferences.isDarkMode);
    } catch (e, stackTrace) {
      // Log error with full context
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to save user preferences',
        screen: 'PreferencesService',
        operation: 'savePreferences',
      );
      
      throw AppException('فشل حفظ الإعدادات');
    }
  }

  /// Get user preferences
  /// Returns default preferences if none are saved
  Future<UserPreferences> getPreferences() async {
    try {
      final prefs = await _preferences;

      final language = prefs.getString(_languageKey) ?? 'ar';
      final isDarkMode = prefs.getBool(_darkModeKey) ?? true;

      return UserPreferences(language: language, isDarkMode: isDarkMode);
    } catch (e, stackTrace) {
      // Log error with full context
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get user preferences',
        screen: 'PreferencesService',
        operation: 'getPreferences',
      );
      
      throw AppException('فشل جلب الإعدادات');
    }
  }

  /// Save language preference
  Future<void> saveLanguage(String language) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(_languageKey, language);
    } catch (e, stackTrace) {
      // Log error with full context
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to save language preference',
        screen: 'PreferencesService',
        operation: 'saveLanguage',
      );
      
      throw AppException('فشل حفظ اللغة');
    }
  }

  /// Get language preference
  Future<String> getLanguage() async {
    try {
      final prefs = await _preferences;
      return prefs.getString(_languageKey) ?? 'ar';
    } catch (e, stackTrace) {
      // Log error with full context
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get language preference',
        screen: 'PreferencesService',
        operation: 'getLanguage',
      );
      
      throw AppException('فشل جلب اللغة');
    }
  }

  /// Save dark mode preference
  Future<void> saveDarkMode(bool isDarkMode) async {
    try {
      final prefs = await _preferences;
      await prefs.setBool(_darkModeKey, isDarkMode);
    } catch (e, stackTrace) {
      // Log error with full context
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to save dark mode preference',
        screen: 'PreferencesService',
        operation: 'saveDarkMode',
      );
      
      throw AppException('فشل حفظ وضع الظلام');
    }
  }

  /// Get dark mode preference
  Future<bool> getDarkMode() async {
    try {
      final prefs = await _preferences;
      return prefs.getBool(_darkModeKey) ?? true;
    } catch (e, stackTrace) {
      // Log error with full context
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get dark mode preference',
        screen: 'PreferencesService',
        operation: 'getDarkMode',
      );
      
      throw AppException('فشل جلب وضع الظلام');
    }
  }

  /// Clear all preferences
  Future<void> clearPreferences() async {
    try {
      final prefs = await _preferences;
      await prefs.remove(_languageKey);
      await prefs.remove(_darkModeKey);
      await prefs.remove(_themeOptionKey);
    } catch (e, stackTrace) {
      // Log error with full context
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to clear preferences',
        screen: 'PreferencesService',
        operation: 'clearPreferences',
      );
      
      throw AppException('فشل مسح الإعدادات');
    }
  }

  /// Save theme option preference
  Future<void> setThemeOption(ThemeOption option) async {
    try {
      final prefs = await _preferences;
      await prefs.setInt(_themeOptionKey, option.value);
    } catch (e, stackTrace) {
      // Log error with full context
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to save theme option',
        screen: 'PreferencesService',
        operation: 'setThemeOption',
      );
      
      throw AppException('فشل حفظ خيار الثيم');
    }
  }

  /// Get theme option preference
  Future<ThemeOption> getThemeOption() async {
    try {
      final prefs = await _preferences;
      final value = prefs.getInt(_themeOptionKey) ?? ThemeOption.system.value;
      return ThemeOption.fromValue(value);
    } catch (e) {
      return ThemeOption.system;
    }
  }

  /// Get theme option preference (synchronous version)
  ThemeOption getThemeOptionSync() {
    try {
      final value = _prefs?.getInt(_themeOptionKey) ?? ThemeOption.system.value;
      return ThemeOption.fromValue(value);
    } catch (e) {
      return ThemeOption.system;
    }
  }
}
