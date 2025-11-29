import 'package:flutter/foundation.dart';

/// Application logger that only logs in debug mode.
/// All logging is automatically disabled in release builds.
class AppLogger {
  static const bool _enableLogging = kDebugMode;

  /// Log a general message
  static void log(String message) {
    if (_enableLogging) {
      debugPrint(message);
    }
  }

  /// Log an info message
  static void info(String message) {
    if (_enableLogging) {
      debugPrint('ℹ️ INFO: $message');
    }
  }

  /// Log a warning message
  static void warning(String message) {
    if (_enableLogging) {
      debugPrint('⚠️ WARNING: $message');
    }
  }

  /// Log an error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_enableLogging) {
      debugPrint('❌ ERROR: $message${error != null ? '\nError: $error' : ''}');
      if (stackTrace != null) {
        debugPrint('Stack trace:\n$stackTrace');
      }
    }
  }

  /// Log a debug message (same as log but more explicit)
  static void debug(String message) {
    if (_enableLogging) {
      debugPrint('🐛 DEBUG: $message');
    }
  }

  /// Log a success message
  static void success(String message) {
    if (_enableLogging) {
      debugPrint('✅ SUCCESS: $message');
    }
  }
}
