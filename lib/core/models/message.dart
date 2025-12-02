import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// Message model representing a chat message
class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final MessageType type;
  final String content; // text content or audio URL
  final DateTime timestamp;
  final bool isRead;
  
  // Story reply metadata (only for storyReply type)
  final String? storyId;
  final String? storyMediaUrl;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.storyId,
    this.storyMediaUrl,
  });

  /// Convert Message to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type.name,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      if (storyId != null) 'storyId': storyId,
      if (storyMediaUrl != null) 'storyMediaUrl': storyMediaUrl,
    };
  }

  /// Create Message from JSON (Firestore document)
  factory Message.fromJson(Map<String, dynamic> json) {
    // Handle timestamp - can be String (ISO8601) or Timestamp object
    DateTime timestamp;
    final timestampValue = json['timestamp'];
    if (timestampValue is String) {
      timestamp = DateTime.parse(timestampValue);
    } else if (timestampValue is Timestamp) {
      // Handle Firestore Timestamp
      timestamp = timestampValue.toDate();
    } else {
      // Fallback to current time if parsing fails
      timestamp = DateTime.now();
    }

    return Message(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      content: json['content'] as String,
      timestamp: timestamp,
      isRead: json['isRead'] as bool? ?? false,
      storyId: json['storyId'] as String?,
      storyMediaUrl: json['storyMediaUrl'] as String?,
    );
  }

  /// Create a copy of Message with updated fields
  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    MessageType? type,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? storyId,
    String? storyMediaUrl,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      storyId: storyId ?? this.storyId,
      storyMediaUrl: storyMediaUrl ?? this.storyMediaUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Message &&
        other.id == id &&
        other.chatId == chatId &&
        other.senderId == senderId &&
        other.receiverId == receiverId &&
        other.type == type &&
        other.content == content &&
        other.timestamp == timestamp &&
        other.isRead == isRead &&
        other.storyId == storyId &&
        other.storyMediaUrl == storyMediaUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      chatId,
      senderId,
      receiverId,
      type,
      content,
      timestamp,
      isRead,
      storyId,
      storyMediaUrl,
    );
  }
}
