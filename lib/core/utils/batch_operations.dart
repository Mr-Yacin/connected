import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class for managing Firestore batch operations.
/// 
/// Provides standardized patterns for atomic operations and reduces code duplication.
class BatchOperations {
  final FirebaseFirestore _firestore;

  BatchOperations({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Execute a batch operation with automatic commit
  /// 
  /// Example:
  /// ```dart
  /// await BatchOperations().executeBatch((batch) {
  ///   batch.set(docRef, data);
  ///   batch.update(anotherRef, updates);
  /// });
  /// ```
  Future<void> executeBatch(
    void Function(WriteBatch batch) operations,
  ) async {
    final batch = _firestore.batch();
    operations(batch);
    await batch.commit();
  }

  /// Execute multiple document operations atomically
  /// 
  /// Useful for operations like bulk updates or deletions
  Future<void> executeMultipleOperations(
    List<void Function(WriteBatch batch)> operations,
  ) async {
    final batch = _firestore.batch();
    for (final operation in operations) {
      operation(batch);
    }
    await batch.commit();
  }

  /// Batch set multiple documents
  Future<void> batchSet(
    Map<DocumentReference, Map<String, dynamic>> documents, {
    SetOptions? options,
  }) async {
    final batch = _firestore.batch();
    documents.forEach((docRef, data) {
      if (options != null) {
        batch.set(docRef, data, options);
      } else {
        batch.set(docRef, data);
      }
    });
    await batch.commit();
  }

  /// Batch update multiple documents
  Future<void> batchUpdate(
    Map<DocumentReference, Map<String, dynamic>> updates,
  ) async {
    final batch = _firestore.batch();
    updates.forEach((docRef, updateData) {
      batch.update(docRef, updateData);
    });
    await batch.commit();
  }

  /// Batch delete multiple documents
  Future<void> batchDelete(List<DocumentReference> documents) async {
    final batch = _firestore.batch();
    for (final docRef in documents) {
      batch.delete(docRef);
    }
    await batch.commit();
  }

  /// Increment/decrement multiple fields atomically
  /// 
  /// Example:
  /// ```dart
  /// await BatchOperations().batchIncrement({
  ///   userRef: {'likesCount': 1, 'viewsCount': 1},
  ///   profileRef: {'followersCount': -1},
  /// });
  /// ```
  Future<void> batchIncrement(
    Map<DocumentReference, Map<String, int>> increments,
  ) async {
    final batch = _firestore.batch();
    increments.forEach((docRef, fields) {
      final updates = <String, dynamic>{};
      fields.forEach((field, value) {
        updates[field] = FieldValue.increment(value);
      });
      batch.update(docRef, updates);
    });
    await batch.commit();
  }

  /// Batch operation with conditional updates
  /// 
  /// Checks conditions before applying updates (requires reading documents first)
  Future<void> batchConditionalUpdate({
    required Map<DocumentReference, Map<String, dynamic>> updates,
    required bool Function(DocumentSnapshot doc) condition,
  }) async {
    // Read all documents first
    final docs = await Future.wait(
      updates.keys.map((ref) => ref.get()),
    );

    final batch = _firestore.batch();
    for (var i = 0; i < docs.length; i++) {
      final doc = docs[i];
      final ref = updates.keys.elementAt(i);
      final updateData = updates[ref]!;

      if (condition(doc)) {
        batch.update(ref, updateData);
      }
    }

    await batch.commit();
  }

  /// Create or update documents in batch with merge
  Future<void> batchMerge(
    Map<DocumentReference, Map<String, dynamic>> documents,
  ) async {
    await batchSet(documents, options: SetOptions(merge: true));
  }

  /// Batch array union operations
  Future<void> batchArrayUnion(
    Map<DocumentReference, Map<String, List<dynamic>>> arrayUpdates,
  ) async {
    final batch = _firestore.batch();
    arrayUpdates.forEach((docRef, fields) {
      final updates = <String, dynamic>{};
      fields.forEach((field, values) {
        updates[field] = FieldValue.arrayUnion(values);
      });
      batch.update(docRef, updates);
    });
    await batch.commit();
  }

  /// Batch array remove operations
  Future<void> batchArrayRemove(
    Map<DocumentReference, Map<String, List<dynamic>>> arrayUpdates,
  ) async {
    final batch = _firestore.batch();
    arrayUpdates.forEach((docRef, fields) {
      final updates = <String, dynamic>{};
      fields.forEach((field, values) {
        updates[field] = FieldValue.arrayRemove(values);
      });
      batch.update(docRef, updates);
    });
    await batch.commit();
  }

  /// Helper to create batched operations from query results
  /// 
  /// Useful for bulk operations on query results
  Future<void> batchOperationFromQuery({
    required Query query,
    required void Function(WriteBatch batch, QueryDocumentSnapshot doc) operation,
    int batchSize = 500,
  }) async {
    final snapshot = await query.get();
    final docs = snapshot.docs;

    for (var i = 0; i < docs.length; i += batchSize) {
      final batch = _firestore.batch();
      final end = (i + batchSize < docs.length) ? i + batchSize : docs.length;

      for (var j = i; j < end; j++) {
        operation(batch, docs[j]);
      }

      await batch.commit();
    }
  }

  /// Safely increment a counter with bounds checking
  /// 
  /// Prevents negative counters and enforces maximum values
  Future<void> safeIncrement({
    required DocumentReference docRef,
    required String field,
    required int increment,
    int min = 0,
    int? max,
  }) async {
    final doc = await docRef.get();
    final currentValue = (doc.data() as Map<String, dynamic>?)?[field] as int? ?? 0;
    final newValue = currentValue + increment;

    if (newValue < min || (max != null && newValue > max)) {
      return; // Skip update if out of bounds
    }

    await docRef.update({field: FieldValue.increment(increment)});
  }

  /// Batch safe increment operations
  Future<void> batchSafeIncrement(
    Map<DocumentReference, Map<String, int>> increments, {
    int min = 0,
    int? max,
  }) async {
    // Read all documents first to check current values
    final docs = await Future.wait(
      increments.keys.map((ref) => ref.get()),
    );

    final batch = _firestore.batch();
    for (var i = 0; i < docs.length; i++) {
      final doc = docs[i];
      final ref = increments.keys.elementAt(i);
      final fields = increments[ref]!;
      final data = doc.data() as Map<String, dynamic>?;

      final updates = <String, dynamic>{};
      fields.forEach((field, increment) {
        final currentValue = data?[field] as int? ?? 0;
        final newValue = currentValue + increment;

        // Only add to batch if within bounds
        if (newValue >= min && (max == null || newValue <= max)) {
          updates[field] = FieldValue.increment(increment);
        }
      });

      if (updates.isNotEmpty) {
        batch.update(ref, updates);
      }
    }

    await batch.commit();
  }
}
