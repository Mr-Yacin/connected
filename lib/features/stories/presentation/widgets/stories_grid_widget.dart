import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/story.dart';
import '../../../../core/models/discovery_filters.dart';
import '../../../../services/monitoring/app_logger.dart';
import '../providers/story_provider.dart';
import '../providers/story_user_provider.dart';
import '../screens/multi_user_story_view_screen.dart';
import 'story_card_widget.dart';
import 'story_management_sheet.dart';

/// Stories grid widget with 3-column layout and infinite scroll
class StoriesGridWidget extends ConsumerStatefulWidget {
  final String currentUserId;
  final DiscoveryFilters? filters;

  const StoriesGridWidget({
    super.key,
    required this.currentUserId,
    this.filters,
  });

  @override
  ConsumerState<StoriesGridWidget> createState() => _StoriesGridWidgetState();
}

class _StoriesGridWidgetState extends ConsumerState<StoriesGridWidget> {
  final ScrollController _scrollController = ScrollController();
  List<String> _shuffledUserIds = [];
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Load initial stories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paginatedStoriesProvider.notifier).loadInitialStories();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Detect when user scrolls near bottom (80% threshold)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    ref.read(paginatedStoriesProvider.notifier).loadMoreStories().then((_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    });
  }

  void _navigateToShuffle() {
    // Navigate to shuffle screen (index 1 in bottom nav)
    context.push('/shuffle');
  }

  List<String> _applyFiltersToUserIds(List<String> userIds) {
    final filters = widget.filters;
    
    // If no filters are active, return all user IDs
    if (filters == null || !filters.hasActiveFilters) {
      return userIds;
    }

    // Filter user IDs based on user profiles
    final storyUsersState = ref.read(storyUsersProvider);
    final filteredIds = <String>[];

    AppLogger.debug(
      'Applying filters',
      data: {
        'gender': filters.gender?.toString() ?? 'null',
        'minAge': filters.minAge?.toString() ?? 'null',
        'maxAge': filters.maxAge?.toString() ?? 'null',
        'country': filters.country ?? 'null',
        'totalUsers': userIds.length,
      },
    );

    for (final userId in userIds) {
      final profile = storyUsersState.profiles[userId];
      
      if (profile == null) {
        // If profile not loaded yet, include the user
        AppLogger.debug('Profile not loaded for user: $userId - including by default');
        filteredIds.add(userId);
        continue;
      }

      AppLogger.debug(
        'Checking user',
        data: {
          'name': profile.name ?? userId,
          'age': profile.age?.toString() ?? 'null',
          'gender': profile.gender ?? 'null',
          'country': profile.country ?? 'null',
        },
      );

      // Apply gender filter
      if (filters.gender != null && profile.gender != filters.gender) {
        AppLogger.debug('Filtered out by gender: ${profile.gender} != ${filters.gender}');
        continue;
      }

      // Apply age filter
      if (filters.minAge != null && profile.age != null && profile.age! < filters.minAge!) {
        AppLogger.debug('Filtered out by min age: ${profile.age} < ${filters.minAge}');
        continue;
      }
      if (filters.maxAge != null && profile.age != null && profile.age! > filters.maxAge!) {
        AppLogger.debug('Filtered out by max age: ${profile.age} > ${filters.maxAge}');
        continue;
      }

      // Apply country filter
      if (filters.country != null && profile.country != filters.country) {
        AppLogger.debug('Filtered out by country: ${profile.country} != ${filters.country}');
        continue;
      }

      AppLogger.debug('User passed all filters');
      filteredIds.add(userId);
    }

    AppLogger.debug('Filtered result: ${filteredIds.length} users passed filters');
    return filteredIds;
  }

  @override
  Widget build(BuildContext context) {
    final paginatedState = ref.watch(paginatedStoriesProvider);
    final filters = widget.filters;

    // Group stories by user - this is what we'll display in grid
    final Map<String, List<Story>> storiesByUser = {};
    for (var story in paginatedState.stories) {
      // Skip current user's stories
      if (story.userId == widget.currentUserId) continue;
      
      if (!storiesByUser.containsKey(story.userId)) {
        storiesByUser[story.userId] = [];
      }
      storiesByUser[story.userId]!.add(story);
    }

    // Convert to list of user IDs for grid display
    final List<String> allUserIds = storiesByUser.keys.toList();
    
    // Load user profiles for all story creators
    if (allUserIds.isNotEmpty) {
      Future.microtask(() {
        ref.read(storyUsersProvider.notifier).loadProfiles(allUserIds);
      });
    }
    
    // Apply filters to user IDs
    final filteredUserIds = _applyFiltersToUserIds(allUserIds);
    
    // Initialize or update shuffled list
    // IMPORTANT: Always update when filters change or user count changes
    if (_shuffledUserIds.isEmpty || 
        _shuffledUserIds.length != filteredUserIds.length ||
        !_shuffledUserIds.every((id) => filteredUserIds.contains(id))) {
      _shuffledUserIds = List.from(filteredUserIds)..shuffle();
      AppLogger.debug('Shuffled user list updated: ${_shuffledUserIds.length} users');
    }
    
    final userIds = _shuffledUserIds;

    // Show loading indicator for initial load
    if (paginatedState.stories.isEmpty && paginatedState.isLoadingMore) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error if present
    if (paginatedState.error != null && paginatedState.stories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'خطأ في تحميل القصص',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              paginatedState.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(paginatedStoriesProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (userIds.isEmpty) {
      // Check if it's due to filters or no stories at all
      final hasFilters = filters != null && filters.hasActiveFilters;
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.explore_off : Icons.photo_library_outlined,
              size: hasFilters ? 80 : 64,
              color: hasFilters ? Colors.grey[300] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'لا توجد قصص بهذه الفلاتر' : 'لا توجد قصص متاحة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters ? 'جرب تغيير الفلاتر أو استخدم الشفل' : 'كن أول من يشارك قصة!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _navigateToShuffle,
                icon: const Icon(Icons.shuffle),
                label: const Text('الذهاب للشفل'),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: _shuffledUserIds.length + (paginatedState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the end
        if (index == _shuffledUserIds.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoadingMore
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
            ),
          );
        }

        // Get user ID and all their stories using shuffled order
        final userId = _shuffledUserIds[index];
        final userStories = storiesByUser[userId]!;
        
        // Use the first (most recent) story as preview
        final previewStory = userStories.first;
        
        // Get user profile for display name and profile photo
        return Consumer(
          builder: (context, ref, _) {
            final storyUsersState = ref.watch(storyUsersProvider);
            final userProfile = storyUsersState.profiles[userId];
            final displayName = userProfile?.name ?? 'مستخدم';
            final profileImageUrl = userProfile?.profileImageUrl;

            return StoryCardWidget(
              story: previewStory,
              userName: displayName,
              profileImageUrl: profileImageUrl,
              storiesCount: userStories.length,
              onTap: () {
                // Simple navigation - no animation when opening
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiUserStoryViewScreen(
                      userIds: _shuffledUserIds,
                      currentUserId: widget.currentUserId,
                      initialUserIndex: index,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
