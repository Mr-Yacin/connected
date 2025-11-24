import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/story.dart';
import '../../domain/repositories/story_repository.dart';

/// Firestore implementation of StoryRepository
class FirestoreStoryRepository implements StoryRepository {
  final FirebaseFirestore _firestore;
  static const String _storiesCollection = 'stories';

  FirestoreStoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Story> createStory(Story story) async {
    try {
      // Generate ID if not provided
      final docRef = story.id.isEmpty
          ? _firestore.collection(_storiesCollection).doc()
          : _firestore.collection(_storiesCollection).doc(story.id);

      // Create story with generated ID and 24-hour expiration
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      final newStory = Story(
        id: docRef.id,
        userId: story.userId,
        mediaUrl: story.mediaUrl,
        type: story.type,
        createdAt: now,
        expiresAt: expiresAt,
        viewerIds: [],
      );

      await docRef.set(newStory.toJson());
      return newStory;
    } catch (e) {
      throw Exception('Failed to create story: $e');
    }
  }

  @override
  Stream<List<Story>> getActiveStories() {
    try {
      final now = DateTime.now();

      return _firestore
          .collection(_storiesCollection)
          .where('expiresAt', isGreaterThan: now.toIso8601String())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Story.fromJson(doc.data()))
            .where((story) => !story.isExpired) // Additional client-side filter
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get active stories: $e');
    }
  }

  @override
  Future<int> deleteExpiredStories() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_storiesCollection)
          .where('expiresAt', isLessThanOrEqualTo: now.toIso8601String())
          .get();

      int deletedCount = 0;
      final batch = _firestore.batch();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        deletedCount++;
      }

      if (deletedCount > 0) {
        await batch.commit();
      }

      return deletedCount;
    } catch (e) {
      throw Exception('Failed to delete expired stories: $e');
    }
  }

  @override
  Future<void> recordView(String storyId, String viewerId) async {
    try {
      final docRef = _firestore.collection(_storiesCollection).doc(storyId);

      // Use arrayUnion to add viewerId only if it doesn't exist
      await docRef.update({
        'viewerIds': FieldValue.arrayUnion([viewerId]),
      });
    } catch (e) {
      throw Exception('Failed to record view: $e');
    }
  }

  @override
  Stream<List<Story>> getUserStories(String userId) {
    try {
      final now = DateTime.now();

      return _firestore
          .collection(_storiesCollection)
          .where('userId', isEqualTo: userId)
          .where('expiresAt', isGreaterThan: now.toIso8601String())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Story.fromJson(doc.data()))
            .where((story) => !story.isExpired)
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get user stories: $e');
    }
  }

  @override
  Future<void> deleteStory(String storyId) async {
    try {
      await _firestore.collection(_storiesCollection).doc(storyId).delete();
    } catch (e) {
      throw Exception('Failed to delete story: $e');
    }
  }
}
