import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// Helper to get current user from auth state
extension CurrentUserExtension on WidgetRef {
  String? get currentUserId {
    final userAsync = watch(currentUserProvider);
    return userAsync.value?.uid;
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _countryController = TextEditingController();
  final _dialectController = TextEditingController();
  
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isImageBlurred = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final userId = ref.currentUserId;
    if (userId != null) {
      ref.read(profileProvider.notifier).loadProfile(userId);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _countryController.dispose();
    _dialectController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في اختيار الصورة: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    final userId = ref.currentUserId;
    if (userId == null) return;

    try {
      final imageUrl = await ref
          .read(profileProvider.notifier)
          .uploadProfileImage(userId, _selectedImage!);

      // Update profile with new image URL
      final currentProfile = ref.read(profileProvider).profile;
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          profileImageUrl: imageUrl,
        );
        await ref.read(profileProvider.notifier).updateProfile(updatedProfile);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع الصورة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في رفع الصورة: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.currentUserId;
    if (userId == null) return;

    final currentProfile = ref.read(profileProvider).profile;
    if (currentProfile == null) return;

    try {
      final updatedProfile = currentProfile.copyWith(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        country: _countryController.text.trim(),
        dialect: _dialectController.text.trim(),
        isImageBlurred: _isImageBlurred,
      );

      await ref.read(profileProvider.notifier).updateProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ البيانات بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في حفظ البيانات: $e')),
        );
      }
    }
  }

  Future<void> _generateAnonymousLink() async {
    final userId = ref.currentUserId;
    if (userId == null) return;

    try {
      final link = await ref
          .read(profileProvider.notifier)
          .generateAnonymousLink(userId);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('الرابط المجهول'),
            content: SelectableText(link),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في توليد الرابط: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;

    // Update controllers when profile loads
    if (profile != null && _nameController.text.isEmpty) {
      _nameController.text = profile.name ?? '';
      _ageController.text = profile.age?.toString() ?? '';
      _countryController.text = profile.country ?? '';
      _dialectController.text = profile.dialect ?? '';
      _isImageBlurred = profile.isImageBlurred;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: _generateAnonymousLink,
            tooltip: 'توليد رابط مجهول',
          ),
        ],
      ),
      body: profileState.isLoading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Image Section
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (profile?.profileImageUrl != null
                                    ? NetworkImage(profile!.profileImageUrl!)
                                    : null) as ImageProvider?,
                            child: _selectedImage == null &&
                                    profile?.profileImageUrl == null
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 20),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: profileState.isUploading ? null : _uploadImage,
                        child: profileState.isUploading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('رفع الصورة'),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Blur Toggle
                    SwitchListTile(
                      title: const Text('تمويه الصورة الشخصية'),
                      subtitle: const Text('إخفاء الصورة جزئياً للآخرين'),
                      value: _isImageBlurred,
                      onChanged: (value) {
                        setState(() {
                          _isImageBlurred = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء إدخال الاسم';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Age Field
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'العمر',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء إدخال العمر';
                        }
                        final age = int.tryParse(value.trim());
                        if (age == null || age < 18 || age > 100) {
                          return 'الرجاء إدخال عمر صحيح (18-100)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Country Field
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'الدولة',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء إدخال الدولة';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Dialect Field
                    TextFormField(
                      controller: _dialectController,
                      decoration: const InputDecoration(
                        labelText: 'اللهجة',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.language_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء إدخال اللهجة';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: profileState.isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: profileState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('حفظ التغييرات'),
                    ),

                    if (profileState.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          profileState.error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    if (profile?.anonymousLink != null) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'الرابط المجهول:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        profile!.anonymousLink!,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
