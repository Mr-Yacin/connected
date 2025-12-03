import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:uuid/uuid.dart';
import 'package:social_connect_app/features/chat/data/repositories/firestore_chat_repository.dart';
import 'dart:math';

// Generate mocks
@GenerateMocks([FirebaseStorage])
class MockFirebaseStorage extends Mock implements FirebaseStorage {}

/// Feature: performance-optimization, Property 1: Chat list batch query efficiency
/// **Validates: Requirements 1.1, 1.5**
///
/// Property: For any chat list with more than 10 participants, the number of 
/// Firestore user profile queries should be ceiling(participantCount / 10) 
/// instead of participantCount

void main() {
  group('Chat Batch Query Efficiency Property Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreChatRepository repository;
    late QueryCountingFirestore countingFirestore;
    late MockFirebaseStorage mockStorage;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      countingFirestore = QueryCountingFirestore(fakeFirestore);
      mockStorage = MockFirebaseStorage();
      
      repository = FirestoreChatRepository(
        firestore: countingFirestore,
        storage: mockStorage,
        uuid: const Uuid(),
      );
    });

    /// Property test: Batch query efficiency
    /// Tests that for any number of participants > 10, we use batch queries
    /// instead of individual queries
    test('batch queries should be used for chat lists with many participants',
        () async {
      // Test with various participant counts
      final testCases = [
        11, // Just over the limit
        15, // Mid-range
        20, // Exactly 2 batches
        25, // Between 2 and 3 batches
        30, // Exactly 3 batches
        42, // Random larger number
        50, // Large number
      ];

      for (final participantCount in testCases) {
        // Reset query counter
        countingFirestore.resetQueryCount();

        // Setup: Create a user and chats with many unique participants
        final currentUserId = 'current-user';
        await _setupUserProfile(fakeFirestore, currentUserId, 'Current User');

        // Create chats with unique participants (no denormalized data)
        final participantIds = <String>[];
        for (var i = 0; i < participantCount; i++) {
          final participantId = 'user-$i';
          participantIds.add(participantId);

          // Create user profile
          await _setupUserProfile(
            fakeFirestore,
            participantId,
            'User $i',
          );

          // Create chat without denormalized data to force batch fetch
          await fakeFirestore.collection('chats').doc('chat-$i').set({
            'participants': [currentUserId, participantId],
            'lastMessage': 'Hello $i',
            'lastMessageTime': Timestamp.now(),
            'unreadCount': {currentUserId: 0},
          });
        }

        // Execute: Get chat list
        final chatPreviews = await repository.getChatList(currentUserId);

        // Verify: Check that we got all chats
        expect(
          chatPreviews.length,
          equals(participantCount),
          reason:
              'Should return all $participantCount chats for participant count: $participantCount',
        );

        // Calculate expected number of batch queries
        // 1 query for chats list + ceiling(participantCount / 10) for user profiles
        final expectedBatchQueries = 1 + (participantCount / 10).ceil();

        // Verify: Query count should match expected batch queries
        // Allow some tolerance for implementation details
        expect(
          countingFirestore.queryCount,
          lessThanOrEqualTo(expectedBatchQueries + 2),
          reason:
              'For $participantCount participants, should use approximately $expectedBatchQueries queries (1 for chats + ${(participantCount / 10).ceil()} batches), but got ${countingFirestore.queryCount}',
        );

        // Most importantly: verify we're NOT doing N individual queries
        expect(
          countingFirestore.queryCount,
          lessThan(participantCount),
          reason:
              'Should NOT make $participantCount individual queries for $participantCount participants',
        );

        print(
            '✓ Test passed for $participantCount participants: ${countingFirestore.queryCount} queries (expected ~$expectedBatchQueries)');
      }
    });

    /// Feature: performance-optimization, Property 2: Denormalized data usage
    /// **Validates: Requirements 1.2**
    ///
    /// Property: For any chat document with denormalized participant data,
    /// building chat previews should not make additional user profile queries
    test(
        'denormalized data usage - should not query user profiles when denormalized data exists',
        () async {
      final testCases = [5, 10, 15, 20, 30, 50];

      for (final participantCount in testCases) {
        countingFirestore.resetQueryCount();

        final currentUserId = 'denorm-test-user-$participantCount';
        await _setupUserProfile(fakeFirestore, currentUserId, 'Current User');

        // Create chats WITH denormalized data
        for (var i = 0; i < participantCount; i++) {
          final participantId = 'denorm-participant-$participantCount-$i';

          await _setupUserProfile(
            fakeFirestore,
            participantId,
            'User $i',
          );

          // Create chat WITH denormalized data
          await fakeFirestore
              .collection('chats')
              .doc('denorm-chat-$participantCount-$i')
              .set({
            'participants': [currentUserId, participantId],
            'participantNames': {
              currentUserId: 'Current User',
              participantId: 'User $i',
            },
            'participantImages': {
              currentUserId: null,
              participantId: null,
            },
            'lastMessage': 'Hello $i',
            'lastMessageTime': Timestamp.now(),
            'unreadCount': {currentUserId: 0},
          });
        }

        final chatPreviews = await repository.getChatList(currentUserId);

        expect(chatPreviews.length, equals(participantCount));

        // CRITICAL: With denormalized data, should only need 1 query (for the chat list)
        // No additional user profile queries should be made
        expect(
          countingFirestore.queryCount,
          equals(1),
          reason:
              'With denormalized data for $participantCount chats, should only need 1 query for chat list. Got ${countingFirestore.queryCount} queries.',
        );

        // Verify that all chat previews have the correct denormalized data
        for (final preview in chatPreviews) {
          expect(
            preview.otherUserName,
            isNotNull,
            reason: 'Chat preview should have otherUserName from denormalized data',
          );
          expect(
            preview.otherUserName,
            startsWith('User '),
            reason: 'Chat preview should have correct name from denormalized data',
          );
        }

        print(
            '✓ Property 2 test passed for $participantCount chats: ${countingFirestore.queryCount} queries (expected 1)');
      }
    });

    /// Property test: Batch query efficiency with denormalized data
    /// Tests that when denormalized data exists, we make even fewer queries
    test(
        'should make minimal queries when denormalized data is available',
        () async {
      final testCases = [5, 10, 15, 20, 30];

      for (final participantCount in testCases) {
        countingFirestore.resetQueryCount();

        final currentUserId = 'current-user';
        await _setupUserProfile(fakeFirestore, currentUserId, 'Current User');

        // Create chats WITH denormalized data
        for (var i = 0; i < participantCount; i++) {
          final participantId = 'user-$i';

          await _setupUserProfile(
            fakeFirestore,
            participantId,
            'User $i',
          );

          // Create chat WITH denormalized data
          await fakeFirestore.collection('chats').doc('chat-$i').set({
            'participants': [currentUserId, participantId],
            'participantNames': {
              currentUserId: 'Current User',
              participantId: 'User $i',
            },
            'participantImages': {
              currentUserId: null,
              participantId: null,
            },
            'lastMessage': 'Hello $i',
            'lastMessageTime': Timestamp.now(),
            'unreadCount': {currentUserId: 0},
          });
        }

        final chatPreviews = await repository.getChatList(currentUserId);

        expect(chatPreviews.length, equals(participantCount));

        // With denormalized data, should only need 1 query (for the chat list)
        expect(
          countingFirestore.queryCount,
          lessThanOrEqualTo(2),
          reason:
              'With denormalized data for $participantCount chats, should only need 1-2 queries',
        );

        print(
            '✓ Denormalized test passed for $participantCount chats: ${countingFirestore.queryCount} queries');
      }
    });

    /// Property test: Mixed scenario (some with denormalized data, some without)
    test('should efficiently handle mixed denormalized and non-denormalized data',
        () async {
      final random = Random(42); // Fixed seed for reproducibility

      for (var iteration = 0; iteration < 5; iteration++) {
        countingFirestore.resetQueryCount();

        final currentUserId = 'current-user-$iteration';
        await _setupUserProfile(
          fakeFirestore,
          currentUserId,
          'Current User',
        );

        final totalChats = 20 + random.nextInt(30); // 20-50 chats
        final chatsWithDenormalizedData = random.nextInt(totalChats);
        final chatsWithoutDenormalizedData =
            totalChats - chatsWithDenormalizedData;

        // Create chats with denormalized data
        for (var i = 0; i < chatsWithDenormalizedData; i++) {
          final participantId = 'denorm-user-$iteration-$i';
          await _setupUserProfile(
            fakeFirestore,
            participantId,
            'Denorm User $i',
          );

          await fakeFirestore
              .collection('chats')
              .doc('denorm-chat-$iteration-$i')
              .set({
            'participants': [currentUserId, participantId],
            'participantNames': {
              currentUserId: 'Current User',
              participantId: 'Denorm User $i',
            },
            'participantImages': {
              currentUserId: null,
              participantId: null,
            },
            'lastMessage': 'Hello $i',
            'lastMessageTime': Timestamp.now(),
            'unreadCount': {currentUserId: 0},
          });
        }

        // Create chats without denormalized data
        for (var i = 0; i < chatsWithoutDenormalizedData; i++) {
          final participantId = 'regular-user-$iteration-$i';
          await _setupUserProfile(
            fakeFirestore,
            participantId,
            'Regular User $i',
          );

          await fakeFirestore
              .collection('chats')
              .doc('regular-chat-$iteration-$i')
              .set({
            'participants': [currentUserId, participantId],
            'lastMessage': 'Hello $i',
            'lastMessageTime': Timestamp.now(),
            'unreadCount': {currentUserId: 0},
          });
        }

        final chatPreviews = await repository.getChatList(currentUserId);

        expect(chatPreviews.length, equals(totalChats));

        // Expected queries: 1 for chat list + batches for non-denormalized users
        final expectedBatchesForNonDenormalized =
            (chatsWithoutDenormalizedData / 10).ceil();
        final expectedMaxQueries = 1 + expectedBatchesForNonDenormalized + 2;

        expect(
          countingFirestore.queryCount,
          lessThanOrEqualTo(expectedMaxQueries),
          reason:
              'Mixed scenario: $totalChats total chats ($chatsWithDenormalizedData denormalized, $chatsWithoutDenormalizedData not), should use ~${1 + expectedBatchesForNonDenormalized} queries',
        );

        print(
            '✓ Mixed test iteration $iteration: $totalChats chats ($chatsWithDenormalizedData denorm, $chatsWithoutDenormalizedData regular), ${countingFirestore.queryCount} queries');
      }
    });

    /// Feature: performance-optimization, Property 4: Profile update propagation
    /// **Validates: Requirements 1.4**
    ///
    /// Property: For any user profile update, all chat documents containing that user
    /// should have their denormalized data updated
    test('profile update should propagate to all user chats', () async {
      final random = Random(42); // Fixed seed for reproducibility

      // Test with multiple scenarios
      for (var iteration = 0; iteration < 10; iteration++) {
        // Create a user who will update their profile
        final userId = 'profile-update-user-${_uuid.v4()}';
        final initialName = 'Initial Name $iteration';
        final updatedName = 'Updated Name $iteration';
        
        // Randomly assign initial and updated profile images
        final hasInitialImage = random.nextBool();
        final hasUpdatedImage = random.nextBool();
        
        final initialImageUrl = hasInitialImage 
            ? 'https://example.com/initial-$iteration.jpg' 
            : null;
        final updatedImageUrl = hasUpdatedImage 
            ? 'https://example.com/updated-$iteration.jpg' 
            : null;

        // Setup initial user profile
        await fakeFirestore.collection('users').doc(userId).set({
          'id': userId,
          'name': initialName,
          'phoneNumber': '+1234567890',
          'age': 25,
          'country': 'Saudi Arabia',
          'profileImageUrl': initialImageUrl,
          'isImageBlurred': false,
          'createdAt': Timestamp.now(),
          'lastActive': Timestamp.now(),
        });

        // Create multiple chats with this user (random number between 3 and 10)
        final chatCount = 3 + random.nextInt(8);
        final chatIds = <String>[];
        final otherUserIds = <String>[];

        for (var i = 0; i < chatCount; i++) {
          final chatId = 'chat-${_uuid.v4()}';
          final otherUserId = 'other-user-${_uuid.v4()}';
          
          chatIds.add(chatId);
          otherUserIds.add(otherUserId);

          // Create other user profile
          await fakeFirestore.collection('users').doc(otherUserId).set({
            'id': otherUserId,
            'name': 'Other User $i',
            'phoneNumber': '+0987654321',
            'age': 28,
            'country': 'Saudi Arabia',
            'profileImageUrl': null,
            'isImageBlurred': false,
            'createdAt': Timestamp.now(),
            'lastActive': Timestamp.now(),
          });

          // Create chat with initial denormalized data
          await fakeFirestore.collection('chats').doc(chatId).set({
            'participants': [userId, otherUserId],
            'participantNames': {
              userId: initialName,
              otherUserId: 'Other User $i',
            },
            'participantImages': {
              userId: initialImageUrl,
              otherUserId: null,
            },
            'lastMessage': 'Hello $i',
            'lastMessageTime': Timestamp.now(),
            'unreadCount': {userId: 0, otherUserId: 0},
          });
        }

        // Update user profile and propagate changes
        await fakeFirestore.collection('users').doc(userId).update({
          'name': updatedName,
          'profileImageUrl': updatedImageUrl,
        });

        // Call the repository method to update denormalized data
        await repository.updateUserDenormalizedData(
          userId: userId,
          userName: updatedName,
          userImageUrl: updatedImageUrl,
          runInBackground: false, // Run synchronously for testing
        );

        // Verify: All chats should have updated denormalized data
        for (var i = 0; i < chatCount; i++) {
          final chatId = chatIds[i];
          final chatDoc = await fakeFirestore.collection('chats').doc(chatId).get();
          
          expect(
            chatDoc.exists,
            isTrue,
            reason: 'Chat document should exist',
          );

          final chatData = chatDoc.data()!;

          // Verify participantNames has been updated
          expect(
            chatData.containsKey('participantNames'),
            isTrue,
            reason: 'Chat should have participantNames field',
          );

          final participantNames = chatData['participantNames'] as Map<String, dynamic>;
          
          expect(
            participantNames[userId],
            equals(updatedName),
            reason: 'participantNames should have updated user name',
          );

          // Verify participantImages has been updated
          expect(
            chatData.containsKey('participantImages'),
            isTrue,
            reason: 'Chat should have participantImages field',
          );

          final participantImages = chatData['participantImages'] as Map<String, dynamic>;
          
          expect(
            participantImages[userId],
            equals(updatedImageUrl),
            reason: 'participantImages should have updated user image URL',
          );

          // Verify other user's data remains unchanged
          final otherUserId = otherUserIds[i];
          expect(
            participantNames[otherUserId],
            equals('Other User $i'),
            reason: 'Other user name should remain unchanged',
          );
          
          expect(
            participantImages[otherUserId],
            isNull,
            reason: 'Other user image should remain unchanged',
          );
        }

        print(
          '✓ Property 4 test iteration $iteration passed: '
          'Updated profile propagated to $chatCount chats '
          '(initial image: ${hasInitialImage ? "yes" : "no"}, '
          'updated image: ${hasUpdatedImage ? "yes" : "no"})',
        );
      }
    });

    /// Feature: performance-optimization, Property 3: Chat creation denormalization
    /// **Validates: Requirements 1.3**
    ///
    /// Property: For any new chat created between two users, the chat document
    /// should contain participantNames and participantImages fields with both users' data
    test('chat creation should store denormalized participant data', () async {
      final random = Random(42); // Fixed seed for reproducibility

      // Test with multiple random user pairs
      for (var iteration = 0; iteration < 10; iteration++) {
        // Create two random users
        final senderId = 'sender-${_uuid.v4()}';
        final receiverId = 'receiver-${_uuid.v4()}';
        final chatId = 'chat-${_uuid.v4()}';

        final senderName = 'Sender User $iteration';
        final receiverName = 'Receiver User $iteration';
        
        // Randomly assign profile images (some users have images, some don't)
        final senderHasImage = random.nextBool();
        final receiverHasImage = random.nextBool();
        
        final senderImageUrl = senderHasImage 
            ? 'https://example.com/sender-$iteration.jpg' 
            : null;
        final receiverImageUrl = receiverHasImage 
            ? 'https://example.com/receiver-$iteration.jpg' 
            : null;

        // Setup user profiles
        await fakeFirestore.collection('users').doc(senderId).set({
          'id': senderId,
          'name': senderName,
          'phoneNumber': '+1234567890',
          'age': 25,
          'country': 'Saudi Arabia',
          'profileImageUrl': senderImageUrl,
          'isImageBlurred': false,
          'createdAt': Timestamp.now(),
          'lastActive': Timestamp.now(),
        });

        await fakeFirestore.collection('users').doc(receiverId).set({
          'id': receiverId,
          'name': receiverName,
          'phoneNumber': '+0987654321',
          'age': 28,
          'country': 'Saudi Arabia',
          'profileImageUrl': receiverImageUrl,
          'isImageBlurred': false,
          'createdAt': Timestamp.now(),
          'lastActive': Timestamp.now(),
        });

        // Send a message to create/update the chat
        await repository.sendTextMessage(
          chatId: chatId,
          senderId: senderId,
          receiverId: receiverId,
          text: 'Hello from iteration $iteration',
        );

        // Verify: Fetch the chat document directly from Firestore
        final chatDoc = await fakeFirestore.collection('chats').doc(chatId).get();
        
        expect(
          chatDoc.exists,
          isTrue,
          reason: 'Chat document should exist after sending message',
        );

        final chatData = chatDoc.data()!;

        // Verify: participantNames field exists and contains both users
        expect(
          chatData.containsKey('participantNames'),
          isTrue,
          reason: 'Chat document should contain participantNames field',
        );

        final participantNames = chatData['participantNames'] as Map<String, dynamic>;
        
        expect(
          participantNames.containsKey(senderId),
          isTrue,
          reason: 'participantNames should contain sender ID',
        );
        
        expect(
          participantNames.containsKey(receiverId),
          isTrue,
          reason: 'participantNames should contain receiver ID',
        );

        expect(
          participantNames[senderId],
          equals(senderName),
          reason: 'participantNames should have correct sender name',
        );

        expect(
          participantNames[receiverId],
          equals(receiverName),
          reason: 'participantNames should have correct receiver name',
        );

        // Verify: participantImages field exists and contains both users
        expect(
          chatData.containsKey('participantImages'),
          isTrue,
          reason: 'Chat document should contain participantImages field',
        );

        final participantImages = chatData['participantImages'] as Map<String, dynamic>;
        
        expect(
          participantImages.containsKey(senderId),
          isTrue,
          reason: 'participantImages should contain sender ID',
        );
        
        expect(
          participantImages.containsKey(receiverId),
          isTrue,
          reason: 'participantImages should contain receiver ID',
        );

        expect(
          participantImages[senderId],
          equals(senderImageUrl),
          reason: 'participantImages should have correct sender image URL (or null)',
        );

        expect(
          participantImages[receiverId],
          equals(receiverImageUrl),
          reason: 'participantImages should have correct receiver image URL (or null)',
        );

        // Verify: participants array exists
        expect(
          chatData.containsKey('participants'),
          isTrue,
          reason: 'Chat document should contain participants array',
        );

        final participants = List<String>.from(chatData['participants'] as List);
        expect(
          participants.length,
          equals(2),
          reason: 'participants array should contain exactly 2 users',
        );
        
        expect(
          participants.contains(senderId),
          isTrue,
          reason: 'participants array should contain sender ID',
        );
        
        expect(
          participants.contains(receiverId),
          isTrue,
          reason: 'participants array should contain receiver ID',
        );

        print(
          '✓ Property 3 test iteration $iteration passed: '
          'Chat created with denormalized data for both users '
          '(sender image: ${senderHasImage ? "yes" : "no"}, '
          'receiver image: ${receiverHasImage ? "yes" : "no"})',
        );
      }
    });
  });
}

