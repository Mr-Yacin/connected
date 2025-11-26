import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/enums.dart';
import '../../../moderation/presentation/providers/moderation_provider.dart';
import '../../../moderation/presentation/widgets/report_bottom_sheet.dart';
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
        title: const Text('حظر المستخدم'),
        content: const Text(
          'هل تريد حظر هذا المستخدم؟ لن يتمكن من التواصل معك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حظر'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(moderationProvider.notifier)
          .blockUser(widget.currentUserId, widget.otherUserId);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حظر المستخدم')));
        Navigator.of(context).pop();
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
      appBar: AppBar(
        title: Row(
          children: [
            // Profile image
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.otherUserImageUrl != null
                  ? NetworkImage(widget.otherUserImageUrl!)
                  : null,
              child: widget.otherUserImageUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            // User name
            Expanded(
              child: Text(
                widget.otherUserName ?? 'مستخدم',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
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
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('حظر المستخدم'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('الإبلاغ عن المستخدم'),
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
                  return const Center(
                    child: Text(
                      'لا توجد رسائل بعد\nابدأ المحادثة!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final notifier = ref.read(chatNotifierProvider.notifier);
                final hasMore = notifier.hasMoreMessages(widget.chatId);

                return Column(
                  children: [
                    // Load more indicator at top
                    if (_isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (hasMore && messages.length >= 50)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextButton.icon(
                          onPressed: _loadMoreMessages,
                          icon: const Icon(Icons.arrow_upward, size: 16),
                          label: const Text('تحميل رسائل أقدم'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                          ),
                        ),
                      ),

                    // Messages list
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'حدث خطأ في تحميل الرسائل',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(
                          paginatedMessagesStreamProvider(widget.chatId),
                        );
                      },
                      child: const Text('إعادة المحاولة'),
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
