import 'package:cloud_firestore/cloud_firestore.dart';

/// Discovery filters model for filtering user search results
class DiscoveryFilters {
  final String? country;
  final String? dialect;
  final int? minAge;
  final int? maxAge;
  final List<String> excludedUserIds;
  final int pageSize;
  final DocumentSnapshot? lastDocument;

  DiscoveryFilters({
    this.country,
    this.dialect,
    this.minAge,
    this.maxAge,
    this.excludedUserIds = const [],
    this.pageSize = 20,
    this.lastDocument,
  });

  /// Convert DiscoveryFilters to JSON
  /// Note: lastDocument is not serialized as it's runtime state
  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'dialect': dialect,
      'minAge': minAge,
      'maxAge': maxAge,
      'excludedUserIds': excludedUserIds,
      'pageSize': pageSize,
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
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  /// Create a copy of DiscoveryFilters with updated fields
  DiscoveryFilters copyWith({
    String? country,
    String? dialect,
    int? minAge,
    int? maxAge,
    List<String>? excludedUserIds,
    int? pageSize,
    DocumentSnapshot? lastDocument,
    bool clearLastDocument = false,
  }) {
    return DiscoveryFilters(
      country: country ?? this.country,
      dialect: dialect ?? this.dialect,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      excludedUserIds: excludedUserIds ?? this.excludedUserIds,
      pageSize: pageSize ?? this.pageSize,
      lastDocument: clearLastDocument ? null : (lastDocument ?? this.lastDocument),
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
        other.pageSize == pageSize &&
        _listEquals(other.excludedUserIds, excludedUserIds);
  }

  @override
  int get hashCode {
    return Object.hash(
      country,
      dialect,
      minAge,
      maxAge,
      pageSize,
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
