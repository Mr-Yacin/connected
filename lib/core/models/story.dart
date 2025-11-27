import 'enums.dart';

/// Story model representing a temporary story post
class Story {
  final String id;
  final String userId;
  final String mediaUrl;
  final StoryType type;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewerIds;
  final List<String> likedBy;
  final int replyCount;

  Story({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
    this.viewerIds = const [],
    this.likedBy = const [],
    this.replyCount = 0,
  });

  /// Check if the story has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Convert Story to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'mediaUrl': mediaUrl,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'viewerIds': viewerIds,
      'likedBy': likedBy,
      'replyCount': replyCount,
    };
  }

  /// Create Story from JSON (Firestore document)
  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      userId: json['userId'] as String,
      mediaUrl: json['mediaUrl'] as String,
      type: StoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StoryType.image,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      viewerIds: (json['viewerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      likedBy: (json['likedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      replyCount: (json['replyCount'] as int?) ?? 0,
    );
  }

  /// Create a copy of Story with updated fields
  Story copyWith({
    String? id,
    String? userId,
    String? mediaUrl,
    StoryType? type,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? viewerIds,
    List<String>? likedBy,
    int? replyCount,
  }) {
    return Story(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewerIds: viewerIds ?? this.viewerIds,
      likedBy: likedBy ?? this.likedBy,
      replyCount: replyCount ?? this.replyCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Story &&
        other.id == id &&
        other.userId == userId &&
        other.mediaUrl == mediaUrl &&
        other.type == type &&
        other.createdAt == createdAt &&
        other.expiresAt == expiresAt &&
        _listEquals(other.viewerIds, viewerIds) &&
        _listEquals(other.likedBy, likedBy) &&
        other.replyCount == replyCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      mediaUrl,
      type,
      createdAt,
      expiresAt,
      Object.hashAll(viewerIds),
      Object.hashAll(likedBy),
      replyCount,
    );
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
