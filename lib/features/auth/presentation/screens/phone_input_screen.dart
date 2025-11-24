import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/models/country_code.dart';
import '../providers/auth_provider.dart';
import 'otp_verification_screen.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  CountryCode _selectedCountry = CountryCodes.defaultCountry;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال رقم الهاتف';
    }

    // Remove spaces and special characters
    final cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanNumber.length < _selectedCountry.minLength) {
      return 'رقم الهاتف قصير جداً (${_selectedCountry.minLength} أرقام على الأقل)';
    }

    if (cleanNumber.length > _selectedCountry.maxLength) {
      return 'رقم الهاتف طويل جداً (${_selectedCountry.maxLength} أرقام كحد أقصى)';
    }

    return null;
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'اختر الدولة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            
            const Divider(),
            
            // Country list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: CountryCodes.all.length,
                itemBuilder: (context, index) {
                  final country = CountryCodes.all[index];
                  final isSelected = country.code == _selectedCountry.code &&
                      country.nameAr == _selectedCountry.nameAr;
                  
                  return ListTile(
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 32),
                    ),
                    title: Text(
                      country.nameAr,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      country.code,
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCountry = country;
                        _phoneController.clear();
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Clear any previous errors
    ref.read(authNotifierProvider.notifier).clearError();

    // Format phone number
    final cleanNumber = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    final fullPhoneNumber = '${_selectedCountry.code}$cleanNumber';

    try {
      await ref.read(authNotifierProvider.notifier).sendOtp(fullPhoneNumber);

      if (mounted) {
        // Navigate to OTP verification screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const OtpVerificationScreen(),
          ),
        );
      }
    } on RateLimitException catch (e) {
      if (mounted) {
        _showErrorDialog(e.message);
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
        appBar: AppBar(
          title: const Text('تسجيل الدخول'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // Icon
                  Icon(
                    Icons.phone_android,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    'أدخل رقم هاتفك',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    'سنرسل لك رمز التحقق عبر رسالة نصية',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Phone number input
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Country code selector
                      InkWell(
                        onTap: _showCountryPicker,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedCountry.flag,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _selectedCountry.code,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, size: 20),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Phone number field
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(_selectedCountry.maxLength),
                          ],
                          decoration: InputDecoration(
                            labelText: 'رقم الهاتف',
                            hintText: '${_selectedCountry.minLength == _selectedCountry.maxLength ? _selectedCountry.minLength : '${_selectedCountry.minLength}-${_selectedCountry.maxLength}'} أرقام',
                            hintTextDirection: TextDirection.rtl,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          validator: _validatePhoneNumber,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Send OTP button
                  FilledButton(
                    onPressed: authState.isLoading ? null : _sendOtp,
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
                        : const Text(
                            'إرسال رمز التحقق',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  
                  const Spacer(),
                  
                  // Privacy notice
                  Text(
                    'بالمتابعة، أنت توافق على شروط الخدمة وسياسة الخصوصية',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
