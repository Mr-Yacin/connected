class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

class AuthException extends AppException {
  AuthException(super.message, {super.code});

  @override
  String toString() => 'AuthException: $message${code != null ? ' (code: $code)' : ''}';
}

class NetworkException extends AppException {
  NetworkException(super.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ValidationException extends AppException {
  ValidationException(super.message);

  @override
  String toString() => 'ValidationException: $message';
}

class PermissionException extends AppException {
  PermissionException(super.message);

  @override
  String toString() => 'PermissionException: $message';
}

class RateLimitException extends AuthException {
  final DateTime retryAfter;

  RateLimitException(super.message, this.retryAfter, {super.code});

  @override
  String toString() => 'RateLimitException: $message (retry after: $retryAfter)';
}
