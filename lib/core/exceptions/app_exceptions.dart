class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  /// Get user-friendly Arabic error message
  String get userFriendlyMessage => message;

  /// Check if this error is retryable
  bool get isRetryable => false;

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

class AuthException extends AppException {
  AuthException(super.message, {super.code});

  @override
  String get userFriendlyMessage {
    if (message.contains('invalid-verification-code')) {
      return 'رمز التحقق غير صحيح. يرجى المحاولة مرة أخرى.';
    } else if (message.contains('session-expired')) {
      return 'انتهت صلاحية الجلسة. يرجى إعادة المحاولة.';
    } else if (message.contains('too-many-requests')) {
      return 'عدد كبير جداً من المحاولات. يرجى الانتظار قليلاً.';
    }
    return message;
  }

  @override
  String toString() => 'AuthException: $message${code != null ? ' (code: $code)' : ''}';
}

class NetworkException extends AppException {
  NetworkException(super.message);

  @override
  String get userFriendlyMessage => 'خطأ في الاتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';

  @override
  bool get isRetryable => true;

  @override
  String toString() => 'NetworkException: $message';
}

class ValidationException extends AppException {
  ValidationException(super.message);

  @override
  String get userFriendlyMessage => message;

  @override
  String toString() => 'ValidationException: $message';
}

class PermissionException extends AppException {
  PermissionException(super.message);

  @override
  String get userFriendlyMessage => 'ليس لديك صلاحية للقيام بهذا الإجراء.';

  @override
  String toString() => 'PermissionException: $message';
}

class RateLimitException extends AuthException {
  final DateTime retryAfter;

  RateLimitException(super.message, this.retryAfter, {super.code});

  @override
  String get userFriendlyMessage => 'تم تجاوز الحد المسموح من المحاولات. يرجى الانتظار والمحاولة لاحقاً.';

  @override
  String toString() => 'RateLimitException: $message (retry after: $retryAfter)';
}

class StorageException extends AppException {
  StorageException(super.message, {super.code});

  @override
  String get userFriendlyMessage {
    if (message.contains('unauthorized')) {
      return 'ليس لديك صلاحية لرفع الملفات.';
    } else if (message.contains('quota-exceeded')) {
      return 'تم تجاوز مساحة التخزين المتاحة.';
    } else if (message.contains('invalid-file-type')) {
      return 'نوع الملف غير مدعوم.';
    }
    return 'حدث خطأ أثناء رفع الملف. يرجى المحاولة مرة أخرى.';
  }

  @override
  bool get isRetryable => true;

  @override
  String toString() => 'StorageException: $message${code != null ? ' (code: $code)' : ''}';
}

class OfflineException extends AppException {
  OfflineException() : super('لا يوجد اتصال بالإنترنت');

  @override
  String get userFriendlyMessage => 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';

  @override
  bool get isRetryable => true;

  @override
  String toString() => 'OfflineException: $message';
}

