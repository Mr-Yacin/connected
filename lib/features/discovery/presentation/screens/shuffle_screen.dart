import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/utils/chat_utils.dart';
import '../../../../services/analytics/analytics_events.dart';
import '../../../../services/monitoring/crashlytics_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/discovery_provider.dart';
import '../providers/follow_provider.dart';
import '../providers/like_provider.dart';
import '../widgets/user_card.dart';
import '../widgets/filter_bottom_sheet.dart';

/// Screen for discovering random users (Shuffle feature)
class ShuffleScreen extends ConsumerStatefulWidget {
  const ShuffleScreen({super.key});

  @override
  ConsumerState<ShuffleScreen> createState() => _ShuffleScreenState();
}

class _ShuffleScreenState extends ConsumerState<ShuffleScreen> {
  @override
  void initState() {
    super.initState();
    
    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsEventsProvider).trackScreenView('shuffle_screen');
    });
    
    // Initialize with current user ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
        ref.read(discoveryProvider.notifier).setCurrentUserId(currentUser.uid);
        ref.read(discoveryProvider.notifier).getRandomUser();
      }
    });
  }

  void _showFilterBottomSheet() {
    final currentFilters = ref.read(discoveryProvider).filters;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialFilters: currentFilters,
        onApply: (filters) {
          ref.read(discoveryProvider.notifier).updateFilters(filters);
          ref.read(discoveryProvider.notifier).getRandomUser();
        },
      ),
    );
  }

  Future<void> _handleLike() async {
    final currentUser = ref.read(discoveryProvider).currentUser;
    final loggedInUser = ref.read(currentUserProvider).value;

    if (currentUser != null && loggedInUser != null) {
      try {
        await ref
            .read(likeProvider.notifier)
            .toggleLike(loggedInUser.uid, currentUser.id);

        final isLiked = ref.read(likeProvider).likedUsers[currentUser.id] ?? false;

        // Track like event using existing method
        if (isLiked) {
          await ref.read(analyticsEventsProvider).trackPostLiked(
            postId: currentUser.id,
            authorId: currentUser.id,
          );
        }

        if (mounted) {
          final message = isLiked ? 'تم الإعجاب!' : 'تم إلغاء الإعجاب';
          if (isLiked) {
            SnackbarHelper.showSuccess(context, message);
          } else {
            SnackbarHelper.showInfo(context, message);
          }
        }

        // Auto-shuffle to next user only if liked
        if (isLiked) {
          _loadNextUser();
        }
      } catch (e, stackTrace) {
        await ref.read(crashlyticsServiceProvider).logError(
          e,
          stackTrace,
          reason: 'Failed to like profile',
          information: [
            'screen: shuffle_screen',
            'userId: ${loggedInUser.uid}',
            'likedUserId: ${currentUser.id}',
          ],
        );
        
        if (mounted) {
          SnackbarHelper.showError(context, 'فشل في الإعجاب: $e');
        }
      }
    }
  }

  Future<void> _handleFollow() async {
    final currentUser = ref.read(discoveryProvider).currentUser;
    final loggedInUser = ref.read(currentUserProvider).value;

    if (currentUser != null && loggedInUser != null) {
      try {
        await ref
            .read(followProvider.notifier)
            .toggleFollow(loggedInUser.uid, currentUser.id);

        final isFollowing = ref.read(followProvider).followingStatus[currentUser.id] ?? false;

        // Track follow event
        if (isFollowing) {
          await ref.read(analyticsEventsProvider).trackUserFollowed(
            followedUserId: currentUser.id,
          );
        } else {
          await ref.read(analyticsEventsProvider).trackUserUnfollowed(
            unfollowedUserId: currentUser.id,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFollowing ? 'تمت المتابعة بنجاح!' : 'تم إلغاء المتابعة'),
              backgroundColor: isFollowing ? Colors.green : Colors.orange,
            ),
          );
        }

        // Auto-shuffle to next user only if followed
        if (isFollowing) {
          _loadNextUser();
        }
      } catch (e, stackTrace) {
        await ref.read(crashlyticsServiceProvider).logError(
          e,
          stackTrace,
          reason: 'Failed to follow user',
          information: [
            'screen: shuffle_screen',
            'userId: ${loggedInUser.uid}',
            'followedUserId: ${currentUser.id}',
          ],
        );
        
        if (mounted) {
          SnackbarHelper.showError(context, 'فشل في المتابعة: $e');
        }
      }
    }
  }

  void _handleViewProfile() {
    final currentUser = ref.read(discoveryProvider).currentUser;
    if (currentUser != null) {
      context.push('/profile/${currentUser.id}');
    }
  }

  void _handleChat() {
    final currentUser = ref.read(discoveryProvider).currentUser;
    final loggedInUser = ref.read(currentUserProvider).value;

    if (currentUser != null && loggedInUser != null) {
      // Navigate to chat screen with this user
      final otherUserId = currentUser.id;
      final currentUserId = loggedInUser.uid;
      // Generate deterministic chat ID to prevent duplicates
      final chatId = ChatUtils.generateChatId(currentUserId, otherUserId);

      context.push(
        '/chat/$chatId?currentUserId=$currentUserId&otherUserId=$otherUserId&otherUserName=${Uri.encodeComponent(currentUser.name ?? "")}&otherUserImageUrl=${Uri.encodeComponent(currentUser.profileImageUrl ?? "")}',
      );
    }
  }

  void _loadNextUser() {
    ref.read(discoveryProvider.notifier).shuffleWithCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(discoveryProvider);
    final likeState = ref.watch(likeProvider);
    final followState = ref.watch(followProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loggedInUser = ref.watch(currentUserProvider).value;
    
    // Check if current user is liked/followed
    final currentUser = discoveryState.currentUser;
    
    // Load follow and like status if we have a current user and they're not cached
    if (currentUser != null && loggedInUser != null) {
      final isFollowingCached = followState.followingStatus[currentUser.id];
      final isLikedCached = likeState.likedUsers[currentUser.id];
      
      if (isFollowingCached == null) {
        Future.microtask(() {
          ref.read(followProvider.notifier).checkFollowStatus(
            loggedInUser.uid,
            currentUser.id,
          );
        });
      }
      
      if (isLikedCached == null) {
        Future.microtask(() {
          ref.read(likeProvider.notifier).checkIfLiked(
            loggedInUser.uid,
            currentUser.id,
          );
        });
      }
    }
    
    final isLiked = currentUser != null 
        ? (likeState.likedUsers[currentUser.id] ?? false)
        : false;
    final isFollowing = currentUser != null
        ? (followState.followingStatus[currentUser.id] ?? false)
        : false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الشفل'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
            tooltip: 'الفلاتر',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Filter indicator
              if (discoveryState.filters.hasActiveFilters)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.filter_alt,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'الفلاتر نشطة',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          ref.read(discoveryProvider.notifier).resetFilters();
                          ref.read(discoveryProvider.notifier).getRandomUser();
                        },
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Cooldown indicator
              if (discoveryState.cooldownSeconds > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'انتظر ${discoveryState.cooldownSeconds} ثانية',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),

              // Main content
              Expanded(child: _buildContent(discoveryState, isDark, isLiked, isFollowing)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: discoveryState.canShuffle ? _loadNextUser : null,
        backgroundColor: discoveryState.canShuffle 
            ? AppColors.primary 
            : Colors.grey,
        icon: const Icon(Icons.shuffle),
        label: const Text('شفل'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildContent(DiscoveryState state, bool isDark, bool isLiked, bool isFollowing) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNextUser,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (state.currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'لا يوجد مستخدمين متاحين',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'جرب تغيير الفلاتر أو العودة لاحقاً',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showFilterBottomSheet,
              icon: const Icon(Icons.filter_list),
              label: const Text('تعديل الفلاتر'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: UserCard(
          user: state.currentUser!,
          isLiked: isLiked,
          isFollowing: isFollowing,
          onLike: _handleLike,
          onFollow: _handleFollow,
          onChat: _handleChat,
          onViewProfile: _handleViewProfile,
        ),
      ),
    );
  }
}
