import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final bool isConvertingAccount;

  const OtpVerificationScreen({super.key, this.isConvertingAccount = false});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _remainingSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 60;
    _canResend = false;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _showErrorDialog('يرجى إدخال رمز التحقق');
      return;
    }

    if (otp.length != 6) {
      _showErrorDialog('رمز التحقق يجب أن يكون 6 أرقام');
      return;
    }

    try {
      if (widget.isConvertingAccount) {
        await ref
            .read(authNotifierProvider.notifier)
            .convertToPermamentAccount(otp);
      } else {
        await ref.read(authNotifierProvider.notifier).verifyOtp(otp);
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم التحقق بنجاح!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // Small delay to ensure auth state is updated
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          // Navigate to home - router will handle redirection
          context.go('/');
        }
      }
    } on ValidationException catch (e) {
      if (mounted) {
        _showErrorDialog(e.message);
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى');
      }
    }
  }

  Future<void> _resendOtp() async {
    final authState = ref.read(authNotifierProvider);

    if (authState.phoneNumber == null) {
      _showErrorDialog('رقم الهاتف غير موجود');
      return;
    }

    if (!ref.read(authNotifierProvider.notifier).canResendOtp()) {
      _showErrorDialog('يرجى الانتظار قبل إعادة إرسال الرمز');
      return;
    }

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .sendOtp(authState.phoneNumber!);

      if (mounted) {
        _startTimer();
        SnackbarHelper.showSuccess(context, 'تم إرسال رمز التحقق مرة أخرى');
      }
    } on RateLimitException catch (e) {
      if (mounted) {
        _showErrorDialog(e.message);
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('حدث خطأ أثناء إعادة إرسال الرمز');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('التحقق من الرمز'), centerTitle: true),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Icon
                Icon(
                  Icons.message,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'أدخل رمز التحقق',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'تم إرسال رمز التحقق إلى رقم هاتفك',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),

                if (authState.phoneNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    authState.phoneNumber!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                  ),
                ],

                const SizedBox(height: 40),

                // OTP input
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(letterSpacing: 16),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: TextStyle(
                      letterSpacing: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.length == 6) {
                      _verifyOtp();
                    }
                  },
                ),

                const SizedBox(height: 24),

                // Timer and resend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_canResend) ...[
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'إعادة الإرسال بعد $_remainingSeconds ثانية',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ] else ...[
                      TextButton.icon(
                        onPressed: authState.isLoading ? null : _resendOtp,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة إرسال الرمز'),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 32),

                // Verify button
                FilledButton(
                  onPressed: authState.isLoading ? null : _verifyOtp,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('تحقق', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
