import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/exceptions/app_exceptions.dart';

/// Repository for managing follow relationships
class FollowRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Follow a user (direct follow, no request needed)
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();

      // Add to current user's following list
      final followingRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);

      batch.set(followingRef, {
        'userId': targetUserId,
        'followedAt': FieldValue.serverTimestamp(),
      });

      // Add to target user's followers list
      final followerRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);

      batch.set(followerRef, {
        'userId': currentUserId,
        'followedAt': FieldValue.serverTimestamp(),
      });

      // Update follower counts
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'followingCount': FieldValue.increment(1),
      });

      final targetUserRef = _firestore.collection('users').doc(targetUserId);
      batch.update(targetUserRef, {
        'followerCount': FieldValue.increment(1),
      });

      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppException(
        'فشل في متابعة المستخدم',
        code: e.code,
      );
    } catch (e) {
      throw AppException(
        'حدث خطأ غير متوقع',
      );
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();

      // Remove from current user's following list
      final followingRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);

      batch.delete(followingRef);

      // Remove from target user's followers list
      final followerRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);

      batch.delete(followerRef);

      // Update follower counts
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'followingCount': FieldValue.increment(-1),
      });

      final targetUserRef = _firestore.collection('users').doc(targetUserId);
      batch.update(targetUserRef, {
        'followerCount': FieldValue.increment(-1),
      });

      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppException(
        'فشل في إلغاء المتابعة',
        code: e.code,
      );
    } catch (e) {
      throw AppException(
        'حدث خطأ غير متوقع',
      );
    }
  }

  /// Check if current user is following target user
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .get();

      return doc.exists;
    } on FirebaseException catch (e) {
      throw AppException(
        'فشل في التحقق من حالة المتابعة',
        code: e.code,
      );
    } catch (e) {
      throw AppException(
        'حدث خطأ غير متوقع',
      );
    }
  }

  /// Get follower count for a user
  Future<int> getFollowerCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('followers')
          .count()
          .get();

      return snapshot.count ?? 0;
    } on FirebaseException catch (e) {
      throw AppException(
        'فشل في الحصول على عدد المتابعين',
        code: e.code,
      );
    } catch (e) {
      throw AppException(
        'حدث خطأ غير متوقع',
      );
    }
  }

  /// Get following count for a user
  Future<int> getFollowingCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .count()
          .get();

      return snapshot.count ?? 0;
    } on FirebaseException catch (e) {
      throw AppException(
        'فشل في الحصول على عدد المتابعة',
        code: e.code,
      );
    } catch (e) {
      throw AppException(
        'حدث خطأ غير متوقع',
      );
    }
  }
}
