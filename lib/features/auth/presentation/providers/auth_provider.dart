import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_profile.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../services/external/notification_service.dart';

// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

// Provider for current user
final currentUserProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});

// Auth state notifier
class AuthState {
  final bool isLoading;
  final String? error;
  final String? verificationId;
  final String? phoneNumber;
  final bool isGuest;

  AuthState({
    this.isLoading = false,
    this.error,
    this.verificationId,
    this.phoneNumber,
    this.isGuest = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? verificationId,
    String? phoneNumber,
    bool? isGuest,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      verificationId: verificationId ?? this.verificationId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

// Provider for AuthNotifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final authRepository = ref.watch(authRepositoryProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return AuthNotifier(authRepository, profileRepository, notificationService);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final NotificationService _notificationService;

  AuthNotifier(
    this._authRepository,
    this._profileRepository,
    this._notificationService,
  ) : super(AuthState());

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final verificationId = await _authRepository.sendOtp(phoneNumber);
      state = state.copyWith(
        isLoading: false,
        verificationId: verificationId,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<UserCredential> verifyOtp(String otp) async {
    if (state.verificationId == null) {
      throw Exception('معرف التحقق غير موجود');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final userCredential = await _authRepository.verifyOtp(
        state.verificationId!,
        otp,
      );

      // Create user profile if it doesn't exist
      if (userCredential.user != null) {
        final user = userCredential.user!;
        final exists = await _profileRepository.profileExists(user.uid);

        if (!exists) {
          final newProfile = UserProfile(
            id: user.uid,
            phoneNumber: user.phoneNumber ?? state.phoneNumber ?? '',
            createdAt: DateTime.now(),
            lastActive: DateTime.now(),
          );
          await _profileRepository.createProfile(newProfile);
        }

        // ✅ CRITICAL: Save FCM token after successful login
        await _notificationService.refreshAndSaveToken();
      }

      state = state.copyWith(isLoading: false);
      return userCredential;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // ✅ Delete FCM token before logout (so user won't get notifications)
      await _notificationService.deleteToken();

      await _authRepository.signOut();
      
      // Reset state - this will trigger auth state change and clean up providers
      state = AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  bool canResendOtp() {
    if (state.phoneNumber == null) return false;
    return _authRepository.canResendOtp(state.phoneNumber!);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> signInAsGuest() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.signInAnonymously();
      state = state.copyWith(isLoading: false, isGuest: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<UserCredential> convertToPermamentAccount(String otp) async {
    if (state.verificationId == null) {
      throw Exception('معرف التحقق غير موجود');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Link phone number to anonymous account
      final userCredential = await _authRepository.linkPhoneNumber(
        state.verificationId!,
        otp,
      );

      // Create/update user profile
      if (userCredential.user != null) {
        final user = userCredential.user!;

        // Check if profile exists (it should for guest users)
        final exists = await _profileRepository.profileExists(user.uid);

        if (exists) {
          // Update existing guest profile with phone number
          final profile = await _profileRepository.getProfile(user.uid);
          final updatedProfile = profile.copyWith(
            phoneNumber: user.phoneNumber ?? state.phoneNumber ?? '',
            isGuest: false,
          );
          await _profileRepository.updateProfile(updatedProfile);
        } else {
          // This shouldn't happen, but create profile if it doesn't exist
          final newProfile = UserProfile(
            id: user.uid,
            phoneNumber: user.phoneNumber ?? state.phoneNumber ?? '',
            createdAt: DateTime.now(),
            lastActive: DateTime.now(),
          );
          await _profileRepository.createProfile(newProfile);
        }

        // ✅ CRITICAL: Save FCM token after successful account conversion
        await _notificationService.refreshAndSaveToken();
      }

      state = state.copyWith(isLoading: false, isGuest: false);
      return userCredential;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}
