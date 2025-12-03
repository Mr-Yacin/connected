import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/repositories/follow_repository.dart';

/// Repository for managing follow relationships
class FirestoreFollowRepository implements FollowRepository {
  final FirebaseFirestore _firestore;

  FirestoreFollowRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      // Prevent self-following
      if (currentUserId == targetUserId) {
        throw AppException('لا يمكنك متابعة نفسك');
      }

      debugPrint('DEBUG: Following user: $targetUserId');

      // Check if already following
      final followingRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);

      final alreadyFollowing = await followingRef.get();
      if (alreadyFollowing.exists) {
        debugPrint('DEBUG: Already following user $targetUserId');
        return; // Already following
      }

      final batch = _firestore.batch();

      // Add to current user's following list
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
      debugPrint('DEBUG: Successfully followed user $targetUserId');
    } on FirebaseException catch (e) {
      debugPrint('ERROR: Firebase error while following: ${e.code} - ${e.message}');
      throw AppException(
        'فشل في متابعة المستخدم',
        code: e.code,
      );
    } catch (e) {
      debugPrint('ERROR: Error while following: $e');
      if (e is AppException) rethrow;
      throw AppException('حدث خطأ غير متوقع');
    }
  }

  @override
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      debugPrint('DEBUG: Unfollowing user: $targetUserId');

      // Check if actually following
      final followingRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);

      final isFollowing = await followingRef.get();
      if (!isFollowing.exists) {
        debugPrint('DEBUG: Not following user $targetUserId');
        return; // Not following
      }

      final batch = _firestore.batch();

      // Remove from current user's following list
      batch.delete(followingRef);

      // Remove from target user's followers list
      final followerRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);

      batch.delete(followerRef);

      // Update follower counts (prevent negative numbers)
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      final currentUserDoc = await currentUserRef.get();
      final currentFollowingCount =
          (currentUserDoc.data()?['followingCount'] as int?) ?? 0;

      if (currentFollowingCount > 0) {
        batch.update(currentUserRef, {
          'followingCount': FieldValue.increment(-1),
        });
      }

      final targetUserRef = _firestore.collection('users').doc(targetUserId);
      final targetUserDoc = await targetUserRef.get();
      final targetFollowerCount =
          (targetUserDoc.data()?['followerCount'] as int?) ?? 0;

      if (targetFollowerCount > 0) {
        batch.update(targetUserRef, {
          'followerCount': FieldValue.increment(-1),
        });
      }

      await batch.commit();
      debugPrint('DEBUG: Successfully unfollowed user $targetUserId');
    } on FirebaseException catch (e) {
      debugPrint('ERROR: Firebase error while unfollowing: ${e.code} - ${e.message}');
      throw AppException(
        'فشل في إلغاء المتابعة',
        code: e.code,
      );
    } catch (e) {
      debugPrint('ERROR: Error while unfollowing: $e');
      if (e is AppException) rethrow;
      throw AppException('حدث خطأ غير متوقع');
    }
  }

  @override
  Future<void> toggleFollow(String currentUserId, String targetUserId) async {
    final isFollowing = await this.isFollowing(currentUserId, targetUserId);
    
    if (isFollowing) {
      await unfollowUser(currentUserId, targetUserId);
    } else {
      await followUser(currentUserId, targetUserId);
    }
  }

  @override
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
      debugPrint('ERROR: Failed to check follow status: ${e.code}');
      throw AppException(
        'فشل في التحقق من حالة المتابعة',
        code: e.code,
      );
    } catch (e) {
      debugPrint('ERROR: Failed to check follow status: $e');
      if (e is AppException) rethrow;
      throw AppException('حدث خطأ غير متوقع');
    }
  }

  @override
  Future<List<String>> getFollowers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('followers')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('ERROR: Failed to get followers: $e');
      return [];
    }
  }

  @override
  Future<List<String>> getFollowing(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('ERROR: Failed to get following: $e');
      return [];
    }
  }

  @override
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
      debugPrint('ERROR: Failed to get follower count: ${e.code}');
      throw AppException(
        'فشل في الحصول على عدد المتابعين',
        code: e.code,
      );
    } catch (e) {
      debugPrint('ERROR: Failed to get follower count: $e');
      if (e is AppException) rethrow;
      throw AppException('حدث خطأ غير متوقع');
    }
  }

  @override
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
      debugPrint('ERROR: Failed to get following count: ${e.code}');
      throw AppException(
        'فشل في الحصول على عدد المتابعة',
        code: e.code,
      );
    } catch (e) {
      debugPrint('ERROR: Failed to get following count: $e');
      if (e is AppException) rethrow;
      throw AppException('حدث خطأ غير متوقع');
    }
  }
}
