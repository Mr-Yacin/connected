# Firebase Monitoring Setup Guide

This guide covers the implementation of **Firebase Performance Monitoring**, **Crashlytics**, and **Analytics** in your Flutter social connect app.

## 🎯 Overview

All three services are **FREE** on Firebase's Spark Plan and provide:

- ✅ **Performance Monitoring** - Track app speed, network latency, and custom traces
- ✅ **Crashlytics** - Real-time crash reporting and error tracking
- ✅ **Analytics** - User behavior tracking and engagement metrics

---

## ✅ What's Been Implemented

### 1. Dependencies Added (`pubspec.yaml`)

```yaml
dependencies:
  firebase_performance: ^0.10.0+8
  firebase_analytics: ^11.3.5
  firebase_crashlytics: ^4.1.3
```

### 2. Android Configuration

**`android/settings.gradle.kts`:**
```kotlin
plugins {
    id("com.google.gms.google-services") version("4.3.15") apply false
    id("com.google.firebase.crashlytics") version "3.0.2" apply false
    id("com.google.firebase.firebase-perf") version "1.4.2" apply false
}
```

**`android/app/build.gradle.kts`:**
```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("com.google.firebase.firebase-perf")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
```

### 3. Services Created

- **`lib/services/performance_service.dart`** - Performance monitoring and analytics
- **`lib/services/crashlytics_service.dart`** - Error tracking and crash reporting
- **`lib/services/analytics_events.dart`** - Centralized event tracking
- **`lib/services/monitoring_integration_guide.dart`** - Integration examples

### 4. Initialization (`lib/main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseService.initialize();

  // Initialize Firebase Crashlytics
  await CrashlyticsService.initialize();

  // Initialize Firebase Performance Monitoring
  final performance = FirebasePerformance.instance;
  await performance.setPerformanceCollectionEnabled(true);

  // Initialize Firebase Analytics
  final analytics = FirebaseAnalytics.instance;
  await analytics.setAnalyticsCollectionEnabled(true);

  // Initialize Firebase Crashlytics
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(true);

  runApp(/* ... */);
}
```

---

## 📊 Usage Examples

### Track Screen Views

```dart
class MyScreen extends ConsumerStatefulWidget {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsEventsProvider).trackScreenView('my_screen');
    });
  }
}
```

### Track User Actions

```dart
// Track post creation
await ref.read(analyticsEventsProvider).trackPostCreated(
  postId: 'post_123',
  contentType: 'text',
  hasImage: true,
  hasLocation: false,
);

// Track user follow
await ref.read(analyticsEventsProvider).trackUserFollowed(
  followedUserId: 'user_456',
);

// Track search
await ref.read(analyticsEventsProvider).trackSearch(
  searchTerm: 'flutter',
  resultCount: 10,
  searchType: 'users',
);
```

### Track Performance

```dart
final performance = ref.read(performanceServiceProvider);

// Track async operation performance
await performance.trackPerformance(
  'load_user_data',
  () async {
    // Your data loading logic
    return await fetchUserData();
  },
);
```

### Track Errors

```dart
try {
  // Your code
} catch (error, stackTrace) {
  await ref.read(analyticsEventsProvider).trackError(
    errorType: 'data_load_error',
    errorMessage: error.toString(),
    location: 'MyWidget',
    stackTrace: stackTrace,
  );
}
```

### Track Image Upload

```dart
final startTime = DateTime.now();

// Upload image
await uploadImageToStorage(file);

final uploadDuration = DateTime.now().difference(startTime);

