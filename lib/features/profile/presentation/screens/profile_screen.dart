import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/enums.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../moderation/presentation/providers/moderation_provider.dart';
import '../../../moderation/presentation/widgets/report_bottom_sheet.dart';

import '../providers/profile_provider.dart';

/// Helper to get current user from auth state
extension CurrentUserExtension on WidgetRef {
  String? get currentUserId {
    final userAsync = watch(currentUserProvider);
    return userAsync.value?.uid;
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  final String? viewedUserId; // If viewing another user's profile

  const ProfileScreen({super.key, this.viewedUserId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _DebugStatus extends StatelessWidget {
  final ProfileState profileState;
  final String? currentUserId;
  final String? viewedUserId;
  final bool? hasLoadedProfile;
  final bool? fetchInProgress;

  const _DebugStatus({
    required this.profileState,
    required this.currentUserId,
    required this.viewedUserId,
    this.hasLoadedProfile,
    this.fetchInProgress,
  });

  @override
  Widget build(BuildContext context) {
    final profileSummary = profileState.profile != null
        ? profileState.profile!.toJson().toString()
        : 'No profile loaded';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'معلومات التصحيح',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('isLoading: ${profileState.isLoading}'),
        Text('isUploading: ${profileState.isUploading}'),
        Text('hasLoadedProfile: $hasLoadedProfile'),
        Text('fetchInProgress: $fetchInProgress'),
        Text('profile == null: ${profileState.profile == null}'),
        Text('currentUserId: $currentUserId'),
        Text('viewedUserId: $viewedUserId'),
        if (profileState.error != null)
          Text(
            'error: ${profileState.error}',
            style: const TextStyle(color: Colors.red),
          ),
        const SizedBox(height: 8),
        Text(
          profileSummary,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
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
  bool _hasLoadedProfile = false;
  bool _profileFetchInProgress = false;
  bool _showDebugPanel = false;
  bool _profileLoadScheduled = false;

  @override
  void initState() {
    super.initState();
    // Listen for user changes to load profile once user is available
    // We do this in a post-frame callback to avoid state errors during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoadedProfile) {
        _checkAndLoadProfile();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedProfile &&
        !_profileFetchInProgress &&
        !_profileLoadScheduled) {
      _profileLoadScheduled = true;
      Future.microtask(() async {
        _profileLoadScheduled = false;
        await _checkAndLoadProfile();
      });
    }
  }

  Future<void> _checkAndLoadProfile({String? userId}) async {
    if (_profileFetchInProgress) return;

    final resolvedUserId =
        userId ??
        widget.viewedUserId ??
        ref.read(currentUserProvider).value?.uid ??
        FirebaseAuth.instance.currentUser?.uid;

    debugPrint("DEBUG: _checkAndLoadProfile called. userId: $resolvedUserId");

    if (resolvedUserId == null) {
      debugPrint("DEBUG: userId is null, cannot load profile");
      return;
    }

    _profileFetchInProgress = true;
    try {
      await ref.read(profileProvider.notifier).loadProfile(resolvedUserId);
      _hasLoadedProfile = true;
    } finally {
      _profileFetchInProgress = false;
    }
  }

  bool get _isViewingOwnProfile {
    final currentUserId = ref.currentUserId;
    final viewedUserId = widget.viewedUserId;
    return viewedUserId == null || viewedUserId == currentUserId;
  }

  Future<void> _blockUser() async {
    final currentUserId = ref.currentUserId;
    final viewedUserId = widget.viewedUserId;

    if (currentUserId == null || viewedUserId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حظر المستخدم'),
        content: const Text(
          'هل تريد حظر هذا المستخدم؟ لن يتمكن من التواصل معك أو رؤية ملفك الشخصي.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حظر'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(moderationProvider.notifier)
          .blockUser(currentUserId, viewedUserId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حظر المستخدم')));
        Navigator.of(context).pop();
      }
    }
  }

  void _reportUser() {
    final currentUserId = ref.currentUserId;
    final viewedUserId = widget.viewedUserId;

    if (currentUserId == null || viewedUserId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReportBottomSheet(
          reporterId: currentUserId,
          reportedUserId: viewedUserId,
          reportType: ReportType.user,
        ),
      ),
    );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في اختيار الصورة: $e')));
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
        // Clear the selected image after successful upload
        setState(() {
          _selectedImage = null;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم رفع الصورة بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في رفع الصورة: $e')));
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

      // Reload the profile from Firestore to ensure we have the latest data
      await ref.read(profileProvider.notifier).loadProfile(userId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ البيانات بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في حفظ البيانات: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في توليد الرابط: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for user changes
    ref.listen<AsyncValue<User?>>(currentUserProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && !_hasLoadedProfile) {
          _checkAndLoadProfile(userId: user.uid);
        }
      });
    });

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
          if (_isViewingOwnProfile) ...[
            IconButton(
              icon: const Icon(Icons.link),
              onPressed: _generateAnonymousLink,
              tooltip: 'توليد رابط مجهول',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                context.push('/settings');
              },
              tooltip: 'الإعدادات',
            ),
          ] else ...[
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'block') {
                  _blockUser();
                } else if (value == 'report') {
                  _reportUser();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حظر المستخدم'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('الإبلاغ عن المستخدم'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: profileState.isLoading && profile == null
          ? Center(
              child: _DebugStatus(
                profileState: profileState,
                currentUserId: ref.currentUserId,
                viewedUserId: widget.viewedUserId,
                hasLoadedProfile: _hasLoadedProfile,
                fetchInProgress: _profileFetchInProgress,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showDebugPanel = !_showDebugPanel;
                          });
                        },
                        icon: const Icon(Icons.bug_report),
                        label: Text(
                          _showDebugPanel
                              ? 'إخفاء معلومات التصحيح'
                              : 'عرض معلومات التصحيح',
                        ),
                      ),
                    ),
                    if (_showDebugPanel)
                      Card(
                        color: Colors.grey.shade100,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _DebugStatus(
                            profileState: profileState,
                            currentUserId: ref.currentUserId,
                            viewedUserId: widget.viewedUserId,
                            hasLoadedProfile: _hasLoadedProfile,
                            fetchInProgress: _profileFetchInProgress,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
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
