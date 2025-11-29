import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/analytics_events.dart';
import '../../../../services/crashlytics_service.dart';
import '../../../moderation/presentation/providers/moderation_provider.dart';
import '../../../moderation/presentation/widgets/report_bottom_sheet.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';

/// Screen for individual chat conversation
class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;
  final String? otherUserName;
  final String? otherUserImageUrl;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
    this.otherUserName,
    this.otherUserImageUrl,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    
    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsEventsProvider).trackScreenView('chat_screen');
    });
    
    // OPTIMIZED: Mark chat as read when opening to reset unread count
    Future.microtask(() {
      ref
          .read(chatNotifierProvider.notifier)
          .markChatAsRead(widget.chatId, widget.currentUserId);
    });

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Clear messages cache when leaving chat
    ref.read(chatNotifierProvider.notifier).clearMessagesCache(widget.chatId);
    super.dispose();
  }

  void _onScroll() {
    // Load more when scrolling to top (older messages)
    if (_scrollController.position.pixels <= 100 && !_isLoadingMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    final notifier = ref.read(chatNotifierProvider.notifier);

    // Check if there are more messages to load
    if (!notifier.hasMoreMessages(widget.chatId)) return;

    setState(() => _isLoadingMore = true);

    try {
      final messagesAsync = ref.read(
        paginatedMessagesStreamProvider(widget.chatId),
      );

      await messagesAsync.when(
        data: (messages) async {
          if (messages.isNotEmpty) {
            final oldestMessage = messages.first;
            await notifier.loadMoreMessages(
              widget.chatId,
              oldestMessage.timestamp,
            );
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    } catch (e, stackTrace) {
      await ref.read(crashlyticsServiceProvider).logError(
        e,
        stackTrace,
        reason: 'Failed to load more messages',
        information: [
          'screen: chat_screen',
          'chatId: ${widget.chatId}',
          'action: load_more_messages',
        ],
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _blockUser(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(
              'حظر المستخدم',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: const Text(
          'هل تريد حظر هذا المستخدم؟ لن يتمكن من التواصل معك.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('إلغاء', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('حظر', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(moderationProvider.notifier)
            .blockUser(widget.currentUserId, widget.otherUserId);

        // Track block user event
        await ref.read(analyticsEventsProvider).trackUserFollowed(
          followedUserId: widget.otherUserId, // Using existing method
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text('تم حظر المستخدم بنجاح'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e, stackTrace) {
        await ref.read(crashlyticsServiceProvider).logError(
          e,
          stackTrace,
          reason: 'Failed to block user',
          information: [
            'screen: chat_screen',
            'currentUserId: ${widget.currentUserId}',
            'otherUserId: ${widget.otherUserId}',
          ],
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في حظر المستخدم'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _reportUser(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReportBottomSheet(
          reporterId: widget.currentUserId,
          reportedUserId: widget.otherUserId,
          reportType: ReportType.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // OPTIMIZED: Use paginated messages stream
    final messagesAsync = ref.watch(
      paginatedMessagesStreamProvider(widget.chatId),
    );

    // Listen for new messages to mark chat as read
    ref.listen(paginatedMessagesStreamProvider(widget.chatId), (
      previous,
      next,
    ) {
      if (next.hasValue) {
        ref
            .read(chatNotifierProvider.notifier)
            .markChatAsRead(widget.chatId, widget.currentUserId);
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  viewedUserId: widget.otherUserId,
                ),
              ),
            );
          },
          child: Row(
            children: [
              // Profile image with online indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundImage: widget.otherUserImageUrl != null
                        ? NetworkImage(widget.otherUserImageUrl!)
                        : null,
                    child: widget.otherUserImageUrl == null
                        ? Icon(Icons.person, color: AppColors.primary)
                        : null,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // User name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUserName ?? 'مستخدم',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'block') {
                _blockUser(context, ref);
              } else if (value == 'report') {
                _reportUser(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('حظر المستخدم', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Text('الإبلاغ عن المستخدم', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد رسائل بعد',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ابدأ المحادثة الآن!',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final notifier = ref.read(chatNotifierProvider.notifier);
                final hasMore = notifier.hasMoreMessages(widget.chatId);

                return Column(
                  children: [
                    // Load more indicator at top
                    if (_isLoadingMore)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (hasMore && messages.length >= 50)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextButton.icon(
                          onPressed: _loadMoreMessages,
                          icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                          label: const Text('تحميل رسائل أقدم'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ),

                    // Messages list
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 4,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          // Reverse index for reversed list
                          final reversedIndex = messages.length - 1 - index;
                          final message = messages[reversedIndex];
                          final isMe = message.senderId == widget.currentUserId;

                          // Mark message as read if it's from the other user
                          if (!isMe && !message.isRead) {
                            Future.microtask(() {
                              ref
                                  .read(chatNotifierProvider.notifier)
                                  .markAsRead(widget.chatId, message.id);
                            });
                          }

                          return MessageBubble(message: message, isMe: isMe);
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'حدث خطأ في تحميل الرسائل',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يرجى المحاولة مرة أخرى',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(
                          paginatedMessagesStreamProvider(widget.chatId),
                        );
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Message input bar
          MessageInputBar(
            chatId: widget.chatId,
            senderId: widget.currentUserId,
            receiverId: widget.otherUserId,
          ),
        ],
      ),
    );
  }
}
