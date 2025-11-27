import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/models/like.dart';
import '../../data/repositories/firestore_like_repository.dart';
import '../../domain/repositories/like_repository.dart';
import '../../../profile/data/repositories/firestore_profile_repository.dart';

/// Provider for LikeRepository
final likeRepositoryProvider = Provider<LikeRepository>((ref) {
  return FirestoreLikeRepository();
});

/// State for like management
class LikeState {
  final bool isLoading;
  final String? error;
  final Map<String, bool> likedUsers; // userId -> hasLiked
  final List<UserProfile> likedByUsers; // Users who liked current user
  final int likeCount;

  LikeState({
    this.isLoading = false,
    this.error,
    this.likedUsers = const {},
    this.likedByUsers = const [],
    this.likeCount = 0,
  });

  LikeState copyWith({
    bool? isLoading,
    String? error,
    Map<String, bool>? likedUsers,
    List<UserProfile>? likedByUsers,
    int? likeCount,
  }) {
    return LikeState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      likedUsers: likedUsers ?? this.likedUsers,
      likedByUsers: likedByUsers ?? this.likedByUsers,
      likeCount: likeCount ?? this.likeCount,
    );
  }
}

/// Provider for managing likes
class LikeNotifier extends StateNotifier<LikeState> {
  final LikeRepository _repository;
  final FirestoreProfileRepository _profileRepository;

  LikeNotifier(this._repository, this._profileRepository) : super(LikeState());

  /// Like a user
  Future<void> likeUser(String fromUserId, String toUserId) async {
    try {
      debugPrint('DEBUG: Liking user: $toUserId');
      
      // Optimistically update state
      final updatedLikedUsers = Map<String, bool>.from(state.likedUsers);
      updatedLikedUsers[toUserId] = true;
      state = state.copyWith(likedUsers: updatedLikedUsers, error: null);
      
      await _repository.likeUser(fromUserId, toUserId);

      // Verify the like status from Firestore after the operation
      final hasLiked = await _repository.hasLiked(fromUserId, toUserId);
      updatedLikedUsers[toUserId] = hasLiked;
      state = state.copyWith(likedUsers: updatedLikedUsers);

      debugPrint('DEBUG: Successfully liked user, verified status: $hasLiked');
    } catch (e) {
      debugPrint('ERROR: Failed to like user: $e');
      
      // Revert optimistic update on error
      final updatedLikedUsers = Map<String, bool>.from(state.likedUsers);
      final actualStatus = await _repository.hasLiked(fromUserId, toUserId);
      updatedLikedUsers[toUserId] = actualStatus;
      
      state = state.copyWith(
        likedUsers: updatedLikedUsers,
        error: 'فشل في الإعجاب: $e',
      );
      rethrow;
    }
  }

  /// Unlike a user
  Future<void> unlikeUser(String fromUserId, String toUserId) async {
    try {
      debugPrint('DEBUG: Unliking user: $toUserId');
      
      // Optimistically update state
      final updatedLikedUsers = Map<String, bool>.from(state.likedUsers);
      updatedLikedUsers[toUserId] = false;
      state = state.copyWith(likedUsers: updatedLikedUsers, error: null);
      
      await _repository.unlikeUser(fromUserId, toUserId);

      // Verify the like status from Firestore after the operation
      final hasLiked = await _repository.hasLiked(fromUserId, toUserId);
      updatedLikedUsers[toUserId] = hasLiked;
      state = state.copyWith(likedUsers: updatedLikedUsers);

      debugPrint('DEBUG: Successfully unliked user, verified status: $hasLiked');
    } catch (e) {
      debugPrint('ERROR: Failed to unlike user: $e');
      
      // Revert optimistic update on error
      final updatedLikedUsers = Map<String, bool>.from(state.likedUsers);
      final actualStatus = await _repository.hasLiked(fromUserId, toUserId);
      updatedLikedUsers[toUserId] = actualStatus;
      
      state = state.copyWith(
        likedUsers: updatedLikedUsers,
        error: 'فشل في إلغاء الإعجاب: $e',
      );
      rethrow;
    }
  }

  /// Toggle like status
  Future<void> toggleLike(String fromUserId, String toUserId) async {
    final hasLiked = state.likedUsers[toUserId] ?? false;
    
    if (hasLiked) {
      await unlikeUser(fromUserId, toUserId);
    } else {
      await likeUser(fromUserId, toUserId);
    }
  }

  /// Check if user has liked another user
  Future<bool> checkIfLiked(String fromUserId, String toUserId) async {
    try {
      // Check cache first
      if (state.likedUsers.containsKey(toUserId)) {
        return state.likedUsers[toUserId]!;
      }

      // Fetch from repository
      final hasLiked = await _repository.hasLiked(fromUserId, toUserId);

      // Update cache
      final updatedLikedUsers = Map<String, bool>.from(state.likedUsers);
      updatedLikedUsers[toUserId] = hasLiked;

      state = state.copyWith(likedUsers: updatedLikedUsers);

      return hasLiked;
    } catch (e) {
      debugPrint('ERROR: Failed to check like status: $e');
      return false;
    }
  }

  /// Load users who liked the current user
  Future<void> loadLikedByUsers(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final likes = await _repository.getUserLikes(userId);
      
      // Fetch user profiles for users who liked
      final userProfiles = <UserProfile>[];
      for (final like in likes) {
        try {
          final profile = await _profileRepository.getProfile(like.fromUserId);
          userProfiles.add(profile);
        } catch (e) {
          debugPrint('ERROR: Failed to load profile for ${like.fromUserId}: $e');
        }
      }

      state = state.copyWith(
        isLoading: false,
        likedByUsers: userProfiles,
        likeCount: likes.length,
        error: null,
      );
    } catch (e) {
      debugPrint('ERROR: Failed to load liked by users: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في تحميل المعجبين: $e',
      );
    }
  }

  /// Get likes for a user (returns raw Like objects)
  Future<List<Like>> getLikes(String userId) async {
    return await _repository.getUserLikes(userId);
  }

  /// Clear cache
  void clearCache() {
    state = LikeState();
  }
}

/// Provider for like state management
final likeProvider = StateNotifierProvider<LikeNotifier, LikeState>((ref) {
  final repository = ref.watch(likeRepositoryProvider);
  final profileRepository = FirestoreProfileRepository();
  return LikeNotifier(repository, profileRepository);
});
