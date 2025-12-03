// ignore_for_file: avoid_print
// Print statements are the intended logging mechanism for this service

import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:uuid/uuid.dart';

/// Log levels for structured logging
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Centralized logging service with structured log levels and production filtering
/// Provides consistent logging across the application with automatic Crashlytics
/// and Analytics integration in production mode.
class AppLogger {
  static bool _isProduction = kReleaseMode;
  static String? _userId;
  static String? _sessionId;

  // ANSI color codes for terminal output
  static const String _cyan = '\x1B[36m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _reset = '\x1B[0m';
  static const String _bold = '\x1B[1m';

  /// Initialize the logger with optional user ID
  /// Generates a unique session ID for tracking
  static void initialize({String? userId}) {
    _userId = userId;
    _sessionId = const Uuid().v4();
    
    if (kDebugMode) {
      print('$_green${_bold}AppLogger initialized$_reset');
      print('${_green}Session ID: $_sessionId$_reset');
      if (userId != null) {
        print('${_green}User ID: $userId$_reset\n');
      }
    }
  }

  /// Update the user ID (e.g., after login)
  static void setUserId(String? userId) {
    _userId = userId;
    
    if (kDebugMode && userId != null) {
      print('${_green}AppLogger: User ID set to $userId$_reset');
    }
  }

  /// Log a debug message (filtered out in production)
  static void debug(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, data: data);
  }

  /// Log an info message (filtered out in production)
  static void info(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, data: data);
  }

  /// Log a warning message
  static void warning(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, data: data);
  }

  /// Log an error message with optional error object and stack trace
  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Core logging method
  static void _log(
    LogLevel level,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // Skip debug/info logs in production
    if (_isProduction && (level == LogLevel.debug || level == LogLevel.info)) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final logData = {
      'timestamp': timestamp,
      'level': level.name,
      'message': message,
      if (_userId != null) 'userId': _userId,
      if (_sessionId != null) 'sessionId': _sessionId,
      if (data != null) ...data,
    };

    if (kDebugMode) {
      // Console output in debug mode with colors
      _printColoredLog(level, timestamp, message, data, error, stackTrace);
    } else {
      // Send to Crashlytics and Analytics in production
      _logToProduction(level, message, error, stackTrace, logData);
    }
  }

  /// Print colored log to console in debug mode
  static void _printColoredLog(
    LogLevel level,
    String timestamp,
    String message,
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    final color = _getColorForLevel(level);
    final levelName = level.name.toUpperCase();

    print('$color$_bold[$levelName] $timestamp$_reset');
    print('$color$message$_reset');

    if (data != null && data.isNotEmpty) {
      print('${color}Data:$_reset');
      data.forEach((key, value) {
        print('  $key: $value');
      });
    }

    if (error != null) {
      print('${_red}Error: $error$_reset');
    }

    if (stackTrace != null) {
      print('${_yellow}Stack Trace:$_reset');
      final stackLines = stackTrace.toString().split('\n').take(3);
      for (final line in stackLines) {
        print('  $line');
      }
    }

    print(''); // Empty line for readability
  }

  /// Log to production services (Crashlytics and Analytics)
  static void _logToProduction(
    LogLevel level,
    String message,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic> logData,
  ) {
    try {
      // Set custom keys in Crashlytics for filtering
      final crashlytics = FirebaseCrashlytics.instance;
      
      logData.forEach((key, value) {
        crashlytics.setCustomKey(key, value);
      });

      // Record error to Crashlytics if it's an error level
      if (level == LogLevel.error && error != null) {
        crashlytics.recordError(
          error,
          stackTrace,
          reason: message,
          fatal: false,
        );
      } else {
        // Log message to Crashlytics
        crashlytics.log('[$level.name] $message');
      }

      // Send to Firebase Analytics
      FirebaseAnalytics.instance.logEvent(
        name: 'app_log',
        parameters: {
          ...logData,
          // Ensure values are compatible with Analytics
          'level': level.name,
          'message': message.length > 100 
              ? '${message.substring(0, 97)}...' 
              : message,
        },
      );
    } catch (e) {
      // Fallback if production logging fails
      if (kDebugMode) {
        print('Failed to log to production services: $e');
      }
    }
  }

  /// Get ANSI color code for log level
  static String _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return _cyan;
      case LogLevel.info:
        return _green;
      case LogLevel.warning:
        return _yellow;
      case LogLevel.error:
        return _red;
    }
  }

  /// Get the current session ID
  static String? get sessionId => _sessionId;

  /// Get the current user ID
  static String? get userId => _userId;

  /// Check if running in production mode
  static bool get isProduction => _isProduction;

  /// Override production mode (for testing purposes)
  @visibleForTesting
  static void setProductionMode(bool isProduction) {
    _isProduction = isProduction;
  }

  /// Reset logger state (for testing purposes)
  @visibleForTesting
  static void reset() {
    _userId = null;
    _sessionId = null;
    _isProduction = kReleaseMode;
  }
}
