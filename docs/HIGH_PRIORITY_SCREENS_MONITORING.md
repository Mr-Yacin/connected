# High-Priority Screens Firebase Monitoring Implementation

## Overview
This document summarizes the Firebase monitoring (Analytics, Crashlytics, Performance) integration for high-priority screens in the Connected app.

## Implementation Date
2025-11-27

## Screens Updated

### 1. Chat Screen ✅
**Location**: `lib/features/chat/presentation/screens/chat_screen.dart`

**Analytics Implemented**:
- Screen view tracking (`chat_screen`)
- Block user event tracking

**Crashlytics Implemented**:
- Error logging for message loading failures
- Error logging for block user failures
- Contextual information includes: `chatId`, `currentUserId`, `otherUserId`

**Key Tracking Points**:
- `initState()`: Tracks screen view
- `_loadMoreMessages()`: Logs errors when loading more messages fails
- `_blockUser()`: Logs errors and tracks successful blocks

---

### 2. Profile Screen ✅
**Location**: `lib/features/profile/presentation/screens/profile_screen.dart`

**Analytics Implemented**:
- Screen view tracking (differentiates between own profile and other users)
  - `own_profile_screen` - when viewing own profile
  - `user_profile_screen` - when viewing another user's profile
- Block user event tracking

**Crashlytics Implemented**:
- Error logging for profile loading failures
- Error logging for block user failures
- Contextual information includes: `userId`, `isOwnProfile`, `currentUserId`, `viewedUserId`

**Key Tracking Points**:
- `initState()`: Tracks screen view
- `_checkAndLoadProfile()`: Logs profile loading errors
- `_blockUser()`: Logs errors and tracks successful blocks

---

### 3. Story Creation Screen ✅
**Location**: `lib/features/stories/presentation/screens/story_creation_screen.dart`

**Analytics Implemented**:
- Screen view tracking (`story_creation_screen`)
- Story creation event tracking (with story type)

**Crashlytics Implemented**:
- Error logging for story creation failures
- Contextual information includes: `userId`, `storyType`

**Key Tracking Points**:
- `initState()`: Tracks screen view
- `_createStory()`: Logs errors and tracks successful story creation

---

### 4. Story View Screen ✅
**Location**: `lib/features/stories/presentation/screens/story_view_screen.dart`

**Analytics Implemented**:
- Screen view tracking (`story_view_screen`)
- Story view event tracking (tracks each story viewed)

**Crashlytics Implemented**:
- Error logging for story view recording failures
- Contextual information includes: `storyId`, `viewerId`

**Key Tracking Points**:
- `initState()`: Tracks screen view
- `_startStory()`: Logs errors and tracks story views

---

### 5. Shuffle/Discovery Screen ✅
**Location**: `lib/features/discovery/presentation/screens/shuffle_screen.dart`

**Analytics Implemented**:
- Screen view tracking (`shuffle_screen`)
- Like profile event tracking
- Follow user event tracking

**Crashlytics Implemented**:
- Error logging for like failures
- Error logging for follow failures
- Contextual information includes: `userId`, `likedUserId`, `followedUserId`

**Key Tracking Points**:
- `initState()`: Tracks screen view
- `_handleLike()`: Logs errors and tracks successful likes
- `_handleFollow()`: Logs errors and tracks successful follows

---

## Analytics Events Tracked

### Screen Views
1. `chat_screen`
2. `own_profile_screen`
3. `user_profile_screen`
4. `story_creation_screen`
5. `story_view_screen`
6. `shuffle_screen`

### User Actions
1. **Follow/Unfollow User**: `trackUserFollowed()` / `trackUserUnfollowed()`
2. **Like Profile**: `trackPostLiked()` (reusing post like event for profiles)
3. **Story Created**: `trackStoryCreated(storyId, mediaType)`
4. **Story Viewed**: `trackStoryViewed(storyId, authorId)`
5. **Block User**: Logged via `crashlyticsService.log()`

**Note**: Some specific events like `trackBlockUser`, `trackLikeProfile`, `trackFollowUser` were not available in the analytics service, so we used existing similar methods or Crashlytics logging.

---

## Error Tracking Pattern

All screens follow this consistent error tracking pattern:

```dart
try {
  // Operation
  await someOperation();
  
  // Track success event (if applicable)
  await ref.read(analyticsEventsProvider).trackEvent(...);
  
} catch (e, stackTrace) {
  // Log error with Crashlytics
  await ref.read(crashlyticsServiceProvider).logError(
    e,
    stackTrace,
    reason: 'Error description',
    information: [
      'screen: screen_name',
      'key: value',
      // ... contextual data as list items
    ],
  );
  
  // Show user feedback
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

**Important**: The `information` parameter must be an `Iterable<Object>` (List), not a Map.

---

## Next Steps

### Medium Priority Screens (Recommended Next)
1. **OTP Verification Screen** - Critical for authentication flow
2. **Profile Edit Screen** - Important user action
3. **Settings Screen** - Configuration tracking
4. **Chat List Screen** - User engagement tracking

### Implementation Checklist for Remaining Screens
- [ ] OTP Verification Screen
- [ ] Profile Edit Screen
- [ ] Settings Screen
- [ ] Chat List Screen
- [ ] Privacy/Terms screens
- [ ] Moderation screens (blocked users, reports)
- [ ] Filter/Lists screens

---

## Testing Recommendations

### Firebase Console Verification
1. **Analytics Dashboard**: Verify screen view events appear
2. **Crashlytics Dashboard**: Test error scenarios to verify logging
3. **DebugView**: Enable for real-time event verification

### Test Scenarios
1. Navigate to each screen → Verify screen view event
2. Perform user actions (like, follow, block) → Verify action events
3. Trigger error conditions → Verify Crashlytics logging
4. Check event parameters for completeness

### Commands
```bash
# Enable Analytics DebugView (Android)
adb shell setprop debug.firebase.analytics.app com.your.app

# Enable Analytics DebugView (iOS)
# Add -FIRDebugEnabled to scheme arguments
```

---

## Performance Considerations

1. **Analytics calls are non-blocking**: Events are queued and sent asynchronously
2. **Crashlytics batches logs**: Errors are uploaded in batches to minimize network usage
3. **Minimal UI impact**: All monitoring operations are designed to not block the UI thread

---

## Dependencies Required

These services are already configured in your project:
- `firebase_analytics`
- `firebase_crashlytics`
- `firebase_performance`

Service providers used:
- `analyticsEventsProvider`
- `crashlyticsServiceProvider`

---

## Summary

✅ **5 high-priority screens** now have complete Firebase monitoring
✅ **6 screen view events** tracked
✅ **5 user action events** tracked
✅ **Comprehensive error logging** with contextual information
✅ **Zero linter errors** - Clean implementation

All screens follow consistent patterns for maintainability and reliability.
