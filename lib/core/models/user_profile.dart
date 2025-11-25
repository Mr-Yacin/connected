import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile model representing a user in the system
class UserProfile {
  final String id;
  final String phoneNumber;
  final String? name;
  final int? age;
  final String? country;
  final String? dialect;
  final String? profileImageUrl;
  final String? gender;
  final bool isActive;
  final bool isImageBlurred;
  final String? anonymousLink;
  final DateTime createdAt;
  final DateTime lastActive;

  UserProfile({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.age,
    this.country,
    this.dialect,
    this.profileImageUrl,
    this.gender,
    this.isActive = true,
    this.isImageBlurred = false,
    this.anonymousLink,
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
      'dialect': dialect,
      'profileImageUrl': profileImageUrl,
      'gender': gender,
      'isActive': isActive,
      'isImageBlurred': isImageBlurred,
      'anonymousLink': anonymousLink,
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
      dialect: json['dialect'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      gender: json['gender'] as String?,
      isActive: json.containsKey('isActive') ? parseBool(json['isActive']) : true,
      isImageBlurred: parseBool(json['isImageBlurred']),
      anonymousLink: json['anonymousLink'] as String?,
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
    String? dialect,
    String? profileImageUrl,
    String? gender,
    bool? isActive,
    bool? isImageBlurred,
    String? anonymousLink,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return UserProfile(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      age: age ?? this.age,
      country: country ?? this.country,
      dialect: dialect ?? this.dialect,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      gender: gender ?? this.gender,
      isActive: isActive ?? this.isActive,
      isImageBlurred: isImageBlurred ?? this.isImageBlurred,
      anonymousLink: anonymousLink ?? this.anonymousLink,
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
        other.dialect == dialect &&
        other.profileImageUrl == profileImageUrl &&
        other.gender == gender &&
        other.isActive == isActive &&
        other.isImageBlurred == isImageBlurred &&
        other.anonymousLink == anonymousLink &&
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
      dialect,
      profileImageUrl,
      gender,
      isActive,
      isImageBlurred,
      anonymousLink,
      createdAt,
      lastActive,
    );
  }
}
