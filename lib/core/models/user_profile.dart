import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile model representing a user in the system
class UserProfile {
  final String id;
  final String phoneNumber;
  final String? name;
  final int? age;
  final String? country;
  final String? profileImageUrl;
  final String? gender;
  final String? bio;
  final bool isActive;
  final bool isImageBlurred;
  final String? anonymousLink;
  final int followerCount;
  final int followingCount;
  final int likesCount;
  final DateTime createdAt;
  final DateTime lastActive;

  UserProfile({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.age,
    this.country,
    this.profileImageUrl,
    this.gender,
    this.bio,
    this.isActive = true,
    this.isImageBlurred = false,
    this.anonymousLink,
    this.followerCount = 0,
    this.followingCount = 0,
    this.likesCount = 0,
    required this.createdAt,
    required this.lastActive,
  });

  /// Convert UserProfile to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'age': age,
      'country': country,
      'profileImageUrl': profileImageUrl,
      'gender': gender,
      'bio': bio,
      'isActive': isActive,
      'isImageBlurred': isImageBlurred,
      'anonymousLink': anonymousLink,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'likesCount': likesCount,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }

  /// Create UserProfile from JSON (Firestore document)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, {required DateTime fallback}) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is num) {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      }
      if (value is String && value.isNotEmpty) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return fallback;
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim());
      return null;
    }

    bool parseBool(dynamic value) {
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.toLowerCase();
        return normalized == 'true' || normalized == '1';
      }
      return false;
    }

    final now = DateTime.now();

    return UserProfile(
      id: (json['id'] as String?) ?? (json['uid'] as String?) ?? '',
      phoneNumber: (json['phoneNumber'] as String?) ?? '',
      name: json['name'] as String?,
      age: parseInt(json['age']),
      country: json['country'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      isActive: json.containsKey('isActive') ? parseBool(json['isActive']) : true,
      isImageBlurred: parseBool(json['isImageBlurred']),
      anonymousLink: json['anonymousLink'] as String?,
      followerCount: parseInt(json['followerCount']) ?? 0,
      followingCount: parseInt(json['followingCount']) ?? 0,
      likesCount: parseInt(json['likesCount']) ?? 0,
      createdAt: parseDate(json['createdAt'], fallback: now),
      lastActive: parseDate(json['lastActive'], fallback: now),
    );
  }

  /// Create a copy of UserProfile with updated fields
  UserProfile copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    int? age,
    String? country,
    String? profileImageUrl,
    String? gender,
    String? bio,
    bool? isActive,
    bool? isImageBlurred,
    String? anonymousLink,
    int? followerCount,
    int? followingCount,
    int? likesCount,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return UserProfile(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      age: age ?? this.age,
      country: country ?? this.country,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      isActive: isActive ?? this.isActive,
      isImageBlurred: isImageBlurred ?? this.isImageBlurred,
      anonymousLink: anonymousLink ?? this.anonymousLink,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfile &&
        other.id == id &&
        other.phoneNumber == phoneNumber &&
        other.name == name &&
        other.age == age &&
        other.country == country &&
        other.profileImageUrl == profileImageUrl &&
        other.gender == gender &&
        other.bio == bio &&
        other.isActive == isActive &&
        other.isImageBlurred == isImageBlurred &&
        other.anonymousLink == anonymousLink &&
        other.followerCount == followerCount &&
        other.followingCount == followingCount &&
        other.likesCount == likesCount &&
        other.createdAt == createdAt &&
        other.lastActive == lastActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      phoneNumber,
      name,
      age,
      country,
      profileImageUrl,
      gender,
      bio,
      isActive,
      isImageBlurred,
      anonymousLink,
      followerCount,
      followingCount,
      likesCount,
      createdAt,
      lastActive,
    );
  }
}
