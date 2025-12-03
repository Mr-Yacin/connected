import 'dart:async';
import '../../../../services/monitoring/app_logger.dart';
import '../../../../services/monitoring/error_logging_service.dart';
import '../../domain/repositories/story_repository.dart';

/// Service for managing story expiration
/// Periodically checks and deletes expired stories
class StoryExpirationService {
  final StoryRepository _storyRepository;
  Timer? _timer;
  bool _isRunning = false;

  StoryExpirationService(this._storyRepository);

  /// Start the expiration service
  /// Runs cleanup every hour by default
  void start({Duration interval = const Duration(hours: 1)}) {
    if (_isRunning) {
      return;
    }

    _isRunning = true;

    // Run immediately on start
    _cleanupExpiredStories();

    // Schedule periodic cleanup
    _timer = Timer.periodic(interval, (_) {
      _cleanupExpiredStories();
    });
  }

  /// Stop the expiration service
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  /// Check if the service is running
  bool get isRunning => _isRunning;

  /// Manually trigger cleanup of expired stories
  Future<int> cleanupNow() async {
    return await _cleanupExpiredStories();
  }

  /// Internal method to cleanup expired stories
  Future<int> _cleanupExpiredStories() async {
    try {
      final deletedCount = await _storyRepository.deleteExpiredStories();
      if (deletedCount > 0) {
        AppLogger.info('StoryExpirationService: Deleted $deletedCount expired stories');
      }
      return deletedCount;
    } catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Error cleaning up expired stories',
        screen: 'StoryExpirationService',
        operation: 'cleanupExpiredStories',
        collection: 'stories',
      );
      return 0;
    }
  }

  /// Dispose the service and cleanup resources
  void dispose() {
    stop();
  }
}
