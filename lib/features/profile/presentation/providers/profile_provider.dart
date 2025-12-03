import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../data/repositories/firestore_profile_repository.dart';
import '../../data/services/image_blur_service.dart';
import '../../../../services/media/image_compression_service.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

/// Provider for ProfileRepository
final profileRepositoryProvider = Provider<FirestoreProfileRepository>((ref) {
  final imageCompression = ref.watch(imageCompressionServiceProvider);
  return FirestoreProfileRepository(imageCompression: imageCompression);
});

/// Provider for ImageBlurService
final imageBlurServiceProvider = Provider<ImageBlurService>((ref) {
  return ImageBlurService();
});

/// State for profile operations
class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;
  final bool isUploading;
  final String? loadedUserId;

  ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
    this.isUploading = false,
    this.loadedUserId,
  });

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? error,
    bool? isUploading,
    String? loadedUserId,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isUploading: isUploading ?? this.isUploading,
      loadedUserId: loadedUserId ?? this.loadedUserId,
    );
  }
}

/// Profile provider for managing profile state
class ProfileNotifier extends StateNotifier<ProfileState> {
  final FirestoreProfileRepository _repository;
  final ImageBlurService _blurService;
  final Ref _ref;

  ProfileNotifier(this._repository, this._blurService, this._ref) : super(ProfileState());

  /// Reset profile state (for switching between users)
  void resetState() {
    state = ProfileState();
  }

  /// Load user profile
  Future<void> loadProfile(String userId, {bool forceReload = false}) async {
    // Check if we already have this user's profile loaded
    if (!forceReload &&
        state.loadedUserId == userId &&
        state.profile != null &&
        !state.isLoading) {
      // Profile for this user is already loaded, no need to reload
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = await _repository.getProfile(userId);
      state = state.copyWith(
        profile: profile,
        isLoading: false,
        loadedUserId: userId,
      );
    } on AppException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: 'حدث خطأ غير متوقع', isLoading: false);
    }
  }

  /// Reload profile silently (without showing loading indicator)
  Future<void> refreshProfile(String userId) async {
    try {
      final profile = await _repository.getProfile(userId);
      state = state.copyWith(
        profile: profile,
        loadedUserId: userId,
        error: null,
      );
    } on AppException catch (e) {
      // Silent failure - don't update error state
      debugPrint('ERROR: Failed to refresh profile: ${e.message}');
    } catch (e) {
      debugPrint('ERROR: Failed to refresh profile: $e');
    }
  }

  /// Update profile
  Future<void> updateProfile(UserProfile profile) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Store old profile to check if name or image changed
      final oldProfile = state.profile;
      
      // Update profile in Firestore
      await _repository.updateProfile(profile);
      state = state.copyWith(profile: profile, isLoading: false);
      
      // Check if name or profile image changed
      final nameChanged = oldProfile?.name != profile.name;
      final imageChanged = oldProfile?.profileImageUrl != profile.profileImageUrl;
      
      // If name or image changed, update denormalized data in all chats
      if (nameChanged || imageChanged) {
        final chatRepository = _ref.read(chatRepositoryProvider);
        
        // Run in background to not block the UI
        await chatRepository.updateUserDenormalizedData(
          userId: profile.id,
          userName: profile.name ?? '',
          userImageUrl: profile.profileImageUrl,
          runInBackground: true,
        );
      }
    } on AppException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
      rethrow;
    } catch (e) {
      state = state.copyWith(error: 'حدث خطأ غير متوقع', isLoading: false);
      rethrow;
    }
  }

  /// Upload profile image
  Future<String> uploadProfileImage(String userId, File image) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      final imageUrl = await _repository.uploadProfileImage(userId, image);
      state = state.copyWith(isUploading: false);
      return imageUrl;
    } on AppException catch (e) {
      state = state.copyWith(error: e.message, isUploading: false);
      rethrow;
    } catch (e) {
      state = state.copyWith(error: 'حدث خطأ غير متوقع', isUploading: false);
      rethrow;
    }
  }

  /// Generate anonymous link
  Future<String> generateAnonymousLink(String userId) async {
    try {
      // If we already have the profile in memory and it contains a link,
      // reuse it instead of generating a new one.
      if (state.profile?.anonymousLink != null) {
        return state.profile!.anonymousLink!;
      }

      // Ensure we have the latest profile from Firestore before generating
      // a new link. This avoids creating duplicates when the provider
      // hasn't finished loading yet.
      if (state.profile == null) {
        try {
          final latestProfile = await _repository.getProfile(userId);
          state = state.copyWith(profile: latestProfile);

          if (latestProfile.anonymousLink != null) {
            return latestProfile.anonymousLink!;
          }
        } catch (_) {
          // If fetching the profile fails (e.g., poor connectivity),
          // we still allow the user to generate a link so the main action succeeds.
        }
      }

      final link = await _repository.generateAnonymousLink(userId);

      // Update profile with the new link
      if (state.profile != null) {
        final updatedProfile = state.profile!.copyWith(anonymousLink: link);
        await _repository.updateProfile(updatedProfile);
        state = state.copyWith(profile: updatedProfile);
      }

      return link;
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(error: 'حدث خطأ غير متوقع');
      rethrow;
    }
  }

  /// Apply blur to image
  Future<File> applyBlurToImage(File image, {int blurLevel = 10}) async {
    try {
      return await _blurService.applyBlur(image, blurLevel: blurLevel);
    } catch (e) {
      state = state.copyWith(error: 'فشل في تطبيق التمويه');
      rethrow;
    }
  }

  /// Toggle blur setting
  Future<void> toggleBlur(bool isBlurred) async {
    if (state.profile == null) return;

    final updatedProfile = state.profile!.copyWith(isImageBlurred: isBlurred);
    await updateProfile(updatedProfile);
  }
}

/// Provider for viewing OTHER users' profiles (not your own)
/// For your own profile, use currentUserProfileProvider
final viewedProfileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      final blurService = ref.watch(imageBlurServiceProvider);
      return ProfileNotifier(repository, blurService, ref);
    });
