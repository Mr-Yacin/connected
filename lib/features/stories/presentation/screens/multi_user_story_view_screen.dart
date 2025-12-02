import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cube_transition_plus/cube_transition_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/story.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/models/story_reply.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../providers/story_provider.dart';
import '../providers/story_user_provider.dart';
import '../../../moderation/presentation/providers/moderation_provider.dart';
import '../../../moderation/presentation/widgets/report_bottom_sheet.dart';
import '../widgets/story_management_sheet.dart';

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
  late PageController _userPageController;
  late int _currentUserIndex;
  int _currentStoryIndex = 0;
  late AnimationController _storyProgressController;
  Timer? _storyTimer;
  static const Duration _storyDuration = Duration(seconds: 5);

  final Map<String, List<Story>> _userStoriesCache = {};
  bool _isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialUserIndex;

    _userPageController = PageController(initialPage: widget.initialUserIndex);

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
    _userPageController.dispose();
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
      // Load all user profiles first
      await ref.read(storyUsersProvider.notifier).loadProfiles(widget.userIds);

      // Then load their stories and sort chronologically
      for (final userId in widget.userIds) {
        final userStories = await ref.read(userStoriesProvider(userId).future);

        // Sort stories by creation time (oldest first, like Instagram)
        final sortedStories = List<Story>.from(userStories)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        _userStoriesCache[userId] = sortedStories;
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
      // Move to previous user
      _previousUser();
    }
  }

  void _nextUser() {
    if (_currentUserIndex < widget.userIds.length - 1) {
      _pauseStory();
      setState(() {
        _currentUserIndex++;
        _currentStoryIndex = 0;
      });
      _userPageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousUser() {
    if (_currentUserIndex > 0) {
      _pauseStory();
      setState(() {
        _currentUserIndex--;
        _currentStoryIndex = 0;
      });
      _userPageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _startStory();
    }
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

    // Fixed navigation: LEFT = NEXT (like Instagram/TikTok), RIGHT = PREVIOUS
    if (details.globalPosition.dx < screenWidth / 3) {
      // Left third - NEXT story/user
      _nextStory();
    } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
      // Right third - PREVIOUS story/user
      _previousStory();
    }
    // Middle third - pause/resume handled by gesture detectors
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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: CubePageView(
        controller: _userPageController,
        onPageChanged: (index) {
          setState(() {
            _currentUserIndex = index;
            _currentStoryIndex = 0;
          });
        },
        children: List.generate(
          widget.userIds.length,
          (userIndex) {
            final userId = widget.userIds[userIndex];
            final stories = _userStoriesCache[userId] ?? [];

            if (stories.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد قصص',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final story = stories[_currentStoryIndex.clamp(0, stories.length - 1)];
            final isOwnStory = story.userId == widget.currentUserId;

            return _buildFullStoryScreen(story, stories, isOwnStory);
          },
        ),
      ),
    );
  }

  Widget _buildFullStoryScreen(Story story, List<Story> stories, bool isOwnStory) {
    return GestureDetector(
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
        if (details.primaryVelocity != null &&
            details.primaryVelocity! > 500) {
          Navigator.pop(context);
        }
      },
      child: Stack(
        children: [
          // 1. Story Content (Image/Video)
          _buildStoryContent(story),

          // 2. Progress Indicators
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              children: List.generate(
                stories.length,
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

          // 3. Header with User Info & Timestamp
          _buildHeader(story),

          // 4. Bottom Action Bar
          if (!_isTyping) _buildBottomActions(story, isOwnStory),

          // 5. Quick reactions when typing
          if (_isTyping) _buildQuickReactions(story),
        ],
      ),
    );
  }

  Widget _buildHeader(Story story) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
          left: 8,
          right: 8,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.black.withValues(alpha: 0.4),
              Colors.black.withValues(alpha: 0.2),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 0.8, 1.0],
          ),
        ),
        child: Consumer(
          builder: (context, ref, _) {
            final storyUsersState = ref.watch(storyUsersProvider);
            final userProfile = storyUsersState.profiles[story.userId];
            final displayName = userProfile?.name ?? 'مستخدم';
            final profileImageUrl = userProfile?.profileImageUrl;
            final isOwnStory = story.userId == widget.currentUserId;

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: profileImageUrl != null
                      ? CachedNetworkImageProvider(profileImageUrl)
                      : null,
                  backgroundColor: Colors.grey[800],
                  child: profileImageUrl == null
                      ? const Icon(Icons.person, color: Colors.grey, size: 18)
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
                          fontSize: 16,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3.0,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getTimeAgo(story.createdAt),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3.0,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Three-dot menu for both own and other users' stories
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    if (isOwnStory) {
                      _showOwnStoryOptions(context, story);
                    } else {
                      _showReportOptions(context, story);
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomActions(Story story, bool isOwnStory) {
    return Positioned(
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
            ? _buildOwnStoryStats(story)
            : _buildMessageAndLikeBar(story),
      ),
    );
  }

  Widget _buildQuickReactions(Story story) {
    return Positioned(
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildQuickReaction('😂', story),
                          _buildQuickReaction('😮', story),
                          _buildQuickReaction('😍', story),
                          _buildQuickReaction('😢', story),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Second Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildQuickReaction('👏', story),
                          _buildQuickReaction('🔥', story),
                          _buildQuickReaction('🎉', story),
                          _buildQuickReaction('💯', story),
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
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _messageController,
                            focusNode: _messageFocusNode,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'أرسل رسالة...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(story),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _sendMessage(story),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOwnStoryOptions(BuildContext context, Story story) {
    _pauseStory();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryManagementSheet(
        story: story,
        currentUserId: widget.currentUserId,
      ),
    ).then((_) async {
      // Resume story when bottom sheet is dismissed
      if (!mounted) return;
      
      // Check if story still exists (wasn't deleted)
      try {
        final userStories = await ref.read(userStoriesProvider(story.userId).future);
        final storyStillExists = userStories.any((s) => s.id == story.id);
        
        if (!storyStillExists) {
          // Story was deleted, update cache and navigate
          _userStoriesCache[story.userId]?.removeWhere((s) => s.id == story.id);
          
          if (_userStoriesCache[story.userId]?.isEmpty ?? true) {
            // No more stories for this user
            if (_currentUserIndex < widget.userIds.length - 1) {
              _nextUser();
            } else {
              Navigator.pop(context);
            }
          } else {
            // Move to next story
            _nextStory();
          }
        } else {
          // Story still exists, just resume
          _resumeStory();
        }
      } catch (e) {
        // On error, just resume
        _resumeStory();
      }
    });
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
              ],
            ),
          ),
        );
      },
    ).then((_) => _resumeStory());
  }

  void _reportStory(Story story) async {
    _pauseStory();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportBottomSheet(
        reporterId: widget.currentUserId,
        reportedUserId: story.userId,
        reportedContentId: story.id,
        reportType: ReportType.story,
      ),
    );

    if (result == true && mounted) {
      SnackbarHelper.showSuccess(
        context,
        'تم إرسال البلاغ بنجاح',
      );
    }

    _resumeStory();
  }

  void _blockUser(String userId) async {
    try {
      await ref.read(moderationRepositoryProvider).blockUser(
            widget.currentUserId,
            userId,
          );

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'تم حظر المستخدم بنجاح',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'فشل في حظر المستخدم: ${e.toString()}',
        );
      }
    }
  }

  void _deleteStory(Story story) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القصة'),
        content: const Text('هل أنت متأكد من حذف هذه القصة؟'),
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

    if (confirmed != true) {
      _resumeStory();
      return;
    }

    try {
      await ref.read(storyRepositoryProvider).deleteStory(story.id);

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'تم حذف القصة بنجاح');
        
        // Remove from cache
        _userStoriesCache[story.userId]?.removeWhere((s) => s.id == story.id);
        
        // If no more stories for this user, exit
        if (_userStoriesCache[story.userId]?.isEmpty ?? true) {
          Navigator.pop(context);
        } else {
          // Move to next story
          _nextStory();
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'فشل في حذف القصة: ${e.toString()}',
        );
      }
      _resumeStory();
    }
  }

  void _showStoryInsights(Story story) {
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إحصائيات القصة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInsightRow(
                    Icons.visibility,
                    'المشاهدات',
                    '${story.viewerIds.length}',
                  ),
                  const SizedBox(height: 16),
                  _buildInsightRow(
                    Icons.favorite,
                    'الإعجابات',
                    '${story.likedBy.length}',
                  ),
                  const SizedBox(height: 16),
                  _buildInsightRow(
                    Icons.message,
                    'الردود',
                    '${story.replyCount}',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إغلاق'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) => _resumeStory());
  }

  Widget _buildInsightRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _shareStory(Story story) {
    _resumeStory();
    
    // TODO: Implement share functionality in future task
    SnackbarHelper.showInfo(
      context,
      'مشاركة القصة - سيتم تنفيذها قريباً',
    );
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
      // Create the story reply (this also increments reply count in Firestore)
      await repository.createStoryReply(reply);

      // Update local cache to reflect the new reply count
      if (_userStoriesCache.containsKey(story.userId)) {
        final stories = _userStoriesCache[story.userId]!;
        final storyIndex = stories.indexWhere((s) => s.id == story.id);
        if (storyIndex != -1) {
          final updatedStory = stories[storyIndex].copyWith(
            replyCount: stories[storyIndex].replyCount + 1,
          );
          _userStoriesCache[story.userId]![storyIndex] = updatedStory;
          if (mounted) {
            setState(() {});
          }
        }
      }

      // Invalidate providers to ensure fresh data on next load
      ref.invalidate(activeStoriesProvider);
      ref.invalidate(userStoriesProvider(story.userId));

      _messageController.clear();
      _messageFocusNode.unfocus();

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'تم إرسال الرسالة');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'فشل في إرسال الرسالة: ${e.toString()}',
        );
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }

  Widget _buildStoryContent(Story story) {
    // Preload adjacent stories for smooth transitions
    _preloadAdjacentStories();
    
    return SizedBox.expand(
      child: story.type == StoryType.image
          ? CachedNetworkImage(
              imageUrl: story.mediaUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            )
          : const Center(
              child: Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
            ),
    );
  }
  
  /// Preload adjacent stories (previous and next) for smooth transitions
  void _preloadAdjacentStories() {
    final currentStories = _getCurrentUserStories();
    
    // Preload next story in current user's stories
    if (_currentStoryIndex < currentStories.length - 1) {
      final nextStory = currentStories[_currentStoryIndex + 1];
      if (nextStory.type == StoryType.image) {
        precacheImage(CachedNetworkImageProvider(nextStory.mediaUrl), context);
      }
    }
    
    // Preload first story of next user
    if (_currentStoryIndex == currentStories.length - 1 && 
        _currentUserIndex < widget.userIds.length - 1) {
      final nextUserId = widget.userIds[_currentUserIndex + 1];
      final nextUserStories = _userStoriesCache[nextUserId];
      if (nextUserStories != null && nextUserStories.isNotEmpty) {
        final nextUserFirstStory = nextUserStories[0];
        if (nextUserFirstStory.type == StoryType.image) {
          precacheImage(CachedNetworkImageProvider(nextUserFirstStory.mediaUrl), context);
        }
      }
    }
    
    // Preload previous story in current user's stories
    if (_currentStoryIndex > 0) {
      final prevStory = currentStories[_currentStoryIndex - 1];
      if (prevStory.type == StoryType.image) {
        precacheImage(CachedNetworkImageProvider(prevStory.mediaUrl), context);
      }
    }
    
    // Preload last story of previous user
    if (_currentStoryIndex == 0 && _currentUserIndex > 0) {
      final prevUserId = widget.userIds[_currentUserIndex - 1];
      final prevUserStories = _userStoriesCache[prevUserId];
      if (prevUserStories != null && prevUserStories.isNotEmpty) {
        final prevUserLastStory = prevUserStories[prevUserStories.length - 1];
        if (prevUserLastStory.type == StoryType.image) {
          precacheImage(CachedNetworkImageProvider(prevUserLastStory.mediaUrl), context);
        }
      }
    }
  }

  Widget _buildMessageAndLikeBar(Story story) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              _messageFocusNode.requestFocus();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'أرسل رسالة...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () async {
            final repository = ref.read(storyRepositoryProvider);
            final isLiked = story.likedBy.contains(widget.currentUserId);

            try {
              if (isLiked) {
                await repository.unlikeStory(story.id, widget.currentUserId);
              } else {
                await repository.likeStory(story.id, widget.currentUserId);
              }
              // Refresh both active stories and user-specific stories
              ref.invalidate(activeStoriesProvider);
              ref.invalidate(userStoriesProvider(story.userId));
            } catch (e) {
              if (mounted) {
                SnackbarHelper.showError(
                  context,
                  'فشل في تحديث الإعجاب',
                );
              }
            }
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              story.likedBy.contains(widget.currentUserId)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: story.likedBy.contains(widget.currentUserId)
                  ? Colors.red
                  : Colors.white,
              size: 20,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Views
        Row(
          children: [
            const Icon(Icons.visibility, color: Colors.white, size: 20),
            const SizedBox(width: 4),
            Text(
              '${story.viewerIds.length}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        // Likes
        Row(
          children: [
            const Icon(Icons.favorite, color: Colors.red, size: 20),
            const SizedBox(width: 4),
            Text(
              '${story.likedBy.length}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        // Replies
        Row(
          children: [
            const Icon(Icons.message, color: Colors.white, size: 20),
            const SizedBox(width: 4),
            Text(
              '${story.replyCount}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
}
