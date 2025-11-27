/// Story reply model representing a message reply to a story
class StoryReply {
  final String id;
  final String storyId;
  final String senderId;
  final String message;
  final DateTime createdAt;

  StoryReply({
    required this.id,
    required this.storyId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  /// Convert StoryReply to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storyId': storyId,
      'senderId': senderId,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create StoryReply from JSON (Firestore document)
  factory StoryReply.fromJson(Map<String, dynamic> json) {
    return StoryReply(
      id: json['id'] as String,
      storyId: json['storyId'] as String,
      senderId: json['senderId'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Create a copy of StoryReply with updated fields
  StoryReply copyWith({
    String? id,
    String? storyId,
    String? senderId,
    String? message,
    DateTime? createdAt,
  }) {
    return StoryReply(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StoryReply &&
        other.id == id &&
        other.storyId == storyId &&
        other.senderId == senderId &&
        other.message == message &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      storyId,
      senderId,
      message,
      createdAt,
    );
  }
}
