/// User profile model representing a user in the system
class UserProfile {
  final String id;
  final String phoneNumber;
  final String? name;
  final int? age;
  final String? country;
  final String? dialect;
  final String? profileImageUrl;
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
      'isImageBlurred': isImageBlurred,
      'anonymousLink': anonymousLink,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }

  /// Create UserProfile from JSON (Firestore document)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String,
      name: json['name'] as String?,
      age: json['age'] as int?,
      country: json['country'] as String?,
      dialect: json['dialect'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      isImageBlurred: json['isImageBlurred'] as bool? ?? false,
      anonymousLink: json['anonymousLink'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActive: DateTime.parse(json['lastActive'] as String),
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
      isImageBlurred,
      anonymousLink,
      createdAt,
      lastActive,
    );
  }
}
