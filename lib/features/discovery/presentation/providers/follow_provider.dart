import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/follow_repository.dart';

/// Provider for FollowRepository
final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository();
});

/// State for follow operations
class FollowState {
  final Map<String, bool> followingStatus; // userId -> isFollowing
  final bool isLoading;
  final String? error;

  FollowState({
    this.followingStatus = const {},
    this.isLoading = false,
    this.error,
  });

  FollowState copyWith({
    Map<String, bool>? followingStatus,
    bool? isLoading,
    String? error,
  }) {
    return FollowState(
      followingStatus: followingStatus ?? this.followingStatus,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Follow notifier for managing follow state
class FollowNotifier extends StateNotifier<FollowState> {
  final FollowRepository _repository;

  FollowNotifier(this._repository) : super(FollowState());

  /// Follow a user
  Future<void> followUser(String currentUserId, String targetUserId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.followUser(currentUserId, targetUserId);

      // Update state
      final updatedStatus = Map<String, bool>.from(state.followingStatus);
      updatedStatus[targetUserId] = true;

      state = state.copyWith(
        followingStatus: updatedStatus,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.unfollowUser(currentUserId, targetUserId);

      // Update state
      final updatedStatus = Map<String, bool>.from(state.followingStatus);
      updatedStatus[targetUserId] = false;

      state = state.copyWith(
        followingStatus: updatedStatus,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  /// Check if following a user
  Future<void> checkFollowStatus(String currentUserId, String targetUserId) async {
    try {
      final isFollowing = await _repository.isFollowing(currentUserId, targetUserId);

      final updatedStatus = Map<String, bool>.from(state.followingStatus);
      updatedStatus[targetUserId] = isFollowing;

      state = state.copyWith(followingStatus: updatedStatus);
    } catch (e) {
      // Silently fail for status check
    }
  }

  /// Get follow status for a user
  bool isFollowing(String targetUserId) {
    return state.followingStatus[targetUserId] ?? false;
  }
}

/// Provider for FollowNotifier
final followProvider = StateNotifierProvider<FollowNotifier, FollowState>((ref) {
  final repository = ref.watch(followRepositoryProvider);
  return FollowNotifier(repository);
});
