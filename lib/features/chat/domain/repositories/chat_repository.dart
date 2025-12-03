import 'dart:io';
import '../../../../core/models/message.dart';

/// Repository interface for chat operations
abstract class ChatRepository {
  /// Get messages stream for real-time updates
  Stream<List<Message>> getMessages(String chatId);
  
  /// Get paginated messages for a chat
  /// Returns a stream of messages limited by [limit]
  /// Use [lastMessageTimestamp] to load older messages
  Stream<List<Message>> getMessagesPaginated({
    required String chatId,
    int limit = 50,
    DateTime? lastMessageTimestamp,
  });
  
  /// Send a text message
  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  });
  
  /// Send a voice message
  Future<void> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required File audioFile,
  });
  
  /// Send a story reply message
  Future<void> sendStoryReplyMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
    required String storyId,
    required String storyMediaUrl,
  });
  
  /// Mark a message as read
  Future<void> markAsRead(String chatId, String messageId);
  
  /// Mark entire chat as read for a user (resets unread count)
  Future<void> markChatAsRead(String chatId, String userId);
  
  /// Get list of chats for a user
  Future<List<ChatPreview>> getChatList(String userId);
  
  /// Get chat list stream for real-time updates
  Stream<List<ChatPreview>> getChatListStream(String userId);
  
  /// Update denormalized participant data in all chats for a specific user
  /// This should be called when a user updates their profile (name or profile image)
  /// Set [runInBackground] to true to run the update asynchronously without blocking
  Future<void> updateUserDenormalizedData({
    required String userId,
    required String userName,
    String? userImageUrl,
    bool runInBackground = false,
  });
}

/// Chat preview model for chat list
class ChatPreview {
  final String chatId;
  final String otherUserId;
  final String? otherUserName;
  final String? otherUserImageUrl;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  ChatPreview({
    required this.chatId,
    required this.otherUserId,
    this.otherUserName,
    this.otherUserImageUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserImageUrl': otherUserImageUrl,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
    };
  }

  factory ChatPreview.fromJson(Map<String, dynamic> json) {
    return ChatPreview(
      chatId: json['chatId'] as String,
      otherUserId: json['otherUserId'] as String,
      otherUserName: json['otherUserName'] as String?,
      otherUserImageUrl: json['otherUserImageUrl'] as String?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}
