import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers for Firebase Performance and Analytics
final firebasePerformanceProvider = Provider<FirebasePerformance>((ref) {
  return FirebasePerformance.instance;
});

final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

final performanceServiceProvider = Provider<PerformanceService>((ref) {
  return PerformanceService(
    performance: ref.watch(firebasePerformanceProvider),
    analytics: ref.watch(firebaseAnalyticsProvider),
  );
});

/// Service for tracking app performance and analytics
class PerformanceService {
  final FirebasePerformance performance;
  final FirebaseAnalytics analytics;

  PerformanceService({
    required this.performance,
    required this.analytics,
  });

  /// Start a custom trace for performance monitoring
  Future<Trace> startTrace(String traceName) async {
    final trace = performance.newTrace(traceName);
    await trace.start();
    return trace;
  }

  /// Stop a custom trace
  Future<void> stopTrace(Trace trace) async {
    await trace.stop();
  }

  /// Track a screen view
  Future<void> trackScreenView(String screenName) async {
    await analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }

  /// Track a custom event
  Future<void> trackEvent(
    String eventName, {
    Map<String, Object?>? parameters,
  }) async {
    // Convert Map<String, Object?> to Map<String, Object> by filtering out null values
    final nonNullParams = parameters?.map(
      (key, value) => MapEntry(key, value ?? ''),
    ).cast<String, Object>();
    
    await analytics.logEvent(
      name: eventName,
      parameters: nonNullParams,
    );
  }

  /// Track message sent event
  Future<void> trackMessageSent({
    required String chatId,
    required String messageType,
  }) async {
    await analytics.logEvent(
      name: 'message_sent',
      parameters: {
        'chat_id': chatId,
        'message_type': messageType,
      },
    );
  }

  /// Track story created event
  Future<void> trackStoryCreated({
    required String storyId,
    required String mediaType,
  }) async {
    await analytics.logEvent(
      name: 'story_created',
      parameters: {
        'story_id': storyId,
        'media_type': mediaType,
      },
    );
  }

  /// Track user search event
  Future<void> trackSearch({
    required String searchTerm,
    required int resultCount,
  }) async {
    await analytics.logEvent(
      name: 'search',
      parameters: {
        'search_term': searchTerm,
        'result_count': resultCount,
      },
    );
  }

  /// Track profile view event
  Future<void> trackProfileView(String userId) async {
    await analytics.logEvent(
      name: 'profile_view',
      parameters: {
        'user_id': userId,
      },
    );
  }

  /// Track image upload performance
  Future<void> trackImageUpload({
    required String location,
    required int fileSizeBytes,
    required Duration uploadDuration,
  }) async {
    await analytics.logEvent(
      name: 'image_upload',
      parameters: {
        'location': location,
        'file_size_bytes': fileSizeBytes,
        'upload_duration_ms': uploadDuration.inMilliseconds,
      },
    );
  }

  /// Set user properties for analytics
  Future<void> setUserProperties({
    required String userId,
    String? age,
    String? gender,
    String? country,
  }) async {
    await analytics.setUserId(id: userId);
    
    if (age != null) {
      await analytics.setUserProperty(name: 'age', value: age);
    }
    
    if (gender != null) {
      await analytics.setUserProperty(name: 'gender', value: gender);
    }
    
    if (country != null) {
      await analytics.setUserProperty(name: 'country', value: country);
    }
  }

  /// Track HTTP request performance
  Future<HttpMetric> startHttpMetric(
    String url,
    HttpMethod method,
  ) async {
    final metric = performance.newHttpMetric(url, method);
    await metric.start();
    return metric;
  }

  /// Complete HTTP request metric
  Future<void> completeHttpMetric(
    HttpMetric metric, {
    int? requestPayloadSize,
    int? responseCode,
    int? responsePayloadSize,
  }) async {
    if (requestPayloadSize != null) {
      metric.requestPayloadSize = requestPayloadSize;
    }
    
    if (responseCode != null) {
      metric.httpResponseCode = responseCode;
    }
    
    if (responsePayloadSize != null) {
      metric.responsePayloadSize = responsePayloadSize;
    }
    
    await metric.stop();
  }
}

/// Extension to easily track widget performance
extension PerformanceExtension on PerformanceService {
  /// Execute a function and track its performance
  Future<T> trackPerformance<T>(
    String traceName,
    Future<T> Function() function,
  ) async {
    final trace = await startTrace(traceName);
    
    try {
      final result = await function();
      await stopTrace(trace);
      return result;
    } catch (e) {
      trace.setMetric('error', 1);
      await stopTrace(trace);
      rethrow;
    }
  }
}
