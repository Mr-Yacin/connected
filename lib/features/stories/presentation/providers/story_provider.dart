import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/models/story.dart';
import '../../../../core/models/enums.dart';
import '../../data/repositories/firestore_story_repository.dart';
import '../../data/services/story_expiration_service.dart';
import '../../domain/repositories/story_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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

/// Provider for user-specific stories stream with auth state validation
final userStoriesProvider = StreamProvider.family<List<Story>, String>((ref, userId) {
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

  StoryCreationState({
    this.isLoading = false,
    this.error,
    this.createdStory,
  });

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

  StoryCreationNotifier(this._repository, this._storage)
      : super(StoryCreationState());

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

      state = state.copyWith(
        isLoading: false,
        createdStory: createdStory,
      );
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
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = type == StoryType.image ? 'jpg' : 'mp4';
      final path = 'stories/$userId/$timestamp.$extension';

      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
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
      state = state.copyWith(
        error: 'فشل في حذف القصة: ${e.toString()}',
      );
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
  return StoryCreationNotifier(repository, storage);
});
