import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../core/exceptions/app_exceptions.dart';

/// Service for handling push notifications using Firebase Cloud Messaging
class NotificationService {
  final FirebaseMessaging _messaging;
  
  String? _fcmToken;

  NotificationService({
    FirebaseMessaging? messaging,
  }) : _messaging = messaging ?? FirebaseMessaging.instance;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
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

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('تم منح صلاحية الإشعارات');
        }
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (kDebugMode) {
          print('تم منح صلاحية الإشعارات المؤقتة');
        }
      } else {
        if (kDebugMode) {
          print('لم يتم منح صلاحية الإشعارات');
        }
      }

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $_fcmToken');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (kDebugMode) {
          print('FCM Token refreshed: $newToken');
        }
        // TODO: Update token in Firestore user document
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      throw AppException('فشل في تهيئة خدمة الإشعارات: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('رسالة في المقدمة: ${message.notification?.title}');
      print('البيانات: ${message.data}');
    }

    // Show local notification or update UI
    // This can be customized based on your needs
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('تم النقر على الإشعار: ${message.notification?.title}');
      print('البيانات: ${message.data}');
    }

    // Navigate to appropriate screen based on message data
    // This can be customized based on your needs
    final chatId = message.data['chatId'] as String?;
    if (chatId != null) {
      // TODO: Navigate to chat screen
      if (kDebugMode) {
        print('الانتقال إلى المحادثة: $chatId');
      }
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('تم الاشتراك في الموضوع: $topic');
      }
    } catch (e) {
      throw AppException('فشل في الاشتراك في الموضوع: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('تم إلغاء الاشتراك من الموضوع: $topic');
      }
    } catch (e) {
      throw AppException('فشل في إلغاء الاشتراك من الموضوع: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      if (kDebugMode) {
        print('تم حذف FCM Token');
      }
    } catch (e) {
      throw AppException('فشل في حذف الرمز: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('رسالة في الخلفية: ${message.notification?.title}');
    print('البيانات: ${message.data}');
  }
  // Handle background message
  // This can be customized based on your needs
}
