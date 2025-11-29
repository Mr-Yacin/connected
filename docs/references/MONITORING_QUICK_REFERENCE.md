# 🚀 Firebase Monitoring Quick Reference

## Import
```dart
import 'package:social_connect_app/services/analytics_events.dart';
```

## Basic Usage

### Screen Tracking
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(analyticsEventsProvider).trackScreenView('screen_name');
  });
}
```

### Event Tracking
```dart
final analytics = ref.read(analyticsEventsProvider);

// User actions
await analytics.trackPostCreated(postId: '...', contentType: 'text');
await analytics.trackUserFollowed(followedUserId: '...');
await analytics.trackMessageSent(chatId: '...', messageType: 'text');

// Navigation
await analytics.trackTabChanged(fromTab: 'home', toTab: 'profile');
```

### Error Tracking
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
}
```

### Performance Tracking
```dart
final performance = ref.read(performanceServiceProvider);

await performance.trackPerformance('operation_name', () async {
  return await yourAsyncOperation();
});
```

## Common Events

| Action | Method |
|--------|--------|
| User signs up | `trackSignUp(method, userId)` |
| User logs in | `trackLogin(method, userId)` |
| Post created | `trackPostCreated(postId, contentType, ...)` |
| Post liked | `trackPostLiked(postId, authorId)` |
| Story viewed | `trackStoryViewed(storyId, authorId)` |
| Message sent | `trackMessageSent(chatId, messageType)` |
| User followed | `trackUserFollowed(followedUserId)` |
| Search performed | `trackSearch(term, count, type)` |
| Image uploaded | `trackImageUpload(location, size, duration)` |
| Screen viewed | `trackScreenView(screenName)` |
| Error occurred | `trackError(type, message, location, stack)` |

## Firebase Console

- **Analytics**: https://console.firebase.google.com → Analytics
- **Crashlytics**: https://console.firebase.google.com → Crashlytics
- **Performance**: https://console.firebase.google.com → Performance

## Files

- Service: `lib/services/analytics_events.dart`
- Guide: `lib/services/monitoring_integration_guide.dart`
- Docs: `docs/FIREBASE_MONITORING_SETUP.md`
- Summary: `MONITORING_IMPLEMENTATION_SUMMARY.md`
