import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/current_user_profile_provider.dart';

/// Helper to get current user from auth state
extension CurrentUserExtension on WidgetRef {
  String? get currentUserId {
    final userAsync = watch(currentUserProvider);
    return userAsync.value?.uid;
  }
}

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _countryController = TextEditingController();
  final _bioController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isImageBlurred = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() {
    if (_hasInitialized) return;
    
    final profile = ref.read(currentUserProfileProvider).profile;
    if (profile != null) {
      debugPrint('DEBUG: Initializing profile edit with data: ${profile.name}');
      _nameController.text = profile.name ?? '';
      _ageController.text = profile.age?.toString() ?? '';
      _countryController.text = profile.country ?? '';
      _isImageBlurred = profile.isImageBlurred;
      _hasInitialized = true;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _countryController.dispose();
    _bioController.dispose();
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
        debugPrint('DEBUG: Image picked: ${image.path}');
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('ERROR: Failed to pick image: $e');
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
      debugPrint('DEBUG: Starting image upload for user: $userId');
      final imageUrl = await ref
          .read(currentUserProfileProvider.notifier)
          .uploadProfileImage(userId, _selectedImage!);

      debugPrint('DEBUG: Image uploaded successfully: $imageUrl');

      // Update profile with new image URL
      final currentProfile = ref.read(currentUserProfileProvider).profile;
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          profileImageUrl: imageUrl,
        );
        await ref.read(currentUserProfileProvider.notifier).updateProfile(updatedProfile);
      }

      if (mounted) {
        // Clear the selected image after successful upload
        setState(() {
          _selectedImage = null;
        });

        SnackbarHelper.showSuccess(context, 'تم رفع الصورة بنجاح');
      }
    } catch (e) {
      debugPrint('ERROR: Failed to upload image: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'فشل في رفع الصورة: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.currentUserId;
    if (userId == null) return;

    final currentProfile = ref.read(currentUserProfileProvider).profile;
    if (currentProfile == null) return;

    try {
      debugPrint('DEBUG: Saving profile for user: $userId');
      final updatedProfile = currentProfile.copyWith(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        country: _countryController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        isImageBlurred: _isImageBlurred,
      );

      await ref.read(currentUserProfileProvider.notifier).updateProfile(updatedProfile);

      // Reload the profile from Firestore to ensure we have the latest data
      await ref.read(currentUserProfileProvider.notifier).loadProfile(userId);

      debugPrint('DEBUG: Profile saved successfully');

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'تم حفظ البيانات بنجاح');
        context.pop(); // Go back to profile screen
      }
    } catch (e) {
      debugPrint('ERROR: Failed to save profile: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'فشل في حفظ البيانات: $e');
      }
    }
  }

  Future<void> _cancel() async {
    final hasChanges = _selectedImage != null ||
        _nameController.text != (ref.read(currentUserProfileProvider).profile?.name ?? '') ||
        _ageController.text != (ref.read(currentUserProfileProvider).profile?.age?.toString() ?? '') ||
        _countryController.text != (ref.read(currentUserProfileProvider).profile?.country ?? '') ||
        _bioController.text != (ref.read(currentUserProfileProvider).profile?.bio ?? '') ||
        _isImageBlurred != (ref.read(currentUserProfileProvider).profile?.isImageBlurred ?? false);

    if (hasChanges) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تجاهل التغييرات'),
          content: const Text('هل تريد تجاهل التغييرات غير المحفوظة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('تجاهل'),
            ),
          ],
        ),
      );

      if (shouldDiscard == true && mounted) {
        context.pop();
      }
    } else {
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(currentUserProfileProvider);
    final profile = profileState.profile;

    // Initialize data when profile is available
    if (profile != null && !_hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeData();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancel,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: profileState.isLoading ? null : _saveProfile,
            tooltip: 'حفظ',
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
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (profile?.profileImageUrl != null
                                          ? NetworkImage(
                                              profile!.profileImageUrl!,
                                            )
                                          : null)
                                      as ImageProvider?,
                            child:
                                _selectedImage == null &&
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
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
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
                        onPressed: profileState.isUploading
                            ? null
                            : _uploadImage,
                        child: profileState.isUploading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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

                    // Bio Field
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'النبذة الشخصية',
                        hintText: 'اكتب نبذة عن نفسك... (اختياري)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      maxLength: 200,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
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

                    const SizedBox(height: 12),

                    // Cancel Button
                    OutlinedButton(
                      onPressed: _cancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('إلغاء'),
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
                  ],
                ),
              ),
            ),
    );
  }
}
