import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing viewed users with time-based reset
class ViewedUsersService {
  static const String _viewedUsersKey = 'viewed_users';
  static const String _lastResetKey = 'viewed_users_last_reset';
  static const int _resetHours = 12; // Reset after 12 hours
  static const int _maxViewedUsers = 100; // Max 100 viewed users

  /// Get viewed user IDs
  Future<Set<String>> getViewedUsers() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if reset is needed
    await _checkAndResetIfNeeded(prefs);

    // Get viewed users
    final viewedUsersJson = prefs.getStringList(_viewedUsersKey) ?? [];
    return viewedUsersJson.toSet();
  }

  /// Add a viewed user
  Future<void> addViewedUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if reset is needed
    await _checkAndResetIfNeeded(prefs);

    // Get current viewed users
    var viewedUsers = prefs.getStringList(_viewedUsersKey) ?? [];

    // Add new user if not already viewed
    if (!viewedUsers.contains(userId)) {
      viewedUsers.add(userId);

      // Enforce max limit (remove oldest if needed)
      if (viewedUsers.length > _maxViewedUsers) {
        viewedUsers = viewedUsers.sublist(viewedUsers.length - _maxViewedUsers);
      }

      await prefs.setStringList(_viewedUsersKey, viewedUsers);
    }
  }

  /// Add multiple viewed users
  Future<void> addViewedUsers(Set<String> userIds) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if reset is needed
    await _checkAndResetIfNeeded(prefs);

    // Get current viewed users
    var viewedUsers = prefs.getStringList(_viewedUsersKey) ?? [];
    final viewedSet = viewedUsers.toSet();

    // Add new users
    viewedSet.addAll(userIds);
    var updatedList = viewedSet.toList();

    // Enforce max limit (keep most recent)
    if (updatedList.length > _maxViewedUsers) {
      updatedList = updatedList.sublist(updatedList.length - _maxViewedUsers);
    }

    await prefs.setStringList(_viewedUsersKey, updatedList);
  }

  /// Clear all viewed users
  Future<void> clearViewedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_viewedUsersKey);
    await prefs.setString(_lastResetKey, DateTime.now().toIso8601String());
  }

  /// Check if reset is needed and reset if necessary
  Future<void> _checkAndResetIfNeeded(SharedPreferences prefs) async {
    final lastResetStr = prefs.getString(_lastResetKey);

    if (lastResetStr == null) {
      // First time, set reset timestamp
      await prefs.setString(_lastResetKey, DateTime.now().toIso8601String());
      return;
    }

    final lastReset = DateTime.parse(lastResetStr);
    final now = DateTime.now();
    final hoursSinceReset = now.difference(lastReset).inHours;

    if (hoursSinceReset >= _resetHours) {
      // Reset is needed
      await prefs.remove(_viewedUsersKey);
      await prefs.setString(_lastResetKey, now.toIso8601String());
    }
  }

  /// Get time until next reset
  Future<Duration> getTimeUntilReset() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetStr = prefs.getString(_lastResetKey);

    if (lastResetStr == null) {
      return Duration(hours: _resetHours);
    }

    final lastReset = DateTime.parse(lastResetStr);
    final nextReset = lastReset.add(Duration(hours: _resetHours));
    final now = DateTime.now();

    if (now.isAfter(nextReset)) {
      return Duration.zero;
    }

    return nextReset.difference(now);
  }

  /// Get viewed users count
  Future<int> getViewedUsersCount() async {
    final viewedUsers = await getViewedUsers();
    return viewedUsers.length;
  }

  /// Check if user was viewed
  Future<bool> wasUserViewed(String userId) async {
    final viewedUsers = await getViewedUsers();
    return viewedUsers.contains(userId);
  }
}
