import '../../../../core/models/story.dart';

/// Repository interface for managing stories
abstract class StoryRepository {
  /// Create a new story
  /// Returns the created story with generated ID
  Future<Story> createStory(Story story);

  /// Get stream of active (non-expired) stories
  /// Stories are ordered by createdAt descending (newest first)
  Stream<List<Story>> getActiveStories();

  /// Get paginated active stories
  /// Returns a stream of stories limited by [limit]
  /// Use [lastStoryCreatedAt] to load older stories
  Stream<List<Story>> getActiveStoriesPaginated({
    int limit = 20,
    DateTime? lastStoryCreatedAt,
  });

  /// Delete expired stories (stories older than 24 hours)
  /// Returns the number of stories deleted
  Future<int> deleteExpiredStories();

  /// Record a view for a story
  /// Adds viewerId to the story's viewerIds list
  Future<void> recordView(String storyId, String viewerId);

  /// Get stories for a specific user
  Stream<List<Story>> getUserStories(String userId);

  /// Delete a specific story
  Future<void> deleteStory(String storyId);
}
