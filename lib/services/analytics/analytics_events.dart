import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_connect_app/services/monitoring/performance_service.dart';
import 'package:social_connect_app/services/monitoring/crashlytics_service.dart';

/// Centralized analytics events service that combines Performance and Crashlytics
final analyticsEventsProvider = Provider<AnalyticsEvents>((ref) {
  return AnalyticsEvents(
    performanceService: ref.watch(performanceServiceProvider),
    crashlyticsService: ref.watch(crashlyticsServiceProvider),
  );
});

class AnalyticsEvents {
  final PerformanceService performanceService;
  final CrashlyticsService crashlyticsService;

  AnalyticsEvents({
    required this.performanceService,
    required this.crashlyticsService,
  });

  // ============ Authentication Events ============
  
  Future<void> trackSignUp({
    required String method,
    required String userId,
  }) async {
    await performanceService.trackEvent(
      'sign_up',
      parameters: {
        'method': method,
      },
    );
    await crashlyticsService.setUserIdentifier(userId);
    await crashlyticsService.log('User signed up: $userId with method: $method');
  }

  Future<void> trackLogin({
    required String method,
    required String userId,
  }) async {
    await performanceService.trackEvent(
      'login',
      parameters: {
        'method': method,
      },
    );
    await crashlyticsService.setUserIdentifier(userId);
    await crashlyticsService.log('User logged in: $userId');
  }

  Future<void> trackLogout(String userId) async {
    await performanceService.trackEvent('logout');
    await crashlyticsService.log('User logged out: $userId');
  }

  // ============ Post Events ============
  
  Future<void> trackPostCreated({
    required String postId,
    required String contentType,
    bool hasImage = false,
    bool hasLocation = false,
  }) async {
    await performanceService.trackEvent(
      'post_created',
      parameters: {
        'post_id': postId,
        'content_type': contentType,
        'has_image': hasImage,
        'has_location': hasLocation,
      },
    );
    await crashlyticsService.log('Post created: $postId');
  }

  Future<void> trackPostLiked({
    required String postId,
    required String authorId,
  }) async {
    await performanceService.trackEvent(
      'post_liked',
      parameters: {
        'post_id': postId,
        'author_id': authorId,
      },
    );
  }

  Future<void> trackPostShared({
    required String postId,
    required String shareMethod,
  }) async {
    await performanceService.trackEvent(
      'post_shared',
      parameters: {
        'post_id': postId,
        'share_method': shareMethod,
      },
    );
  }

  Future<void> trackCommentAdded({
    required String postId,
    required String commentId,
  }) async {
    await performanceService.trackEvent(
      'comment_added',
      parameters: {
        'post_id': postId,
        'comment_id': commentId,
      },
    );
  }

  // ============ Story Events ============
  
  Future<void> trackStoryViewed({
    required String storyId,
    required String authorId,
  }) async {
    await performanceService.trackEvent(
      'story_viewed',
      parameters: {
        'story_id': storyId,
        'author_id': authorId,
      },
    );
  }

  Future<void> trackStoryCreated({
    required String storyId,
    required String mediaType,
  }) async {
    await performanceService.trackStoryCreated(
      storyId: storyId,
      mediaType: mediaType,
    );
    await crashlyticsService.log('Story created: $storyId');
  }

  // ============ Chat Events ============
  
  Future<void> trackMessageSent({
    required String chatId,
    required String messageType,
  }) async {
    await performanceService.trackMessageSent(
      chatId: chatId,
      messageType: messageType,
    );
  }

  Future<void> trackChatOpened({
    required String chatId,
    required String recipientId,
  }) async {
    await performanceService.trackEvent(
      'chat_opened',
      parameters: {
        'chat_id': chatId,
        'recipient_id': recipientId,
      },
    );
    await crashlyticsService.log('Chat opened: $chatId');
  }

