# Stories Feature - Code Cleanup & Organization Recommendations

## Analysis Date
December 2, 2025

## Summary
The stories feature has several areas of code duplication and opportunities for better organization. Below are the key findings and recommendations.

---

## 🔴 Critical Duplications Found

### 1. **`_getTimeAgo()` Function - Duplicated 3 Times**
**Location:**
- `multi_user_story_view_screen.dart` (line 1072)
- `story_card_widget.dart` (line 316)
- `story_view_screen.dart` (line 400)

**Issue:** Same time formatting logic repeated in 3 files with slight variations.

**Recommendation:** Create a shared utility class
```dart
// lib/features/stories/utils/story_time_formatter.dart
class StoryTimeFormatter {
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes}د';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours}س';
    } else {
      return 'منذ ${difference.inDays}ي';
    }
  }
}
```

---

### 2. **Profile Avatar Widget - Duplicated 2+ Times**
**Location:**
- `multi_user_story_view_screen.dart` (in `_buildHeader()`)
- `story_card_widget.dart` (in profile avatar section)

**Issue:** Same circular profile image with border, shadow, and error handling repeated.

**Recommendation:** Create a reusable widget
```dart
// lib/features/stories/presentation/widgets/story_profile_avatar.dart
class StoryProfileAvatar extends StatelessWidget {
  final String? profileImageUrl;
  final double size;
  final double borderWidth;
  
  const StoryProfileAvatar({
    super.key,
    this.profileImageUrl,
    this.size = 40,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: profileImageUrl != null
            ? CachedNetworkImage(
                imageUrl: profileImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.person,
                    color: Colors.grey[600],
                    size: size * 0.6,
                  ),
                ),
              )
            : Container(
                color: Colors.grey[300],
                child: Icon(
                  Icons.person,
                  color: Colors.grey[600],
                  size: size * 0.6,
                ),
              ),
      ),
    );
  }
}
```

---

### 3. **Story Stats Display - Duplicated 3+ Times**
**Location:**
- `multi_user_story_view_screen.dart` (`_buildOwnStoryStats()`)
- `story_card_widget.dart` (in bottom overlay)
- `story_management_sheet.dart` (in subtitle and insights)

**Issue:** Views/Likes/Replies display logic repeated with icons.

**Recommendation:** Create a reusable stats widget
```dart
// lib/features/stories/presentation/widgets/story_stats_row.dart
class StoryStatsRow extends StatelessWidget {
  final int viewCount;
  final int likeCount;
  final int replyCount;
  final double iconSize;
  final double fontSize;
  final Color color;
  final bool showLabels;
  
  const StoryStatsRow({
    super.key,
    required this.viewCount,
    required this.likeCount,
    required this.replyCount,
    this.iconSize = 14,
    this.fontSize = 11,
    this.color = Colors.white,
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStat(Icons.visibility, viewCount, showLabels ? 'مشاهدة' : null),
        const SizedBox(width: 12),
        _buildStat(Icons.favorite, likeCount, showLabels ? 'إعجاب' : null),
        if (replyCount > 0) ...[
          const SizedBox(width: 12),
          _buildStat(Icons.message, replyCount, showLabels ? 'رد' : null),
        ],
      ],
    );
  }
  
  Widget _buildStat(IconData icon, int count, String? label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: iconSize),
        const SizedBox(width: 4),
        Text(
          label != null ? '$count $label' : '$count',
          style: TextStyle(color: color, fontSize: fontSize),
        ),
      ],
    );
  }
}
```

---

### 4. **Story Insights Dialog - Duplicated Logic**
**Location:**
- `multi_user_story_view_screen.dart` (`_showStoryInsights()` + `_buildInsightRow()`)
- `story_management_sheet.dart` (`_showInsightsDialog()` + `_InsightRow`)

**Issue:** Same insights display with different styling.

**Recommendation:** Consolidate into `story_management_sheet.dart` and remove from `multi_user_story_view_screen.dart`. The management sheet already handles this better.

---

### 5. **Message Input Bar - Similar Patterns**
**Location:**
- `multi_user_story_view_screen.dart` (`_buildMessageAndLikeBar()` and `_buildQuickReactions()`)

**Issue:** Complex input bar with reactions could be extracted.

