import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/story.dart';
import '../../../../core/models/discovery_filters.dart';
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
  int _scrollToBottomCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.95) {
      // Auto-shuffle when reaching bottom
      _handleScrollToBottom();
    }
  }

  void _handleScrollToBottom() {
    if (_shuffledUserIds.isEmpty) return;
    
    _scrollToBottomCount++;
    
    // Shuffle logic based on story count
    final shouldShuffle = _shuffledUserIds.length < 10 
        ? true  // Always shuffle if few stories
        : _scrollToBottomCount % 3 == 0;  // Every 3rd scroll if many stories
    
    if (shouldShuffle) {
      setState(() {
        _shuffledUserIds = List.from(_shuffledUserIds)..shuffle();
      });
    }
  }

  void _navigateToShuffle() {
    // Navigate to shuffle screen (index 1 in bottom nav)
    context.push('/shuffle');
  }

  void _showStoryManagementSheet(BuildContext context, Story story) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryManagementSheet(
        story: story,
        currentUserId: widget.currentUserId,
      ),
    );
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

    print('🔍 Applying filters: gender=${filters.gender}, minAge=${filters.minAge}, maxAge=${filters.maxAge}, country=${filters.country}');
    print('📊 Total users to filter: ${userIds.length}');

    for (final userId in userIds) {
      final profile = storyUsersState.profiles[userId];
      
      if (profile == null) {
        // If profile not loaded yet, include the user
        print('⚠️ Profile not loaded for user: $userId - including by default');
        filteredIds.add(userId);
        continue;
      }

      print('👤 Checking user: ${profile.name ?? userId} - age: ${profile.age}, gender: ${profile.gender}, country: ${profile.country}');

      // Apply gender filter
      if (filters.gender != null && profile.gender != filters.gender) {
        print('  ❌ Filtered out by gender: ${profile.gender} != ${filters.gender}');
        continue;
      }

      // Apply age filter
      if (filters.minAge != null && profile.age != null && profile.age! < filters.minAge!) {
        print('  ❌ Filtered out by min age: ${profile.age} < ${filters.minAge}');
        continue;
      }
      if (filters.maxAge != null && profile.age != null && profile.age! > filters.maxAge!) {
        print('  ❌ Filtered out by max age: ${profile.age} > ${filters.maxAge}');
        continue;
      }

      // Apply country filter
      if (filters.country != null && profile.country != filters.country) {
        print('  ❌ Filtered out by country: ${profile.country} != ${filters.country}');
        continue;
      }

      print('  ✅ User passed all filters');
      filteredIds.add(userId);
    }

    print('✅ Filtered result: ${filteredIds.length} users passed filters');
    return filteredIds;
  }

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(activeStoriesProvider);
    final filters = widget.filters;

    return storiesAsync.when(
      data: (allStories) {
        // Group stories by user - this is what we'll display in grid
        final Map<String, List<Story>> storiesByUser = {};
        for (var story in allStories) {
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
          print('🔄 Shuffled user list updated: ${_shuffledUserIds.length} users');
        }
        
        final userIds = _shuffledUserIds;

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
          itemCount: _shuffledUserIds.length,
          itemBuilder: (context, index) {
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
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        // ✅ Handle permission-denied errors gracefully with retry
        if (error.toString().contains('permission-denied') || 
            error.toString().contains('PERMISSION_DENIED')) {
          // Auto-retry after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              ref.refresh(activeStoriesProvider);
            }
          });
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'جاري تحميل القصص...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'يرجى الانتظار قليلاً',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        }
        
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
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(activeStoriesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        );
      },
    );
  }
}
