import 'package:shared_preferences/shared_preferences.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/theme/theme_option.dart';

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
    } catch (e) {
      throw AppException('فشل حفظ الإعدادات: $e');
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
    } catch (e) {
      throw AppException('فشل جلب الإعدادات: $e');
    }
  }

  /// Save language preference
  Future<void> saveLanguage(String language) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(_languageKey, language);
    } catch (e) {
      throw AppException('فشل حفظ اللغة: $e');
    }
  }

  /// Get language preference
  Future<String> getLanguage() async {
    try {
      final prefs = await _preferences;
      return prefs.getString(_languageKey) ?? 'ar';
    } catch (e) {
      throw AppException('فشل جلب اللغة: $e');
    }
  }

  /// Save dark mode preference
  Future<void> saveDarkMode(bool isDarkMode) async {
    try {
      final prefs = await _preferences;
      await prefs.setBool(_darkModeKey, isDarkMode);
    } catch (e) {
      throw AppException('فشل حفظ وضع الظلام: $e');
    }
  }

  /// Get dark mode preference
  Future<bool> getDarkMode() async {
    try {
      final prefs = await _preferences;
      return prefs.getBool(_darkModeKey) ?? true;
    } catch (e) {
      throw AppException('فشل جلب وضع الظلام: $e');
    }
  }

  /// Clear all preferences
  Future<void> clearPreferences() async {
    try {
      final prefs = await _preferences;
      await prefs.remove(_languageKey);
      await prefs.remove(_darkModeKey);
      await prefs.remove(_themeOptionKey);
    } catch (e) {
      throw AppException('فشل مسح الإعدادات: $e');
    }
  }

  /// Save theme option preference
  Future<void> setThemeOption(ThemeOption option) async {
    try {
      final prefs = await _preferences;
      await prefs.setInt(_themeOptionKey, option.value);
    } catch (e) {
      throw AppException('فشل حفظ خيار الثيم: $e');
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
