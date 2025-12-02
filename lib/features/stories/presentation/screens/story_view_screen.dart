import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/story.dart';
import '../../../../core/models/enums.dart';
import '../../../../services/analytics/analytics_events.dart';
import '../../../../services/monitoring/crashlytics_service.dart';
import '../providers/story_provider.dart';
import '../providers/story_user_provider.dart';
import '../../utils/story_time_formatter.dart';

/// Screen for viewing stories in fullscreen mode
class StoryViewScreen extends ConsumerStatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final String currentUserId;

  const StoryViewScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.currentUserId,
  });

  @override
  ConsumerState<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends ConsumerState<StoryViewScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  Timer? _progressTimer;
  static const Duration _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    );

    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsEventsProvider).trackScreenView('story_view_screen');

      // Load user profile for story creator
      if (widget.stories.isNotEmpty) {
        final userId = widget.stories.first.userId;
        ref.read(storyUsersProvider.notifier).loadProfiles([userId]);
      }
    });

    _startStory();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startStory() {
    _progressController.reset();
    _progressController.forward();

    // Record view only if viewing someone else's story
    final story = widget.stories[_currentIndex];
    if (story.userId != widget.currentUserId) {
      ref
          .read(storyCreationProvider.notifier)
          .recordView(story.id, widget.currentUserId)
          .then((_) {
            // Track story view event
            ref
                .read(analyticsEventsProvider)
                .trackStoryViewed(storyId: story.id, authorId: story.userId);

            // Refresh UI after recording view
            ref.invalidate(activeStoriesProvider);
          })
          .catchError((e, stackTrace) {
            // Log error if view recording fails
            ref
                .read(crashlyticsServiceProvider)
                .logError(
                  e,
                  stackTrace,
                  reason: 'Failed to record story view',
                  information: [
                    'screen: story_view_screen',
                    'storyId: ${story.id}',
                    'viewerId: ${widget.currentUserId}',
                  ],
                );
          });
    }

    // Auto-advance to next story
    _progressTimer?.cancel();
    _progressTimer = Timer(_storyDuration, () {
      _nextStory();
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _startStory();
    }
  }

  void _pauseStory() {
    _progressController.stop();
    _progressTimer?.cancel();
  }

  void _resumeStory() {
    _progressController.forward();
    final remainingTime = _storyDuration * (1 - _progressController.value);
    _progressTimer?.cancel();
    _progressTimer = Timer(remainingTime, () {
      _nextStory();
    });
  }

  /// Delete the current story
  Future<void> _deleteStory() async {
    final story = widget.stories[_currentIndex];

    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القصة'),
        content: const Text(
          'هل تريد حذف هذه القصة؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(storyCreationProvider.notifier).deleteStory(story.id);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف القصة بنجاح')));

        // If this was the only story, go back
        if (widget.stories.length == 1) {
          Navigator.pop(context);
        } else {
          // Otherwise, move to next story or close if it was the last
          if (_currentIndex >= widget.stories.length - 1) {
            Navigator.pop(context);
          } else {
            _nextStory();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في حذف القصة: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false, // We handle bottom padding manually
        child: GestureDetector(
          onTapDown: (details) {
            _pauseStory();
          },
          onTapUp: (details) {
            _resumeStory();

            // Determine tap location for navigation
            final screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth / 3) {
              _previousStory();
            } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
              _nextStory();
            }
          },
          onLongPressStart: (_) {
            _pauseStory();
          },
          onLongPressEnd: (_) {
            _resumeStory();
          },
          child: Stack(
            children: [
              // Story content
              Center(
                child: story.type == StoryType.image
                    ? CachedNetworkImage(
                        imageUrl: story.mediaUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 50,
                          ),
                        )
                      )
                    : const Center(
                        child: Text(
                          'فيديو',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ),
              ),

              // Progress indicators
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 8,
                child: Row(
                  children: List.generate(
                    widget.stories.length,
                    (index) => Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: index < _currentIndex
                            ? Container(color: Colors.white)
                            : index == _currentIndex
                            ? AnimatedBuilder(
                                animation: _progressController,
                                builder: (context, child) {
                                  return LinearProgressIndicator(
                                    value: _progressController.value,
                                    backgroundColor: Colors.white30,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                  );
                                },
                              )
                            : Container(color: Colors.white30),
                      ),
                    ),
                  ),
                ),
              ),

              // Header with user info and close button
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                left: 8,
                right: 8,
                child: Consumer(
                  builder: (context, ref, _) {
                    final storyUsersState = ref.watch(storyUsersProvider);
                    final userProfile = storyUsersState.profiles[story.userId];
                    final displayName = userProfile?.name ?? 'مستخدم';
                    final profileImageUrl = userProfile?.profileImageUrl;

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : null,
                          backgroundColor: Colors.grey[300],
                          child: profileImageUrl == null
                              ? const Icon(Icons.person, color: Colors.grey, size: 20)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                StoryTimeFormatter.getTimeAgo(story.createdAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Show delete button for own stories
                        if (story.userId == widget.currentUserId)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: _deleteStory,
                            tooltip: 'حذف القصة',
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Viewer count (if it's user's own story)
              if (story.userId == widget.currentUserId)
                Positioned(
                  bottom:
                      MediaQuery.of(context).padding.bottom +
                      80, // Account for navbar
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${story.viewerIds.length} مشاهدة',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