  Future<void> trackVoiceMessageRecorded({
    required String chatId,
    required int durationSeconds,
  }) async {
    await performanceService.trackEvent(
      'voice_message_recorded',
      parameters: {
        'chat_id': chatId,
        'duration_seconds': durationSeconds,
      },
    );
  }

  // ============ Social Events ============
  
  Future<void> trackUserFollowed({
    required String followedUserId,
  }) async {
    await performanceService.trackEvent(
      'user_followed',
      parameters: {
        'followed_user_id': followedUserId,
      },
    );
  }

  Future<void> trackUserUnfollowed({
    required String unfollowedUserId,
  }) async {
    await performanceService.trackEvent(
      'user_unfollowed',
      parameters: {
        'unfollowed_user_id': unfollowedUserId,
      },
    );
  }

  Future<void> trackProfileViewed({
    required String userId,
  }) async {
    await performanceService.trackProfileView(userId);
  }

  // ============ Search Events ============
  
  Future<void> trackSearch({
    required String searchTerm,
    required int resultCount,
    required String searchType,
  }) async {
    await performanceService.trackSearch(
      searchTerm: searchTerm,
      resultCount: resultCount,
    );
    await crashlyticsService.setCustomKey('last_search', searchTerm);
  }

  // ============ Media Events ============
  
  Future<void> trackImageUpload({
    required String location,
    required int fileSizeBytes,
    required Duration uploadDuration,
  }) async {
    await performanceService.trackImageUpload(
      location: location,
      fileSizeBytes: fileSizeBytes,
      uploadDuration: uploadDuration,
    );
  }

  Future<void> trackImagePickerOpened({
    required String source,
  }) async {
    await performanceService.trackEvent(
      'image_picker_opened',
      parameters: {
        'source': source,
      },
    );
  }

  // ============ Navigation Events ============
  
  Future<void> trackScreenView(String screenName) async {
    await performanceService.trackScreenView(screenName);
    await crashlyticsService.log('Screen viewed: $screenName');
  }

  Future<void> trackTabChanged({
    required String fromTab,
    required String toTab,
  }) async {
    await performanceService.trackEvent(
      'tab_changed',
      parameters: {
        'from_tab': fromTab,
        'to_tab': toTab,
      },
    );
  }

  // ============ Settings Events ============
  
  Future<void> trackThemeChanged({
    required String theme,
  }) async {
    await performanceService.trackEvent(
      'theme_changed',
      parameters: {
        'theme': theme,
      },
    );
    await crashlyticsService.setCustomKey('theme_preference', theme);
  }

  Future<void> trackNotificationToggled({
    required bool enabled,
  }) async {
    await performanceService.trackEvent(
      'notification_toggled',
      parameters: {
        'enabled': enabled,
      },
    );
  }

  Future<void> trackLanguageChanged({
    required String language,
  }) async {
    await performanceService.trackEvent(
      'language_changed',
      parameters: {
        'language': language,
      },
    );
    await crashlyticsService.setCustomKey('language_preference', language);
  }

  // ============ Error Events ============
  
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    required String location,
    StackTrace? stackTrace,
  }) async {
    await crashlyticsService.logError(
      errorMessage,
      stackTrace,
      reason: errorType,
      information: ['location: $location', 'error_type: $errorType'],
    );
    
    await performanceService.trackEvent(
      'error_occurred',
      parameters: {
        'error_type': errorType,
        'location': location,
      },
    );
  }

  // ============ Performance Events ============
  
  Future<void> trackAppStartup({
    required Duration startupDuration,
  }) async {
    await performanceService.trackEvent(
      'app_startup',
      parameters: {
        'startup_duration_ms': startupDuration.inMilliseconds,
      },
    );
  }

  Future<void> trackApiCall({
    required String endpoint,
    required Duration duration,
    required int statusCode,
  }) async {
    await performanceService.trackEvent(
      'api_call',
      parameters: {
        'endpoint': endpoint,
        'duration_ms': duration.inMilliseconds,
        'status_code': statusCode,
      },
    );
  }
}
