# Clean Architecture Guidelines

## Quick Reference

### Clean Architecture Layers

```
presentation/ → domain/ ← data/
     ↓                      ↓
  (UI Logic)         (Data Sources)
```

**Dependency Rule**: Dependencies point **inward** (toward domain)

---

## Feature Structure Template

When creating a new feature, use this structure:

```
lib/features/your_feature/
├── data/
│   ├── models/              # Data models (DTOs)
│   │   └── *_model.dart
│   └── repositories/        # Repository implementations
│       └── firestore_*_repository.dart
├── domain/
│   ├── entities/            # Business entities (optional if using core models)
│   │   └── *.dart
│   ├── repositories/        # Repository interfaces
│   │   └── *_repository.dart
│   └── usecases/           # Business logic
│       └── *.dart
└── presentation/
    ├── providers/           # State management (Riverpod)
    │   └── *_provider.dart
    ├── screens/            # Full-screen pages
    │   └── *_screen.dart
    └── widgets/            # Reusable UI components
        └── *.dart
```

---

## Layer Responsibilities

### 1️⃣ Domain Layer (Core Business Logic)

**Purpose**: Define business rules and contracts

**Contains**:
- **Entities**: Pure business objects (or use `core/models`)
- **Repository Interfaces**: Abstract contracts for data access
- **Use Cases**: Business logic operations

**Rules**:
- ✅ NO imports from data or presentation
- ✅ NO imports from external packages (except Dart SDK)
- ✅ CAN import from `core/`

**Example Repository Interface**:
```dart
// lib/features/chat/domain/repositories/chat_repository.dart
abstract class ChatRepository {
  Stream<List<Message>> getMessages(String chatId);
  Future<void> sendMessage({required String chatId, required String text});
}
```

**Example Use Case**:
```dart
// lib/features/chat/domain/usecases/send_message.dart
class SendMessageUseCase {
  final ChatRepository _repository;
  
  SendMessageUseCase(this._repository);
  
  Future<void> call({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    // Validate input
    if (text.trim().isEmpty) {
      throw ValidationException('Message cannot be empty');
    }
    
    // Business rule: Max message length
    if (text.length > 1000) {
      throw ValidationException('Message too long');
    }
    
    // Delegate to repository
    return _repository.sendMessage(
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: text.trim(),
    );
  }
}
```

---

### 2️⃣ Data Layer (Data Sources & Implementation)

**Purpose**: Implement data access and external integrations

**Contains**:
- **Repository Implementations**: Concrete implementations of domain interfaces
- **Data Models**: DTOs for serialization (optional if using core models)
- **Data Sources**: API clients, database access, etc.

