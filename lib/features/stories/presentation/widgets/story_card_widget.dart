import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/story.dart';
import '../../../../core/models/enums.dart';
import '../../utils/story_time_formatter.dart';
import 'common/story_profile_avatar.dart';

/// Individual story card widget for grid display
/// Shows ONE card per user with all their stories count
class StoryCardWidget extends StatelessWidget {
  final Story story;
  final String? userName;
  final String? profileImageUrl; // User's profile photo
  final int storiesCount; // Number of stories this user has
  final VoidCallback onTap;

  const StoryCardWidget({
    super.key,
    required this.story,
    this.userName,
    this.profileImageUrl,
    this.storiesCount = 1,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            // Layered effect for multiple stories (background layers)
            if (storiesCount > 1) ...[
            Positioned(
              top: 4,
              left: 4,
              right: 4,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[400],
                ),
              ),
            ),
            if (storiesCount > 2)
              Positioned(
                top: 2,
                left: 2,
                right: 2,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                  ),
                ),
              ),
          ],
          
          // Main card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
              // Story preview image
              if (story.type == StoryType.image)
                CachedNetworkImage(
                  imageUrl: story.mediaUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                )
              else
                // Video placeholder
                Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),

              // Gradient overlay at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // User name at bottom left
                      if (userName != null)
                        Expanded(
                          child: Text(
                            userName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Profile avatar at bottom right
                      StoryProfileAvatar(
                        profileImageUrl: profileImageUrl,
                        size: 32,
                        borderWidth: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // Time at top left
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    StoryTimeFormatter.getTimeAgo(story.createdAt),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Stories count indicator at top right
              if (storiesCount > 1)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.layers,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$storiesCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


            ],
          ),
        ),
      ),
          ],
        ),
      ),
    );
  }
}