await ref.read(analyticsEventsProvider).trackImageUpload(
  location: 'profile_picture',
  fileSizeBytes: fileSize,
  uploadDuration: uploadDuration,
);
```

---

## 🎛️ Available Analytics Events

The `AnalyticsEvents` service provides these tracking methods:

### Authentication
- `trackSignUp(method, userId)`
- `trackLogin(method, userId)`
- `trackLogout(userId)`

### Posts
- `trackPostCreated(postId, contentType, hasImage, hasLocation)`
- `trackPostLiked(postId, authorId)`
- `trackPostShared(postId, shareMethod)`
- `trackCommentAdded(postId, commentId)`

### Stories
- `trackStoryViewed(storyId, authorId)`
- `trackStoryCreated(storyId, mediaType)`

### Chat
- `trackMessageSent(chatId, messageType)`
- `trackChatOpened(chatId, recipientId)`
- `trackVoiceMessageRecorded(chatId, durationSeconds)`

### Social
- `trackUserFollowed(followedUserId)`
- `trackUserUnfollowed(unfollowedUserId)`
- `trackProfileViewed(userId)`

### Search
- `trackSearch(searchTerm, resultCount, searchType)`

### Media
- `trackImageUpload(location, fileSizeBytes, uploadDuration)`
- `trackImagePickerOpened(source)`

### Navigation
- `trackScreenView(screenName)`
- `trackTabChanged(fromTab, toTab)`

### Settings
- `trackThemeChanged(theme)`
- `trackNotificationToggled(enabled)`
- `trackLanguageChanged(language)`

### Errors
- `trackError(errorType, errorMessage, location, stackTrace)`

---

## 🔧 Firebase Console Setup

### 1. Enable Services

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **`social-connect-app`**
3. Navigate to each service:

#### Analytics
- Click **Analytics** → **Dashboard**
- Already enabled automatically with Firebase

#### Crashlytics
- Click **Crashlytics** in the left menu
- Click **Enable Crashlytics**
- Wait for initialization (requires app restart)

#### Performance Monitoring
- Click **Performance** in the left menu  
- Click **Get Started**
- Enable Performance Monitoring

### 2. Wait for Data

- **Initial data**: 24-48 hours
- **Crash reports**: Appear immediately after a crash
- **Performance**: First traces after app usage

---

## 📱 Testing the Implementation

### Test Crashlytics

```dart
// Add a test crash button (remove in production)
ElevatedButton(
  onPressed: () {
    throw Exception('Test Crashlytics crash');
  },
  child: Text('Test Crash'),
);
```

### Test Performance

```dart
// Performance is tracked automatically for:
// - App startup time
// - Network requests
// - Screen rendering
// - Custom traces
```

### Test Analytics

```dart
// Analytics events are sent automatically
// Check Firebase Console → Analytics → Events
// Events appear within 24 hours
```

---

## 🚀 Next Steps

### 1. Add More Screen Tracking

Add `trackScreenView()` to all major screens:

```dart
// In each screen's initState()
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(analyticsEventsProvider).trackScreenView('screen_name');
  });
}
```

### 2. Add Error Boundaries

Wrap error-prone operations:

```dart
try {
  await riskyOperation();
} catch (error, stackTrace) {
  await ref.read(analyticsEventsProvider).trackError(
    errorType: 'operation_error',
    errorMessage: error.toString(),
    location: 'WidgetName',
    stackTrace: stackTrace,
  );
  rethrow; // Or handle gracefully
}
```

### 3. Track Critical User Flows

Add tracking to important user journeys:

- User onboarding completion
- First post creation
- First message sent
- First story created
- Profile completion percentage

### 4. Monitor Performance Bottlenecks

Track slow operations:

```dart
final trace = await performanceService.startTrace('image_processing');
await processImage(file);
await performanceService.stopTrace(trace);
```

---

## 📈 Monitoring in Production

### Firebase Console - Analytics
- **Events**: See all tracked events
- **Users**: Active users, retention
- **Funnels**: User journey completion
- **Demographics**: User location, language

### Firebase Console - Crashlytics
- **Crashes**: Stack traces, affected users
- **Non-fatals**: Logged errors
- **Keys**: Custom debugging info
- **Logs**: Breadcrumb trail before crash

### Firebase Console - Performance
- **App start time**: Cold/warm start metrics
- **Network requests**: Latency, success rate
- **Screen rendering**: Frame rate
- **Custom traces**: Your tracked operations

---

## 🎯 Best Practices

### DO ✅
- Track user journeys and conversion funnels
- Log errors with context (custom keys)
- Monitor slow operations (> 1 second)
- Set user properties for segmentation
- Use descriptive event names

### DON'T ❌
- Track PII (Personally Identifiable Information)
- Log passwords or sensitive data
- Create too many unique events (> 500 limit)
- Track every button click
- Forget to test in debug mode first

---

## 🔍 Troubleshooting

### Events not appearing?
- Wait 24-48 hours for first data
- Check Firebase Console → DebugView for real-time testing
- Enable debug mode: `flutter run --dart-define=DEBUG_MODE=true`

### Crashes not reported?
- Ensure Crashlytics is enabled in Firebase Console
- Check network connectivity
- Crashes appear within minutes (not 24 hours like analytics)

### Performance data missing?
- Performance Monitoring must be enabled in Console
- Traces appear after 30 minutes
- Automatic traces (app start) work immediately

---

## 📚 Resources

- [Firebase Performance Documentation](https://firebase.google.com/docs/perf-mon)
- [Firebase Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)
- [Firebase Analytics Documentation](https://firebase.google.com/docs/analytics)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

---

## ✅ Implementation Checklist

- [x] Add dependencies to `pubspec.yaml`
- [x] Configure Android build files
- [x] Initialize services in `main.dart`
- [x] Create service classes
- [x] Add tracking to key screens
- [ ] Enable Crashlytics in Firebase Console
- [ ] Enable Performance Monitoring in Firebase Console
- [ ] Add tracking to remaining screens
- [ ] Test crash reporting
- [ ] Monitor first analytics data (24-48 hours)

---

**Status**: ✅ Core implementation complete. Ready to enable in Firebase Console and add tracking to remaining screens.
