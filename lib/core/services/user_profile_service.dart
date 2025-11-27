import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../../features/profile/data/repositories/firestore_profile_repository.dart';

/// Centralized service for user profile operations.
/// Provides common profile fetching logic to avoid duplication.
class UserProfileService {
  final FirestoreProfileRepository _profileRepository;

  UserProfileService({
    FirestoreProfileRepository? profileRepository,
  }) : _profileRepository = profileRepository ?? FirestoreProfileRepository();

  /// Fetch multiple user profiles by their IDs.
  /// 
  /// Returns a list of UserProfiles. Silently skips profiles that fail to load.
  /// This is useful for loading follower/following lists where some profiles
  /// might be inaccessible.
  /// 
  /// Parameters:
  /// - [userIds]: List of user IDs to fetch
  Future<List<UserProfile>> fetchMultipleProfiles(List<String> userIds) async {
    final profiles = <UserProfile>[];
    
    for (final userId in userIds) {
      try {
        final profile = await _profileRepository.getProfile(userId);
        profiles.add(profile);
      } catch (e) {
        // Log but don't throw - we want to continue fetching other profiles
        debugPrint('WARNING: Failed to fetch profile for user $userId: $e');
      }
    }
    
    return profiles;
  }

  /// Fetch a single user profile.
  /// Throws an exception if the profile cannot be fetched.
  Future<UserProfile> fetchProfile(String userId) async {
    return await _profileRepository.getProfile(userId);
  }

  /// Check if a profile exists for a user ID.
  Future<bool> profileExists(String userId) async {
    return await _profileRepository.profileExists(userId);
  }

  /// Batch fetch profiles with error handling.
  /// Returns a Map of userId -> UserProfile for successfully fetched profiles.
  /// Failed fetches are omitted from the result.
  Future<Map<String, UserProfile>> batchFetchProfiles(
    List<String> userIds,
  ) async {
    final profiles = <String, UserProfile>{};
    
    await Future.wait(
      userIds.map((userId) async {
        try {
          final profile = await _profileRepository.getProfile(userId);
          profiles[userId] = profile;
        } catch (e) {
          debugPrint('WARNING: Failed to fetch profile for user $userId: $e');
        }
      }),
    );
    
    return profiles;
  }
}
