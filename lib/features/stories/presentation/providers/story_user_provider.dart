import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// Provider to get user profile for a story creator
/// This is used to display names and profile images in the story bar
final storyUserProfileProvider = FutureProvider.family<UserProfile?, String>((
  ref,
  userId,
) async {
  try {
    final repository = ref.watch(profileRepositoryProvider);
    final profile = await repository.getProfile(userId);
    return profile;
  } catch (e) {
    // Return null if profile cannot be loaded
    // This allows graceful degradation to showing user ID
    return null;
  }
});

/// Cache entry with expiration timestamp
class _CachedProfile {
  final UserProfile profile;
  final DateTime cachedAt;

  _CachedProfile(this.profile, this.cachedAt);

  bool isExpired() {
    return DateTime.now().difference(cachedAt).inMinutes >= 5;
  }
}

/// State for caching multiple story user profiles
class StoryUsersState {
  final Map<String, _CachedProfile> _profileCache;
  final bool isLoading;
  final String? error;

  StoryUsersState({
    // ignore: library_private_types_in_public_api
    Map<String, _CachedProfile>? profileCache,
    this.isLoading = false,
    this.error,
  }) : _profileCache = profileCache ?? {};

  /// Get profiles that are not expired
  Map<String, UserProfile> get profiles {
    return Map.fromEntries(
      _profileCache.entries
          .where((entry) => !entry.value.isExpired())
          .map((entry) => MapEntry(entry.key, entry.value.profile)),
    );
  }

  StoryUsersState copyWith({
    // ignore: library_private_types_in_public_api
    Map<String, _CachedProfile>? profileCache,
    bool? isLoading,
    String? error,
  }) {
    return StoryUsersState(
      profileCache: profileCache ?? _profileCache,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier to manage multiple story user profiles efficiently
class StoryUsersNotifier extends StateNotifier<StoryUsersState> {
  final ProfileRepository _repository;

  StoryUsersNotifier(this._repository) : super(StoryUsersState());

  /// Load profiles in batches of 10 with caching and expiration
  Future<void> loadProfilesBatch(List<String> userIds) async {
    // Filter out already-cached profiles that are not expired
    final now = DateTime.now();
    final uncachedIds = userIds.where((id) {
      final cached = state._profileCache[id];
      return cached == null || cached.isExpired();
    }).toList();

    if (uncachedIds.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final Map<String, _CachedProfile> newProfiles = {};

      // Load in batches of 10
      const batchSize = 10;
      for (var i = 0; i < uncachedIds.length; i += batchSize) {
        final batch = uncachedIds.skip(i).take(batchSize).toList();
        
        // Load batch in parallel
        final results = await Future.wait(
          batch.map((userId) async {
            try {
              final profile = await _repository.getProfile(userId);
              return MapEntry(
                userId,
                _CachedProfile(profile, now),
              );
            } catch (e) {
              // Skip profiles that fail to load
              return null;
            }
          }),
        );

        // Add successfully loaded profiles to map
        for (final entry in results) {
          if (entry != null) {
            newProfiles[entry.key] = entry.value;
          }
        }
      }

      // Merge with existing profiles
      state = state.copyWith(
        profileCache: {...state._profileCache, ...newProfiles},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load profiles for multiple users at once (legacy method, now uses batch loading)
  Future<void> loadProfiles(List<String> userIds) async {
    return loadProfilesBatch(userIds);
  }

  /// Get a single profile from cache
  UserProfile? getProfile(String userId) {
    return state.profiles[userId];
  }

  /// Clear all cached profiles
  void clear() {
    state = StoryUsersState();
  }

  /// Clear expired profiles from cache
  void clearExpired() {
    final validProfiles = Map<String, _CachedProfile>.fromEntries(
      state._profileCache.entries.where((entry) => !entry.value.isExpired()),
    );
    state = state.copyWith(profileCache: validProfiles);
  }
}

/// Provider for story users notifier
final storyUsersProvider =
    StateNotifierProvider<StoryUsersNotifier, StoryUsersState>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      return StoryUsersNotifier(repository);
    });
