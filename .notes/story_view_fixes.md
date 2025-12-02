# Story View Screen Fixes

## Issues Fixed

### 1. ✅ Story Content Hidden Under Navigation Bar
**Problem**: The viewer count and other bottom elements were being obscured by the bottom navigation bar.

**Solution**:
- Wrapped the entire screen in `SafeArea` with `bottom: false` to preserve top insets
- Updated the viewer count position from `bottom: 20` to `bottom: MediaQuery.of(context).padding.bottom + 80`
- Added 80px extra padding to account for the navigation bar height

**Code Changes**:
```dart
// Before
Positioned(
  bottom: 20,
  ...
)

// After  
Positioned(
  bottom: MediaQuery.of(context).padding.bottom + 80, // Account for navbar
  ...
)
```

### 2. ✅ No Delete Option for Own Stories
**Problem**: Users couldn't delete their own stories.

**Solution**:
- Added a `_deleteStory()` method with confirmation dialog
- Added a delete button (trash icon) in the header for own stories only
- Implemented smart navigation after deletion:
  - If only one story: closes the viewer
  - If multiple stories: moves to next story
  - If deleting last story: closes the viewer

**Features**:
- ✅ Confirmation dialog before deletion (Arabic text)
- ✅ Success/error feedback with SnackBar
- ✅ Calls `storyCreationProvider.deleteStory()` to remove from Firestore
- ✅ Delete button only visible for own stories (`story.userId == widget.currentUserId`)

**UI Updates**:
```dart
// Delete button added to header (only for own stories)
if (story.userId == widget.currentUserId)
  IconButton(
    icon: const Icon(Icons.delete, color: Colors.white),
    onPressed: _deleteStory,
    tooltip: 'حذف القصة',
  ),
```

## User Experience Improvements

### Before:
- ❌ Viewer count hidden under navbar
- ❌ No way to delete stories
- ❌ Content could overlap with system UI

### After:
- ✅ All content visible and above navigation bar
- ✅ Easy one-tap story deletion with confirmation
- ✅ Proper spacing from bottom edge
- ✅ Smart navigation after deletion
- ✅ Clear feedback messages in Arabic

## Technical Details

### SafeArea Implementation
```dart
Scaffold(
  body: SafeArea(
    bottom: false, // We handle bottom padding manually
    child: GestureDetector(
      // ... story viewer content
    ),
  ),
)
```

**Why `bottom: false`?**
- We need custom bottom padding to account for the navigation bar
- Using `bottom: true` would add default padding that's not enough
- Manual calculation gives us precise control

### Delete Flow
1. User taps delete icon
2. Confirmation dialog appears (Arabic)
3. If confirmed:
   - Calls Firestore to delete story
   - Shows success message
   - Navigates appropriately based on story count
4. If error:
   - Shows error message with details
   - Stays on current story

### Navigation Logic After Delete
```dart
if (widget.stories.length == 1) {
  Navigator.pop(context); // Only story, close viewer
} else if (_currentIndex >= widget.stories.length - 1) {
  Navigator.pop(context); // Was last story, close viewer
} else {
  _nextStory(); // Move to next story
}
```

## Testing Checklist

- [x] Verify viewer count is visible above navbar
- [x] Test delete button appears only for own stories
- [x] Confirm deletion dialog shows correct Arabic text
- [x] Test deleting single story (should close viewer)
- [x] Test deleting first of multiple stories (should show next)
- [x] Test deleting last of multiple stories (should close)
- [x] Verify error handling for failed deletion
- [x] Check SafeArea works on different device sizes

## Files Modified

1. `lib/features/stories/presentation/screens/story_view_screen.dart`
   - Added `_deleteStory()` method
   - Added delete button to header
   - Wrapped body in SafeArea
   - Updated viewer count positioning
