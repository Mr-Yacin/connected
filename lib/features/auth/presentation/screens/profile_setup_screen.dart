import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../services/external/location_service.dart';
import '../../../profile/data/repositories/firestore_profile_repository.dart';

/// Screen for new users to complete their profile after OTP verification
class ProfileSetupScreen extends StatefulWidget {
  final bool isGuest;

  const ProfileSetupScreen({super.key, this.isGuest = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationService = LocationService();
  final _profileRepository = FirestoreProfileRepository();

  int? _selectedAge;
  String? _selectedGender;
  String? _selectedCountry;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;

  final List<String> _genderOptions = ['ذكر', 'أنثى', 'أفضل عدم الإفصاح'];

  @override
  void initState() {
    super.initState();
    _checkLocationPermissionAndDetect();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Check location permission and auto-detect country
  Future<void> _checkLocationPermissionAndDetect() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Request permission
      final granted = await _locationService.requestLocationPermission();

      if (granted) {
        // Try to detect country
        final country = await _locationService.getCurrentCountry();
        if (country != null && mounted) {
          final arabicCountry = LocationService.convertCountryToArabic(country);
          setState(() => _selectedCountry = arabicCountry);
        }
      }
    } catch (e) {
      // Silently fail - user can select manually
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  /// Submit the profile setup form
  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAge == null) {
      _showErrorDialog('يرجى اختيار العمر');
      return;
    }

    if (_selectedGender == null) {
      _showErrorDialog('يرجى اختيار الجنس');
      return;
    }

    if (_selectedCountry == null) {
      _showErrorDialog('يرجى اختيار الدولة');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final now = DateTime.now();
      final profile = UserProfile(
        id: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        name: _nameController.text.trim(),
        age: _selectedAge,
        gender: _selectedGender,
        country: _selectedCountry,
        createdAt: now,
        lastActive: now,
        isActive: true,
        isImageBlurred: false,
        isGuest: widget.isGuest,
      );

      await _profileRepository.createProfile(profile);

      if (mounted) {
        // Navigate to home screen
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('حدث خطأ أثناء حفظ البيانات. يرجى المحاولة مرة أخرى.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إكمال الملف الشخصي'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Guest mode banner - sticky at top, always visible
            if (widget.isGuest)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'أنت تستخدم وضع الزائر. بياناتك مؤقتة وستُحذف عند تسجيل الخروج. قم بالتسجيل لحفظ بياناتك.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Scrollable form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Welcome message
                    Text(
                      'مرحباً بك! 👋',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يرجى إكمال معلوماتك الشخصية للمتابعة',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        labelText: 'الاسم *',
                        hintText: 'أدخل اسمك',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الاسم مطلوب';
                        }
                        if (value.trim().length < 2) {
                          return 'الاسم يجب أن يكون حرفين على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Age dropdown
                    DropdownButtonFormField<int>(
                      value: _selectedAge,
                      decoration: const InputDecoration(
                        labelText: 'العمر *',
                        prefixIcon: Icon(Icons.cake_outlined),
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('اختر العمر'),
                      items: List.generate(82, (index) => index + 18)
                          .map(
                            (age) => DropdownMenuItem(
                              value: age,
                              child: Text('$age سنة'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedAge = value),
                      validator: (value) {
                        if (value == null) {
                          return 'العمر مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Gender selection
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'الجنس *',
                        prefixIcon: Icon(Icons.wc_outlined),
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('اختر الجنس'),
                      items: _genderOptions
                          .map(
                            (gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedGender = value),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الجنس مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Country selection with loading indicator
                    if (_isLoadingLocation)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 16),
                              Expanded(child: Text('جارٍ تحديد موقعك...')),
                            ],
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedCountry,
                        decoration: const InputDecoration(
                          labelText: 'الدولة *',
                          prefixIcon: Icon(Icons.public_outlined),
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('اختر الدولة'),
                        items: LocationService.getCountryList()
                            .map(
                              (country) => DropdownMenuItem(
                                value: country,
                                child: Text(country),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCountry = value),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الدولة مطلوبة';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 32),

                    // Submit button
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submitProfile,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'إنشاء الحساب',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Info text
                    Text(
                      'جميع الحقول المميزة بـ (*) مطلوبة',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
