/// Discovery filters model for filtering user search results
class DiscoveryFilters {
  final String? country;
  final String? dialect;
  final int? minAge;
  final int? maxAge;
  final List<String> excludedUserIds;

  DiscoveryFilters({
    this.country,
    this.dialect,
    this.minAge,
    this.maxAge,
    this.excludedUserIds = const [],
  });

  /// Convert DiscoveryFilters to JSON
  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'dialect': dialect,
      'minAge': minAge,
      'maxAge': maxAge,
      'excludedUserIds': excludedUserIds,
    };
  }

  /// Create DiscoveryFilters from JSON
  factory DiscoveryFilters.fromJson(Map<String, dynamic> json) {
    return DiscoveryFilters(
      country: json['country'] as String?,
      dialect: json['dialect'] as String?,
      minAge: json['minAge'] as int?,
      maxAge: json['maxAge'] as int?,
      excludedUserIds: (json['excludedUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Create a copy of DiscoveryFilters with updated fields
  DiscoveryFilters copyWith({
    String? country,
    String? dialect,
    int? minAge,
    int? maxAge,
    List<String>? excludedUserIds,
  }) {
    return DiscoveryFilters(
      country: country ?? this.country,
      dialect: dialect ?? this.dialect,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      excludedUserIds: excludedUserIds ?? this.excludedUserIds,
    );
  }

  /// Check if any filters are active
  bool get hasActiveFilters =>
      country != null ||
      dialect != null ||
      minAge != null ||
      maxAge != null ||
      excludedUserIds.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DiscoveryFilters &&
        other.country == country &&
        other.dialect == dialect &&
        other.minAge == minAge &&
        other.maxAge == maxAge &&
        _listEquals(other.excludedUserIds, excludedUserIds);
  }

  @override
  int get hashCode {
    return Object.hash(
      country,
      dialect,
      minAge,
      maxAge,
      Object.hashAll(excludedUserIds),
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