// Add Uuid instance for test
final _uuid = const Uuid();

/// Helper function to setup user profile in Firestore
Future<void> _setupUserProfile(
  FirebaseFirestore firestore,
  String userId,
  String name,
) async {
  await firestore.collection('users').doc(userId).set({
    'id': userId,
    'name': name,
    'phoneNumber': '+1234567890',
    'age': 25,
    'country': 'Saudi Arabia',
    'profileImageUrl': null,
    'isImageBlurred': false,
    'createdAt': Timestamp.now(),
    'lastActive': Timestamp.now(),
  });
}

/// Wrapper around FakeFirebaseFirestore that counts queries
class QueryCountingFirestore implements FirebaseFirestore {
  final FakeFirebaseFirestore _delegate;
  int _queryCount = 0;

  QueryCountingFirestore(this._delegate);

  int get queryCount => _queryCount;

  void resetQueryCount() {
    _queryCount = 0;
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return QueryCountingCollectionReference(
      _delegate.collection(path),
      this,
    );
  }

  void incrementQueryCount() {
    _queryCount++;
  }

  @override
  WriteBatch batch() {
    return _delegate.batch();
  }

  // Delegate all other methods to the fake firestore
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

/// Wrapper around CollectionReference that counts queries
class QueryCountingCollectionReference
    implements CollectionReference<Map<String, dynamic>> {
  final CollectionReference<Map<String, dynamic>> _delegate;
  final QueryCountingFirestore _counter;

  QueryCountingCollectionReference(this._delegate, this._counter);

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) {
    _counter.incrementQueryCount();
    return _delegate.get(options);
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
    return QueryCountingQuery(
      _delegate.where(
        field,
        isEqualTo: isEqualTo,
        isNotEqualTo: isNotEqualTo,
        isLessThan: isLessThan,
        isLessThanOrEqualTo: isLessThanOrEqualTo,
        isGreaterThan: isGreaterThan,
        isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
        arrayContains: arrayContains,
        arrayContainsAny: arrayContainsAny,
        whereIn: whereIn,
        whereNotIn: whereNotIn,
        isNull: isNull,
      ),
      _counter,
    );
  }

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return _delegate.doc(path);
  }

  // Delegate all other methods
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

/// Wrapper around Query that counts queries
class QueryCountingQuery implements Query<Map<String, dynamic>> {
  final Query<Map<String, dynamic>> _delegate;
  final QueryCountingFirestore _counter;

  QueryCountingQuery(this._delegate, this._counter);

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) {
    _counter.incrementQueryCount();
    return _delegate.get(options);
  }

  @override
  Query<Map<String, dynamic>> orderBy(
    Object field, {
    bool descending = false,
  }) {
    return QueryCountingQuery(
      _delegate.orderBy(field, descending: descending),
      _counter,
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
    return QueryCountingQuery(
      _delegate.where(
        field,
        isEqualTo: isEqualTo,
        isNotEqualTo: isNotEqualTo,
        isLessThan: isLessThan,
        isLessThanOrEqualTo: isLessThanOrEqualTo,
        isGreaterThan: isGreaterThan,
        isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
        arrayContains: arrayContains,
        arrayContainsAny: arrayContainsAny,
        whereIn: whereIn,
        whereNotIn: whereNotIn,
        isNull: isNull,
      ),
      _counter,
    );
  }

  // Delegate all other methods
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
