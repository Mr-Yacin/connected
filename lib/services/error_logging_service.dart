// ignore_for_file: avoid_print
// Print statements are the intended logging mechanism for this service

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Centralized error logging service for Firebase operations
/// Provides detailed error tracking with categorization and colored console output
class ErrorLoggingService {
  // ANSI color codes for terminal output
  static const String _red = '\x1B[31m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _green = '\x1B[32m';
  static const String _reset = '\x1B[0m';
  static const String _bold = '\x1B[1m';

  // Error categories
  static const String _categoryConnection = 'CONNECTION';
  static const String _categoryAuth = 'AUTHENTICATION';
  static const String _categoryFirestore = 'FIRESTORE';
  static const String _categoryStorage = 'STORAGE';
  static const String _categoryGeneral = 'GENERAL';

  /// Log a Firebase connection error
  static void logConnectionError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    String? screen,
  }) {
    _logError(
      category: _categoryConnection,
      error: error,
      stackTrace: stackTrace,
      context: context,
      screen: screen,
    );
  }

  /// Log a Firebase Authentication error
  static void logAuthError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    String? screen,
    String? operation,
  }) {
    _logError(
      category: _categoryAuth,
      error: error,
      stackTrace: stackTrace,
      context: context,
      screen: screen,
      operation: operation,
    );
  }

  /// Log a Firestore error
  static void logFirestoreError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    String? screen,
    String? operation,
    String? collection,
    String? documentId,
  }) {
    final additionalInfo = <String, String?>{
      if (collection != null) 'Collection': collection,
      if (documentId != null) 'Document ID': documentId,
    };

    _logError(
      category: _categoryFirestore,
      error: error,
      stackTrace: stackTrace,
      context: context,
      screen: screen,
      operation: operation,
      additionalInfo: additionalInfo,
    );
  }

  /// Log a Firebase Storage error
  static void logStorageError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    String? screen,
    String? operation,
    String? filePath,
  }) {
    final additionalInfo = <String, String?>{
      if (filePath != null) 'File Path': filePath,
    };

    _logError(
      category: _categoryStorage,
      error: error,
      stackTrace: stackTrace,
      context: context,
      screen: screen,
      operation: operation,
      additionalInfo: additionalInfo,
    );
  }

  /// Log a general Firebase error
  static void logGeneralError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    String? screen,
    String? operation,
  }) {
    _logError(
      category: _categoryGeneral,
      error: error,
      stackTrace: stackTrace,
      context: context,
      screen: screen,
      operation: operation,
    );
  }

  /// Log Firebase initialization success
  static void logInitializationSuccess() {
    if (kDebugMode) {
      final timestamp = DateTime.now().toString().split('.')[0];
      print('$_green$_bold✓ [FIREBASE SUCCESS] $timestamp$_reset');
      print('$_green━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset');
      print('${_green}Firebase initialized successfully$_reset');
      print('$_green━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset\n');
    }
  }

  /// Core error logging method
  static void _logError({
    required String category,
    required dynamic error,
    StackTrace? stackTrace,
    String? context,
    String? screen,
    String? operation,
    Map<String, String?>? additionalInfo,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toString().split('.')[0];
    final errorMessage = _extractErrorMessage(error);
    final errorCode = _extractErrorCode(error);

    // Print header
    print('$_red$_bold🔴 [FIREBASE ERROR] $timestamp$_reset');
    print('$_red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset');

    // Print category
    print('${_yellow}Category: $_bold$category$_reset');

    // Print screen if provided
    if (screen != null) {
      print('${_blue}Screen: $_bold$screen$_reset');
    }

    // Print operation if provided
    if (operation != null) {
      print('${_blue}Operation: $_bold$operation$_reset');
    }

    // Print context if provided
    if (context != null) {
      print('${_blue}Context: $context$_reset');
    }

    // Print error code if available
    if (errorCode != null) {
      print('${_red}Error Code: $_bold$errorCode$_reset');
    }

    // Print error message
    print('${_red}Error: $errorMessage$_reset');

    // Print additional info
    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      additionalInfo.forEach((key, value) {
        if (value != null) {
          print('$_blue$key: $value$_reset');
        }
      });
    }

    // Print stack trace if available
    if (stackTrace != null) {
      print('${_yellow}Stack Trace:$_reset');
      final stackLines = stackTrace.toString().split('\n').take(5);
      for (final line in stackLines) {
        print('  $line');
      }
    }

    // Print footer
    print('$_red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset\n');
  }

  /// Extract error message from various error types
  static String _extractErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return error.message ?? error.toString();
    } else if (error is FirebaseException) {
      return error.message ?? error.toString();
    } else if (error is Exception) {
      return error.toString();
    } else {
      return error.toString();
    }
  }

  /// Extract error code from Firebase exceptions
  static String? _extractErrorCode(dynamic error) {
    if (error is FirebaseAuthException) {
      return error.code;
    } else if (error is FirebaseException) {
      return error.code;
    }
    return null;
  }

  /// Get user-friendly error message for display
  static String getUserFriendlyMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
          return 'رقم الهاتف غير صالح';
        case 'invalid-verification-code':
          return 'رمز التحقق غير صحيح';
        case 'code-expired':
          return 'انتهت صلاحية رمز التحقق';
        case 'too-many-requests':
          return 'تم تجاوز عدد المحاولات. يرجى المحاولة لاحقاً';
        case 'network-request-failed':
          return 'خطأ في الاتصال بالإنترنت';
        default:
          return 'حدث خطأ في المصادقة';
      }
    } else if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'ليس لديك صلاحية للوصول إلى هذه البيانات';
        case 'unavailable':
          return 'الخدمة غير متاحة حالياً';
        case 'not-found':
          return 'البيانات المطلوبة غير موجودة';
        case 'already-exists':
          return 'البيانات موجودة بالفعل';
        case 'resource-exhausted':
          return 'تم تجاوز الحد المسموح';
        case 'cancelled':
          return 'تم إلغاء العملية';
        case 'data-loss':
          return 'حدث فقدان في البيانات';
        case 'unauthenticated':
          return 'يجب تسجيل الدخول أولاً';
        default:
          return 'حدث خطأ. يرجى المحاولة مرة أخرى';
      }
    }
    return 'حدث خطأ غير متوقع';
  }
}