**Rules**:
- ✅ CAN import from domain layer (implements interfaces)
- ✅ CAN import from `core/`
- ✅ CAN import external packages (Firestore, HTTP, etc.)
- ✅ SHOULD extend [BaseFirestoreRepository](file:///c:/Users/yacin/Documents/connected/lib/core/data/base_firestore_repository.dart#7-99) for Firestore operations
- ❌ NO imports from presentation layer

**Example Repository Implementation**:
```dart
// lib/features/chat/data/repositories/firestore_chat_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/message.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/data/base_firestore_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../../../services/error_logging_service.dart';

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
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromJson(doc.data()))
            .toList());
  }
  
  @override
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    return handleFirestoreVoidOperation(
      operation: () async {
        // Firestore operations here
      },
      operationName: 'sendMessage',
      screen: 'ChatScreen',
      arabicErrorMessage: 'فشل في إرسال الرسالة',
    );
  }
}
```

---

### 3️⃣ Presentation Layer (UI & State)

**Purpose**: Display data and handle user interactions

**Contains**:
- **Screens**: Full-page widgets
- **Widgets**: Reusable UI components
- **Providers**: State management (Riverpod)

**Rules**:
- ✅ CAN import from domain layer (use repository interfaces)
- ✅ CAN import from `core/`
- ✅ CAN import UI packages (Flutter, Riverpod, etc.)
- ❌ NO imports from data layer (use dependency injection)

**Example Provider**:
```dart
// lib/features/chat/presentation/providers/chat_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/send_message.dart';

// Inject repository (from data layer via DI)
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FirestoreChatRepository(); // In real app, use DI container
});

// Provide use case
final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.read(chatRepositoryProvider));
});

// UI state provider
final chatMessagesProvider = StreamProvider.family<List<Message>, String>(
  (ref, chatId) {
    final repository = ref.read(chatRepositoryProvider);
    return repository.getMessages(chatId);
  },
);
```

**Example Screen**:
```dart
// lib/features/chat/presentation/screens/chat_screen.dart
class ChatScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatId = 'example-chat-id';
    final messagesAsync = ref.watch(chatMessagesProvider(chatId));
    
    return messagesAsync.when(
      data: (messages) => ListView.builder(...),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

---

## Using Core Module

### When to Use Core

**Use `core/models/`** when:
- ✅ Model is shared across multiple features
- ✅ Model is a domain entity (not a DTO)
- ✅ Examples: `UserProfile`, [Message](file:///c:/Users/yacin/Documents/connected/lib/features/chat/data/repositories/firestore_chat_repository.dart#28-79), `Story`

**Use `core/exceptions/`** when:
- ✅ Creating custom exceptions
- ✅ Examples: `AppException`, `AuthException`, `ValidationException`

**Use `core/utils/`** when:
- ✅ Creating utilities used by multiple features
- ✅ Examples: `error_handler`, `snackbar_helper`, `query_builder`

**Use `core/data/`** when:
- ✅ Creating base classes for repositories
- ✅ Example: Extend [BaseFirestoreRepository](file:///c:/Users/yacin/Documents/connected/lib/core/data/base_firestore_repository.dart#7-99)

### Example: Using Core in Repository

```dart
import '../../../../core/models/user_profile.dart';         // Shared model
import '../../../../core/exceptions/app_exceptions.dart';   // Shared exception
import '../../../../core/data/base_firestore_repository.dart'; // Base class
import '../../../../services/error_logging_service.dart';  // Infrastructure

class FirestoreProfileRepository extends BaseFirestoreRepository 
    implements ProfileRepository {
  
  @override
  Future<UserProfile> getProfile(String userId) async {
    return handleFirestoreOperation(
      operation: () async {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (!doc.exists) {
          throw AppException('Profile not found');
        }
        return UserProfile.fromJson(doc.data()!);
      },
      operationName: 'getProfile',
      screen: 'ProfileScreen',
      arabicErrorMessage: 'فشل في جلب الملف الشخصي',
    );
  }
}
```

---

## Using Infrastructure Services

### Services Location: `lib/services/`

Services provide cross-cutting concerns:
- Logging: `error_logging_service.dart`, `crashlytics_service.dart`
- Analytics: `analytics_events.dart`
- System: `connectivity_service.dart`, `location_service.dart`
- Storage: `preferences_service.dart`, `image_cache_service.dart`

### When to Use Services

**Use in Data Layer**:
```dart
// In repository implementation
import '../../../../services/error_logging_service.dart';

class FirestoreAuthRepository implements AuthRepository {
  Future<void> signIn() async {
    try {
      // Firebase auth logic
    } catch (e, stackTrace) {
      ErrorLoggingService.logAuthError(e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
```

**DON'T Use in Domain Layer**:
```dart
// ❌ WRONG - Domain should be pure
class SendMessageUseCase {
  Future<void> call() async {
    ErrorLoggingService.log(...); // ❌ NO! Domain shouldn't know about infrastructure
  }
}
```

---

## Dependency Injection Pattern

### Current Pattern (Riverpod)

```dart
// 1. Define repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FirestoreChatRepository();
});

// 2. Inject into use cases
final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.read(chatRepositoryProvider));
});

// 3. Use in UI
class ChatScreen extends ConsumerWidget {
  void sendMessage(String text) {
    final useCase = ref.read(sendMessageUseCaseProvider);
    useCase(chatId: '...', text: text);
  }
}
```

---

## Naming Conventions

### Files
- **Screens**: `*_screen.dart` (e.g., `chat_screen.dart`)
- **Widgets**: `*_widget.dart` (e.g., `message_bubble_widget.dart`)
- **Providers**: `*_provider.dart` (e.g., `chat_provider.dart`)
- **Repositories**: `*_repository.dart` (e.g., `chat_repository.dart`)
- **Use Cases**: `*.dart` (e.g., `send_message.dart`)
- **Models**: `*.dart` (e.g., `message.dart`)

### Classes
- **Screens**: `*Screen` (e.g., `ChatScreen`)
- **Widgets**: `*Widget` (e.g., `MessageBubbleWidget`)
- **Providers**: `*Provider` (e.g., `chatMessagesProvider`)
- **Repositories**: `*Repository` (e.g., `ChatRepository`)
- **Implementations**: `Firestore*Repository` (e.g., `FirestoreChatRepository`)
- **Use Cases**: `*UseCase` (e.g., `SendMessageUseCase`)

---

## Checklist: Adding a New Feature

### Planning Phase
- [ ] Identify business entities (domain models)
- [ ] Define repository interfaces (domain contracts)
- [ ] List use cases (business operations)
- [ ] Check if you can reuse core models

### Implementation Phase

#### 1. Create Feature Folder
```bash
mkdir -p lib/features/my_feature/{data/repositories,domain/repositories,domain/usecases,presentation/screens,presentation/widgets,presentation/providers}
```

#### 2. Domain Layer
- [ ] Create repository interface in `domain/repositories/`
- [ ] Create entities in `domain/entities/` (or use core models)
- [ ] Create use cases in `domain/usecases/`

#### 3. Data Layer
- [ ] Create repository implementation in `data/repositories/`
- [ ] Extend `BaseFirestoreRepository` if using Firestore
- [ ] Import and use infrastructure services for logging
- [ ] Import core models and exceptions

#### 4. Presentation Layer
- [ ] Create providers in `presentation/providers/`
- [ ] Create screens in `presentation/screens/`
- [ ] Create reusable widgets in `presentation/widgets/`
- [ ] Wire up dependency injection

#### 5. Testing
- [ ] Write unit tests for use cases
- [ ] Write unit tests for repositories (with mocks)
- [ ] Write widget tests for screens
- [ ] Manual testing

---

## Common Patterns

### Pattern 1: Firestore Repository with Error Handling

```dart
class FirestoreMyRepository extends BaseFirestoreRepository 
    implements MyRepository {
  
  @override
  Future<MyEntity> getEntity(String id) async {
    return handleFirestoreOperation(
      operation: () async {
        final doc = await _firestore.collection('entities').doc(id).get();
        if (!doc.exists) throw AppException('Not found');
        return MyEntity.fromJson(doc.data()!);
      },
      operationName: 'getEntity',
      screen: 'MyScreen',
      arabicErrorMessage: 'فشل في جلب البيانات',
      collection: 'entities',
      documentId: id,
    );
  }
}
```

### Pattern 2: Stream-based Repository

```dart
@override
Stream<List<MyEntity>> watchEntities() {
  try {
    return _firestore
        .collection('entities')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MyEntity.fromJson(doc.data()))
            .toList());
  } catch (e, stackTrace) {
    ErrorLoggingService.logFirestoreError(e, stackTrace: stackTrace);
    throw AppException('Failed to watch entities');
  }
}
```

### Pattern 3: Use Case with Validation

```dart
class CreateProfileUseCase {
  final ProfileRepository _repository;
  
