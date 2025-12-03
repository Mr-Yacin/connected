/// Abstract interface for follow repository
abstract class FollowRepository {
  /// Follow a user (direct follow, no request needed)
  Future<void> followUser(String currentUserId, String targetUserId);

  /// Unfollow a user
  Future<void> unfollowUser(String currentUserId, String targetUserId);

  /// Toggle follow status
  Future<void> toggleFollow(String currentUserId, String targetUserId);

  /// Check if current user is following target user
  Future<bool> isFollowing(String currentUserId, String targetUserId);

  /// Get followers list for a user
  Future<List<String>> getFollowers(String userId);

  /// Get following list for a user
  Future<List<String>> getFollowing(String userId);

  /// Get follower count for a user
  Future<int> getFollowerCount(String userId);

  /// Get following count for a user
  Future<int> getFollowingCount(String userId);
}
