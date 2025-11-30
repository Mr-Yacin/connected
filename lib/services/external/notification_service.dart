import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/exceptions/app_exceptions.dart';

// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Service for handling push notifications using Firebase Cloud Messaging
class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? _fcmToken;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Get FCM token
      _fcmToken = await _messaging.getToken();

      // Save token to Firestore
      if (_fcmToken != null) {
        await _saveFcmTokenToFirestore(_fcmToken!);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        // Update token in Firestore user document
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
    } catch (e) {
      throw AppException('فشل في تهيئة خدمة الإشعارات: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification or update UI
    // This can be customized based on your needs
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    // Navigate to appropriate screen based on message data
    final chatId = message.data['chatId'] as String?;
    final type = message.data['type'] as String?;

    if (chatId != null && type == 'new_message') {
      // Store chatId for navigation after app is ready
      _pendingChatNavigation = chatId;
    }
  }

  // Pending navigation (to be handled by app router)
  String? _pendingChatNavigation;

  /// Get and clear pending chat navigation
  String? getPendingChatNavigation() {
    final chatId = _pendingChatNavigation;
    _pendingChatNavigation = null;
    return chatId;
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
      }
    } catch (e) {
      // Don't throw - token refresh will retry
    }
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
    } catch (e) {
      // Silent failure - will retry on next token refresh
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      throw AppException('فشل في الاشتراك في الموضوع: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      throw AppException('فشل في إلغاء الاشتراك من الموضوع: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
    } catch (e) {
      throw AppException('فشل في حذف الرمز: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
  // This can be customized based on your needs
}
