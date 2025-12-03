import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/models/story.dart';
import '../../../../core/models/enums.dart';
import '../../data/repositories/firestore_story_repository.dart';
import '../../data/services/story_expiration_service.dart';
import '../../domain/repositories/story_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../discovery/presentation/providers/follow_provider.dart';
import '../../../../services/media/image_compression_service.dart';
import '../../../../services/media/video_compression_service.dart';

/// Provider for StoryRepository
final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return FirestoreStoryRepository();
});

/// Provider for StoryExpirationService
final storyExpirationServiceProvider = Provider<StoryExpirationService>((ref) {
  final repository = ref.watch(storyRepositoryProvider);
  final service = StoryExpirationService(repository);

  // Start the service when created
  service.start();

  // Cleanup when disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for active stories stream with auth state validation
final activeStoriesProvider = StreamProvider<List<Story>>((ref) {
  // ✅ Watch auth state to ensure user is authenticated
  final authState = ref.watch(currentUserProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        // Return empty stream when no authenticated user
        return Stream.value([]);
      }
      final repository = ref.watch(storyRepositoryProvider);
      return repository.getActiveStories();
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// State for paginated stories
class PaginatedStoriesState {
  final List<Story> stories;
  final bool isLoadingMore;
  final bool hasMore;
  final DateTime? lastStoryCreatedAt;
  final String? error;

  PaginatedStoriesState({
    this.stories = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastStoryCreatedAt,
    this.error,
  });

  PaginatedStoriesState copyWith({
    List<Story>? stories,
    bool? isLoadingMore,
    bool? hasMore,
    DateTime? lastStoryCreatedAt,
    String? error,
  }) {
    return PaginatedStoriesState(
      stories: stories ?? this.stories,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastStoryCreatedAt: lastStoryCreatedAt ?? this.lastStoryCreatedAt,
      error: error,
    );
  }
}

/// Notifier for paginated stories
class PaginatedStoriesNotifier extends StateNotifier<PaginatedStoriesState> {
  final StoryRepository _repository;
  static const int _pageSize = 20;

  PaginatedStoriesNotifier(this._repository) : super(PaginatedStoriesState());

  /// Load initial stories
  Future<void> loadInitialStories() async {
    state = PaginatedStoriesState(
      stories: [],
      isLoadingMore: false,
      hasMore: true,
      lastStoryCreatedAt: null,
    );

    await loadMoreStories();
  }

  /// Load more stories (pagination)
  Future<void> loadMoreStories() async {
    // Don't load if already loading or no more items
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      // Get paginated stories stream (we'll take first emission)
      final storiesStream = _repository.getActiveStoriesPaginated(
        limit: _pageSize,
        lastStoryCreatedAt: state.lastStoryCreatedAt,
      );

      // Listen to first emission
      final newStories = await storiesStream.first;

      // Determine if there are more stories
      final hasMore = newStories.length >= _pageSize;

      // Get last story's createdAt for next pagination
      DateTime? lastCreatedAt = state.lastStoryCreatedAt;
      if (newStories.isNotEmpty) {
        lastCreatedAt = newStories.last.createdAt;
      }

      // Append new stories to existing list
      final updatedStories = [...state.stories, ...newStories];

      state = state.copyWith(
        stories: updatedStories,
        isLoadingMore: false,
        hasMore: hasMore,
        lastStoryCreatedAt: lastCreatedAt,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'فشل في تحميل القصص: $e',
      );
    }
  }

  /// Refresh stories (reload from beginning)
  Future<void> refresh() async {
    await loadInitialStories();
  }
}

/// Provider for paginated stories notifier
final paginatedStoriesProvider =
    StateNotifierProvider<PaginatedStoriesNotifier, PaginatedStoriesState>((ref) {
  final repository = ref.watch(storyRepositoryProvider);
  return PaginatedStoriesNotifier(repository);
});

/// Provider for stories from followed users only (plus own stories)
/// This filters the active stories to show only those from users you follow
final followingStoriesProvider = StreamProvider<List<Story>>((ref) async* {
  // Watch auth state to get current user
  final authState = ref.watch(currentUserProvider);

  await for (final user in authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(null);
      }
      return Stream.value(user);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  )) {
    if (user == null) {
      yield [];
      continue;
    }

    final currentUserId = user.uid;

    // Get all active stories
    final allStoriesStream = ref.watch(activeStoriesProvider.stream);

    await for (final allStories in allStoriesStream) {
      try {
        // Get list of users current user is following
        final followRepository = ref.read(followRepositoryProvider);
        final followingUserIds = await followRepository.getFollowing(
          currentUserId,
        );

        // Filter stories to include:
        // 1. Own stories
        // 2. Stories from followed users
        final filteredStories = allStories.where((story) {
          return story.userId == currentUserId || // Own stories
              followingUserIds.contains(
                story.userId,
              ); // Followed users' stories
        }).toList();

        yield filteredStories;
      } catch (e) {
        // On error, just show own stories
        yield allStories
            .where((story) => story.userId == currentUserId)
            .toList();
      }
    }
  }
});

/// Provider for user-specific stories stream with auth state validation
final userStoriesProvider = StreamProvider.family<List<Story>, String>((
  ref,
  userId,
) {
  // ✅ Watch auth state to ensure user is authenticated
  final authState = ref.watch(currentUserProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        // Return empty stream when no authenticated user
        return Stream.value([]);
      }
      final repository = ref.watch(storyRepositoryProvider);
      return repository.getUserStories(userId);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// State for story creation
class StoryCreationState {
  final bool isLoading;
  final String? error;
  final Story? createdStory;

  StoryCreationState({this.isLoading = false, this.error, this.createdStory});

  StoryCreationState copyWith({
    bool? isLoading,
    String? error,
    Story? createdStory,
  }) {
    return StoryCreationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdStory: createdStory ?? this.createdStory,
    );
  }
}

/// Notifier for story creation
class StoryCreationNotifier extends StateNotifier<StoryCreationState> {
  final StoryRepository _repository;
  final FirebaseStorage _storage;
  final ImageCompressionService _imageCompression;
  final VideoCompressionService _videoCompression;

  StoryCreationNotifier(
    this._repository,
    this._storage,
    this._imageCompression,
    this._videoCompression,
  ) : super(StoryCreationState());

  /// Create a new story with media file
  Future<void> createStory({
    required String userId,
    required File mediaFile,
    required StoryType type,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Upload media to Firebase Storage
      final mediaUrl = await _uploadMedia(userId, mediaFile, type);

      // Create story in Firestore
      final story = Story(
        id: '',
        userId: userId,
        mediaUrl: mediaUrl,
        type: type,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      final createdStory = await _repository.createStory(story);

      state = state.copyWith(isLoading: false, createdStory: createdStory);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل في إنشاء القصة: ${e.toString()}',
      );
    }
  }

  /// Upload media file to Firebase Storage
  Future<String> _uploadMedia(String userId, File file, StoryType type) async {
    try {
      // Compress media before upload
      File fileToUpload = file;

      if (type == StoryType.image) {
        fileToUpload = await _imageCompression.compressForStory(file);
      } else if (type == StoryType.video) {
        fileToUpload = await _videoCompression.compressVideo(file);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = type == StoryType.image ? 'jpg' : 'mp4';
      final path = 'stories/$userId/$timestamp.$extension';

      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(fileToUpload);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('فشل في رفع الملف: $e');
    }
  }

  /// Record a view for a story
  Future<void> recordView(String storyId, String viewerId) async {
    try {
      await _repository.recordView(storyId, viewerId);
    } catch (e) {
      // Silently fail - view recording is not critical
      print('Failed to record view: $e');
    }
  }

  /// Delete a story
  Future<void> deleteStory(String storyId) async {
    try {
      await _repository.deleteStory(storyId);
    } catch (e) {
      state = state.copyWith(error: 'فشل في حذف القصة: ${e.toString()}');
    }
  }

  /// Reset state
  void reset() {
    state = StoryCreationState();
  }
}

/// Provider for story creation notifier
final storyCreationProvider =
    StateNotifierProvider<StoryCreationNotifier, StoryCreationState>((ref) {
      final repository = ref.watch(storyRepositoryProvider);
      final storage = FirebaseStorage.instance;
      final imageCompression = ref.watch(imageCompressionServiceProvider);
      final videoCompression = ref.watch(videoCompressionServiceProvider);
      return StoryCreationNotifier(
        repository,
        storage,
        imageCompression,
        videoCompression,
      );
    });
