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

/// State for caching multiple story user profiles
class StoryUsersState {
  final Map<String, UserProfile> profiles;
  final bool isLoading;
  final String? error;

  StoryUsersState({
    this.profiles = const {},
    this.isLoading = false,
    this.error,
  });

  StoryUsersState copyWith({
    Map<String, UserProfile>? profiles,
    bool? isLoading,
    String? error,
  }) {
    return StoryUsersState(
      profiles: profiles ?? this.profiles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier to manage multiple story user profiles efficiently
class StoryUsersNotifier extends StateNotifier<StoryUsersState> {
  final ProfileRepository _repository;

  StoryUsersNotifier(this._repository) : super(StoryUsersState());

  /// Load profiles for multiple users at once
  Future<void> loadProfiles(List<String> userIds) async {
    // Filter out already loaded profiles
    final toLoad = userIds
        .where((id) => !state.profiles.containsKey(id))
        .toList();

    if (toLoad.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final Map<String, UserProfile> newProfiles = {};

      // Load profiles in parallel for better performance
      final results = await Future.wait(
        toLoad.map((userId) async {
          try {
            final profile = await _repository.getProfile(userId);
            return MapEntry(userId, profile);
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

      // Merge with existing profiles
      state = state.copyWith(
        profiles: {...state.profiles, ...newProfiles},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Get a single profile from cache
  UserProfile? getProfile(String userId) {
    return state.profiles[userId];
  }

  /// Clear all cached profiles
  void clear() {
    state = StoryUsersState();
  }
}

/// Provider for story users notifier
final storyUsersProvider =
    StateNotifierProvider<StoryUsersNotifier, StoryUsersState>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      return StoryUsersNotifier(repository);
    });
