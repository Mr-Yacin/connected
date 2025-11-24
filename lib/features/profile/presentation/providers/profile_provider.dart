import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../data/repositories/firestore_profile_repository.dart';
import '../../data/services/image_blur_service.dart';

/// Provider for ProfileRepository
final profileRepositoryProvider = Provider<FirestoreProfileRepository>((ref) {
  return FirestoreProfileRepository();
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

  ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
    this.isUploading = false,
  });

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? error,
    bool? isUploading,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

/// Profile provider for managing profile state
class ProfileNotifier extends StateNotifier<ProfileState> {
  final FirestoreProfileRepository _repository;
  final ImageBlurService _blurService;

  ProfileNotifier(this._repository, this._blurService) : super(ProfileState());

  /// Load user profile
  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final profile = await _repository.getProfile(userId);
      state = state.copyWith(profile: profile, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: 'حدث خطأ غير متوقع', isLoading: false);
    }
  }

  /// Update profile
  Future<void> updateProfile(UserProfile profile) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.updateProfile(profile);
      state = state.copyWith(profile: profile, isLoading: false);
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
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final link = await _repository.generateAnonymousLink(userId);
      
      // Update profile with the new link
      if (state.profile != null) {
        final updatedProfile = state.profile!.copyWith(anonymousLink: link);
        await _repository.updateProfile(updatedProfile);
        state = state.copyWith(profile: updatedProfile, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
      
      return link;
    } on AppException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
      rethrow;
    } catch (e) {
      state = state.copyWith(error: 'حدث خطأ غير متوقع', isLoading: false);
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

/// Provider for ProfileNotifier
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  final blurService = ref.watch(imageBlurServiceProvider);
  return ProfileNotifier(repository, blurService);
});
