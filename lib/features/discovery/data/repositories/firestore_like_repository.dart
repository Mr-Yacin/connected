import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/like.dart';
import '../../../../core/data/base_firestore_repository.dart';
import '../../domain/repositories/like_repository.dart';

/// Firestore implementation of LikeRepository
class FirestoreLikeRepository extends BaseFirestoreRepository 
    implements LikeRepository {
  final FirebaseFirestore _firestore;

  FirestoreLikeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Like a user
  @override
  Future<void> likeUser(String fromUserId, String toUserId) async {
    return handleFirestoreVoidOperation(
      operation: () async {
        if (fromUserId == toUserId) {
          throw Exception('لا يمكنك الإعجاب بنفسك');
        }

        final likeId = '${fromUserId}_$toUserId';
        final likeRef = _firestore.collection('likes').doc(likeId);
        final userRef = _firestore.collection('users').doc(toUserId);

        final likeDoc = await likeRef.get();
        
        if (likeDoc.exists && likeDoc.data()?['isActive'] == true) {
          return;
        }

        await _executeLikeBatch(likeRef, userRef, likeDoc, fromUserId, toUserId, isLike: true);
      },
      operationName: 'likeUser',
      screen: 'ShuffleScreen',
      arabicErrorMessage: 'فشل في الإعجاب بالمستخدم',
      collection: 'likes',
    );
  }

  /// Unlike a user
  @override
  Future<void> unlikeUser(String fromUserId, String toUserId) async {
    return handleFirestoreVoidOperation(
      operation: () async {
        final likeId = '${fromUserId}_$toUserId';
        final likeRef = _firestore.collection('likes').doc(likeId);
        final userRef = _firestore.collection('users').doc(toUserId);

        final likeDoc = await likeRef.get();
        if (!likeDoc.exists || likeDoc.data()?['isActive'] != true) {
          return;
        }

        await _executeLikeBatch(likeRef, userRef, likeDoc, fromUserId, toUserId, isLike: false);
      },
      operationName: 'unlikeUser',
      screen: 'ShuffleScreen',
      arabicErrorMessage: 'فشل في إلغاء الإعجاب',
      collection: 'likes',
    );
  }

  /// Execute atomic batch operation for like/unlike
  Future<void> _executeLikeBatch(
    DocumentReference likeRef,
    DocumentReference userRef,
    DocumentSnapshot likeDoc,
    String fromUserId,
    String toUserId, {
    required bool isLike,
  }) async {
    final batch = _firestore.batch();

    if (isLike) {
      if (likeDoc.exists) {
        batch.update(likeRef, {
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
        });
        batch.update(userRef, {'likesCount': FieldValue.increment(1)});
      } else {
        final like = Like(
          id: '${fromUserId}_$toUserId',
          fromUserId: fromUserId,
          toUserId: toUserId,
          createdAt: DateTime.now(),
          isActive: true,
        );
        batch.set(likeRef, like.toJson());
        batch.update(userRef, {'likesCount': FieldValue.increment(1)});
      }
    } else {
      batch.update(likeRef, {'isActive': false});
      final userDoc = await userRef.get();
      final currentCount = (userDoc.data() as Map<String, dynamic>?)?['likesCount'] as int? ?? 0;
      
      if (currentCount > 0) {
        batch.update(userRef, {'likesCount': FieldValue.increment(-1)});
      }
    }

    await batch.commit();
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
    return handleFirestoreOperation(
      operation: () async {
        final likeId = '${fromUserId}_$toUserId';
        final likeDoc = await _firestore.collection('likes').doc(likeId).get();
        if (!likeDoc.exists) return false;
        final data = likeDoc.data();
        return data?['isActive'] == true;
      },
      operationName: 'hasLiked',
      screen: 'ShuffleScreen',
      arabicErrorMessage: 'فشل في التحقق من حالة الإعجاب',
      collection: 'likes',
    );
  }

  /// Get all active likes received by a user
  @override
  Future<List<Like>> getUserLikes(String userId) async {
    return handleFirestoreOperation(
      operation: () async {
        final querySnapshot = await _firestore
            .collection('likes')
            .where('toUserId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

        return mapQuerySnapshot(
          snapshot: querySnapshot,
          fromJson: Like.fromJson,
        );
      },
      operationName: 'getUserLikes',
      screen: 'LikesListScreen',
      arabicErrorMessage: 'فشل في جلب قائمة الإعجابات',
      collection: 'likes',
    );
  }

  /// Get all active likes given by a user
  @override
  Future<List<Like>> getUserLikedBy(String userId) async {
    return handleFirestoreOperation(
      operation: () async {
        final querySnapshot = await _firestore
            .collection('likes')
            .where('fromUserId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

        return mapQuerySnapshot(
          snapshot: querySnapshot,
          fromJson: Like.fromJson,
        );
      },
      operationName: 'getUserLikedBy',
      screen: 'LikesListScreen',
      arabicErrorMessage: 'فشل في جلب قائمة المعجبين',
      collection: 'likes',
    );
  }

  /// Get like count for a user (number of users who liked them)
  @override
  Future<int> getLikeCount(String userId) async {
    return handleFirestoreOperation(
      operation: () async {
        final querySnapshot = await _firestore
            .collection('likes')
            .where('toUserId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .get();

        return querySnapshot.size;
      },
      operationName: 'getLikeCount',
      screen: 'ProfileScreen',
      arabicErrorMessage: 'فشل في جلب عدد الإعجابات',
      collection: 'likes',
    );
  }
}