  CreateProfileUseCase(this._repository);
  
  Future<void> call({
    required String name,
    required int age,
    required String country,
  }) async {
    // Validation
    if (name.trim().isEmpty) {
      throw ValidationException('Name required');
    }
    
    if (age < 18) {
      throw ValidationException('Must be 18+');
    }
    
    // Business logic
    final profile = UserProfile(
      name: name.trim(),
      age: age,
      country: country,
    );
    
    // Delegate to repository
    return _repository.createProfile(profile);
  }
}
```

---

## Anti-Patterns to Avoid

### ❌ Anti-Pattern 1: Data Layer in Domain

```dart
// ❌ WRONG - domain/repositories/chat_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // NO!

abstract class ChatRepository {
  // Domain should define contracts, not implementations
}
```

### ❌ Anti-Pattern 2: Presentation Importing Data

```dart
// ❌ WRONG - presentation/screens/chat_screen.dart
import '../../data/repositories/firestore_chat_repository.dart';

class ChatScreen {
  final repository = FirestoreChatRepository(); // NO! Use DI
}
```

**✅ Correct**:
```dart
import '../../domain/repositories/chat_repository.dart';

class ChatScreen extends ConsumerWidget {
  Widget build(context, ref) {
    final repository = ref.read(chatRepositoryProvider); // DI
  }
}
```

### ❌ Anti-Pattern 3: Business Logic in Presentation

```dart
// ❌ WRONG - presentation/screens/profile_screen.dart
void saveProfile() {
  if (name.isEmpty || age < 18) { // Business logic in UI
    showError();
  }
  repository.save(profile);
}
```

**✅ Correct**:
```dart
void saveProfile() {
  try {
    ref.read(createProfileUseCaseProvider)(name: name, age: age);
  } on ValidationException catch (e) {
    showError(e.message);
  }
}
```

### ❌ Anti-Pattern 4: Cross-Feature Dependencies

```dart
// ❌ WRONG - features/chat/data/repositories/
import '../../../profile/data/repositories/profile_repository.dart'; // NO!
```

**✅ Correct**: Import from `core/` or inject dependencies

---

## Quick Reference: Import Rules

### Domain Layer
```dart
✅ import 'core/models/*.dart';
✅ import 'core/exceptions/*.dart';
❌ import 'package:cloud_firestore/...';
❌ import '../../../data/...';
❌ import '../../presentation/...';
```

### Data Layer
```dart
✅ import 'core/models/*.dart';
✅ import 'core/exceptions/*.dart';
✅ import 'core/data/base_firestore_repository.dart';
✅ import 'services/error_logging_service.dart';
✅ import '../../domain/repositories/...';
✅ import 'package:cloud_firestore/...';
❌ import '../../presentation/...';
```

### Presentation Layer
```dart
✅ import 'core/models/*.dart';
✅ import 'core/exceptions/*.dart';
✅ import 'core/utils/*.dart';
✅ import 'core/widgets/*.dart';
✅ import '../../domain/repositories/...';
✅ import '../../domain/usecases/...';
✅ import 'package:flutter/...';
✅ import 'package:flutter_riverpod/...';
❌ import '../../data/...';
```

---

## Summary

**Core Principles**:
1. **Separation of Concerns**: Each layer has one responsibility
2. **Dependency Inversion**: Code depends on abstractions, not concrete implementations
3. **Testability**: Use cases and repositories are easily mockable
4. **Scalability**: Features are independent modules

**When in doubt**:
- Look at existing features (auth, chat, profile) as templates
- Follow the dependency rule: dependencies point toward domain
- Use core for shared code, services for infrastructure
- Keep business logic in use cases, not in UI or repositories
