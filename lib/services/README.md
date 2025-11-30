# Services Directory Structure

This directory contains infrastructure services organized by category for better maintainability and scalability.

## Directory Organization

### 📊 `monitoring/`
Services for application monitoring, error tracking, and performance:
- **`error_logging_service.dart`** - Centralized error logging and reporting
- **`crashlytics_service.dart`** - Firebase Crashlytics integration
- **`performance_service.dart`** - Performance monitoring and metrics
- **`monitoring_integration_guide.dart`** - Integration documentation

### 📈 `analytics/`
Services for user behavior tracking and analytics:
- **`analytics_events.dart`** - Firebase Analytics event tracking

### 💾 `storage/`
Services for local data persistence and caching:
- **`preferences_service.dart`** - SharedPreferences wrapper (theme, settings, etc.)
- **`image_cache_service.dart`** - Image caching management

### 🌐 `external/`
Services for external integrations and system features:
- **`firebase_service.dart`** - Firebase initialization
- **`notification_service.dart`** - Push notifications
- **`connectivity_service.dart`** - Network connectivity status
- **`location_service.dart`** - GPS and location services
- **`retry_service.dart`** - Retry logic for failed operations
- **`user_data_service.dart`** - User data management

## Usage Guidelines

### Importing Services

Use the organized paths when importing:

```dart
// Monitoring services
import 'package:social_connect_app/services/monitoring/error_logging_service.dart';
import 'package:social_connect_app/services/monitoring/crashlytics_service.dart';

// Analytics
import 'package:social_connect_app/services/analytics/analytics_events.dart';

// Storage
import 'package:social_connect_app/services/storage/preferences_service.dart';

// External
import 'package:social_connect_app/services/external/notification_service.dart';
```

### When to Use Services

**✅ Use in Data Layer:**
- Repository implementations can use infrastructure services
- Example: Error logging in Firestore operations

**❌ Don't Use in Domain Layer:**
- Domain should be pure business logic
- No infrastructure dependencies

**⚠️ Sparingly in Presentation:**
- Prefer using through repositories when possible
- Direct usage acceptable for cross-cutting concerns (analytics, error logging)

## Adding New Services

1. **Determine Category**
   - Monitoring? Analytics? Storage? External?
   
2. **Create in Appropriate Subdirectory**
   ```
   services/
   └── [category]/
       └── your_new_service.dart
   ```

3. **Follow Existing Patterns**
   - Use singleton pattern if stateful
   - Provide initialization methods
   - Handle errors gracefully

4. **Update This README**
   - Document the new service
   - Explain its purpose and usage

## Architecture Notes

These services provide **infrastructure concerns** (cross-cutting functionality) rather than business logic:

- **Not Feature-Specific**: Used across multiple features
- **Not Business Logic**: Handle technical concerns, not domain rules
- **Reusable**: Designed for application-wide use
- **Infrastructure Layer**: Sit outside the clean architecture layers

For feature-specific services, consider placing them in:
```
lib/features/[feature_name]/data/services/
```
