import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/story.dart';
import '../providers/story_provider.dart';
import '../providers/story_user_provider.dart';
import '../screens/multi_user_story_view_screen.dart';
import '../screens/story_camera_screen.dart';

/// Horizontal bar widget displaying active stories
class StoryBarWidget extends ConsumerWidget {
  final String currentUserId;

  const StoryBarWidget({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use followingStoriesProvider to show stories from followed users + own stories
    final storiesAsync = ref.watch(followingStoriesProvider);

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: storiesAsync.when(
        data: (stories) {
          // Group stories by user
          final Map<String, List<Story>> storiesByUser = {};
          for (var story in stories) {
            if (!storiesByUser.containsKey(story.userId)) {
              storiesByUser[story.userId] = [];
            }
            storiesByUser[story.userId]!.add(story);
          }

          // Separate own stories from following stories
          final ownStories = storiesByUser[currentUserId];
          final followingStoriesMap = Map<String, List<Story>>.from(storiesByUser);
          followingStoriesMap.remove(currentUserId);

          // Load user profiles for all story creators
          final userIds = storiesByUser.keys.toList();
          if (userIds.isNotEmpty) {
            // Trigger profile loading
            Future.microtask(() {
              ref.read(storyUsersProvider.notifier).loadProfiles(userIds);
            });
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: 1 + followingStoriesMap.length, // Always show own profile
            itemBuilder: (context, index) {
              // First item is always own profile (with or without stories)
              if (index == 0) {
                final hasUnviewed = ownStories?.any(
                  (story) => !story.viewerIds.contains(currentUserId),
                ) ?? false;
                
                return _StoryAvatar(
                  userId: currentUserId,
                  stories: ownStories,
                  hasUnviewed: hasUnviewed,
                  isOwnStory: true,
                  hasStories: ownStories != null && ownStories.isNotEmpty,
                  // Tap on avatar: view stories if exist, otherwise create
                  onTap: () {
                    if (ownStories != null && ownStories.isNotEmpty) {
                      // View own stories
                      final allUserIds = [currentUserId, ...followingStoriesMap.keys];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MultiUserStoryViewScreen(
                            userIds: allUserIds,
                            currentUserId: currentUserId,
                            initialUserIndex: 0,
                          ),
                        ),
                      );
                    } else {
                      // Create new story (fallback if no stories)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoryCameraScreen(
                            userId: currentUserId,
                          ),
                        ),
                      );
                    }
                  },
                  // Tap on + icon: always create new story
                  onPlusTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoryCameraScreen(
                          userId: currentUserId,
                        ),
                      ),
                    );
                  },
                );
              }

              // Following stories
              final followingIndex = index - 1; // Always subtract 1 since own profile is always first
              
              // ✅ FIX: Add bounds check to prevent crash
              if (followingIndex < 0 || followingIndex >= followingStoriesMap.length) {
                return const SizedBox.shrink();
              }
              
              final userId = followingStoriesMap.keys.elementAt(followingIndex);
              final userStories = followingStoriesMap[userId]!;
              final hasUnviewed = userStories.any(
                (story) => !story.viewerIds.contains(currentUserId),
              );

              // Build list of all user IDs in order (own profile always first)
              final allUserIds = [currentUserId, ...followingStoriesMap.keys];
              
              // Calculate the correct initial index
              final initialUserIndex = index;

              return _StoryAvatar(
                userId: userId,
                stories: userStories,
                hasUnviewed: hasUnviewed,
                isOwnStory: false,
                hasStories: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MultiUserStoryViewScreen(
                        userIds: allUserIds,
                        currentUserId: currentUserId,
                        initialUserIndex: initialUserIndex,
                      ),
                    ),
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
                ref.refresh(followingStoriesProvider);
              }
            });

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    'جاري تحميل القصص...',
                    style: TextStyle(
                      fontSize: 12,
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
                const Icon(Icons.error_outline, size: 32, color: Colors.red),
                const SizedBox(height: 8),
                Text('خطأ في تحميل القصص', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => ref.refresh(followingStoriesProvider),
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Story avatar widget
class _StoryAvatar extends ConsumerWidget {
  final String userId;
  final List<Story>? stories;
  final bool hasUnviewed;
  final bool isOwnStory;
  final bool hasStories;
  final VoidCallback onTap;
  final VoidCallback? onPlusTap; // New: separate tap for + icon

  const _StoryAvatar({
    required this.userId,
    required this.stories,
    required this.hasUnviewed,
    required this.isOwnStory,
    required this.hasStories,
    required this.onTap,
    this.onPlusTap, // Optional: only for own story
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user profile from cache
    final storyUsersState = ref.watch(storyUsersProvider);
    final userProfile = storyUsersState.profiles[userId];

    // Determine display name: use "قصتي" for own stories, otherwise use profile name
    final displayName = isOwnStory 
        ? 'قصتي' 
        : (userProfile?.name ?? 'مستخدم');

    // Get profile image URL, fallback to story media if not available
    final profileImageUrl = userProfile?.profileImageUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasUnviewed && hasStories
                        ? const LinearGradient(
                            colors: [Colors.purple, Colors.pink, Colors.orange],
                          )
                        : null,
                    border: !hasUnviewed || !hasStories
                        ? Border.all(color: Colors.grey, width: 2)
                        : null,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: profileImageUrl != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(profileImageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: profileImageUrl == null ? Colors.grey[300] : null,
                    ),
                    child: profileImageUrl == null
                        ? const Icon(Icons.person, color: Colors.grey, size: 30)
                        : null,
                  ),
                ),
                // Show "+" icon for own story (always visible, separately tappable)
                if (isOwnStory)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: GestureDetector(
                      onTap: onPlusTap ?? onTap, // Use separate handler if provided
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              displayName,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
