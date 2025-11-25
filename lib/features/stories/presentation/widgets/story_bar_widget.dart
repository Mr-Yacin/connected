import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/story.dart';
import '../providers/story_provider.dart';
import '../screens/story_view_screen.dart';
import '../screens/story_creation_screen.dart';

/// Horizontal bar widget displaying active stories
class StoryBarWidget extends ConsumerWidget {
  final String currentUserId;

  const StoryBarWidget({
    super.key,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(activeStoriesProvider);

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

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: storiesByUser.length + 1, // +1 for "Add Story" button
            itemBuilder: (context, index) {
              // First item is "Add Story" button
              if (index == 0) {
                return _AddStoryButton(userId: currentUserId);
              }

              // Get user stories
              final userId = storiesByUser.keys.elementAt(index - 1);
              final userStories = storiesByUser[userId]!;
              final hasUnviewed = userStories.any(
                (story) => !story.viewerIds.contains(currentUserId),
              );

              return _StoryAvatar(
                userId: userId,
                stories: userStories,
                hasUnviewed: hasUnviewed,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoryViewScreen(
                        stories: userStories,
                        initialIndex: 0,
                        currentUserId: currentUserId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('خطأ في تحميل القصص: $error'),
        ),
      ),
    );
  }
}

/// Add Story button widget
class _AddStoryButton extends StatelessWidget {
  final String userId;

  const _AddStoryButton({required this.userId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryCreationScreen(userId: userId),
          ),
        );
      },
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
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'قصتك',
              style: TextStyle(fontSize: 12),
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

/// Story avatar widget
class _StoryAvatar extends StatelessWidget {
  final String userId;
  final List<Story> stories;
  final bool hasUnviewed;
  final VoidCallback onTap;

  const _StoryAvatar({
    required this.userId,
    required this.stories,
    required this.hasUnviewed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    ? LinearGradient(
                        colors: [
                          Colors.purple,
                          Colors.pink,
                          Colors.orange,
                        ],
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
                  image: stories.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(stories.first.mediaUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.grey[300],
                ),
                child: stories.isEmpty
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userId.substring(0, 8), // Show first 8 chars of userId
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
