import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/story.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/models/story_reply.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../providers/story_provider.dart';
import '../../../moderation/presentation/providers/moderation_provider.dart';
import '../../../moderation/presentation/widgets/report_bottom_sheet.dart';

/// Screen for viewing stories with automatic progression between users
class MultiUserStoryViewScreen extends ConsumerStatefulWidget {
  final List<String> userIds;
  final String currentUserId;
  final int initialUserIndex;

  const MultiUserStoryViewScreen({
    super.key,
    required this.userIds,
    required this.currentUserId,
    this.initialUserIndex = 0,
  });

  @override
  ConsumerState<MultiUserStoryViewScreen> createState() =>
      _MultiUserStoryViewScreenState();
}

class _MultiUserStoryViewScreenState
    extends ConsumerState<MultiUserStoryViewScreen>
    with TickerProviderStateMixin {
  late int _currentUserIndex;
  int _currentStoryIndex = 0;
  int? _previousUserIndex; // Track previous user for transition
  late AnimationController _userTransitionController;
  late AnimationController _storyProgressController;
  Timer? _storyTimer;
  static const Duration _storyDuration = Duration(seconds: 5);
  static const Duration _transitionDuration = Duration(milliseconds: 500);

  final Map<String, List<Story>> _userStoriesCache = {};
  bool _isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialUserIndex;

    _userTransitionController = AnimationController(
      vsync: this,
      duration: _transitionDuration,
    );

    _storyProgressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    );

    // Listen to focus changes to detect when typing starts/stops
    _messageFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isTyping = _messageFocusNode.hasFocus;
        });

        // Resume story when keyboard is dismissed
        if (!_messageFocusNode.hasFocus && _isTyping) {
          _resumeStory();
        }
      }
    });

    _loadAllUserStories();
  }

  @override
  void dispose() {
    _userTransitionController.dispose();
    _storyProgressController.dispose();
    _storyTimer?.cancel();
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAllUserStories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      for (final userId in widget.userIds) {
        final userStories = await ref.read(userStoriesProvider(userId).future);
        _userStoriesCache[userId] = userStories;
      }
    } catch (e) {
      print('Error loading user stories: $e');
    }

    setState(() {
      _isLoading = false;
    });

    if (_userStoriesCache.isNotEmpty) {
      _startStory();
    }
  }

  void _startStory() {
    _storyProgressController.reset();
    _storyProgressController.forward();

    // Record view for current story
    final currentStories = _getCurrentUserStories();
    if (currentStories.isNotEmpty &&
        _currentStoryIndex < currentStories.length) {
      final story = currentStories[_currentStoryIndex];
      if (story.userId != widget.currentUserId) {
        ref
            .read(storyCreationProvider.notifier)
            .recordView(story.id, widget.currentUserId);
      }
    }

    // Auto-advance after story duration
    _storyTimer?.cancel();
    _storyTimer = Timer(_storyDuration, () {
      _nextStory();
    });
  }

  void _pauseStory() {
    _storyProgressController.stop();
    _storyTimer?.cancel();
  }

  void _resumeStory() {
    _storyProgressController.forward();
    final remainingTime = _storyDuration * (1 - _storyProgressController.value);
    _storyTimer?.cancel();
    _storyTimer = Timer(remainingTime, () {
      _nextStory();
    });
  }

  List<Story> _getCurrentUserStories() {
    if (_currentUserIndex >= widget.userIds.length) return [];
    final userId = widget.userIds[_currentUserIndex];
    return _userStoriesCache[userId] ?? [];
  }

  void _nextStory() {
    final currentStories = _getCurrentUserStories();

    if (_currentStoryIndex < currentStories.length - 1) {
      // Next story within same user
      setState(() {
        _currentStoryIndex++;
      });
      _startStory();
    } else {
      // Move to next user
      _nextUser();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      // Previous story within same user
      setState(() {
        _currentStoryIndex--;
      });
      _startStory();
    } else if (_currentUserIndex > 0) {
      // Move to previous user and show their last story
      setState(() {
        _currentUserIndex--;
      });
      _loadUserStories(() {
        final prevStories = _getCurrentUserStories();
        if (prevStories.isNotEmpty) {
          setState(() {
            _currentStoryIndex = prevStories.length - 1;
          });
        }
        _startStory();
      });
    }
  }

  void _nextUser() {
    if (_currentUserIndex < widget.userIds.length - 1) {
      // Pause current story and show 3D flip transition
      _pauseStory();

      // Save previous user index for transition
      setState(() {
        _previousUserIndex = _currentUserIndex;
      });

      // Start the flip animation
      _userTransitionController.forward(from: 0.0).then((_) {
        // At halfway point (90 degrees), switch to next user
        setState(() {
          _currentUserIndex++;
          _currentStoryIndex = 0;
        });

        // Complete the flip animation
        _userTransitionController.reverse(from: 1.0).then((_) {
          setState(() {
            _previousUserIndex = null;
          });
          _loadUserStories(() {
            _startStory();
          });
        });
      });
    } else {
      // All stories completed, exit
      Navigator.pop(context);
    }
  }

  void _previousUser() {
    if (_currentUserIndex > 0) {
      // Pause current story and show 3D flip transition
      _pauseStory();

      setState(() {
        _previousUserIndex = _currentUserIndex;
      });

      // Start the flip animation (backwards)
      _userTransitionController.forward(from: 0.0).then((_) {
        setState(() {
          _currentUserIndex--;
        });

        _userTransitionController.reverse(from: 1.0).then((_) {
          setState(() {
            _previousUserIndex = null;
          });
          _loadUserStories(() {
            final stories = _getCurrentUserStories();
            if (stories.isNotEmpty) {
              setState(() {
                _currentStoryIndex = 0;
              });
            }
            _startStory();
          });
        });
      });
    }
  }

  void _loadUserStories(VoidCallback onComplete) {
    final userId = widget.userIds[_currentUserIndex];

    // Load stories if not cached
    if (!_userStoriesCache.containsKey(userId)) {
      ref.read(userStoriesProvider(userId).future).then((stories) {
        setState(() {
          _userStoriesCache[userId] = stories;
        });
        onComplete();
      });
    } else {
      _nextStory();
    }
    // Middle half - pause/resume handled by gesture detectors
  }

  void _onTap(TapUpDetails details) {
    // If typing, dismiss keyboard and reset state
    if (_isTyping) {
      _messageFocusNode.unfocus();
      setState(() {
        _isTyping = false;
      });
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;

    if (details.globalPosition.dx < screenWidth / 4) {
      // Left quarter - previous story/user
      _previousStory();
    } else if (details.globalPosition.dx > screenWidth * 3 / 4) {
      // Right quarter - next story/user
      _nextStory();
    }
    // Middle half - pause/resume handled by gesture detectors
  }

  void _showReportOptions(BuildContext context, Story story) {
    _pauseStory();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.red),
                  title: const Text('الإبلاغ عن القصة'),
                  onTap: () {
                    Navigator.pop(context);
                    _reportStory(story);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('حظر المستخدم'),
                  onTap: () {
                    Navigator.pop(context);
                    _blockUser(story.userId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel),
                  title: const Text('إلغاء'),
                  onTap: () {
                    Navigator.pop(context);
                    _resumeStory();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    ).then((_) => _resumeStory());
  }

  void _reportStory(Story story) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReportBottomSheet(
          reporterId: widget.currentUserId,
          reportedUserId: story.userId,
          reportedContentId: story.id,
          reportType: ReportType.story,
        ),
      ),
    );
  }

  Future<void> _blockUser(String userId) async {
    try {
      await ref
          .read(moderationProvider.notifier)
          .blockUser(widget.currentUserId, userId);

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'تم حظر المستخدم بنجاح');
        Navigator.of(context).pop();
        // Close the story view as we blocked the user
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'فشل في حظر المستخدم: $e');
      }
    }
  }

  Future<void> _toggleLike(Story story) async {
    final repository = ref.read(storyRepositoryProvider);
    final isLiked = story.likedBy.contains(widget.currentUserId);

    try {
      if (isLiked) {
        await repository.unlikeStory(story.id, widget.currentUserId);
      } else {
        await repository.likeStory(story.id, widget.currentUserId);
      }
      ref.invalidate(activeStoriesProvider);
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'فشل في الإعجاب: $e');
      }
    }
  }

  Future<void> _sendMessage(Story story, {String? quickReaction}) async {
    final message = quickReaction ?? _messageController.text.trim();
    if (message.isEmpty) return;

    final repository = ref.read(storyRepositoryProvider);

    final reply = StoryReply(
      id: '',
      storyId: story.id,
      senderId: widget.currentUserId,
      message: message,
      createdAt: DateTime.now(),
    );

    try {
      await repository.createStoryReply(reply);
      ref.invalidate(activeStoriesProvider);

      _messageController.clear();
      setState(() {
        _isTyping = false;
      });
      _messageFocusNode.unfocus();

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'تم إرسال الرسالة!',
          duration: const Duration(seconds: 1),
        );
      }

      _resumeStory();
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'فشل في إرسال الرسالة: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final currentStories = _getCurrentUserStories();
    if (currentStories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'لا توجد قصص لهذا المستخدم',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _nextUser, child: const Text('التالي')),
            ],
          ),
        ),
      );
    }

    final currentStory = currentStories[_currentStoryIndex];
    final isOwnStory = currentStory.userId == widget.currentUserId;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) {
          if (!_isTyping) _pauseStory();
        },
        onTapUp: _onTap,
        onTapCancel: () {
          if (!_isTyping) _resumeStory();
        },
        onLongPressStart: (_) {
          if (!_isTyping) _pauseStory();
        },
        onLongPressEnd: (_) {
          if (!_isTyping) _resumeStory();
        },
        onVerticalDragEnd: (details) {
          // Swipe down to exit
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 500) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            // Story content - shows current user's story (no animation when moving within same user)
            if (_userTransitionController.value == 0.0)
              _buildStoryContent(currentStory),

            // 3D box flip animation ONLY when transitioning between users
            if (_userTransitionController.value > 0.0)
              AnimatedBuilder(
                animation: _userTransitionController,
                builder: (context, child) {
                  // Create a 3D flip animation showing both sides
                  final angle =
                      _userTransitionController.value *
                      math.pi; // 180 degrees full rotation

                  // First half of animation (0 to 0.5) - show previous user (front face)
                  // Second half (0.5 to 1.0) - show current user (back face)
                  final showCurrentUser = _userTransitionController.value > 0.5;

                  final displayAngle = showCurrentUser
                      ? angle // Continue rotating
                      : angle; // Show rotation

                  final transform = Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateY(displayAngle);

                  // Get the story to display
                  Story storyToShow;
                  if (showCurrentUser) {
                    // Show current user's first story
                    storyToShow = currentStory;
                  } else {
                    // Show previous user's last story
                    if (_previousUserIndex != null) {
                      final prevUserId = widget.userIds[_previousUserIndex!];
                      final prevStories = _userStoriesCache[prevUserId];
                      if (prevStories != null && prevStories.isNotEmpty) {
                        storyToShow = prevStories.last;
                      } else {
                        storyToShow = currentStory;
                      }
                    } else {
                      storyToShow = currentStory;
                    }
                  }

                  return Transform(
                    transform: transform,
                    alignment: Alignment.center,
                    child: _buildStoryContent(storyToShow),
                  );
                },
              ),

            // Progress indicators - ONLY for current user's stories
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(
                  currentStories.length,
                  (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: index < _currentStoryIndex
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : index == _currentStoryIndex
                          ? AnimatedBuilder(
                              animation: _storyProgressController,
                              builder: (context, child) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: _storyProgressController.value,
                                    backgroundColor: Colors.white30,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.white30,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            // Header with user info and report button
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(currentStory.mediaUrl),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentStory.userId.substring(0, 8),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // Show report button only for other users' stories
                  if (!isOwnStory)
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () =>
                          _showReportOptions(context, currentStory),
                    ),
                ],
              ),
            ),

            // Bottom action bar - message input and like (when NOT typing)
            if (!_isTyping)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(context).padding.bottom + 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: isOwnStory
                      ? _buildOwnStoryStats(currentStory)
                      : _buildMessageAndLikeBar(currentStory),
                ),
              ),

            // Quick reactions + keyboard area (when typing) - PRO DESIGN
            if (_isTyping)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.only(
                        bottom: math.max(
                          MediaQuery.of(context).viewInsets.bottom,
                          MediaQuery.of(context).padding.bottom,
                        ),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.black.withValues(alpha: 0.8),
                            Colors.black,
                          ],
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Quick Reactions - 2 Lines, No Scroll
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                // First Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildQuickReaction('😂', currentStory),
                                    _buildQuickReaction('😮', currentStory),
                                    _buildQuickReaction('😍', currentStory),
                                    _buildQuickReaction('😢', currentStory),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Second Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildQuickReaction('👏', currentStory),
                                    _buildQuickReaction('🔥', currentStory),
                                    _buildQuickReaction('🎉', currentStory),
                                    _buildQuickReaction('💯', currentStory),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Pro Input Bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextField(
                                            controller: _messageController,
                                            focusNode: _messageFocusNode,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              height: 1.2,
                                            ),
                                            textDirection: TextDirection.rtl,
                                            decoration: InputDecoration(
                                              hintText: 'أرسل رسالة...',
                                              hintStyle: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.5,
                                                ),
                                                fontSize: 15,
                                              ),
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                            ),
                                            onChanged: (value) {
                                              setState(() {});
                                            },
                                            onSubmitted: (_) {
                                              if (_messageController.text
                                                  .trim()
                                                  .isNotEmpty) {
                                                _sendMessage(currentStory);
                                              }
                                            },
                                          ),
                                        ),
                                        if (_messageController.text
                                            .trim()
                                            .isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Icon(
                                              Icons.image_outlined,
                                              color: Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
                                              size: 24,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Send button with animation
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 200),
                                  child:
                                      _messageController.text.trim().isNotEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                            right: 12,
                                          ),
                                          child: GestureDetector(
                                            onTap: () =>
                                                _sendMessage(currentStory),
                                            child: Container(
                                              width: 44,
                                              height: 44,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color(
                                                      0xFF833AB4,
                                                    ), // Instagram-like purple
                                                    Color(
                                                      0xFFFD1D1D,
                                                    ), // Instagram-like red
                                                    Color(
                                                      0xFFFCAF45,
                                                    ), // Instagram-like orange
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.arrow_upward_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(Story story) {
    return Center(
      child: story.type == StoryType.image
          ? Image.network(
              story.mediaUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 50),
                );
              },
            )
          : const Center(
              child: Text(
                'فيديو',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
    );
  }

  Widget _buildMessageAndLikeBar(Story story) {
    final isLiked = story.likedBy.contains(widget.currentUserId);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              _pauseStory();
              setState(() {
                _isTyping = true;
              });
              // Request focus after a slight delay to ensure animation completes
              Future.delayed(const Duration(milliseconds: 100), () {
                _messageFocusNode.requestFocus();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.message_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'أرسل رسالة...',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => _toggleLike(story),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickReaction(String emoji, Story story) {
    return GestureDetector(
      onTap: () {
        _sendMessage(story, quickReaction: emoji);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(emoji, style: const TextStyle(fontSize: 36)),
      ),
    );
  }

  Widget _buildOwnStoryStats(Story story) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility, color: Colors.white, size: 20),
            const SizedBox(width: 4),
            Text(
              '${story.viewerIds.length}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.favorite, color: Colors.white, size: 20),
            const SizedBox(width: 4),
            Text(
              '${story.likedBy.length}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.message, color: Colors.white, size: 20),
            const SizedBox(width: 4),
            Text(
              '${story.replyCount}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
