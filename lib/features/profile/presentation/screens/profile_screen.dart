import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
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

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _hasLoadedProfile = false;
  bool _profileFetchInProgress = false;
  bool _profileLoadScheduled = false;

  @override
  void initState() {
    super.initState();
    // Listen for user changes to load profile once user is available
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
      debugPrint("DEBUG: Profile loaded successfully");
    } catch (e) {
      debugPrint("ERROR: Failed to load profile: $e");
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
      debugPrint("DEBUG: Blocking user: $viewedUserId");
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

    debugPrint("DEBUG: Reporting user: $viewedUserId");
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

  Future<void> _copyAnonymousLink(String link) async {
    try {
      await Clipboard.setData(ClipboardData(text: link));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نسخ الرابط')),
        );
      }
      debugPrint("DEBUG: Link copied to clipboard: $link");
    } catch (e) {
      debugPrint("ERROR: Failed to copy link: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في نسخ الرابط: $e')),
        );
      }
    }
  }

  Future<void> _shareAnonymousLink(String link) async {
    try {
      debugPrint("DEBUG: Sharing link: $link");
      await Share.share(
        'تواصل معي بشكل مجهول عبر هذا الرابط:\n$link',
        subject: 'رابط الملف الشخصي المجهول',
      );
    } catch (e) {
      debugPrint("ERROR: Failed to share link: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في مشاركة الرابط: $e')),
        );
      }
    }
  }

  Future<void> _generateAnonymousLink() async {
    final userId = ref.currentUserId;
    if (userId == null) return;

    try {
      debugPrint("DEBUG: Generating anonymous link for user: $userId");
      final link = await ref
          .read(profileProvider.notifier)
          .generateAnonymousLink(userId);

      debugPrint("DEBUG: Anonymous link generated: $link");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم توليد الرابط المجهول')),
        );
      }
    } catch (e) {
      debugPrint("ERROR: Failed to generate anonymous link: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في توليد الرابط: $e')),
        );
      }
    }
  }

  String _buildFullAnonymousUrl(String linkHash) {
    // TODO: Replace with your actual domain
    const domain = 'https://connected.app';
    return '$domain/profile/link/$linkHash';
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

    debugPrint("DEBUG: ProfileScreen build - isLoading: ${profileState.isLoading}, hasProfile: ${profile != null}");

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          if (_isViewingOwnProfile) ...[
            if (profile?.anonymousLink != null)
              IconButton(
                icon: const Icon(Icons.link),
                onPressed: () {
                  final fullUrl = _buildFullAnonymousUrl(profile!.anonymousLink!);
                  _shareAnonymousLink(fullUrl);
                },
                tooltip: 'مشاركة الرابط المجهول',
              )
            else
              IconButton(
                icon: const Icon(Icons.add_link),
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
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'لم يتم العثور على الملف الشخصي',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (profileState.error != null)
                        Text(
                          profileState.error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Image
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          backgroundImage: profile.profileImageUrl != null
                              ? NetworkImage(profile.profileImageUrl!)
                              : null,
                          child: profile.profileImageUrl == null
                              ? const Icon(Icons.person, size: 60)
                              : null,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Profile Information Cards
                      _buildInfoCard(
                        icon: Icons.person_outline,
                        label: 'الاسم',
                        value: profile.name ?? 'غير محدد',
                      ),

                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.cake_outlined,
                        label: 'العمر',
                        value: profile.age?.toString() ?? 'غير محدد',
                      ),

                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.flag_outlined,
                        label: 'الدولة',
                        value: profile.country ?? 'غير محدد',
                      ),

                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.blur_on,
                        label: 'تمويه الصورة',
                        value: profile.isImageBlurred ? 'مفعّل' : 'غير مفعّل',
                      ),

                      // Anonymous Link Section
                      if (_isViewingOwnProfile && profile.anonymousLink != null) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'الرابط المجهول',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20),
                                  onPressed: () {
                                    final fullUrl = _buildFullAnonymousUrl(
                                      profile.anonymousLink!,
                                    );
                                    _copyAnonymousLink(fullUrl);
                                  },
                                  tooltip: 'نسخ الرابط',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share, size: 20),
                                  onPressed: () {
                                    final fullUrl = _buildFullAnonymousUrl(
                                      profile.anonymousLink!,
                                    );
                                    _shareAnonymousLink(fullUrl);
                                  },
                                  tooltip: 'مشاركة الرابط',
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        InkWell(
                          onTap: () {
                            final fullUrl = _buildFullAnonymousUrl(
                              profile.anonymousLink!,
                            );
                            _copyAnonymousLink(fullUrl);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.link,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _buildFullAnonymousUrl(profile.anonymousLink!),
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Edit Button (only for own profile)
                      if (_isViewingOwnProfile) ...[
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            debugPrint("DEBUG: Navigating to profile edit screen");
                            context.push('/profile/edit');
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('تعديل الملف الشخصي'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],

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
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
