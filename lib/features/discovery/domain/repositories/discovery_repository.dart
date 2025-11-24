import '../../../../core/models/user_profile.dart';
import '../../../../core/models/discovery_filters.dart';

/// Repository interface for discovery operations
abstract class DiscoveryRepository {
  /// Get a random user based on filters
  /// Excludes blocked users and applies all specified filters
  Future<UserProfile?> getRandomUser(String currentUserId, DiscoveryFilters filters);
  
  /// Get a list of filtered users
  /// Returns users matching all specified filters
  Future<List<UserProfile>> getFilteredUsers(String currentUserId, DiscoveryFilters filters);
}
