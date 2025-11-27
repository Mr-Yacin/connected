import 'package:cloud_firestore/cloud_firestore.dart';

/// Like model representing a like from one user to another
class Like {
  final String id;
  final String fromUserId; // User who gave the like
  final String toUserId; // User who received the like
  final DateTime createdAt;
  final bool isActive; // For soft delete

  Like({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.createdAt,
    this.isActive = true,
  });

  /// Convert Like to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Create Like from JSON (Firestore document)
  factory Like.fromJson(Map<String, dynamic> json) {
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

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.toLowerCase();
        return normalized == 'true' || normalized == '1';
      }
      return false;
    }

    final now = DateTime.now();

    return Like(
      id: (json['id'] as String?) ?? '',
      fromUserId: (json['fromUserId'] as String?) ?? '',
      toUserId: (json['toUserId'] as String?) ?? '',
      createdAt: parseDate(json['createdAt'], fallback: now),
      isActive: json.containsKey('isActive') ? parseBool(json['isActive']) : true,
    );
  }

  /// Create a copy of Like with updated fields
  Like copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Like(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Like &&
        other.id == id &&
        other.fromUserId == fromUserId &&
        other.toUserId == toUserId &&
        other.createdAt == createdAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      fromUserId,
      toUserId,
      createdAt,
      isActive,
    );
  }
}
