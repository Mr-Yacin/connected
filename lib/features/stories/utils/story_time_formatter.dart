/// Utility class for formatting story timestamps
/// 
/// Provides consistent time formatting across the stories feature
/// with Arabic language support.
class StoryTimeFormatter {
  /// Formats a DateTime into a human-readable "time ago" string in Arabic
  /// 
  /// Examples:
  /// - Less than 1 minute: "الآن"
  /// - Less than 1 hour: "منذ 5د"
  /// - Less than 24 hours: "منذ 3س"
  /// - 1 day or more: "منذ 2ي"
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
