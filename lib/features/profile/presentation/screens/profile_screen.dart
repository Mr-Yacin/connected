import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/enums.dart';
import '../../../../services/analytics_events.dart';
import '../../../../services/crashlytics_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../moderation/presentation/providers/moderation_provider.dart';
import '../../../moderation/presentation/widgets/report_bottom_sheet.dart';
import '../../../discovery/presentation/providers/follow_provider.dart';

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

    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isOwnProfile = widget.viewedUserId == null;
      ref
          .read(analyticsEventsProvider)
          .trackScreenView(
            isOwnProfile ? 'own_profile_screen' : 'user_profile_screen',
          );
    });

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
      debugPrint(
        "DEBUG: didUpdateWidget - viewedUserId changed from ${oldWidget.viewedUserId} to ${widget.viewedUserId}",
      );
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
      debugPrint(
        "DEBUG: didChangeDependencies - viewedUserId changed from $_lastViewedUserId to $currentViewedUserId",
      );
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

  Future<void> _checkAndLoadProfile({
    String? userId,
    bool forceReload = false,
  }) async {
    if (_profileFetchInProgress) return;

    final resolvedUserId =
        userId ??
        widget.viewedUserId ??
        ref.read(currentUserProvider).value?.uid ??
        FirebaseAuth.instance.currentUser?.uid;

    debugPrint(
      "DEBUG: _checkAndLoadProfile called. userId: $resolvedUserId, forceReload: $forceReload",
    );

    // Determine which provider to use based on whether viewing own profile
    final isOwnProfile = widget.viewedUserId == null;

    if (isOwnProfile) {
      debugPrint(
        "DEBUG: Current state loadedUserId: ${ref.read(currentUserProfileProvider).loadedUserId}",
      );
    } else {
      debugPrint(
        "DEBUG: Current state loadedUserId: ${ref.read(viewedProfileProvider).loadedUserId}",
      );
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
    } catch (e, stackTrace) {
      debugPrint("ERROR: Failed to load profile: $e");
      await ref
          .read(crashlyticsServiceProvider)
          .logError(
            e,
            stackTrace,
            reason: 'Failed to load profile',
            information: [
              'screen: profile_screen',
              'userId: $resolvedUserId',
              'isOwnProfile: ${isOwnProfile.toString()}',
            ],
          );
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
      try {
        debugPrint("DEBUG: Blocking user: $viewedUserId");
        await ref
            .read(moderationProvider.notifier)
            .blockUser(currentUserId, viewedUserId);

        // Log block action
        await ref
            .read(crashlyticsServiceProvider)
            .log('User blocked: $currentUserId blocked $viewedUserId');

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم حظر المستخدم')));
          Navigator.of(context).pop();
        }
      } catch (e, stackTrace) {
        await ref
            .read(crashlyticsServiceProvider)
            .logError(
              e,
              stackTrace,
              reason: 'Failed to block user from profile',
              information: [
                'screen: profile_screen',
                'currentUserId: $currentUserId',
                'viewedUserId: $viewedUserId',
              ],
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في حظر المستخدم'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في نسخ الرابط: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في مشاركة الرابط: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في توليد الرابط: $e')));
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
        ? ref.watch(currentUserProfileProvider) // Own profile
        : ref.watch(viewedProfileProvider); // Other user's profile

    final profile = profileState.profile;

    debugPrint(
      "DEBUG: ProfileScreen build - viewedUserId: ${widget.viewedUserId}, loadedUserId: ${profileState.loadedUserId}, hasProfile: ${profile != null}",
    );

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
                  expandedHeight: 185,
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

                      // Bio Card (if available)
                      if (profile.bio != null && profile.bio!.isNotEmpty)
                        _buildBioCard(profile),

                      if (profile.bio != null && profile.bio!.isNotEmpty)
                        const SizedBox(height: 16),

                      // Follow/Message buttons for other users' profiles
                      if (!_isViewingOwnProfile)
                        _buildOtherUserActions(profile),

                      if (!_isViewingOwnProfile) const SizedBox(height: 24),

                      // Quick Actions (only for own profile)
                      if (_isViewingOwnProfile) _buildQuickActions(profile),

                      const SizedBox(height: 24),

                      // Profile Information Grid
                      _buildInformationGrid(profile),

                      const SizedBox(height: 24),

                      // View Likes Button (only for own profile)
                      if (_isViewingOwnProfile && profile.likesCount > 0)
                        _buildViewLikesButton(profile),

                      if (_isViewingOwnProfile && profile.likesCount > 0)
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
      decoration: BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Image
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: profile.profileImageUrl != null
                          ? NetworkImage(profile.profileImageUrl!)
                          : null,
                      child: profile.profileImageUrl == null
                          ? Icon(
                              Icons.person,
                              size: 38,
                              color: Colors.grey[400],
                            )
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
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 9),

              // Name and Info Combined
              Column(
                children: [
                  Text(
                    profile.name ?? 'مستخدم',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (profile.age != null) ...[
                        Icon(
                          Icons.cake_outlined,
                          size: 12.5,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${profile.age}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (profile.age != null && profile.country != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.5),
                          child: Container(
                            width: 2.5,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      if (profile.country != null) ...[
                        Icon(
                          Icons.location_on_outlined,
                          size: 12.5,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            profile.country!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherUserActions(dynamic profile) {
    final currentUserId = ref.currentUserId;
    if (currentUserId == null) return const SizedBox.shrink();

    final followState = ref.watch(followProvider);

    // Load follow status from Firestore if not in cache
    final isFollowing = followState.followingStatus[profile.id];

    // If we don't have the follow status cached, load it
    if (isFollowing == null) {
      // Load asynchronously without blocking the UI
      Future.microtask(() {
        ref
            .read(followProvider.notifier)
            .checkFollowStatus(currentUserId, profile.id);
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: (isFollowing ?? false)
                  ? Icons.person_remove_outlined
                  : Icons.person_add_outlined,
              label: (isFollowing ?? false) ? 'إلغاء المتابعة' : 'متابعة',
              gradient: (isFollowing ?? false)
                  ? LinearGradient(
                      colors: [Colors.grey.shade600, Colors.grey.shade700],
                    )
                  : AppColors.primaryGradient,
              onTap: () async {
                try {
                  await ref
                      .read(followProvider.notifier)
                      .toggleFollow(currentUserId, profile.id);

                  final newStatus =
                      ref.read(followProvider).followingStatus[profile.id] ??
                      false;

                  // Refresh the viewed profile to get updated counts
                  await ref
                      .read(viewedProfileProvider.notifier)
                      .refreshProfile(profile.id);

                  // Also refresh current user's profile to update their following count
                  await ref
                      .read(currentUserProfileProvider.notifier)
                      .refreshProfile(currentUserId);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          newStatus
                              ? 'تمت المتابعة بنجاح!'
                              : 'تم إلغاء المتابعة',
                        ),
                        backgroundColor: newStatus
                            ? Colors.green
                            : Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل في المتابعة: $e')),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.chat_bubble_outline,
              label: 'محادثة',
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              onTap: () {
                final otherUserId = profile.id;
                final chatId = 'new_$otherUserId';

                context.push(
                  '/chat/$chatId?currentUserId=$currentUserId&otherUserId=$otherUserId&otherUserName=${Uri.encodeComponent(profile.name ?? "")}&otherUserImageUrl=${Uri.encodeComponent(profile.profileImageUrl ?? "")}',
                );
              },
            ),
          ),
        ],
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
              icon: Icons.edit,
              label: 'تعديل',
              gradient: AppColors.primaryGradient,
              onTap: () => context.push('/profile/edit'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: profile.anonymousLink != null
                  ? Icons.share
                  : Icons.add_link,
              label: profile.anonymousLink != null ? 'مشاركة' : 'رابط',
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              onTap: () {
                if (profile.anonymousLink != null) {
                  final fullUrl = _buildFullAnonymousUrl(
                    profile.anonymousLink!,
                  );
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
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
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).cardTheme.shadowColor ??
                  Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.favorite,
              value: '${profile.likesCount ?? 0}',
              color: Colors.red.shade400,
              onTap: _isViewingOwnProfile && (profile.likesCount ?? 0) > 0
                  ? () => context.push('/likes')
                  : null,
            ),
            Container(width: 1, height: 40, color: Colors.grey.shade200),
            _buildStatItem(
              icon: Icons.people,
              value: '${profile.followerCount ?? 0}',
              color: AppColors.primary,
              onTap: (profile.followerCount ?? 0) > 0
                  ? () => context.push(
                      '/followers/${profile.id}?userName=${Uri.encodeComponent(profile.name ?? "المستخدم")}',
                    )
                  : null,
            ),
            Container(width: 1, height: 40, color: Colors.grey.shade200),
            _buildStatItem(
              icon: Icons.person_add,
              value: '${profile.followingCount ?? 0}',
              color: AppColors.secondary,
              onTap: (profile.followingCount ?? 0) > 0
                  ? () => context.push(
                      '/following/${profile.id}?userName=${Uri.encodeComponent(profile.name ?? "المستخدم")}',
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    final child = Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(padding: const EdgeInsets.all(8), child: child),
      );
    }

    return child;
  }

  Widget _buildBioCard(dynamic profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).cardTheme.shadowColor ??
                  Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                profile.bio!,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewLikesButton(dynamic profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => context.push('/likes'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink.shade400, Colors.red.shade400],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                'عرض الإعجابات (${profile.likesCount})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnonymousLinkCard(dynamic profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).cardTheme.shadowColor ??
                  Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.link, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _buildFullAnonymousUrl(profile.anonymousLink!),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
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
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
