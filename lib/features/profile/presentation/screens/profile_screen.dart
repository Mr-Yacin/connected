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
import '../providers/current_user_profile_provider.dart';

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
  String? _lastViewedUserId; // Track the last viewed user to detect changes

  @override
  void initState() {
    super.initState();
    _lastViewedUserId = widget.viewedUserId;
    // Listen for user changes to load profile once user is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadProfile(forceReload: true);
    });
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // This is called when widget is rebuilt with different parameters
    if (oldWidget.viewedUserId != widget.viewedUserId) {
      debugPrint("DEBUG: didUpdateWidget - viewedUserId changed from ${oldWidget.viewedUserId} to ${widget.viewedUserId}");
      _lastViewedUserId = widget.viewedUserId;
      _hasLoadedProfile = false;
      _profileFetchInProgress = false; // Reset fetch flag
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndLoadProfile(forceReload: true);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if viewedUserId has changed
    final currentViewedUserId = widget.viewedUserId;
    bool userIdChanged = false;
    if (_lastViewedUserId != currentViewedUserId) {
      debugPrint("DEBUG: didChangeDependencies - viewedUserId changed from $_lastViewedUserId to $currentViewedUserId");
      _lastViewedUserId = currentViewedUserId;
      userIdChanged = true;
      // Reset loaded flag to force reload when user changes
      _hasLoadedProfile = false;
    }
    
    if (!_hasLoadedProfile &&
        !_profileFetchInProgress &&
        !_profileLoadScheduled) {
      _profileLoadScheduled = true;
      Future.microtask(() async {
        _profileLoadScheduled = false;
        await _checkAndLoadProfile(forceReload: userIdChanged);
      });
    }
  }

  Future<void> _checkAndLoadProfile({String? userId, bool forceReload = false}) async {
    if (_profileFetchInProgress) return;

    final resolvedUserId =
        userId ??
        widget.viewedUserId ??
        ref.read(currentUserProvider).value?.uid ??
        FirebaseAuth.instance.currentUser?.uid;

    debugPrint("DEBUG: _checkAndLoadProfile called. userId: $resolvedUserId, forceReload: $forceReload");
    
    // Determine which provider to use based on whether viewing own profile
    final isOwnProfile = widget.viewedUserId == null;
    
    if (isOwnProfile) {
      debugPrint("DEBUG: Current state loadedUserId: ${ref.read(currentUserProfileProvider).loadedUserId}");
    } else {
      debugPrint("DEBUG: Current state loadedUserId: ${ref.read(viewedProfileProvider).loadedUserId}");
    }

    if (resolvedUserId == null) {
      debugPrint("DEBUG: userId is null, cannot load profile");
      return;
    }

    // Use the correct provider based on context
    final notifier = isOwnProfile
        ? ref.read(currentUserProfileProvider.notifier)
        : ref.read(viewedProfileProvider.notifier);

    final currentState = isOwnProfile
        ? ref.read(currentUserProfileProvider)
        : ref.read(viewedProfileProvider);

    // Check if we need to force reload (when switching users)
    if (forceReload || currentState.loadedUserId != resolvedUserId) {
      debugPrint("DEBUG: Force reloading profile for user: $resolvedUserId");
      // Clear the current state to force reload
      notifier.resetState();
    }

    _profileFetchInProgress = true;
    try {
      await notifier.loadProfile(resolvedUserId);
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
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('تم نسخ الرابط'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
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
          .read(currentUserProfileProvider.notifier)
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
    // Use DIFFERENT providers based on whether viewing own profile or another's
    final profileState = widget.viewedUserId == null
        ? ref.watch(currentUserProfileProvider)  // Own profile
        : ref.watch(viewedProfileProvider);       // Other user's profile
    
    final profile = profileState.profile;
    
    debugPrint("DEBUG: ProfileScreen build - viewedUserId: ${widget.viewedUserId}, loadedUserId: ${profileState.loadedUserId}, hasProfile: ${profile != null}");

    return Scaffold(
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
              : CustomScrollView(
                  slivers: [
                    // Gradient Header with Profile Image
                    SliverAppBar(
                      expandedHeight: 280,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        background: _buildProfileHeader(profile),
                      ),
                      actions: [
                        if (_isViewingOwnProfile)
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () => context.push('/settings'),
                            tooltip: 'الإعدادات',
                          )
                        else
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
                    ),

                    // Content
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),

                          // Quick Actions (only for own profile)
                          if (_isViewingOwnProfile)
                            _buildQuickActions(profile),

                          const SizedBox(height: 24),

                          // Profile Information Grid
                          _buildInformationGrid(profile),

                          const SizedBox(height: 24),

                          // Anonymous Link Card
                          if (_isViewingOwnProfile && profile.anonymousLink != null)
                            _buildAnonymousLinkCard(profile),

                          if (profileState.error != null) ...[
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  profileState.error!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildProfileHeader(dynamic profile) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Profile Image with Gradient Border
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.8),
                    Colors.white.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.white,
                    backgroundImage: profile.profileImageUrl != null
                        ? NetworkImage(profile.profileImageUrl!)
                        : null,
                    child: profile.profileImageUrl == null
                        ? const Icon(Icons.person, size: 56, color: Colors.grey)
                        : null,
                  ),
                  if (profile.isImageBlurred)
                    Positioned.fill(
                      child: ClipOval(
                        child: Container(
                          color: Colors.black54,
                          child: const Icon(
                            Icons.blur_on,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              profile.name ?? 'غير محدد',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Country and Age Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        profile.country ?? 'غير محدد',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cake, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        profile.age != null ? '${profile.age} سنة' : 'غير محدد',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(dynamic profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.edit_outlined,
              label: 'تعديل الملف',
              gradient: AppColors.primaryGradient,
              onTap: () => context.push('/profile/edit'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: profile.anonymousLink != null ? Icons.link : Icons.add_link,
              label: profile.anonymousLink != null ? 'مشاركة الرابط' : 'توليد رابط',
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              onTap: () {
                if (profile.anonymousLink != null) {
                  final fullUrl = _buildFullAnonymousUrl(profile.anonymousLink!);
                  _shareAnonymousLink(fullUrl);
                } else {
                  _generateAnonymousLink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationGrid(dynamic profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات الملف الشخصي',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.people,
                  label: 'المتابعون',
                  value: '${profile.followerCount ?? 0}',
                  color: AppColors.primary,
                ),
                _buildStatItem(
                  icon: Icons.person_add,
                  label: 'المتابَعون',
                  value: '${profile.followingCount ?? 0}',
                  color: AppColors.secondary,
                ),
                _buildStatItem(
                  icon: Icons.favorite,
                  label: 'الإعجابات',
                  value: '${profile.likesCount ?? 0}',
                  color: Colors.red,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            _buildCompactInfoItem(
              icon: Icons.blur_on,
              label: 'خصوصية الصورة',
              value: profile.isImageBlurred ? 'مموهة' : 'ظاهرة',
              color: profile.isImageBlurred ? Colors.orange : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnonymousLinkCard(dynamic profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary.withValues(alpha: 0.1),
              AppColors.primary.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.link,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الرابط المجهول',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'شارك ملفك الشخصي بشكل مجهول',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _buildFullAnonymousUrl(profile.anonymousLink!),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      final fullUrl = _buildFullAnonymousUrl(profile.anonymousLink!);
                      _copyAnonymousLink(fullUrl);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.copy,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      final fullUrl = _buildFullAnonymousUrl(profile.anonymousLink!);
                      _shareAnonymousLink(fullUrl);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.share,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
