import '../../../../core/models/user_profile.dart';
import '../../../../core/models/discovery_filters.dart';

/// Service for applying filters to user lists
class FilterService {
  /// Apply country filter to a list of users
  /// Returns only users from the specified country
  List<UserProfile> applyCountryFilter(
    List<UserProfile> users,
    String country,
  ) {
    return users.where((user) => user.country == country).toList();
  }

  /// Apply gender filter to a list of users
  /// Returns only users of the specified gender
  List<UserProfile> applyGenderFilter(
    List<UserProfile> users,
    String gender,
  ) {
    return users.where((user) => user.gender == gender).toList();
  }

  /// Apply last active filter to a list of users
  /// Returns only users who were active within the specified hours
  List<UserProfile> applyLastActiveFilter(
    List<UserProfile> users,
    int hours,
  ) {
    final cutoffTime = DateTime.now().subtract(Duration(hours: hours));
    return users.where((user) => user.lastActive.isAfter(cutoffTime)).toList();
  }

  /// Apply multiple filters to a list of users using AND logic
  /// All specified filters must match for a user to be included
  List<UserProfile> applyMultipleFilters(
    List<UserProfile> users,
    DiscoveryFilters filters,
  ) {
    var filteredUsers = users;

    // Apply country filter if specified
    if (filters.country != null) {
      filteredUsers = applyCountryFilter(filteredUsers, filters.country!);
    }

    // Apply gender filter if specified
    if (filters.gender != null) {
      filteredUsers = applyGenderFilter(filteredUsers, filters.gender!);
    }

    // Apply age range filters if specified
    if (filters.minAge != null) {
      filteredUsers = filteredUsers
          .where((user) => user.age != null && user.age! >= filters.minAge!)
          .toList();
    }

    if (filters.maxAge != null) {
      filteredUsers = filteredUsers
          .where((user) => user.age != null && user.age! <= filters.maxAge!)
          .toList();
    }

    // Apply last active filter if specified
    if (filters.lastActiveWithinHours != null) {
      filteredUsers = applyLastActiveFilter(
        filteredUsers,
        filters.lastActiveWithinHours!,
      );
    }

    // Exclude specified user IDs
    if (filters.excludedUserIds.isNotEmpty) {
      filteredUsers = filteredUsers
          .where((user) => !filters.excludedUserIds.contains(user.id))
          .toList();
    }

    return filteredUsers;
  }
}
