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

  AuthState({
    this.isLoading = false,
    this.error,
    this.verificationId,
    this.phoneNumber,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? verificationId,
    String? phoneNumber,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      verificationId: verificationId ?? this.verificationId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
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
      state = AuthState(); // Reset state
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
}
