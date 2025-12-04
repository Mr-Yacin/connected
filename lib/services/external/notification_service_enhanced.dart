import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../monitoring/app_logger.dart';
import '../monitoring/error_logging_service.dart';
import 'local_notification_service.dart';

// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final localNotificationService = ref.watch(localNotificationServiceProvider);
  return NotificationService(
    localNotificationService: localNotificationService,
  );
});

/// Callback for handling notification navigation
typedef NotificationNavigationCallback =
    void Function(String route, Map<String, dynamic> params);

/// Service for handling push notifications using Firebase Cloud Messaging
class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocalNotificationService? _localNotificationService;

  String? _fcmToken;
  NotificationNavigationCallback? _navigationCallback;

  // Pending navigation data
  Map<String, dynamic>? _pendingNavigationData;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    LocalNotificationService? localNotificationService,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _localNotificationService = localNotificationService;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Set navigation callback for handling notification taps
  void setNavigationCallback(NotificationNavigationCallback callback) {
    _navigationCallback = callback;

    // Process any pending navigation
    if (_pendingNavigationData != null) {
      _processNotificationNavigation(_pendingNavigationData!);
      _pendingNavigationData = null;
    }
  }

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Initialize local notifications first
      if (_localNotificationService != null) {
        await _localNotificationService!.initialize();
        AppLogger.info('Local notification service initialized');
      }

      // Request permission for notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.info(
        'Notification permission status: ${settings.authorizationStatus}',
      );

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      AppLogger.info('FCM Token: $_fcmToken');

      // Save token to Firestore
      if (_fcmToken != null) {
        await _saveFcmTokenToFirestore(_fcmToken!);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        AppLogger.info('FCM Token refreshed: $newToken');
        await _saveFcmTokenToFirestore(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to initialize notification service',
        screen: 'NotificationService',
        operation: 'initialize',
      );
      throw AppException('فشل في تهيئة خدمة الإشعارات: $e');
    }
  }

  /// Handle foreground messages - Show banner notification
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.debug(
      'Foreground message received: ${message.notification?.title}',
      data: {'messageData': message.data},
    );

    final notification = message.notification;
    if (notification != null && _localNotificationService != null) {
      // Show local notification in foreground
      final notificationType = message.data['type'] ?? 'general';
      final channelId = _getChannelIdForType(notificationType);

      _localNotificationService!.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: notification.title ?? 'إشعار جديد',
        body: notification.body ?? '',
        channelId: channelId,
        payload: notificationType,
      );

      AppLogger.debug(
        'Local notification shown',
        data: {
          'title': notification.title ?? '',
          'body': notification.body ?? '',
          'channel': channelId,
        },
      );
    }

    // Track analytics
    _trackNotificationEvent('received', message.data['type'] ?? 'unknown');
  }

  /// Get channel ID based on notification type
  String _getChannelIdForType(String type) {
    switch (type) {
      case 'new_message':
        return 'messages';
      case 'story_reply':
      case 'story_like':
      case 'new_story':
        return 'stories';
      case 'new_follower':
        return 'social';
      case 'profile_view':
      default:
        return 'general';
    }
  }

  /// Handle notification tap - Navigate to appropriate screen
  void _handleNotificationTap(RemoteMessage message) {
    AppLogger.debug(
      'Notification tapped',
      data: {'messageData': message.data},
    );

    final data = message.data;

    // If callback not set, store for later
    if (_navigationCallback == null) {
      _pendingNavigationData = data;
      AppLogger.debug('Navigation callback not set, storing for later');
      return;
    }

    _processNotificationNavigation(data);
  }

  /// Process notification navigation based on type
  void _processNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    AppLogger.debug('Processing navigation for type: $type');

    if (_navigationCallback == null) return;

    switch (type) {
      case 'new_message':
        // Navigate to chat screen
        final chatId = data['chatId'] ?? '';
        final currentUserId = _auth.currentUser?.uid ?? '';
        final otherUserId = data['otherUserId'] ?? '';
        final otherUserName = data['otherUserName'] ?? '';
        final otherUserImageUrl = data['otherUserImageUrl'] ?? '';

        _navigationCallback!('/chat/$chatId', {
          'currentUserId': currentUserId,
          'otherUserId': otherUserId,
          'otherUserName': otherUserName,
          'otherUserImageUrl': otherUserImageUrl,
        });
        break;

      case 'story_reply':
        // Navigate to story view
        final storyId = data['storyId'] ?? '';
        final userId = data['userId'] ?? '';

        _navigationCallback!('/stories', {
          'storyId': storyId,
          'userId': userId,
        });
        break;

      case 'story_like':
        // Navigate to story view
        final storyId = data['storyId'] ?? '';
        final userId = data['userId'] ?? '';

        _navigationCallback!('/stories', {
          'storyId': storyId,
          'userId': userId,
        });
        break;

      case 'new_story':
        // Navigate to story view
        final storyId = data['storyId'] ?? '';
        final userId = data['userId'] ?? '';

        _navigationCallback!('/stories', {
          'storyId': storyId,
          'userId': userId,
        });
        break;

      case 'profile_view':
        // Navigate to profile
        final viewerId = data['viewerId'] ?? '';

        _navigationCallback!('/profile/$viewerId', {'viewedUserId': viewerId});
        break;

      case 'new_follower':
        // Navigate to profile
        final followerId = data['followerId'] ?? '';

        _navigationCallback!('/profile/$followerId', {
          'viewedUserId': followerId,
        });
        break;

      default:
        // Navigate to home
        AppLogger.debug('Unknown notification type, navigating to home');
        _navigationCallback!('/home', {});
    }

    // Track analytics
    _trackNotificationEvent('tapped', type ?? 'unknown');
  }

  /// Save FCM token to Firestore user document
  Future<void> _saveFcmTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        AppLogger.info('FCM token saved to Firestore for user: ${user.uid}');
      }
    } catch (e, stackTrace) {
      // Don't throw - token refresh will retry
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to save FCM token',
        screen: 'NotificationService',
        operation: 'saveFcmTokenToFirestore',
        collection: 'users',
      );
    }
  }

  /// Track notification analytics
  void _trackNotificationEvent(String action, String type) {
    // TODO: Track with analytics service
    AppLogger.debug(
      'Notification event',
      data: {'action': action, 'type': type},
    );
  }

  /// Manually refresh and save FCM token (call after user login)
  Future<void> refreshAndSaveToken() async {
    try {
      // Delete old token
      await _messaging.deleteToken();

      // Get new token
      _fcmToken = await _messaging.getToken();

      if (_fcmToken != null) {
        await _saveFcmTokenToFirestore(_fcmToken!);
      }
    } catch (e, stackTrace) {
      // Silent failure - will retry on next token refresh
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to refresh token',
        screen: 'NotificationService',
        operation: 'refreshAndSaveToken',
      );
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to subscribe to topic',
        screen: 'NotificationService',
        operation: 'subscribeToTopic',
      );
      throw AppException('فشل في الاشتراك في الموضوع: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to unsubscribe from topic',
        screen: 'NotificationService',
        operation: 'unsubscribeFromTopic',
      );
      throw AppException('فشل في إلغاء الاشتراك من الموضوع: $e');
    }
  }

  /// Delete FCM token (call on logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      AppLogger.info('FCM token deleted');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to delete FCM token',
        screen: 'NotificationService',
        operation: 'deleteToken',
      );
      throw AppException('فشل في حذف الرمز: $e');
    }
  }

  /// Clear pending navigation data
  void clearPendingNavigation() {
    _pendingNavigationData = null;
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  AppLogger.debug(
    'Background message received: ${message.notification?.title}',
    data: {'messageData': message.data},
  );

  // Handle background message
  // You can update local database, show notification, etc.
}
