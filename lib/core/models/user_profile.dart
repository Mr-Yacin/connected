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
  final bool isGuest;
  final String? anonymousLink;
  final int followerCount;
  final int followingCount;
  final DateTime createdAt;
  final DateTime lastActive;
  final Map<String, dynamic>? settings;

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
    this.isGuest = false,
    this.anonymousLink,
    this.followerCount = 0,
    this.followingCount = 0,
    required this.createdAt,
    required this.lastActive,
    this.settings,
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
      'isGuest': isGuest,
      'anonymousLink': anonymousLink,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      if (settings != null) 'settings': settings,
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
      isActive: json.containsKey('isActive')
          ? parseBool(json['isActive'])
          : true,
      isImageBlurred: parseBool(json['isImageBlurred']),
      isGuest: json.containsKey('isGuest') ? parseBool(json['isGuest']) : false,
      anonymousLink: json['anonymousLink'] as String?,
      followerCount: parseInt(json['followerCount']) ?? 0,
      followingCount: parseInt(json['followingCount']) ?? 0,
      createdAt: parseDate(json['createdAt'], fallback: now),
      lastActive: parseDate(json['lastActive'], fallback: now),
      settings: json['settings'] as Map<String, dynamic>?,
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
    bool? isGuest,
    String? anonymousLink,
    int? followerCount,
    int? followingCount,
    DateTime? createdAt,
    DateTime? lastActive,
    Map<String, dynamic>? settings,
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
      isGuest: isGuest ?? this.isGuest,
      anonymousLink: anonymousLink ?? this.anonymousLink,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      settings: settings ?? this.settings,
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
        other.isGuest == isGuest &&
        other.anonymousLink == anonymousLink &&
        other.followerCount == followerCount &&
        other.followingCount == followingCount &&
        other.createdAt == createdAt &&
        other.lastActive == lastActive &&
        _mapsEqual(other.settings, settings);
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
      isGuest,
      anonymousLink,
      followerCount,
      followingCount,
      createdAt,
      lastActive,
      settings,
    );
  }

  /// Helper method for comparing maps
  static bool _mapsEqual(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  /// Helper getter for profile view notification setting
  bool get notifyOnProfileView => settings?['notifyOnProfileView'] ?? false;
}
