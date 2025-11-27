import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/models/like.dart';
import '../../domain/repositories/like_repository.dart';

/// Firestore implementation of LikeRepository
class FirestoreLikeRepository implements LikeRepository {
  final FirebaseFirestore _firestore;

  FirestoreLikeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Like a user
  @override
  Future<void> likeUser(String fromUserId, String toUserId) async {
    try {
      // Prevent self-liking
      if (fromUserId == toUserId) {
        throw Exception('لا يمكنك الإعجاب بنفسك');
      }

      // Use deterministic ID format: fromUserId_toUserId
      final likeId = '${fromUserId}_$toUserId';

      final likeRef = _firestore.collection('likes').doc(likeId);
      final userRef = _firestore.collection('users').doc(toUserId);

      // Check if like already exists
      final likeDoc = await likeRef.get();
      
      if (likeDoc.exists && likeDoc.data()?['isActive'] == true) {
        debugPrint('DEBUG: Like already exists and is active');
        return; // Already liked
      }

      // Use batch for atomic operation
      final batch = _firestore.batch();

      if (likeDoc.exists) {
        // Reactivate existing like
        batch.update(likeRef, {
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
        });
        
        // Increment only if was inactive
        batch.update(userRef, {
          'likesCount': FieldValue.increment(1),
        });
      } else {
        // Create new like
        final like = Like(
          id: likeId,
          fromUserId: fromUserId,
          toUserId: toUserId,
          createdAt: DateTime.now(),
          isActive: true,
        );
        batch.set(likeRef, like.toJson());
        
        // Increment likes count
        batch.update(userRef, {
          'likesCount': FieldValue.increment(1),
        });
      }

      await batch.commit();
      debugPrint('DEBUG: User $fromUserId liked user $toUserId');
    } catch (e) {
      debugPrint('ERROR: Failed to like user: $e');
      rethrow;
    }
  }

  /// Unlike a user
  @override
  Future<void> unlikeUser(String fromUserId, String toUserId) async {
    try {
      final likeId = '${fromUserId}_$toUserId';
      final likeRef = _firestore.collection('likes').doc(likeId);
      final userRef = _firestore.collection('users').doc(toUserId);

      // Check if like exists and is active
      final likeDoc = await likeRef.get();
      if (!likeDoc.exists || likeDoc.data()?['isActive'] != true) {
        debugPrint('DEBUG: Like does not exist or already inactive');
        return;
      }

      // Use batch for atomic operation
      final batch = _firestore.batch();

      // Soft delete: mark as inactive
      batch.update(likeRef, {'isActive': false});

      // Decrement likes count in user profile (ensure doesn't go below 0)
      final userDoc = await userRef.get();
      final currentCount = (userDoc.data()?['likesCount'] as int?) ?? 0;
      
      if (currentCount > 0) {
        batch.update(userRef, {
          'likesCount': FieldValue.increment(-1),
        });
      }

      await batch.commit();
      debugPrint('DEBUG: User $fromUserId unliked user $toUserId');
    } catch (e) {
      debugPrint('ERROR: Failed to unlike user: $e');
      rethrow;
    }
  }

  /// Stream of like count for real-time updates
  Stream<int> getLikeCountStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return 0;
      final data = snapshot.data();
      return (data?['likesCount'] as int?) ?? 0;
    });
  }

  /// Check if user has liked another user
  @override
  Future<bool> hasLiked(String fromUserId, String toUserId) async {
    try {
      final likeId = '${fromUserId}_$toUserId';
      final likeDoc =
          await _firestore.collection('likes').doc(likeId).get();

      if (!likeDoc.exists) return false;

      final data = likeDoc.data();
      return data?['isActive'] == true;
    } catch (e) {
      debugPrint('ERROR: Failed to check like status: $e');
      return false;
    }
  }

  /// Get all active likes received by a user
  @override
  Future<List<Like>> getUserLikes(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('likes')
          .where('toUserId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Like.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('ERROR: Failed to get user likes: $e');
      return [];
    }
  }

  /// Get all active likes given by a user
  @override
  Future<List<Like>> getUserLikedBy(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('likes')
          .where('fromUserId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Like.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('ERROR: Failed to get liked users: $e');
      return [];
    }
  }

  /// Get like count for a user (number of users who liked them)
  @override
  Future<int> getLikeCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('likes')
          .where('toUserId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.size;
    } catch (e) {
      debugPrint('ERROR: Failed to get like count: $e');
      return 0;
    }
  }
}
