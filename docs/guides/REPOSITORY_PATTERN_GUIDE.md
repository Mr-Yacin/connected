# Repository Pattern Guide

## Overview

This guide documents the repository pattern requirements for the Social Connect application. All data access code must follow these patterns to ensure consistency, testability, and maintainability.

## Table of Contents

1. [Core Principles](#core-principles)
2. [Repository Structure](#repository-structure)
3. [Implementation Requirements](#implementation-requirements)
4. [Testing Requirements](#testing-requirements)
5. [Compliance Verification](#compliance-verification)
6. [Examples](#examples)
7. [Common Mistakes](#common-mistakes)

## Core Principles

### 1. Separation of Concerns
- **Domain Layer**: Defines interfaces (contracts) without implementation details
- **Data Layer**: Implements interfaces with concrete data access logic
- **Presentation Layer**: Uses interfaces, never concrete implementations

### 2. Dependency Inversion
- High-level modules (domain) don't depend on low-level modules (data)
- Both depend on abstractions (interfaces)
- Enables dependency injection and testing

### 3. Consistent Error Handling
- All Firestore repositories extend `BaseFirestoreRepository`
- Standardized error logging and reporting
- User-friendly Arabic error messages

## Repository Structure

### Directory Layout

```
lib/features/{feature}/
├── domain/
│   └── repositories/
│       └── {feature}_repository.dart        # Abstract interface
├── data/
│   └── repositories/
│       └── firestore_{feature}_repository.dart  # Concrete implementation
└── presentation/
    └── providers/
        └── {feature}_providers.dart         # Provider definitions
```

### File Naming Conventions

- **Interface**: `{feature}_repository.dart` (e.g., `chat_repository.dart`)
- **Implementation**: `firestore_{feature}_repository.dart` or `firebase_{feature}_repository.dart`
- **Provider**: `{feature}_providers.dart`

## Implementation Requirements

### 1. All Repositories Must Have Interfaces

**Domain Interface** (`lib/features/chat/domain/repositories/chat_repository.dart`):

```dart
/// Repository interface for chat operations
abstract class ChatRepository {
  /// Get messages stream for real-time updates
  Stream<List<Message>> getMessages(String chatId);
  
  /// Send a text message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  });
  
  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId);
}
```

**Key Requirements**:
- ✅ Declared as `abstract class`
- ✅ Contains only method signatures (no implementation)
- ✅ No Firebase imports (cloud_firestore, firebase_storage, etc.)
- ✅ Comprehensive documentation for each method
- ✅ Located in `domain/repositories/` folder

### 2. All Firestore Repositories Must Extend BaseFirestoreRepository

**Data Implementation** (`lib/features/chat/data/repositories/firestore_chat_repository.dart`):

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/data/base_firestore_repository.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/repositories/chat_repository.dart';

/// Firestore implementation of ChatRepository
class FirestoreChatRepository extends BaseFirestoreRepository 
    implements ChatRepository {
  
  final FirebaseFirestore _firestore;
  
  FirestoreChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  @override
  Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromJson(doc.data()))
            .toList());
  }
  
  @override
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    return handleFirestoreVoidOperation(
      operation: () async {
        final message = Message(
          id: _firestore.collection('chats').doc().id,
          chatId: chatId,
          senderId: senderId,
          text: text,
          timestamp: DateTime.now(),
        );
        
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(message.id)
            .set(message.toJson());
      },
      operationName: 'sendMessage',
      screen: 'ChatScreen',
      arabicErrorMessage: 'فشل في إرسال الرسالة',
      collection: 'chats/$chatId/messages',
    );
  }
  
  @override
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    return handleFirestoreVoidOperation(
      operation: () async {
        final batch = _firestore.batch();
        final snapshot = await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('senderId', isNotEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();
        
        for (final doc in snapshot.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        
        await batch.commit();
      },
      operationName: 'markMessagesAsRead',
      screen: 'ChatScreen',
      arabicErrorMessage: 'فشل في تحديث حالة الرسائل',
      collection: 'chats/$chatId/messages',
    );
  }
}
```

**Key Requirements**:
- ✅ Extends `BaseFirestoreRepository`
- ✅ Implements the domain interface
- ✅ Uses `handleFirestoreOperation` for operations that return values
- ✅ Uses `handleFirestoreVoidOperation` for operations that return void
- ✅ Provides Arabic error messages
- ✅ Includes operation name and screen name for logging
- ✅ Located in `data/repositories/` folder

### 3. Providers Must Use Interface Types

**Provider Definition** (`lib/features/chat/presentation/providers/chat_providers.dart`):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_chat_repository.dart';
import '../../domain/repositories/chat_repository.dart';

/// Provider for ChatRepository
/// Uses interface type for dependency injection
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FirestoreChatRepository();
});

/// Provider for messages stream
final messagesProvider = StreamProvider.family<List<Message>, String>((ref, chatId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessages(chatId);
});
```

**Key Requirements**:
- ✅ Provider type is the interface (`ChatRepository`), not the implementation
- ✅ Enables easy mocking for tests
- ✅ Supports dependency injection

## Testing Requirements

### 1. Unit Tests with Mocks

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([ChatRepository])
import 'chat_test.mocks.dart';

void main() {
  group('ChatRepository Tests', () {
    late MockChatRepository mockRepository;
    
    setUp(() {
      mockRepository = MockChatRepository();
    });
    
    test('sendMessage should complete successfully', () async {
      // Arrange
      when(mockRepository.sendMessage(
        chatId: any,
        senderId: any,
        text: any,
      )).thenAnswer((_) async => Future.value());
      
      // Act
      await mockRepository.sendMessage(
        chatId: 'chat123',
        senderId: 'user123',
        text: 'Hello',
      );
      
      // Assert
      verify(mockRepository.sendMessage(
        chatId: 'chat123',
        senderId: 'user123',
        text: 'Hello',
      )).called(1);
    });
  });
}
```

### 2. Integration Tests with Firebase Emulator

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FirebaseFirestore firestore;
  late FirestoreChatRepository repository;
  
  setUpAll(() async {
    // Connect to Firebase Emulator
    firestore = FirebaseFirestore.instance;
    firestore.useFirestoreEmulator('localhost', 8080);
  });
  
  setUp(() {
    repository = FirestoreChatRepository(firestore: firestore);
  });
  
  test('sendMessage should store message in Firestore', () async {
    // Test with real Firestore emulator
    await repository.sendMessage(
      chatId: 'test-chat',
      senderId: 'test-user',
      text: 'Test message',
    );
    
    final messages = await repository.getMessages('test-chat').first;
    expect(messages.length, 1);
    expect(messages.first.text, 'Test message');
  });
}
```

## Compliance Verification

### Automated Checks

Run the compliance verification script:

```bash
# On Unix/Linux/Mac
./tool/verify_repository_patterns.sh

# On Windows
tool\verify_repository_patterns.bat

# Or directly with Dart
dart tool/verify_repository_patterns.dart
```

### What Gets Checked

1. **BaseFirestoreRepository Extension**
   - All Firestore repositories extend `BaseFirestoreRepository`
   - Ensures consistent error handling

2. **Interface Existence**
   - All repository implementations have corresponding interfaces
   - Interfaces are in the correct location (`domain/repositories/`)

3. **Repository Structure**
   - Implementations are in `data/repositories/`
   - Interfaces are in `domain/repositories/`
   - No Firebase imports in domain layer

### CI/CD Integration

Add to your CI/CD pipeline (e.g., GitHub Actions):

```yaml
name: Repository Pattern Compliance

on: [push, pull_request]

jobs:
  verify-patterns:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - name: Verify Repository Patterns
        run: dart tool/verify_repository_patterns.dart
```

## Examples

### Example 1: Story Repository

**Interface** (`lib/features/stories/domain/repositories/story_repository.dart`):
```dart
abstract class StoryRepository {
  Future<Story> createStory(Story story);
  Stream<List<Story>> getActiveStories();
  Future<void> deleteStory(String storyId);
}
```

**Implementation** (`lib/features/stories/data/repositories/firestore_story_repository.dart`):
```dart
class FirestoreStoryRepository extends BaseFirestoreRepository 
    implements StoryRepository {
  
  @override
  Future<Story> createStory(Story story) async {
    return handleFirestoreOperation(
      operation: () async {
        await _firestore.collection('stories').doc(story.id).set(story.toJson());
        return story;
      },
      operationName: 'createStory',
      screen: 'StoryCreation',
      arabicErrorMessage: 'فشل في إنشاء القصة',
      collection: 'stories',
      documentId: story.id,
    );
  }
}
```

### Example 2: Discovery Repository

**Interface** (`lib/features/discovery/domain/repositories/discovery_repository.dart`):
```dart
abstract class DiscoveryRepository {
  Future<UserProfile?> getRandomUser(String currentUserId, DiscoveryFilters filters);
  Future<List<UserProfile>> getFilteredUsers(String currentUserId, DiscoveryFilters filters);
}
```

**Implementation** (`lib/features/discovery/data/repositories/firestore_discovery_repository.dart`):
```dart
class FirestoreDiscoveryRepository extends BaseFirestoreRepository 
    implements DiscoveryRepository {
  
  @override
  Future<UserProfile?> getRandomUser(String currentUserId, DiscoveryFilters filters) async {
    return handleFirestoreOperation(
      operation: () async {
        // Implementation
      },
      operationName: 'getRandomUser',
      screen: 'DiscoveryScreen',
      arabicErrorMessage: 'فشل في جلب المستخدمين',
      collection: 'users',
    );
  }
}
```

## Common Mistakes

### ❌ Mistake 1: Not Extending BaseFirestoreRepository

```dart
// WRONG
class FirestoreChatRepository implements ChatRepository {
  Future<void> sendMessage() async {
    try {
      // Manual error handling
    } catch (e) {
      print('Error: $e'); // Inconsistent logging
    }
  }
}
```

```dart
// CORRECT
class FirestoreChatRepository extends BaseFirestoreRepository 
    implements ChatRepository {
  
  Future<void> sendMessage() async {
    return handleFirestoreVoidOperation(
      operation: () async {
        // Implementation
      },
      operationName: 'sendMessage',
      screen: 'ChatScreen',
      arabicErrorMessage: 'فشل في إرسال الرسالة',
      collection: 'chats',
    );
  }
}
```

### ❌ Mistake 2: No Interface

```dart
// WRONG - No interface
class FirestoreChatRepository extends BaseFirestoreRepository {
  // Implementation without interface
}

// Provider uses concrete type
final chatRepositoryProvider = Provider<FirestoreChatRepository>((ref) {
  return FirestoreChatRepository();
});
```

```dart
// CORRECT - With interface
abstract class ChatRepository {
  Future<void> sendMessage();
}

class FirestoreChatRepository extends BaseFirestoreRepository 
    implements ChatRepository {
  // Implementation
}

// Provider uses interface type
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FirestoreChatRepository();
});
```

### ❌ Mistake 3: Firebase Imports in Domain Layer

```dart
// WRONG - Domain layer importing Firebase
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ChatRepository {
  Future<DocumentSnapshot> getMessage(String id); // Exposes Firebase types
}
```

```dart
// CORRECT - Domain layer uses domain types
abstract class ChatRepository {
  Future<Message> getMessage(String id); // Uses domain model
}
```

### ❌ Mistake 4: Provider Uses Concrete Type

```dart
// WRONG
final chatRepositoryProvider = Provider<FirestoreChatRepository>((ref) {
  return FirestoreChatRepository();
});
```

```dart
// CORRECT
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FirestoreChatRepository();
});
```

## Benefits of Following This Pattern

1. **Testability**: Easy to mock repositories for unit tests
2. **Consistency**: All repositories handle errors the same way
3. **Maintainability**: Changes to data layer don't affect domain/presentation
4. **Flexibility**: Easy to swap implementations (e.g., Firestore → REST API)
5. **Error Handling**: Standardized logging and user-friendly messages
6. **Code Quality**: Enforced through automated compliance checks

## Related Documentation

- [Architecture Guidelines](../architecture_guidelines.md)
- [Error Handling Guide](../../lib/core/data/base_firestore_repository.dart)
- [Testing Strategy](../PERFORMANCE_TESTING_GUIDE.md)
- [Code Review Checklist](../../.github/CODE_REVIEW_CHECKLIST.md)

## Questions?

If you have questions about the repository pattern or need help implementing it:

1. Review the examples in this guide
2. Check existing repositories in the codebase
3. Run the compliance verification script
4. Refer to the architecture guidelines

---

**Last Updated**: December 2025
**Maintained By**: Development Team
