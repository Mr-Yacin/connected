# Services Layer Architecture

## Overview

The services layer provides abstraction for external dependencies and cross-cutting concerns. Services are organized into two categories: **global services** (used across multiple features) and **feature-specific services** (domain-specific logic for a single feature).

## Service Categories

### Global Services (`lib/services/`)

Services that are used across multiple features and don't belong to a specific domain.

#### 📊 Monitoring (`monitoring/`)
Services for application monitoring, error tracking, and performance:

- **`app_logger.dart`** - Structured logging with log levels (debug, info, warning, error)
  - Provides centralized logging with user/session tracking
  - Filters logs in production (debug/info suppressed)
  - Integrates with Crashlytics and Firebase Analytics
  
- **`error_logging_service.dart`** - Centralized error logging and reporting
  - Logs errors with context, screen name, and operation name
  - Supports Firestore-specific error logging
  - Automatically reports to Crashlytics
  
- **`crashlytics_service.dart`** - Firebase Crashlytics integration
  - Records fatal and non-fatal errors
  - Tracks custom keys for filtering
  - Manages user identification
  
- **`performance_service.dart`** - Performance monitoring and metrics
  - Tracks screen load times
  - Monitors network request performance
  - Custom performance traces

- **`monitoring_integration_guide.dart`** - Integration documentation

#### 📈 Analytics (`analytics/`)
Services for user behavior tracking and analytics:

- **`analytics_events.dart`** - Firebase Analytics event tracking
  - Tracks user actions and screen views
  - Custom event parameters
  - User property management

#### 💾 Storage (`storage/`)
Services for local data persistence and caching:

- **`preferences_service.dart`** - SharedPreferences wrapper
  - Stores user preferences (theme, language, settings)
  - Type-safe preference access
  - Async initialization
  
- **`image_cache_service.dart`** - Image caching management
  - LRU cache with size limits
  - Memory-efficient image storage
  - Automatic cache eviction

#### 🎬 Media (`media/`)
Services for media processing:

- **`image_compression_service.dart`** - Image compression and optimization
  - Reduces image file sizes
  - Maintains quality while compressing
  - Supports multiple formats
  
- **`video_compression_service.dart`** - Video compression and optimization
  - Reduces video file sizes
  - Configurable quality settings
  - Progress tracking

#### 🌐 External (`external/`)
Services for external integrations and system features:

- **`firebase_service.dart`** - Firebase initialization
  - Initializes Firebase services
  - Configures Firebase options
  - Handles Firebase errors
  
- **`notification_service.dart`** - Push notifications (basic)
  - FCM token management
  - Notification display
  - Background message handling
  
- **`notification_service_enhanced.dart`** - Enhanced push notifications
  - Advanced notification features
  - Notification channels
  - Custom notification actions
  
- **`connectivity_service.dart`** - Network connectivity status
  - Monitors network state
  - Provides connectivity stream
  - Detects connection type
  
- **`location_service.dart`** - GPS and location services
  - Gets current location
  - Handles location permissions
  - Location accuracy settings
  
- **`retry_service.dart`** - Retry logic for failed operations
  - Exponential backoff
  - Configurable retry attempts
  - Error-specific retry strategies
  
- **`user_data_service.dart`** - User data management
  - User profile caching
  - User data synchronization
  - Profile updates

**When to use global services:**
- Service is used by 3+ features
- Service wraps external SDK (Firebase, etc.)
- Service provides infrastructure (logging, monitoring, caching)
- Service handles cross-cutting concerns (analytics, error tracking)

### Feature-Specific Services (`lib/features/*/data/services/`)

Services that are specific to a single feature's domain logic.

#### Stories Feature (`features/stories/data/services/`)

- **`story_expiration_service.dart`** - Story expiration management
  - Periodically checks for expired stories
  - Automatically deletes expired content
  - Timer-based cleanup

#### Discovery Feature (`features/discovery/data/services/`)

- **`viewed_users_service.dart`** - Viewed users tracking
  - Tracks users already shown in discovery
  - Time-based reset mechanism
  - Local storage persistence
  
- **`filter_service.dart`** - User filtering logic
  - Applies country filters
  - Age range filtering
  - Gender preference filtering

#### Chat Feature (`features/chat/data/services/`)

- **`voice_recorder_service.dart`** - Voice message recording
  - Records audio messages
  - Plays voice messages
  - Audio file management

#### Profile Feature (`features/profile/data/services/`)

- **`image_blur_service.dart`** - Image blur effects
  - Applies blur to profile images
  - Privacy protection for images
  - Configurable blur intensity

#### Moderation Feature (`features/moderation/data/services/`)

- **`block_service.dart`** - User blocking operations
  - Manages blocked users list
  - Block/unblock operations
  - Blocked user filtering

**When to use feature-specific services:**
- Service is only used within one feature
- Service contains domain-specific business logic
- Service manages feature-specific state
- Service doesn't fit into global infrastructure concerns

## Usage Guidelines

### Importing Services

Use organized paths when importing:

