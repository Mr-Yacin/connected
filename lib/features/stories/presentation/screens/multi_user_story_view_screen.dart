import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cube_transition_plus/cube_transition_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/story.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../providers/story_provider.dart';
import '../providers/story_user_provider.dart';
import '../../../moderation/presentation/providers/moderation_provider.dart';
import '../../../moderation/presentation/widgets/report_bottom_sheet.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../widgets/story_management_sheet.dart';
import '../../utils/story_time_formatter.dart';
import '../widgets/common/story_profile_avatar.dart';
import '../widgets/common/story_stats_row.dart';

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

  // LRU cache configuration
  static const int _maxCacheEntries = 50;
  final Map<String, List<Story>> _userStoriesCache = {};
  final Map<String, DateTime> _cacheAccessTimes = {};
  bool _isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isTyping = false;
  
  // Track precached images for cleanup
  final Set<String> _precachedImageUrls = {};

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
        final hadFocus = _isTyping;
        final hasFocus = _messageFocusNode.hasFocus;
        
        setState(() {
          _isTyping = hasFocus;
        });

        // Pause story when keyboard appears
        if (hasFocus && !hadFocus) {
          _pauseStory();
        }
        // Resume story when keyboard is dismissed
        else if (!hasFocus && hadFocus) {
          _resumeStory();
        }
      }
    });

    _loadAllUserStories();
  }

  @override
  void dispose() {
    // Cancel timer first to prevent any callbacks during disposal
    _storyTimer?.cancel();
    _storyTimer = null;
    
    // Dispose all controllers
    _storyProgressController.dispose();
    _userPageController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    
    // Clear user stories cache map
    _userStoriesCache.clear();
    _cacheAccessTimes.clear();
    
    // Evict all precached images from memory
    for (final url in _precachedImageUrls) {
      imageCache.evict(CachedNetworkImageProvider(url));
    }
    _precachedImageUrls.clear();
    
    // Invalidate providers to refresh data for next view
    ref.invalidate(activeStoriesProvider);
    
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

        _addToCache(userId, sortedStories);
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

  /// Add stories to cache with LRU eviction
  void _addToCache(String userId, List<Story> stories) {
    // Check if cache exceeds limit
    if (_userStoriesCache.length >= _maxCacheEntries && !_userStoriesCache.containsKey(userId)) {
      // Find least recently used entry
      String? lruKey;
      DateTime? oldestTime;
      
      for (final entry in _cacheAccessTimes.entries) {
        if (oldestTime == null || entry.value.isBefore(oldestTime)) {
          oldestTime = entry.value;
          lruKey = entry.key;
        }
      }
      
      // Remove LRU entry
      if (lruKey != null) {
        _userStoriesCache.remove(lruKey);
        _cacheAccessTimes.remove(lruKey);
      }
    }
    
    // Add to cache and update access time
    _userStoriesCache[userId] = stories;
    _cacheAccessTimes[userId] = DateTime.now();
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
    
    // Update access time when stories are accessed
    if (_userStoriesCache.containsKey(userId)) {
      _cacheAccessTimes[userId] = DateTime.now();
    }
    
    return _userStoriesCache[userId] ?? [];
  }

  void _nextStory() {
    final currentStories = _getCurrentUserStories();

    if (_currentStoryIndex < currentStories.length - 1) {
      // Next story within same user - simple state update
      setState(() {
        _currentStoryIndex++;
      });
      _startStory();
    } else {
      // Move to next user with cube animation
      _nextUser();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      // Previous story within same user - simple state update
      setState(() {
        _currentStoryIndex--;
      });
      _startStory();
    } else if (_currentUserIndex > 0) {
      // Move to previous user with cube animation
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
      body: PageView.builder(
        controller: _userPageController,
        onPageChanged: (index) {
          setState(() {
            _currentUserIndex = index;
            _currentStoryIndex = 0;
          });
          _startStory();
        },
        itemCount: widget.userIds.length,
        itemBuilder: (context, userIndex) {
          final userId = widget.userIds[userIndex];
          final stories = _userStoriesCache[userId] ?? [];

          if (stories.isEmpty) {
            return Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  'لا توجد قصص',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          final storyIndex = userIndex == _currentUserIndex 
              ? _currentStoryIndex.clamp(0, stories.length - 1)
              : 0;
          final story = stories[storyIndex];
          final isOwnStory = story.userId == widget.currentUserId;

          return _UserStoryPage(
            key: ValueKey('user_$userId'),
            story: story,
            stories: stories,
            isOwnStory: isOwnStory,
            buildFullStoryScreen: (s, ss, own) => _buildFullStoryScreen(s, ss, own),
          );
        },
      ),
    );
  }

  Widget _buildFullStoryScreen(Story story, List<Story> stories, bool isOwnStory) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
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

          // 4. Bottom Action Bar with input
          _buildBottomActions(story, isOwnStory),
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
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
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
                StoryProfileAvatar(
                  profileImageUrl: profileImageUrl,
                  size: 40,
                  borderWidth: 2,
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
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        StoryTimeFormatter.getTimeAgo(story.createdAt),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {}, // Absorb taps to prevent parent GestureDetector from receiving them
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: _isTyping 
                ? math.max(
                    MediaQuery.of(context).viewInsets.bottom,
                    MediaQuery.of(context).padding.bottom,
                  )
                : MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isTyping
                  ? [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black,
                    ]
                  : [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.6),
                    ],
            ),
            border: _isTyping
                ? Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: isOwnStory
              ? _buildOwnStoryStats(story)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quick reactions when typing
                    if (_isTyping) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
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
                    ],
                    // Input bar
                    _buildInputBar(story),
                  ],
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

  Future<void> _sendMessage(Story story, {String? quickReaction}) async {
    final message = quickReaction ?? _messageController.text.trim();

    if (message.isEmpty) return;

    // Optimistic update - increment reply count immediately
    setState(() {
      if (_userStoriesCache.containsKey(story.userId)) {
        final stories = _userStoriesCache[story.userId]!;
        final storyIndex = stories.indexWhere((s) => s.id == story.id);
        if (storyIndex != -1) {
          final updatedStory = stories[storyIndex].copyWith(
            replyCount: stories[storyIndex].replyCount + 1,
          );
          _userStoriesCache[story.userId]![storyIndex] = updatedStory;
        }
      }
    });

    try {
      // Generate chat ID (sorted user IDs to ensure consistency)
      final userIds = [widget.currentUserId, story.userId]..sort();
      final chatId = '${userIds[0]}_${userIds[1]}';

      // Send as chat message with story reply type
      final chatRepository = ref.read(chatRepositoryProvider);
      await chatRepository.sendStoryReplyMessage(
        chatId: chatId,
        senderId: widget.currentUserId,
        receiverId: story.userId,
        text: message,
        storyId: story.id,
        storyMediaUrl: story.mediaUrl,
      );

      // Also increment reply count in Firestore
      final storyRepository = ref.read(storyRepositoryProvider);
      await storyRepository.incrementReplyCount(story.id);

      _messageController.clear();
      _messageFocusNode.unfocus();

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'تم إرسال الرد');
      }
    } catch (e) {
      // Rollback on error
      setState(() {
        if (_userStoriesCache.containsKey(story.userId)) {
          final stories = _userStoriesCache[story.userId]!;
          final storyIndex = stories.indexWhere((s) => s.id == story.id);
          if (storyIndex != -1) {
            final updatedStory = stories[storyIndex].copyWith(
              replyCount: stories[storyIndex].replyCount - 1,
            );
            _userStoriesCache[story.userId]![storyIndex] = updatedStory;
          }
        }
      });
      
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'فشل في إرسال الرد: ${e.toString()}',
        );
      }
    }
  }

  Widget _buildStoryContent(Story story) {
    // Preload adjacent stories for smooth transitions
    _preloadAdjacentStories();
    
    return Container(
      color: Colors.black,
      child: SizedBox.expand(
        child: story.type == StoryType.image
            ? CachedNetworkImage(
                imageUrl: story.mediaUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.black,
                  child: const Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              )
            : const Center(
                child: Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
              ),
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
        _precachedImageUrls.add(nextStory.mediaUrl);
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
          _precachedImageUrls.add(nextUserFirstStory.mediaUrl);
          precacheImage(CachedNetworkImageProvider(nextUserFirstStory.mediaUrl), context);
        }
      }
    }
    
    // Preload previous story in current user's stories
    if (_currentStoryIndex > 0) {
      final prevStory = currentStories[_currentStoryIndex - 1];
      if (prevStory.type == StoryType.image) {
        _precachedImageUrls.add(prevStory.mediaUrl);
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
          _precachedImageUrls.add(prevUserLastStory.mediaUrl);
          precacheImage(CachedNetworkImageProvider(prevUserLastStory.mediaUrl), context);
        }
      }
    }
  }

  Widget _buildInputBar(Story story) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: _isTyping 
                  ? Colors.white
                  : Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _isTyping 
                    ? Colors.grey[300]!
                    : Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Theme(
              data: ThemeData(
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: _isTyping ? Colors.black : Colors.white,
                  selectionColor: _isTyping ? Colors.blue.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.3),
                  selectionHandleColor: _isTyping ? Colors.blue : Colors.white,
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                cursorColor: _isTyping ? Colors.black : Colors.white,
                style: TextStyle(
                  color: _isTyping ? Colors.black : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.none,
                ),
                decoration: InputDecoration(
                  hintText: 'أرسل رسالة...',
                  hintStyle: TextStyle(
                    color: _isTyping ? Colors.grey[600] : Colors.grey[400],
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(story),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (_isTyping)
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
          )
        else
          GestureDetector(
            onTap: () async {
              final repository = ref.read(storyRepositoryProvider);
              final isLiked = story.likedBy.contains(widget.currentUserId);

              // Optimistic update - update local cache immediately for instant UI feedback
              setState(() {
                final userStories = _userStoriesCache[story.userId];
                if (userStories != null) {
                  final storyIndex = userStories.indexWhere((s) => s.id == story.id);
                  if (storyIndex != -1) {
                    final updatedLikedBy = List<String>.from(userStories[storyIndex].likedBy);
                    if (isLiked) {
                      updatedLikedBy.remove(widget.currentUserId);
                    } else {
                      updatedLikedBy.add(widget.currentUserId);
                    }
                    _userStoriesCache[story.userId]![storyIndex] = 
                      userStories[storyIndex].copyWith(likedBy: updatedLikedBy);
                  }
                }
              });

              try {
                // Update Firestore in background
                if (isLiked) {
                  await repository.unlikeStory(story.id, widget.currentUserId);
                } else {
                  await repository.likeStory(story.id, widget.currentUserId);
                }
              } catch (e) {
                // Rollback on error
                setState(() {
                  final userStories = _userStoriesCache[story.userId];
                  if (userStories != null) {
                    final storyIndex = userStories.indexWhere((s) => s.id == story.id);
                    if (storyIndex != -1) {
                      final updatedLikedBy = List<String>.from(userStories[storyIndex].likedBy);
                      if (!isLiked) {
                        updatedLikedBy.remove(widget.currentUserId);
                      } else {
                        updatedLikedBy.add(widget.currentUserId);
                      }
                      _userStoriesCache[story.userId]![storyIndex] = 
                        userStories[storyIndex].copyWith(likedBy: updatedLikedBy);
                    }
                  }
                });
                
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
    return StoryStatsRow(
      viewCount: story.viewerIds.length,
      likeCount: story.likedBy.length,
      replyCount: story.replyCount,
    );
  }
}

/// Wrapper widget to keep user story pages alive during transitions
class _UserStoryPage extends StatefulWidget {
  final Story story;
  final List<Story> stories;
  final bool isOwnStory;
  final Widget Function(Story, List<Story>, bool) buildFullStoryScreen;

  const _UserStoryPage({
    super.key,
    required this.story,
    required this.stories,
    required this.isOwnStory,
    required this.buildFullStoryScreen,
  });

  @override
  State<_UserStoryPage> createState() => _UserStoryPageState();
}

class _UserStoryPageState extends State<_UserStoryPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.buildFullStoryScreen(
      widget.story,
      widget.stories,
      widget.isOwnStory,
    );
  }
}
