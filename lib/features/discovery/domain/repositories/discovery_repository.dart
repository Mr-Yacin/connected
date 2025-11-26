import '../../../../core/models/user_profile.dart';
import '../../../../core/models/discovery_filters.dart';

/// Result class for paginated user queries
class PaginatedUsers {
  final List<UserProfile> users;
  final bool hasMore;
  final DiscoveryFilters updatedFilters;

  PaginatedUsers({
    required this.users,
    required this.hasMore,
    required this.updatedFilters,
  });
}

/// Repository interface for discovery operations
abstract class DiscoveryRepository {
  /// Get a random user based on filters
  /// Excludes blocked users and applies all specified filters
  Future<UserProfile?> getRandomUser(String currentUserId, DiscoveryFilters filters);
  
  /// Get a list of filtered users (deprecated - use getFilteredUsersPaginated)
  /// Returns users matching all specified filters
  @Deprecated('Use getFilteredUsersPaginated for better performance')
  Future<List<UserProfile>> getFilteredUsers(String currentUserId, DiscoveryFilters filters);
  
  /// Get a paginated list of filtered users
  /// Returns users matching all specified filters with pagination support
  Future<PaginatedUsers> getFilteredUsersPaginated(String currentUserId, DiscoveryFilters filters);
}
