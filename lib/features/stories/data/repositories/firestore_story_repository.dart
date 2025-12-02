import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/story.dart';
import '../../../../core/models/story_reply.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/repositories/story_repository.dart';
import '../../../../services/monitoring/error_logging_service.dart';

/// Firestore implementation of StoryRepository
class FirestoreStoryRepository implements StoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Uuid _uuid;

  FirestoreStoryRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    Uuid? uuid,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _uuid = uuid ?? const Uuid();

  @override
  Future<Story> createStory(Story story) async {
    try {
      final storyId = story.id.isEmpty ? _uuid.v4() : story.id;
      final storyPayload = story.copyWith(id: storyId);

      // Save story to Firestore
      await _firestore
          .collection('stories')
          .doc(storyId)
          .set(storyPayload.toJson());

      return storyPayload;
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to create story',
        screen: 'StoryCreationScreen',
        operation: 'createStory',
        collection: 'stories',
      );
      throw AppException('فشل في إنشاء القصة: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error creating story',
        screen: 'StoryCreationScreen',
        operation: 'createStory',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Stream<List<Story>> getActiveStories() {
    try {
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

      return _firestore
          .collection('stories')
          .where(
            'createdAt',
            isGreaterThan: twentyFourHoursAgo.toIso8601String(),
          )
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => Story.fromJson(doc.data()))
                .toList();
          });
    } catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get active stories stream',
        screen: 'HomeScreen',
        operation: 'getActiveStories',
        collection: 'stories',
      );
      throw AppException('فشل في جلب القصص: $e');
    }
  }

  @override
  Stream<List<Story>> getActiveStoriesPaginated({
    int limit = 20,
    DateTime? lastStoryCreatedAt,
  }) {
    try {
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

      var query = _firestore
          .collection('stories')
          .where(
            'createdAt',
            isGreaterThan: twentyFourHoursAgo.toIso8601String(),
          )
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastStoryCreatedAt != null) {
        query = query.startAfter([lastStoryCreatedAt.toIso8601String()]);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => Story.fromJson(doc.data())).toList();
      });
    } catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get paginated active stories',
        screen: 'HomeScreen',
        operation: 'getActiveStoriesPaginated',
        collection: 'stories',
      );
      throw AppException('فشل في جلب القصص: $e');
    }
  }

  @override
  Future<int> deleteExpiredStories() async {
    try {
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

      final snapshot = await _firestore
          .collection('stories')
          .where('createdAt', isLessThan: twentyFourHoursAgo.toIso8601String())
          .get();

      int deletedCount = 0;
      for (final doc in snapshot.docs) {
        final story = Story.fromJson(doc.data());

        // Delete media from storage
        try {
          final ref = _storage.refFromURL(story.mediaUrl);
          await ref.delete();
        } catch (e) {
          // Media might already be deleted, continue
        }

        // Delete story document
        await doc.reference.delete();
        deletedCount++;
      }

      return deletedCount;
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to delete expired stories',
        screen: 'Background Service',
        operation: 'deleteExpiredStories',
        collection: 'stories',
      );
      throw AppException('فشل في حذف القصص المنتهية: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error deleting expired stories',
        screen: 'Background Service',
        operation: 'deleteExpiredStories',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<void> recordView(String storyId, String viewerId) async {
    try {
      // Use transaction to prevent duplicate views
      await _firestore.runTransaction((transaction) async {
        final storyRef = _firestore.collection('stories').doc(storyId);
        final storySnapshot = await transaction.get(storyRef);

        if (!storySnapshot.exists) {
          return; // Story doesn't exist, skip
        }

        final story = Story.fromJson(storySnapshot.data()!);

        // Only add view if not already viewed
        if (!story.viewerIds.contains(viewerId)) {
          transaction.update(storyRef, {
            'viewerIds': FieldValue.arrayUnion([viewerId]),
          });
        }
      });
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to record story view',
        screen: 'StoryViewScreen',
        operation: 'recordView',
        collection: 'stories',
        documentId: storyId,
      );
      throw AppException('فشل في تسجيل المشاهدة: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error recording story view',
        screen: 'StoryViewScreen',
        operation: 'recordView',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Stream<List<Story>> getUserStories(String userId) {
    try {
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

      return _firestore
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .where(
            'createdAt',
            isGreaterThan: twentyFourHoursAgo.toIso8601String(),
          )
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => Story.fromJson(doc.data()))
                .toList();
          });
    } catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get user stories',
        screen: 'ProfileScreen',
        operation: 'getUserStories',
        collection: 'stories',
      );
      throw AppException('فشل في جلب قصص المستخدم: $e');
    }
  }

  @override
  Future<void> deleteStory(String storyId) async {
    try {
      // Get story to find media URL
      final storyDoc = await _firestore
          .collection('stories')
          .doc(storyId)
          .get();
      if (storyDoc.exists) {
        final story = Story.fromJson(storyDoc.data()!);

        // Delete media from storage
        try {
          final ref = _storage.refFromURL(story.mediaUrl);
          await ref.delete();
        } catch (e) {
          // Media might already be deleted, continue with story deletion
          ErrorLoggingService.logStorageError(
            e,
            context:
                'Failed to delete story media (continuing with story deletion)',
            screen: 'StoryViewScreen',
            operation: 'deleteStory',
            filePath: story.mediaUrl,
          );
        }
      }

      // Delete story document
      await _firestore.collection('stories').doc(storyId).delete();
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to delete story',
        screen: 'StoryViewScreen',
        operation: 'deleteStory',
        collection: 'stories',
        documentId: storyId,
      );
      throw AppException('فشل في حذف القصة: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error deleting story',
        screen: 'StoryViewScreen',
        operation: 'deleteStory',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<void> likeStory(String storyId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final storyRef = _firestore.collection('stories').doc(storyId);
        final storySnapshot = await transaction.get(storyRef);

        if (!storySnapshot.exists) {
          return; // Story doesn't exist, skip
        }

        transaction.update(storyRef, {
          'likedBy': FieldValue.arrayUnion([userId]),
        });
      });
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to like story',
        screen: 'StoryViewScreen',
        operation: 'likeStory',
        collection: 'stories',
        documentId: storyId,
      );
      throw AppException('فشل في الإعجاب بالقصة: ${e.message}');
    }
  }

  @override
  Future<void> unlikeStory(String storyId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final storyRef = _firestore.collection('stories').doc(storyId);
        final storySnapshot = await transaction.get(storyRef);

        if (!storySnapshot.exists) {
          return; // Story doesn't exist, skip
        }

        transaction.update(storyRef, {
          'likedBy': FieldValue.arrayRemove([userId]),
        });
      });
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to unlike story',
        screen: 'StoryViewScreen',
        operation: 'unlikeStory',
        collection: 'stories',
        documentId: storyId,
      );
      throw AppException('فشل في إلغاء الإعجاب: ${e.message}');
    }
  }

  @override
  Future<void> incrementReplyCount(String storyId) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'replyCount': FieldValue.increment(1),
      });
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to increment reply count',
        screen: 'StoryViewScreen',
        operation: 'incrementReplyCount',
        collection: 'stories',
        documentId: storyId,
      );
      throw AppException('فشل في تحديث عدد الردود: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error incrementing reply count',
        screen: 'StoryViewScreen',
        operation: 'incrementReplyCount',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }
}
