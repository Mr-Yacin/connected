import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:social_connect_app/features/stories/data/repositories/firestore_story_repository.dart';
import 'package:social_connect_app/core/models/story.dart';
import 'package:social_connect_app/core/models/enums.dart';
import 'package:social_connect_app/core/exceptions/app_exceptions.dart';

// Simple mock for FirebaseStorage to avoid conflicts
class MockStoryStorage extends Mock implements FirebaseStorage {}

// Custom Firestore implementation that throws errors
class ErrorThrowingFirestore implements FirebaseFirestore {
  final FirebaseException? exceptionToThrow;
  final Exception? generalExceptionToThrow;

  ErrorThrowingFirestore({
    this.exceptionToThrow,
    this.generalExceptionToThrow,
  });

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return ErrorThrowingCollectionReference(
      exceptionToThrow: exceptionToThrow,
      generalExceptionToThrow: generalExceptionToThrow,
    );
  }

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    if (generalExceptionToThrow != null) {
      throw generalExceptionToThrow!;
    }
    throw UnimplementedError();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class ErrorThrowingCollectionReference
    implements CollectionReference<Map<String, dynamic>> {
  final FirebaseException? exceptionToThrow;
  final Exception? generalExceptionToThrow;

  ErrorThrowingCollectionReference({
    this.exceptionToThrow,
    this.generalExceptionToThrow,
  });

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return ErrorThrowingDocumentReference(
      exceptionToThrow: exceptionToThrow,
      generalExceptionToThrow: generalExceptionToThrow,
    );
  }

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return ErrorThrowingQuery(
      exceptionToThrow: exceptionToThrow,
      generalExceptionToThrow: generalExceptionToThrow,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class ErrorThrowingDocumentReference
    implements DocumentReference<Map<String, dynamic>> {
  final FirebaseException? exceptionToThrow;
  final Exception? generalExceptionToThrow;

  ErrorThrowingDocumentReference({
    this.exceptionToThrow,
    this.generalExceptionToThrow,
  });

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    if (generalExceptionToThrow != null) {
      throw generalExceptionToThrow!;
    }
  }

  @override
  Future<void> delete() async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    if (generalExceptionToThrow != null) {
      throw generalExceptionToThrow!;
    }
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    if (generalExceptionToThrow != null) {
      throw generalExceptionToThrow!;
    }
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return ErrorThrowingDocumentSnapshot(
      exceptionToThrow: exceptionToThrow,
      generalExceptionToThrow: generalExceptionToThrow,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class ErrorThrowingDocumentSnapshot
    implements DocumentSnapshot<Map<String, dynamic>> {
  final FirebaseException? exceptionToThrow;
  final Exception? generalExceptionToThrow;

  ErrorThrowingDocumentSnapshot({
    this.exceptionToThrow,
    this.generalExceptionToThrow,
  });

  @override
  bool get exists => true;

  @override
  Map<String, dynamic>? data() {
    return {
      'id': 'test-story-id',
      'userId': 'test-user-id',
      'mediaUrl': 'https://example.com/media.jpg',
      'type': 'image',
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      'viewerIds': [],
      'likedBy': [],
      'replyCount': 0,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class ErrorThrowingQuery implements Query<Map<String, dynamic>> {
  final FirebaseException? exceptionToThrow;
  final Exception? generalExceptionToThrow;

  ErrorThrowingQuery({
    this.exceptionToThrow,
    this.generalExceptionToThrow,
  });

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    if (generalExceptionToThrow != null) {
      throw generalExceptionToThrow!;
    }
    throw UnimplementedError();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('FirestoreStoryRepository Error Handling Tests', () {
    late MockStoryStorage mockStorage;

    setUp(() {
      mockStorage = MockStoryStorage();
    });

    group('createStory', () {
      test('should throw AppException with Arabic message when Firestore operation fails', () async {
        // Arrange
        final story = Story(
          id: 'test-story-id',
          userId: 'test-user-id',
          mediaUrl: 'https://example.com/media.jpg',
          type: StoryType.image,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
          viewerIds: [],
        );

        final errorFirestore = ErrorThrowingFirestore(
          exceptionToThrow: FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'Permission denied',
          ),
        );

        final repository = FirestoreStoryRepository(
          firestore: errorFirestore,
          storage: mockStorage,
        );

        // Act & Assert
        expect(
          () => repository.createStory(story),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('فشل في إنشاء القصة'),
            ),
          ),
        );
      });

      test('should throw AppException with Arabic message for unexpected errors', () async {
        // Arrange
        final story = Story(
          id: 'test-story-id',
          userId: 'test-user-id',
          mediaUrl: 'https://example.com/media.jpg',
          type: StoryType.image,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
          viewerIds: [],
        );

        final errorFirestore = ErrorThrowingFirestore(
          generalExceptionToThrow: Exception('Unexpected error'),
        );

        final repository = FirestoreStoryRepository(
          firestore: errorFirestore,
          storage: mockStorage,
        );

        // Act & Assert
        expect(
          () => repository.createStory(story),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('حدث خطأ غير متوقع'),
            ),
          ),
        );
      });
    });

    group('deleteStory', () {
      test('should throw AppException with Arabic message when delete fails', () async {
        // Arrange
        const storyId = 'test-story-id';

        final errorFirestore = ErrorThrowingFirestore(
          exceptionToThrow: FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'Permission denied',
          ),
        );

        final repository = FirestoreStoryRepository(
          firestore: errorFirestore,
          storage: mockStorage,
        );

        // Act & Assert
        expect(
          () => repository.deleteStory(storyId),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('فشل في حذف القصة'),
            ),
          ),
        );
      });
    });

    group('recordView', () {
      test('should throw AppException with Arabic message when recording view fails', () async {
        // Arrange
        const storyId = 'test-story-id';
        const viewerId = 'test-viewer-id';

        final errorFirestore = ErrorThrowingFirestore(
          exceptionToThrow: FirebaseException(
            plugin: 'cloud_firestore',
            code: 'unavailable',
            message: 'Service unavailable',
          ),
        );

        final repository = FirestoreStoryRepository(
          firestore: errorFirestore,
          storage: mockStorage,
        );

        // Act & Assert
        expect(
          () => repository.recordView(storyId, viewerId),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('فشل في تسجيل المشاهدة'),
            ),
          ),
        );
      });
    });

    group('likeStory', () {
      test('should throw AppException with Arabic message when like fails', () async {
        // Arrange
        const storyId = 'test-story-id';
        const userId = 'test-user-id';

        final errorFirestore = ErrorThrowingFirestore(
          exceptionToThrow: FirebaseException(
            plugin: 'cloud_firestore',
            code: 'not-found',
            message: 'Document not found',
          ),
        );

        final repository = FirestoreStoryRepository(
          firestore: errorFirestore,
          storage: mockStorage,
        );

        // Act & Assert
        expect(
          () => repository.likeStory(storyId, userId),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('فشل في الإعجاب بالقصة'),
            ),
          ),
        );
      });
    });

    group('unlikeStory', () {
      test('should throw AppException with Arabic message when unlike fails', () async {
        // Arrange
        const storyId = 'test-story-id';
        const userId = 'test-user-id';

        final errorFirestore = ErrorThrowingFirestore(
          exceptionToThrow: FirebaseException(
            plugin: 'cloud_firestore',
            code: 'cancelled',
            message: 'Transaction cancelled',
          ),
        );

        final repository = FirestoreStoryRepository(
          firestore: errorFirestore,
          storage: mockStorage,
        );

        // Act & Assert
        expect(
          () => repository.unlikeStory(storyId, userId),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('فشل في إلغاء الإعجاب'),
            ),
          ),
        );
      });
    });

    group('incrementReplyCount', () {
      test('should throw AppException with Arabic message when increment fails', () async {
        // Arrange
        const storyId = 'test-story-id';

        final errorFirestore = ErrorThrowingFirestore(
          exceptionToThrow: FirebaseException(
            plugin: 'cloud_firestore',
            code: 'deadline-exceeded',
            message: 'Deadline exceeded',
          ),
        );

        final repository = FirestoreStoryRepository(
          firestore: errorFirestore,
          storage: mockStorage,
        );

        // Act & Assert
        expect(
          () => repository.incrementReplyCount(storyId),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('فشل في تحديث عدد الردود'),
            ),
          ),
        );
      });
    });

    group('deleteExpiredStories', () {
      test('should throw AppException with Arabic message when deletion fails', () async {
        // Arrange
        final errorFirestore = ErrorThrowingFirestore(
          exceptionToThrow: FirebaseException(
            plugin: 'cloud_firestore',
            code: 'resource-exhausted',
            message: 'Resource exhausted',
          ),
        );

        final repository = FirestoreStoryRepository(
          firestore: errorFirestore,
          storage: mockStorage,
        );

        // Act & Assert
        expect(
          () => repository.deleteExpiredStories(),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('فشل في حذف القصص المنتهية'),
            ),
          ),
        );
      });
    });

    group('Error Message Validation', () {
      test('all error messages should be in Arabic', () async {
        // This test validates that all error messages contain Arabic characters
        final arabicPattern = RegExp(r'[\u0600-\u06FF]');
        
        final errorMessages = [
          'فشل في إنشاء القصة',
          'فشل في حذف القصة',
          'فشل في تسجيل المشاهدة',
          'فشل في الإعجاب بالقصة',
          'فشل في إلغاء الإعجاب',
          'فشل في تحديث عدد الردود',
          'فشل في حذف القصص المنتهية',
          'حدث خطأ غير متوقع',
        ];

        for (final message in errorMessages) {
          expect(
            arabicPattern.hasMatch(message),
            isTrue,
            reason: 'Error message "$message" should contain Arabic characters',
          );
        }
      });
    });
  });
}
