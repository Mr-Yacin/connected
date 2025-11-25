import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../services/error_logging_service.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  // Rate limiting: track failed attempts per phone number
  final Map<String, List<DateTime>> _failedAttempts = {};

  // OTP resend cooldown: track last OTP send time per phone number
  final Map<String, DateTime> _lastOtpSentTime = {};

  // Constants
  static const int maxFailedAttempts = 3;
  static const Duration rateLimitDuration = Duration(minutes: 5);
  static const Duration otpResendCooldown = Duration(seconds: 60);

  FirebaseAuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  @override
  Future<String> sendOtp(String phoneNumber) async {
    try {
      // Validate phone number
      if (phoneNumber.isEmpty) {
        throw ValidationException('رقم الهاتف مطلوب');
      }

      // Check resend cooldown
      if (!canResendOtp(phoneNumber)) {
        final lastSent = _lastOtpSentTime[phoneNumber]!;
        final remainingSeconds = otpResendCooldown.inSeconds -
            DateTime.now().difference(lastSent).inSeconds;
        throw RateLimitException(
          'يرجى الانتظار $remainingSeconds ثانية قبل إعادة إرسال الرمز',
          lastSent.add(otpResendCooldown),
        );
      }

      // Check rate limiting
      _checkRateLimit(phoneNumber);

      // Use Completer to properly wait for verification ID
      final completer = Completer<String>();
      
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          if (kDebugMode) {
            print('Auto verification completed');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          ErrorLoggingService.logAuthError(
            e,
            context: 'Phone verification failed',
            screen: 'PhoneInputScreen',
            operation: 'verifyPhoneNumber',
          );
          if (!completer.isCompleted) {
            completer.completeError(
              AuthException(
                _getArabicErrorMessage(e.code),
                code: e.code,
              ),
            );
          }
        },
        codeSent: (String verId, int? resendToken) {
          if (kDebugMode) {
            print('Code sent to $phoneNumber');
          }
          if (!completer.isCompleted) {
            completer.complete(verId);
          }
        },
        codeAutoRetrievalTimeout: (String verId) {
          if (kDebugMode) {
            print('Auto retrieval timeout, verification ID: $verId');
          }
          // Only complete if not already completed by codeSent
          if (!completer.isCompleted) {
            completer.complete(verId);
          }
        },
        timeout: const Duration(seconds: 120),
      );

      // Wait for the verification ID from callbacks
      final verificationId = await completer.future;

      // Record OTP sent time
      recordOtpSent(phoneNumber);

      return verificationId;
    } on ValidationException {
      rethrow;
    } on RateLimitException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      ErrorLoggingService.logAuthError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to send OTP',
        screen: 'PhoneInputScreen',
        operation: 'sendOtp',
      );
      throw AuthException('حدث خطأ أثناء إرسال رمز التحقق');
    }
  }

  @override
  Future<UserCredential> verifyOtp(String verificationId, String otp) async {
    try {
      // Validate OTP
      if (otp.isEmpty) {
        throw ValidationException('رمز التحقق مطلوب');
      }

      if (otp.length != 6) {
        throw ValidationException('رمز التحقق يجب أن يكون 6 أرقام');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      // Clear failed attempts on successful verification
      if (userCredential.user != null) {
        final phoneNumber = userCredential.user!.phoneNumber;
        if (phoneNumber != null) {
          _failedAttempts.remove(phoneNumber);
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e, stackTrace) {
      ErrorLoggingService.logAuthError(
        e,
        stackTrace: stackTrace,
        context: 'OTP verification failed',
        screen: 'OtpVerificationScreen',
        operation: 'verifyOtp',
      );

      // Record failed attempt
      if (e.code == 'invalid-verification-code') {
        // We don't have phone number here, but we can track by verification ID
        _recordFailedAttempt(verificationId);
      }

      throw AuthException(
        _getArabicErrorMessage(e.code),
        code: e.code,
      );
    } on ValidationException {
      rethrow;
    } catch (e, stackTrace) {
      ErrorLoggingService.logAuthError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error during OTP verification',
        screen: 'OtpVerificationScreen',
        operation: 'verifyOtp',
      );
      throw AuthException('حدث خطأ أثناء التحقق من الرمز');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e, stackTrace) {
      ErrorLoggingService.logAuthError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to sign out',
        screen: 'SettingsScreen',
        operation: 'signOut',
      );
      throw AuthException('حدث خطأ أثناء تسجيل الخروج');
    }
  }

  @override
  bool canResendOtp(String phoneNumber) {
    if (!_lastOtpSentTime.containsKey(phoneNumber)) {
      return true;
    }

    final lastSent = _lastOtpSentTime[phoneNumber]!;
    final timeSinceLastSent = DateTime.now().difference(lastSent);

    return timeSinceLastSent >= otpResendCooldown;
  }

  @override
  void recordOtpSent(String phoneNumber) {
    _lastOtpSentTime[phoneNumber] = DateTime.now();
  }

  /// Check if rate limit is exceeded for the phone number
  void _checkRateLimit(String phoneNumber) {
    if (!_failedAttempts.containsKey(phoneNumber)) {
      return;
    }

    final attempts = _failedAttempts[phoneNumber]!;
    final now = DateTime.now();

    // Remove attempts older than rate limit duration
    attempts.removeWhere(
      (attempt) => now.difference(attempt) > rateLimitDuration,
    );

    if (attempts.length >= maxFailedAttempts) {
      final oldestAttempt = attempts.first;
      final retryAfter = oldestAttempt.add(rateLimitDuration);
      final remainingMinutes = retryAfter.difference(now).inMinutes;

      throw RateLimitException(
        'تم تجاوز عدد المحاولات المسموحة. يرجى المحاولة بعد $remainingMinutes دقيقة',
        retryAfter,
        code: 'rate-limit-exceeded',
      );
    }
  }

  /// Record a failed verification attempt
  void _recordFailedAttempt(String identifier) {
    if (!_failedAttempts.containsKey(identifier)) {
      _failedAttempts[identifier] = [];
    }
    _failedAttempts[identifier]!.add(DateTime.now());
  }

  /// Get Arabic error message for Firebase error codes
  String _getArabicErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صالح';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح';
      case 'invalid-verification-id':
        return 'معرف التحقق غير صالح';
      case 'session-expired':
        return 'انتهت صلاحية الجلسة. يرجى المحاولة مرة أخرى';
      case 'quota-exceeded':
        return 'تم تجاوز الحد المسموح. يرجى المحاولة لاحقاً';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'operation-not-allowed':
        return 'العملية غير مسموحة';
      case 'too-many-requests':
        return 'عدد كبير من المحاولات. يرجى المحاولة لاحقاً';
      case 'network-request-failed':
        return 'فشل الاتصال بالشبكة. يرجى التحقق من الاتصال بالإنترنت';
      default:
        return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى';
    }
  }
}
