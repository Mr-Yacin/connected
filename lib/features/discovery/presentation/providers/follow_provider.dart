import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
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
    try {
      debugPrint('DEBUG: Following user: $targetUserId');
      
      // Optimistically update state
      final updatedStatus = Map<String, bool>.from(state.followingStatus);
      updatedStatus[targetUserId] = true;
      state = state.copyWith(followingStatus: updatedStatus, error: null);
      
      await _repository.followUser(currentUserId, targetUserId);

      // Verify the follow status from Firestore after the operation
      final isFollowing = await _repository.isFollowing(currentUserId, targetUserId);
      updatedStatus[targetUserId] = isFollowing;
      state = state.copyWith(followingStatus: updatedStatus);

      debugPrint('DEBUG: Successfully followed user, verified status: $isFollowing');
    } catch (e) {
      debugPrint('ERROR: Failed to follow user: $e');
      
      // Revert optimistic update on error
      final updatedStatus = Map<String, bool>.from(state.followingStatus);
      final actualStatus = await _repository.isFollowing(currentUserId, targetUserId);
      updatedStatus[targetUserId] = actualStatus;
      
      state = state.copyWith(
        followingStatus: updatedStatus,
        error: 'فشل في المتابعة: $e',
      );
      rethrow;
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      debugPrint('DEBUG: Unfollowing user: $targetUserId');
      
      // Optimistically update state
      final updatedStatus = Map<String, bool>.from(state.followingStatus);
      updatedStatus[targetUserId] = false;
      state = state.copyWith(followingStatus: updatedStatus, error: null);
      
      await _repository.unfollowUser(currentUserId, targetUserId);

      // Verify the follow status from Firestore after the operation
      final isFollowing = await _repository.isFollowing(currentUserId, targetUserId);
      updatedStatus[targetUserId] = isFollowing;
      state = state.copyWith(followingStatus: updatedStatus);

      debugPrint('DEBUG: Successfully unfollowed user, verified status: $isFollowing');
    } catch (e) {
      debugPrint('ERROR: Failed to unfollow user: $e');
      
      // Revert optimistic update on error
      final updatedStatus = Map<String, bool>.from(state.followingStatus);
      final actualStatus = await _repository.isFollowing(currentUserId, targetUserId);
      updatedStatus[targetUserId] = actualStatus;
      
      state = state.copyWith(
        followingStatus: updatedStatus,
        error: 'فشل في إلغاء المتابعة: $e',
      );
      rethrow;
    }
  }

  /// Toggle follow status
  Future<void> toggleFollow(String currentUserId, String targetUserId) async {
    final isFollowing = state.followingStatus[targetUserId] ?? false;
    
    if (isFollowing) {
      await unfollowUser(currentUserId, targetUserId);
    } else {
      await followUser(currentUserId, targetUserId);
    }
  }

  /// Check if following a user
  Future<bool> checkFollowStatus(String currentUserId, String targetUserId) async {
    try {
      // Check cache first
      if (state.followingStatus.containsKey(targetUserId)) {
        return state.followingStatus[targetUserId]!;
      }

      // Fetch from repository
      final isFollowing = await _repository.isFollowing(currentUserId, targetUserId);

      // Update cache
      final updatedStatus = Map<String, bool>.from(state.followingStatus);
      updatedStatus[targetUserId] = isFollowing;

      state = state.copyWith(followingStatus: updatedStatus);

      return isFollowing;
    } catch (e) {
      debugPrint('ERROR: Failed to check follow status: $e');
      return false;
    }
  }

  /// Get follow status for a user (from cache)
  bool isFollowing(String targetUserId) {
    return state.followingStatus[targetUserId] ?? false;
  }

  /// Clear cache
  void clearCache() {
    state = FollowState();
  }
}

/// Provider for FollowNotifier
final followProvider = StateNotifierProvider<FollowNotifier, FollowState>((ref) {
  final repository = ref.watch(followRepositoryProvider);
  return FollowNotifier(repository);
});
