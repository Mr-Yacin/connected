import '../repositories/firestore_moderation_repository.dart';

/// Service for handling block-related operations
class BlockService {
  final FirestoreModerationRepository _moderationRepository;

  BlockService({required FirestoreModerationRepository moderationRepository})
      : _moderationRepository = moderationRepository;

  /// Check if a user is blocked by another user
  /// 
  /// [userId] - The ID of the user who might have blocked
  /// [targetUserId] - The ID of the user to check if blocked
  /// Returns true if targetUserId is blocked by userId
  Future<bool> isBlocked(String userId, String targetUserId) async {
    try {
      final blockedUsers = await _moderationRepository.getBlockedUsers(userId);
      return blockedUsers.contains(targetUserId);
    } catch (e) {
      // If there's an error fetching blocked users, assume not blocked
      return false;
    }
  }

  /// Check if access should be prevented between two users
  /// This checks both directions - if either user has blocked the other
  /// 
  /// [userId1] - First user ID
  /// [userId2] - Second user ID
  /// Returns true if access should be prevented
  Future<bool> preventAccess(String userId1, String userId2) async {
    try {
      // Check if user1 blocked user2
      final user1BlockedUser2 = await isBlocked(userId1, userId2);
      if (user1BlockedUser2) return true;

      // Check if user2 blocked user1
      final user2BlockedUser1 = await isBlocked(userId2, userId1);
      if (user2BlockedUser1) return true;

      return false;
    } catch (e) {
      // If there's an error, allow access by default
      return false;
    }
  }

  /// Check if a user can send a message to another user
  /// 
  /// [senderId] - The ID of the user trying to send a message
  /// [receiverId] - The ID of the user who would receive the message
  /// Returns true if the message can be sent
  Future<bool> canSendMessage(String senderId, String receiverId) async {
    final accessPrevented = await preventAccess(senderId, receiverId);
    return !accessPrevented;
  }

  /// Check if a user can view another user's profile
  /// 
  /// [viewerId] - The ID of the user trying to view the profile
  /// [profileUserId] - The ID of the user whose profile is being viewed
  /// Returns true if the profile can be viewed
  Future<bool> canViewProfile(String viewerId, String profileUserId) async {
    final accessPrevented = await preventAccess(viewerId, profileUserId);
    return !accessPrevented;
  }
}
