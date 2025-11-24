import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  /// Send OTP to the provided phone number
  /// Throws [ValidationException] if phone number is invalid
  /// Throws [RateLimitException] if rate limit is exceeded
  /// Throws [AuthException] for other authentication errors
  Future<String> sendOtp(String phoneNumber);

  /// Verify OTP code with the verification ID
  /// Returns UserCredential on success
  /// Throws [AuthException] if verification fails
  /// Throws [RateLimitException] if rate limit is exceeded
  Future<UserCredential> verifyOtp(String verificationId, String otp);

  /// Sign out the current user
  Future<void> signOut();

  /// Stream of authentication state changes
  Stream<User?> authStateChanges();

  /// Get current user
  User? get currentUser;

  /// Check if user can resend OTP (60 second cooldown)
  bool canResendOtp(String phoneNumber);

  /// Record OTP send attempt
  void recordOtpSent(String phoneNumber);
}
