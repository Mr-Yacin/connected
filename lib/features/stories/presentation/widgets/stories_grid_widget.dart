import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/story.dart';
import '../../../../core/models/discovery_filters.dart';
import '../providers/story_provider.dart';
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
  bool _hasLoadedAll = false;

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
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when 80% scrolled
      _loadMore();
    }
  }

  void _loadMore() {
    // In a real app, implement pagination here
    // For now, just check if we've reached the end
    if (!_hasLoadedAll) {
      setState(() {
        _hasLoadedAll = true;
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

        if (userIds.isEmpty && !_hasLoadedAll) {
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
                      itemCount: userIds.length +
                          (_hasLoadedAll ? 0 : 1), // +1 for load more/shuffle
                      itemBuilder: (context, index) {
                        // Show shuffle prompt when reaching the end
                        if (index == userIds.length) {
                          return GestureDetector(
                            onTap: _navigateToShuffle,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shuffle,
                                    size: 40,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'المزيد',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'الشفل',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Get user ID and all their stories
                        final userId = userIds[index];
                        final userStories = storiesByUser[userId]!;
                        
                        // Use the first (most recent) story as preview
                        final previewStory = userStories.first;

                        return StoryCardWidget(
                          story: previewStory,
                          userName: userId.substring(0, 8),
                          storiesCount: userStories.length, // Pass story count
                          onTap: () {
                            // Simple navigation - no animation when opening
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MultiUserStoryViewScreen(
                                  userIds: userIds,
                                  currentUserId: widget.currentUserId,
                                  initialUserIndex: index,
                                ),
                              ),
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
      error: (error, stack) => Center(
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
          ],
        ),
      ),
    );
  }
}