**Recommendation:** Create a dedicated widget
```dart
// lib/features/stories/presentation/widgets/story_reply_bar.dart
class StoryReplyBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onLike;
  final bool isLiked;
  final bool showQuickReactions;
  final Function(String)? onQuickReaction;
  
  // ... implementation
}
```

---

## 🟡 Organization Improvements

### 1. **Create Utils Directory**
```
lib/features/stories/utils/
  ├── story_time_formatter.dart
  ├── story_constants.dart (for durations, sizes, etc.)
  └── story_helpers.dart (for common helper functions)
```

### 2. **Create Common Widgets Directory**
```
lib/features/stories/presentation/widgets/common/
  ├── story_profile_avatar.dart
  ├── story_stats_row.dart
  ├── story_reply_bar.dart
  └── story_gradient_overlay.dart
```

### 3. **Consolidate Gradient Overlays**
Multiple files use similar gradient overlays:
- Top gradient (black to transparent)
- Bottom gradient (transparent to black)

Create a shared widget:
```dart
// lib/features/stories/presentation/widgets/common/story_gradient_overlay.dart
class StoryGradientOverlay extends StatelessWidget {
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final Widget child;
  
  const StoryGradientOverlay.top({required this.child})
      : begin = Alignment.topCenter,
        end = Alignment.bottomCenter;
        
  const StoryGradientOverlay.bottom({required this.child})
      : begin = Alignment.bottomCenter,
        end = Alignment.topCenter;
}
```

---

## 🟢 Additional Recommendations

### 1. **Constants File**
Create a constants file for magic numbers:
```dart
// lib/features/stories/utils/story_constants.dart
class StoryConstants {
  static const Duration storyDuration = Duration(seconds: 5);
  static const double profileAvatarSize = 40.0;
  static const double profileAvatarBorder = 2.0;
  static const double storyProgressHeight = 3.0;
  static const int gridCrossAxisCount = 3;
  static const double gridAspectRatio = 0.7;
}
```

### 2. **Theme Extensions**
Create story-specific theme extensions:
```dart
// lib/features/stories/presentation/theme/story_theme.dart
class StoryTheme {
  static BoxDecoration circularAvatar({required double size}) { ... }
  static TextStyle timeAgoStyle() { ... }
  static LinearGradient topGradient() { ... }
  static LinearGradient bottomGradient() { ... }
}
```

### 3. **Separate Concerns in multi_user_story_view_screen.dart**
This file is 1346 lines - too large. Consider splitting:
- Story navigation logic → Mixin or separate class
- UI building methods → Separate widget files
- Story management → Use existing `story_management_sheet.dart`

---

## 📊 Impact Summary

### Before Cleanup:
- **3 duplicate** `_getTimeAgo()` functions
- **2+ duplicate** profile avatar widgets
- **3+ duplicate** story stats displays
- **2 duplicate** insights dialogs
- **1346 lines** in main screen file

### After Cleanup:
- **1 shared** time formatter utility
- **1 reusable** profile avatar widget
- **1 reusable** stats row widget
- **1 consolidated** insights dialog
- **~800-900 lines** in main screen (estimated)
- **Better maintainability** and consistency

---

## 🎯 Priority Order

1. **High Priority:**
   - Extract `_getTimeAgo()` to utility (quick win, used everywhere)
   - Create `StoryProfileAvatar` widget (visual consistency)
   - Create `StoryStatsRow` widget (used in 3+ places)

2. **Medium Priority:**
   - Remove duplicate insights dialog from `multi_user_story_view_screen.dart`
   - Create constants file
   - Extract gradient overlays

3. **Low Priority:**
   - Create theme extensions
   - Split large screen file into smaller components
   - Create reply bar widget

---

## 🚀 Next Steps

1. Create the utils directory and `StoryTimeFormatter`
2. Create common widgets directory
3. Implement `StoryProfileAvatar` widget
4. Implement `StoryStatsRow` widget
5. Update all files to use new shared components
6. Remove duplicate code
7. Test thoroughly to ensure no regressions

---

## Notes
- All changes should maintain RTL (Arabic) support
- Ensure accessibility is preserved
- Keep existing functionality intact
- Add tests for new utility functions
