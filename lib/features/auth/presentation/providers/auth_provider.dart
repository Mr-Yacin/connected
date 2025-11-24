import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';

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

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState());

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
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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
      state = state.copyWith(isLoading: false);
      return userCredential;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.signOut();
      state = AuthState(); // Reset state
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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

// Provider for AuthNotifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});