```dart
// Global monitoring services
import 'package:social_connect_app/services/monitoring/app_logger.dart';
import 'package:social_connect_app/services/monitoring/error_logging_service.dart';
import 'package:social_connect_app/services/monitoring/crashlytics_service.dart';

// Global analytics
import 'package:social_connect_app/services/analytics/analytics_events.dart';

// Global storage
import 'package:social_connect_app/services/storage/preferences_service.dart';
import 'package:social_connect_app/services/storage/image_cache_service.dart';

// Global media
import 'package:social_connect_app/services/media/image_compression_service.dart';

// Global external
import 'package:social_connect_app/services/external/notification_service.dart';
import 'package:social_connect_app/services/external/firebase_service.dart';

// Feature-specific services
import 'package:social_connect_app/features/stories/data/services/story_expiration_service.dart';
import 'package:social_connect_app/features/discovery/data/services/viewed_users_service.dart';
```

### When to Use Services in Different Layers

**✅ Data Layer (Repositories):**
- Repository implementations can use both global and feature-specific services
- Example: Error logging in Firestore operations
- Example: Image compression before upload

```dart
class FirestoreStoryRepository extends BaseFirestoreRepository {
  final ImageCompressionService _compressionService;
  
  Future<void> uploadStory(Story story) async {
    try {
      // Use global service
      final compressed = await _compressionService.compress(story.image);
      await _firestore.collection('stories').add(compressed);
    } catch (e, stackTrace) {
      // Use global error logging
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to upload story',
        screen: 'StoryCreation',
        operation: 'uploadStory',
        collection: 'stories',
      );
      rethrow;
    }
  }
}
```

**❌ Domain Layer (Entities, Use Cases):**
- Domain should be pure business logic
- No infrastructure dependencies
- No service imports

**⚠️ Presentation Layer (Providers, Screens, Widgets):**
- Prefer using services through repositories when possible
- Direct usage acceptable for cross-cutting concerns:
  - Analytics tracking (user actions)
  - Error logging (UI errors)
  - App logging (debug information)

```dart
class StoryScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Acceptable: Analytics for screen view
    useEffect(() {
      AnalyticsEvents.logScreenView('StoryScreen');
      return null;
    }, []);
    
    return Scaffold(
      // ... UI code
    );
  }
}
```

## Guidelines for Creating New Services

### 1. Determine Service Category

Ask yourself:
- **Is it used by multiple features?** → Global service
- **Is it feature-specific business logic?** → Feature-specific service
- **Does it wrap an external SDK?** → Global service (external/)
- **Does it handle infrastructure concerns?** → Global service
- **Does it contain domain logic for one feature?** → Feature-specific service

### 2. Choose the Right Location

**Global Service Structure:**
```
lib/services/
├── monitoring/        # Error tracking, logging, performance
├── analytics/         # User behavior tracking
├── storage/          # Local persistence, caching
├── media/            # Image/video processing
└── external/         # External SDKs, system features
```

**Feature-Specific Service Structure:**
```
lib/features/[feature_name]/
└── data/
    └── services/
        └── [feature]_service.dart
```

### 3. Follow Service Best Practices

**Service Structure:**
```dart
/// Service for [purpose]
/// 
/// Provides [functionality description]
class MyService {
  // Dependencies (inject via constructor)
  final Dependency _dependency;
  
  MyService(this._dependency);
  
  /// [Method description]
  /// 
  /// Returns [return value description]
  /// Throws [exception types] when [conditions]
  Future<Result> performOperation() async {
    try {
      // Implementation
      return result;
    } catch (e, stackTrace) {
      // Log errors
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Operation failed',
        screen: 'MyService',
        operation: 'performOperation',
      );
      rethrow;
    }
  }
}
```

**Key Principles:**
- **Single Responsibility**: Each service has one clear purpose
- **Stateless**: Services should be stateless (use providers for state)
- **Dependency Injection**: Use constructor injection via Riverpod
- **Error Handling**: Comprehensive try-catch with logging
- **Documentation**: Clear doc comments for public APIs
- **Testing**: Create interfaces for mockability

### 4. Create Service Interface (When Needed)

If the service will have multiple implementations or needs mocking for tests:

```dart
// Interface
abstract class MyService {
  Future<Result> performOperation();
}

// Implementation
class MyServiceImpl implements MyService {
  @override
  Future<Result> performOperation() async {
    // Implementation
  }
}

// Provider
final myServiceProvider = Provider<MyService>((ref) {
  return MyServiceImpl();
});
```

### 5. Register with Dependency Injection

Use Riverpod providers:

```dart
// Global service provider
final myServiceProvider = Provider<MyService>((ref) {
  return MyService();
});

// Service with dependencies
final myServiceProvider = Provider<MyService>((ref) {
  final dependency = ref.watch(dependencyProvider);
  return MyService(dependency);
});
```

### 6. Add Comprehensive Error Handling

All services should handle errors gracefully:

