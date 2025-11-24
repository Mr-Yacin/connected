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

  /// Apply dialect filter to a list of users
  /// Returns only users who speak the specified dialect
  List<UserProfile> applyDialectFilter(
    List<UserProfile> users,
    String dialect,
  ) {
    return users.where((user) => user.dialect == dialect).toList();
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

    // Apply dialect filter if specified
    if (filters.dialect != null) {
      filteredUsers = applyDialectFilter(filteredUsers, filters.dialect!);
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

    // Exclude specified user IDs
    if (filters.excludedUserIds.isNotEmpty) {
      filteredUsers = filteredUsers
          .where((user) => !filters.excludedUserIds.contains(user.id))
          .toList();
    }

    return filteredUsers;
  }
}
