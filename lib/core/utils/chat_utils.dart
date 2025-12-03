/// Utility functions for chat functionality
class ChatUtils {
  /// Generate a deterministic chat ID for two users
  /// 
  /// This ensures that the same chat ID is generated regardless of who
  /// initiates the conversation. User IDs are sorted alphabetically to
  /// guarantee consistency.
  /// 
  /// Example:
  /// - User A (id: "abc") chats with User B (id: "xyz")
  /// - User B (id: "xyz") chats with User A (id: "abc")
  /// - Both generate the same chatId: "abc_xyz"
  /// 
  /// This prevents duplicate chat documents in Firestore.
  static String generateChatId(String userId1, String userId2) {
    if (userId1.isEmpty || userId2.isEmpty) {
      throw ArgumentError('User IDs cannot be empty');
    }
    
    if (userId1 == userId2) {
      throw ArgumentError('Cannot create chat with same user');
    }
    
    // Sort user IDs alphabetically to ensure consistency
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
}
