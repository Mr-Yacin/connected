import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../monitoring/app_logger.dart';

/// Provider for LocalNotificationService
final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

/// Service for handling local notifications (foreground notifications)
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize local notifications with channels
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.debug('Local notifications already initialized');
      return;
    }

    try {
      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Initialize plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      _isInitialized = true;
      AppLogger.info('Local notifications initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize local notifications: $e');
      rethrow;
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    // Messages channel (high priority)
    const AndroidNotificationChannel messagesChannel =
        AndroidNotificationChannel(
      'messages',
      'الرسائل',
      description: 'إشعارات الرسائل الجديدة',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Stories channel (high priority)
    const AndroidNotificationChannel storiesChannel =
        AndroidNotificationChannel(
      'stories',
      'القصص',
      description: 'إشعارات القصص والتفاعلات',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Social channel (high priority)
    const AndroidNotificationChannel socialChannel =
        AndroidNotificationChannel(
      'social',
      'التفاعلات الاجتماعية',
      description: 'إشعارات المتابعين والتفاعلات',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // General channel (default priority)
    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
      'general',
      'عام',
      description: 'إشعارات عامة',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: false,
      showBadge: true,
    );

    // Create channels
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(messagesChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(storiesChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(socialChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);

    AppLogger.info('Notification channels created successfully');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.debug('Notification tapped: ${response.payload}');
    // The payload will be handled by the notification service
    // which has the navigation callback
  }

  /// Show a local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    if (!_isInitialized) {
      AppLogger.warning('Local notifications not initialized, skipping');
      return;
    }

    try {
      // Determine channel name based on ID
      String channelName;
      Importance importance;

      switch (channelId) {
        case 'messages':
          channelName = 'الرسائل';
          importance = Importance.high;
          break;
        case 'stories':
          channelName = 'القصص';
          importance = Importance.high;
          break;
        case 'social':
          channelName = 'التفاعلات الاجتماعية';
          importance = Importance.high;
          break;
        case 'general':
        default:
          channelName = 'عام';
          importance = Importance.defaultImportance;
      }

      // Android notification details
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        channelName,
        importance: importance,
        priority: importance == Importance.high
            ? Priority.high
            : Priority.defaultPriority,
        showWhen: true,
        styleInformation: BigTextStyleInformation(body),
      );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      AppLogger.debug('Local notification shown: $title');
    } catch (e) {
      AppLogger.error('Failed to show local notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
}

