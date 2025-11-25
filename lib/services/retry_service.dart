import 'dart:async';

/// Service for retrying failed operations with exponential backoff
class RetryService {
  /// Retry an operation with exponential backoff
  /// 
  /// [operation] - The async operation to retry
  /// [maxAttempts] - Maximum number of retry attempts (default: 3)
  /// [initialDelay] - Initial delay before first retry (default: 1 second)
  /// [maxDelay] - Maximum delay between retries (default: 30 seconds)
  /// [shouldRetry] - Optional function to determine if error is retryable
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      attempt++;
      
      try {
        return await operation();
      } catch (e) {
        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }

        // Check if we've exhausted all attempts
        if (attempt >= maxAttempts) {
          rethrow;
        }

        // Wait before retrying with exponential backoff
        await Future.delayed(delay);
        
        // Increase delay for next attempt (exponential backoff)
        delay = Duration(
          milliseconds: (delay.inMilliseconds * 2).clamp(
            initialDelay.inMilliseconds,
            maxDelay.inMilliseconds,
          ),
        );
      }
    }
  }

  /// Retry an operation with linear backoff
  /// 
  /// [operation] - The async operation to retry
  /// [maxAttempts] - Maximum number of retry attempts (default: 3)
  /// [delay] - Fixed delay between retries (default: 2 seconds)
  /// [shouldRetry] - Optional function to determine if error is retryable
  static Future<T> retryLinear<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 2),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;

    while (true) {
      attempt++;
      
      try {
        return await operation();
      } catch (e) {
        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }

        // Check if we've exhausted all attempts
        if (attempt >= maxAttempts) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(delay);
      }
    }
  }

  /// Check if an error is retryable (network/timeout errors)
  static bool isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Common retryable error patterns
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('unavailable');
  }
}
