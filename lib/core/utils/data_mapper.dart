import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class for common data transformation operations.
class DataMapper {
  /// Maps a QuerySnapshot to a list of domain models.
  /// 
  /// Example:
  /// ```dart
  /// final posts = DataMapper.mapList(
  ///   snapshot,
  ///   fromJson: Post.fromJson,
  /// );
  /// ```
  static List<T> mapList<T>({
    required QuerySnapshot snapshot,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    return snapshot.docs
        .map((doc) => fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Maps a DocumentSnapshot to a domain model.
  /// Returns null if document doesn't exist.
  /// 
  /// Example:
  /// ```dart
  /// final user = DataMapper.mapDocument(
  ///   snapshot,
  ///   fromJson: UserProfile.fromJson,
  /// );
  /// ```
  static T? mapDocument<T>({
    required DocumentSnapshot snapshot,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null) return null;
    return fromJson(data as Map<String, dynamic>);
  }

  /// Maps a list of DocumentSnapshots to a list of domain models.
  /// Filters out non-existent documents.
  static List<T> mapDocumentList<T>({
    required List<DocumentSnapshot> snapshots,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    return snapshots
        .where((doc) => doc.exists)
        .map((doc) => fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Safely extracts a field from a Map with a default value.
  static T getFieldOrDefault<T>({
    required Map<String, dynamic> map,
    required String key,
    required T defaultValue,
  }) {
    return map[key] as T? ?? defaultValue;
  }

  /// Safely extracts a nullable field from a Map.
  static T? getFieldOrNull<T>({
    required Map<String, dynamic> map,
    required String key,
  }) {
    return map[key] as T?;
  }
}