```dart
Future<Result> performOperation() async {
  try {
    // Operation logic
    return result;
  } on SpecificException catch (e, stackTrace) {
    // Handle specific errors
    ErrorLoggingService.logGeneralError(
      e,
      stackTrace: stackTrace,
      context: 'Specific error occurred',
      screen: 'MyService',
      operation: 'performOperation',
    );
    throw AppException('خطأ محدد', originalError: e);
  } catch (e, stackTrace) {
    // Handle general errors
    ErrorLoggingService.logGeneralError(
      e,
      stackTrace: stackTrace,
      context: 'Unexpected error',
      screen: 'MyService',
      operation: 'performOperation',
    );
    throw AppException('حدث خطأ غير متوقع', originalError: e);
  }
}
```

### 7. Add Logging for Debugging

Use AppLogger for development debugging:

```dart
Future<Result> performOperation() async {
  AppLogger.debug('Starting operation', data: {'param': value});
  
  try {
    final result = await _doWork();
    AppLogger.info('Operation completed', data: {'result': result});
    return result;
  } catch (e, stackTrace) {
    AppLogger.error(
      'Operation failed',
      error: e,
      stackTrace: stackTrace,
      data: {'param': value},
    );
    rethrow;
  }
}
```

### 8. Update This Documentation

After creating a new service:
1. Add it to the appropriate section above
2. Document its purpose and key functionality
3. Provide usage examples if complex
4. Update the service count in overview

## Testing Services

### Unit Testing

Test services in isolation using mocks:

```dart
void main() {
  group('MyService', () {
    late MyService service;
    late MockDependency mockDependency;
    
    setUp(() {
      mockDependency = MockDependency();
      service = MyService(mockDependency);
    });
    
    test('should perform operation successfully', () async {
      // Arrange
      when(mockDependency.doSomething()).thenAnswer((_) async => result);
      
      // Act
      final result = await service.performOperation();
      
      // Assert
      expect(result, expectedResult);
      verify(mockDependency.doSomething()).called(1);
    });
    
    test('should handle errors gracefully', () async {
      // Arrange
      when(mockDependency.doSomething()).thenThrow(Exception('Error'));
      
      // Act & Assert
      expect(
        () => service.performOperation(),
        throwsA(isA<AppException>()),
      );
    });
  });
}
```

### Integration Testing

Test services with real dependencies (Firebase emulators):

```dart
void main() {
  group('MyService Integration Tests', () {
    setUpAll(() async {
      // Initialize Firebase emulators
      await Firebase.initializeApp();
    });
    
    test('should work with real Firebase', () async {
      final service = MyService();
      final result = await service.performOperation();
      expect(result, isNotNull);
    });
  });
}
```

## Architecture Notes

### Service Layer in Clean Architecture

Services sit in the **infrastructure layer** and provide:

- **Cross-cutting concerns**: Logging, analytics, error tracking
- **External integrations**: Firebase, notifications, location
- **Technical utilities**: Compression, caching, retry logic

They are **not** part of the core domain but support it:

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│    (Screens, Widgets, Providers)    │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│          Domain Layer               │
│   (Entities, Use Cases, Repos)      │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│           Data Layer                │
│  (Repository Implementations)       │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│      Infrastructure Layer           │
│         (Services)                  │
│  • Global Services (lib/services/)  │
│  • Feature Services (features/*/    │
│    data/services/)                  │
└─────────────────────────────────────┘
```

### Service vs Repository

**Use a Service when:**
- Wrapping external SDK (Firebase, notifications)
- Providing technical utility (compression, caching)
- Handling cross-cutting concern (logging, analytics)
- No direct data persistence involved

**Use a Repository when:**
- Managing data persistence (Firestore, local DB)
- Implementing data access patterns
- Handling CRUD operations
- Part of domain layer contract

### Global vs Feature-Specific Decision Tree

```
Is the service used by multiple features?
├─ Yes → Global Service (lib/services/)
│  └─ What category?
│     ├─ Error tracking/logging → monitoring/
│     ├─ User behavior tracking → analytics/
│     ├─ Local persistence → storage/
│     ├─ Media processing → media/
│     └─ External SDK/system → external/
│
└─ No → Feature-Specific Service
   └─ Place in: lib/features/[feature]/data/services/
```

## Common Patterns

### Singleton Services

For services that maintain state:

```dart
class MySingletonService {
  static final MySingletonService _instance = MySingletonService._internal();
  
  factory MySingletonService() => _instance;
  
  MySingletonService._internal();
  
  // Service methods
}
```

### Async Initialization

For services requiring async setup:

```dart
class MyService {
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Async initialization
    await _setup();
    _initialized = true;
  }
  
  Future<Result> performOperation() async {
    if (!_initialized) {
      throw StateError('Service not initialized');
    }
    // Operation logic
  }
}
```

### Service with Streams

For services providing real-time data:

```dart
class MyStreamService {
  final _controller = StreamController<Data>.broadcast();
  
  Stream<Data> get dataStream => _controller.stream;
  
  void updateData(Data data) {
    _controller.add(data);
  }
  
  void dispose() {
    _controller.close();
  }
}
```

## Summary

- **Global Services**: Infrastructure concerns used across features
- **Feature Services**: Domain-specific logic for single features
- **Best Practices**: Single responsibility, dependency injection, error handling
- **Testing**: Use interfaces for mockability, test with emulators
- **Documentation**: Keep this README updated with new services
