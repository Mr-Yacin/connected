import 'package:cloud_firestore/cloud_firestore.dart';
import '../exceptions/app_exceptions.dart';
import '../../services/error_logging_service.dart';

/// Base repository class that provides common error handling for Firestore operations.
/// All repository classes should extend this to avoid code duplication.
abstract class BaseFirestoreRepository {
  /// Handles Firestore operations with standardized error handling and logging.
  /// 
  /// Type parameter [T] is the return type of the operation.
  /// 
  /// Parameters:
  /// - [operation]: The async operation to execute
  /// - [operationName]: Name of the operation for logging (e.g., 'fetch user profile')
  /// - [screen]: Screen/feature name where operation is called
  /// - [arabicErrorMessage]: Error message in Arabic to show to users
  /// - [collection]: Optional Firestore collection name for logging
  /// - [documentId]: Optional document ID for logging
  Future<T> handleFirestoreOperation<T>({
    required Future<T> Function() operation,
    required String operationName,
    required String screen,
    required String arabicErrorMessage,
    String? collection,
    String? documentId,
  }) async {
    try {
      return await operation();
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to $operationName',
        screen: screen,
        operation: operationName,
        collection: collection,
        documentId: documentId,
      );
      throw AppException('$arabicErrorMessage: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error during $operationName',
        screen: screen,
        operation: operationName,
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  /// Handles Firestore operations that return void with standardized error handling.
  Future<void> handleFirestoreVoidOperation({
    required Future<void> Function() operation,
    required String operationName,
    required String screen,
    required String arabicErrorMessage,
    String? collection,
    String? documentId,
  }) async {
    await handleFirestoreOperation<void>(
      operation: operation,
      operationName: operationName,
      screen: screen,
      arabicErrorMessage: arabicErrorMessage,
      collection: collection,
      documentId: documentId,
    );
  }

  /// Maps Firestore QuerySnapshot to a list of domain models.
  /// 
  /// Parameters:
  /// - [snapshot]: The QuerySnapshot from Firestore
  /// - [fromJson]: Function to convert Map to domain model
  List<T> mapQuerySnapshot<T>({
    required QuerySnapshot snapshot,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    return snapshot.docs
        .map((doc) => fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Maps Firestore DocumentSnapshot to a domain model.
  /// Returns null if document doesn't exist.
  /// 
  /// Parameters:
  /// - [snapshot]: The DocumentSnapshot from Firestore
  /// - [fromJson]: Function to convert Map to domain model
  T? mapDocumentSnapshot<T>({
    required DocumentSnapshot snapshot,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    if (!snapshot.exists) return null;
    return fromJson(snapshot.data() as Map<String, dynamic>);
  }
}
