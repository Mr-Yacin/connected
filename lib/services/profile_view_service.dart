import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/exceptions/app_exceptions.dart';

/// Service for managing profile view tracking
class ProfileViewService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileViewService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Record a profile view
  /// This will create a record in profile_views collection
  /// and send notification if user has enabled it
  /// Prevents duplicate views within 1 hour
  Future<void> recordProfileView(String profileUserId) async {
    try {
      final currentUser = _auth.currentUser;
      
      // Don't record if user is not logged in
      if (currentUser == null) {
        return;
      }

      // Don't record if user is viewing their own profile
      if (currentUser.uid == profileUserId) {
        return;
      }

      // Check for duplicate views within the last hour
      final isDuplicate = await _isDuplicateView(
        viewerId: currentUser.uid,
        profileUserId: profileUserId,
      );

      if (isDuplicate) {
        print('Duplicate view detected - skipping');
        return;
      }

      // Record the view in Firestore
      await _firestore.collection('profile_views').add({
        'viewerId': currentUser.uid,
        'profileUserId': profileUserId,
        'viewedAt': FieldValue.serverTimestamp(),
      });

      // Check if user wants to be notified
      await _checkAndSendNotification(
        viewerId: currentUser.uid,
        profileUserId: profileUserId,
      );
    } on FirebaseException catch (e) {
      // Log error but don't throw - profile views are not critical
      print('Error recording profile view: ${e.message}');
    } catch (e) {
      // Log error but don't throw
      print('Error recording profile view: $e');
    }
  }

  /// Check if this is a duplicate view within the last hour
  Future<bool> _isDuplicateView({
    required String viewerId,
    required String profileUserId,
  }) async {
    try {
      // Get views from the last hour
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      
      final snapshot = await _firestore
          .collection('profile_views')
          .where('viewerId', isEqualTo: viewerId)
          .where('profileUserId', isEqualTo: profileUserId)
          .orderBy('viewedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return false; // No previous views
      }

      // Check if the last view was within the last hour
      final lastView = snapshot.docs.first.data();
      final viewedAt = lastView['viewedAt'] as Timestamp?;
      
      if (viewedAt == null) {
        return false; // No timestamp, allow new view
      }

      final lastViewTime = viewedAt.toDate();
      final isRecent = lastViewTime.isAfter(oneHourAgo);

      return isRecent;
    } catch (e) {
      print('Error checking duplicate view: $e');
      return false; // On error, allow the view
    }
  }

  /// Check notification settings and send notification if enabled
  Future<void> _checkAndSendNotification({
    required String viewerId,
    required String profileUserId,
  }) async {
    try {
      // Get profile user's settings
      final profileDoc = await _firestore
          .collection('users')
          .doc(profileUserId)
          .get();

      if (!profileDoc.exists) {
        return;
      }

      // Check if notifications are enabled
      final data = profileDoc.data();
      final notifyOnProfileView =
          data?['settings']?['notifyOnProfileView'] ?? false;

      if (!notifyOnProfileView) {
        return;
      }

      // Get FCM token
      final fcmToken = data?['fcmToken'];
      if (fcmToken == null) {
        print('No FCM token found for user $profileUserId');
        return;
      }

      // Send notification
      await _sendProfileViewNotification(
        viewerId: viewerId,
        profileUserId: profileUserId,
        fcmToken: fcmToken,
      );
    } catch (e) {
      print('Error checking notification settings: $e');
    }
  }

  /// Send profile view notification
  Future<void> _sendProfileViewNotification({
    required String viewerId,
    required String profileUserId,
    required String fcmToken,
  }) async {
    try {
      // Get viewer's name
      final viewerDoc = await _firestore
          .collection('users')
          .doc(viewerId)
          .get();
      
      final viewerName = viewerDoc.data()?['name'] ?? 'مستخدم';

      // Send notification via HTTP API
      await _sendFCMNotification(
        token: fcmToken,
        title: 'زيارة جديدة',
        body: '$viewerName زار ملفك الشخصي',
        data: {
          'type': 'profile_view',
          'viewerId': viewerId,
          'profileUserId': profileUserId,
        },
      );

      print('Profile view notification sent successfully');
    } catch (e) {
      print('Error sending profile view notification: $e');
    }
  }

  /// Send FCM notification via HTTP API
  /// Note: This requires Firebase Cloud Messaging API (V1) or Server Key
  /// For production, use Cloud Functions instead
  Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    // TODO: Implement HTTP API call to send FCM notification
    // This requires Server Key from Firebase Console
    // For now, just log the notification
    print('Sending FCM notification:');
    print('Token: $token');
    print('Title: $title');
    print('Body: $body');
    print('Data: $data');
    
    // Note: For production, implement one of these options:
    // 1. Use Cloud Functions (recommended)
    // 2. Use HTTP API with Server Key
    // 3. Use Firebase Admin SDK from backend
  }

  /// Get profile views for a user
  /// Returns list of users who viewed the profile
  Future<List<Map<String, dynamic>>> getProfileViews(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('profile_views')
          .where('profileUserId', isEqualTo: userId)
          .orderBy('viewedAt', descending: true)
          .limit(limit)
          .get();

      final views = <Map<String, dynamic>>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final viewerId = data['viewerId'] as String;
        
        // Get viewer's profile
        final viewerDoc = await _firestore
            .collection('users')
            .doc(viewerId)
            .get();
        
        if (viewerDoc.exists) {
          views.add({
            'id': doc.id,
            'viewerId': viewerId,
            'viewerName': viewerDoc.data()?['name'],
            'viewerProfileImage': viewerDoc.data()?['profileImageUrl'],
            'viewedAt': data['viewedAt'],
          });
        }
      }

      return views;
    } on FirebaseException catch (e) {
      throw AppException(
        'فشل تحميل زيارات البروفايل: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw AppException('حدث خطأ أثناء تحميل زيارات البروفايل: $e');
    }
  }

  /// Get profile views count for a user
  Future<int> getProfileViewsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('profile_views')
          .where('profileUserId', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting profile views count: $e');
      return 0;
    }
  }
}
