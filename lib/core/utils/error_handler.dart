import 'package:firebase_auth/firebase_auth.dart';
import '../exceptions/app_exceptions.dart';
import '../../services/monitoring/error_logging_service.dart';

/// Centralized error handling utility for the application.
///
/// Provides consistent error handling, logging, and user-friendly messages.
class ErrorHandler {
  /// Handle Firebase Auth errors with proper Arabic messages
  static AppException handleAuthError(
    FirebaseAuthException error, {
    required String operation,
    String? screen,
  }) {
    ErrorLoggingService.logAuthError(
      error,
      stackTrace: StackTrace.current,
      context: 'Authentication error during $operation',
      screen: screen,
      operation: operation,
    );

    String message;
    switch (error.code) {
      case 'user-not-found':
        message = 'المستخدم غير موجود';
        break;
      case 'wrong-password':
        message = 'كلمة المرور غير صحيحة';
        break;
      case 'email-already-in-use':
        message = 'البريد الإلكتروني مستخدم بالفعل';
        break;
      case 'weak-password':
        message = 'كلمة المرور ضعيفة جداً';
        break;
      case 'invalid-email':
        message = 'البريد الإلكتروني غير صالح';
        break;
      case 'user-disabled':
        message = 'تم تعطيل حساب المستخدم';
        break;
      case 'too-many-requests':
        message = 'محاولات كثيرة. يرجى المحاولة لاحقاً';
        break;
      case 'operation-not-allowed':
        message = 'العملية غير مسموح بها';
        break;
      case 'network-request-failed':
        message = 'فشل الاتصال بالشبكة';
        break;
      default:
        message = 'حدث خطأ في المصادقة: ${error.message}';
    }

    return AppException(message);
  }

  /// Handle Firestore errors with proper Arabic messages
  static AppException handleFirestoreError(
    FirebaseException error, {
    required String operation,
    String? screen,
    String? collection,
    String? documentId,
  }) {
    ErrorLoggingService.logFirestoreError(
      error,
      stackTrace: StackTrace.current,
      context: 'Firestore error during $operation',
      screen: screen,
      operation: operation,
      collection: collection,
      documentId: documentId,
    );

    String message;
    switch (error.code) {
      case 'permission-denied':
        message = 'ليس لديك صلاحية للوصول إلى هذه البيانات';
        break;
      case 'not-found':
        message = 'البيانات المطلوبة غير موجودة';
        break;
      case 'already-exists':
        message = 'البيانات موجودة بالفعل';
        break;
      case 'resource-exhausted':
        message = 'تم تجاوز حد الاستخدام';
        break;
      case 'failed-precondition':
        message = 'فشل شرط مسبق للعملية';
        break;
      case 'aborted':
        message = 'تم إلغاء العملية';
        break;
      case 'out-of-range':
        message = 'القيمة خارج النطاق المسموح';
        break;
      case 'unimplemented':
        message = 'العملية غير مدعومة';
        break;
      case 'internal':
        message = 'خطأ داخلي في الخادم';
        break;
      case 'unavailable':
        message = 'الخدمة غير متاحة حالياً';
        break;
      case 'data-loss':
        message = 'فقدان البيانات غير قابل للاسترداد';
        break;
      case 'unauthenticated':
        message = 'يجب تسجيل الدخول أولاً';
        break;
      case 'cancelled':
        message = 'تم إلغاء العملية';
        break;
      default:
        message = 'حدث خطأ في قاعدة البيانات: ${error.message}';
    }

    return AppException(message);
  }

  /// Handle Storage errors with proper Arabic messages
  static AppException handleStorageError(
    FirebaseException error, {
    required String operation,
    String? screen,
    String? filePath,
  }) {
    ErrorLoggingService.logStorageError(
      error,
      stackTrace: StackTrace.current,
      context: 'Storage error during $operation',
      screen: screen,
      operation: operation,
      filePath: filePath,
    );

    String message;
    switch (error.code) {
      case 'object-not-found':
        message = 'الملف المطلوب غير موجود';
        break;
      case 'unauthorized':
        message = 'ليس لديك صلاحية للوصول إلى هذا الملف';
        break;
      case 'canceled':
        message = 'تم إلغاء عملية الرفع';
        break;
      case 'unknown':
        message = 'حدث خطأ غير معروف';
        break;
      case 'quota-exceeded':
        message = 'تم تجاوز حد التخزين';
        break;
      case 'unauthenticated':
        message = 'يجب تسجيل الدخول أولاً';
        break;
      case 'retry-limit-exceeded':
        message = 'تم تجاوز عدد المحاولات المسموح';
        break;
      case 'invalid-checksum':
        message = 'الملف تالف';
        break;
      case 'invalid-event-name':
        message = 'حدث غير صالح';
        break;
      case 'invalid-url':
        message = 'رابط الملف غير صالح';
        break;
      case 'invalid-argument':
        message = 'معامل غير صالح';
        break;
      case 'no-default-bucket':
        message = 'لا يوجد مساحة تخزين افتراضية';
        break;
      case 'cannot-slice-blob':
        message = 'فشل في معالجة الملف';
        break;
      case 'server-file-wrong-size':
        message = 'حجم الملف غير متطابق';
        break;
      default:
        message = 'حدث خطأ في التخزين: ${error.message}';
    }

    return AppException(message);
  }

  /// Handle general errors with proper logging
  static AppException handleGeneralError(
    Object error, {
    required String operation,
    String? screen,
    StackTrace? stackTrace,
  }) {
    ErrorLoggingService.logGeneralError(
      error,
      stackTrace: stackTrace ?? StackTrace.current,
      context: 'General error during $operation',
      screen: screen,
      operation: operation,
    );

    if (error is AppException) {
      return error;
    }

    return AppException('حدث خطأ غير متوقع: ${error.toString()}');
  }

  /// Safely execute an async operation with error handling
  static Future<T> safeExecute<T>({
    required Future<T> Function() operation,
    required String operationName,
    String? screen,
  }) async {
    try {
      return await operation();
    } on FirebaseAuthException catch (e) {
      throw handleAuthError(e, operation: operationName, screen: screen);
    } on FirebaseException catch (e) {
      if (e.plugin == 'cloud_firestore') {
        throw handleFirestoreError(e, operation: operationName, screen: screen);
      } else if (e.plugin == 'firebase_storage') {
        throw handleStorageError(e, operation: operationName, screen: screen);
      } else {
        throw handleGeneralError(e, operation: operationName, screen: screen);
      }
    } catch (e, stackTrace) {
      throw handleGeneralError(
        e,
        operation: operationName,
        screen: screen,
        stackTrace: stackTrace,
      );
    }
  }

  /// Safely execute a void async operation with error handling
  static Future<void> safeExecuteVoid({
    required Future<void> Function() operation,
    required String operationName,
    String? screen,
  }) async {
    await safeExecute<void>(
      operation: operation,
      operationName: operationName,
      screen: screen,
    );
  }
}
