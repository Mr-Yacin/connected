import '../../../../core/models/like.dart';

/// Repository interface for managing likes
abstract class LikeRepository {
  /// Like a user
  Future<void> likeUser(String fromUserId, String toUserId);

  /// Unlike a user
  Future<void> unlikeUser(String fromUserId, String toUserId);

  /// Check if user has liked another user
  Future<bool> hasLiked(String fromUserId, String toUserId);

  /// Get all users who liked the specified user
  Future<List<Like>> getUserLikes(String userId);

  /// Get all users that the specified user has liked
  Future<List<Like>> getUserLikedBy(String userId);

  /// Get like count for a user
  Future<int> getLikeCount(String userId);
}
