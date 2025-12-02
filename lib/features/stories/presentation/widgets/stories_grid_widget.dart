import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/story.dart';
import '../../../../core/models/discovery_filters.dart';
import '../providers/story_provider.dart';
import '../providers/story_user_provider.dart';
import '../screens/multi_user_story_view_screen.dart';
import 'story_card_widget.dart';

/// Stories grid widget with 3-column layout and infinite scroll
class StoriesGridWidget extends ConsumerStatefulWidget {
  final String currentUserId;

  const StoriesGridWidget({
    super.key,
    required this.currentUserId,
  });

  @override
  ConsumerState<StoriesGridWidget> createState() => _StoriesGridWidgetState();
}

class _StoriesGridWidgetState extends ConsumerState<StoriesGridWidget> {
  final ScrollController _scrollController = ScrollController();
  DiscoveryFilters _filters = DiscoveryFilters();
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

  List<Story> _applyFilters(List<Story> stories) {
    var filteredStories = stories;

    // Apply filters if any are active
    if (_filters.hasActiveFilters) {
      // Note: To filter stories by user properties, we'd need to fetch user data
      // For now, we'll keep all stories and let the shuffle integration handle it
    }

    return filteredStories;
  }

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(activeStoriesProvider);

    return storiesAsync.when(
      data: (allStories) {
        final filteredStories = _applyFilters(allStories);

        // Group stories by user - this is what we'll display in grid
        final Map<String, List<Story>> storiesByUser = {};
        for (var story in filteredStories) {
          if (!storiesByUser.containsKey(story.userId)) {
            storiesByUser[story.userId] = [];
          }
          storiesByUser[story.userId]!.add(story);
        }

        // Convert to list of user IDs for grid display
        final List<String> userIds = storiesByUser.keys.toList();
        
        // Load user profiles for all story creators
        if (userIds.isNotEmpty) {
          Future.microtask(() {
            ref.read(storyUsersProvider.notifier).loadProfiles(userIds);
          });
        }
        
        // Initialize or update shuffled list
        if (_shuffledUserIds.isEmpty || _shuffledUserIds.length != userIds.length) {
          _shuffledUserIds = List.from(userIds)..shuffle();
        }

        if (userIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد قصص متاحة',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'كن أول من يشارك قصة!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Filter bar
            if (_filters.hasActiveFilters)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_alt,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'الفلاتر نشطة',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _filters = DiscoveryFilters();
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Stories grid - ONE CARD PER USER
            Expanded(
            child: userIds.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.explore_off,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد قصص بهذه الفلاتر',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'جرب تغيير الفلاتر أو استخدم الشفل',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[500],
                                ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _filters = DiscoveryFilters();
                                  });
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('إزالة الفلاتر'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: _navigateToShuffle,
                                icon: const Icon(Icons.shuffle),
                                label: const Text('الذهاب للشفل'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                        
                        // Get user profile for display name
                        return Consumer(
                          builder: (context, ref, _) {
                            final storyUsersState = ref.watch(storyUsersProvider);
                            final userProfile = storyUsersState.profiles[userId];
                            final displayName = userProfile?.name ?? 'مستخدم';

                            return StoryCardWidget(
                              story: previewStory,
                              userName: displayName,
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
                    ),
          ),
        ],
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
