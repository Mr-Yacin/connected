import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for Firebase Crashlytics
final firebaseCrashlyticsProvider = Provider<FirebaseCrashlytics>((ref) {
  return FirebaseCrashlytics.instance;
});

final crashlyticsServiceProvider = Provider<CrashlyticsService>((ref) {
  return CrashlyticsService(
    crashlytics: ref.watch(firebaseCrashlyticsProvider),
  );
});

/// Service for error tracking and crash reporting
class CrashlyticsService {
  final FirebaseCrashlytics crashlytics;

  CrashlyticsService({
    required this.crashlytics,
  });

  /// Initialize Crashlytics
  static Future<void> initialize() async {
    // Pass all uncaught errors from the framework to Crashlytics
    FlutterError.onError = (FlutterErrorDetails errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Log a non-fatal error
  Future<void> logError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object>? information,
  }) async {
    if (information != null) {
      await crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        information: information,
        fatal: false,
      );
    } else {
      await crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: false,
      );
    }
  }

  /// Log a fatal error
  Future<void> logFatalError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object>? information,
  }) async {
    if (information != null) {
      await crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        information: information,
        fatal: true,
      );
    } else {
      await crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: true,
      );
    }
  }

  /// Log a custom message
  Future<void> log(String message) async {
    await crashlytics.log(message);
  }

  /// Set a custom key-value pair
  Future<void> setCustomKey(String key, dynamic value) async {
    await crashlytics.setCustomKey(key, value);
  }

  /// Set user identifier
  Future<void> setUserIdentifier(String userId) async {
    await crashlytics.setUserIdentifier(userId);
  }

  /// Set custom user information
  Future<void> setUserInfo({
    required String userId,
    String? email,
    String? name,
  }) async {
    await crashlytics.setUserIdentifier(userId);
    
    if (email != null) {
      await crashlytics.setCustomKey('user_email', email);
    }
    
    if (name != null) {
      await crashlytics.setCustomKey('user_name', name);
    }
  }

  /// Check if Crashlytics collection is enabled
  Future<bool> isCrashlyticsCollectionEnabled() async {
    return crashlytics.isCrashlyticsCollectionEnabled;
  }

  /// Enable or disable Crashlytics collection
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    await crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  /// Record a Flutter error
  Future<void> recordFlutterError(FlutterErrorDetails errorDetails) async {
    await crashlytics.recordFlutterError(errorDetails);
  }

  /// Send unsent crash reports
  Future<void> sendUnsentReports() async {
    await crashlytics.sendUnsentReports();
  }

  /// Delete unsent crash reports
  Future<void> deleteUnsentReports() async {
    await crashlytics.deleteUnsentReports();
  }

  /// Check if there are unsent reports
  Future<bool> checkForUnsentReports() async {
    return await crashlytics.checkForUnsentReports();
  }
}

/// Extension to wrap functions with error tracking
extension CrashlyticsExtension on CrashlyticsService {
  /// Execute a function and log any errors to Crashlytics
  Future<T?> runWithErrorTracking<T>({
    required Future<T> Function() function,
    required String functionName,
    bool fatal = false,
  }) async {
    try {
      await log('Executing: $functionName');
      return await function();
    } catch (error, stackTrace) {
      await log('Error in $functionName: $error');
      
      if (fatal) {
        await logFatalError(
          error,
          stackTrace,
          reason: 'Error in $functionName',
          information: ['function: $functionName'],
        );
      } else {
        await logError(
          error,
          stackTrace,
          reason: 'Error in $functionName',
          information: ['function: $functionName'],
        );
      }
      
      return null;
    }
  }
}
