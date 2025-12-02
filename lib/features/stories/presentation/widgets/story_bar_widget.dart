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
            itemCount: (ownStories != null ? 1 : 0) + followingStoriesMap.length,
            itemBuilder: (context, index) {
              // First item is own stories if they exist
              if (ownStories != null && index == 0) {
                final hasUnviewed = ownStories.any(
                  (story) => !story.viewerIds.contains(currentUserId),
                );
                
                // Build list of all user IDs in order (own stories first)
                final allUserIds = [currentUserId, ...followingStoriesMap.keys];
                
                return _StoryAvatar(
                  userId: currentUserId,
                  stories: ownStories,
                  hasUnviewed: hasUnviewed,
                  isOwnStory: true,
                  onTap: () {
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
                  },
                );
              }

              // Following stories
              final followingIndex = ownStories != null ? index - 1 : index;
              final userId = followingStoriesMap.keys.elementAt(followingIndex);
              final userStories = followingStoriesMap[userId]!;
              final hasUnviewed = userStories.any(
                (story) => !story.viewerIds.contains(currentUserId),
              );

              // Build list of all user IDs in order
              final allUserIds = ownStories != null 
                  ? [currentUserId, ...followingStoriesMap.keys]
                  : followingStoriesMap.keys.toList();
              
              // Calculate the correct initial index
              final initialUserIndex = ownStories != null 
                  ? followingIndex + 1 
                  : followingIndex;

              return _StoryAvatar(
                userId: userId,
                stories: userStories,
                hasUnviewed: hasUnviewed,
                isOwnStory: false,
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
  final List<Story> stories;
  final bool hasUnviewed;
  final bool isOwnStory;
  final VoidCallback onTap;

  const _StoryAvatar({
    required this.userId,
    required this.stories,
    required this.hasUnviewed,
    required this.isOwnStory,
    required this.onTap,
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
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewed
                    ? const LinearGradient(
                        colors: [Colors.purple, Colors.pink, Colors.orange],
                      )
                    : null,
                border: !hasUnviewed
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
