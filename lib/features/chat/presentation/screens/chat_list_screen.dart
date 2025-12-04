import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/loading_state_widget.dart';
import '../../domain/repositories/chat_repository.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

/// Screen for displaying list of chats
class ChatListScreen extends ConsumerWidget {
  final String currentUserId;

  const ChatListScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatListAsync = ref.watch(chatListProvider(currentUserId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body: chatListAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد محادثات بعد',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ابدأ محادثة جديدة من صفحة الاستكشاف',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(chatListProvider(currentUserId));
            },
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _ChatListTile(
                  chat: chat,
                  currentUserId: currentUserId,
                );
              },
            ),
          );
        },
        loading: () => ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) => const ShimmerListItem(),
        ),
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
                'حدث خطأ في تحميل المحادثات',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.invalidate(chatListProvider(currentUserId));
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  final ChatPreview chat;
  final String currentUserId;

  const _ChatListTile({
    required this.chat,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(
                viewedUserId: chat.otherUserId,
              ),
            ),
          );
        },
        child: CircleAvatar(
          radius: 28,
          backgroundImage: chat.otherUserImageUrl != null && chat.otherUserImageUrl!.isNotEmpty
              ? NetworkImage(chat.otherUserImageUrl!)
              : null,
          onBackgroundImageError: chat.otherUserImageUrl != null && chat.otherUserImageUrl!.isNotEmpty
              ? (exception, stackTrace) {
                  debugPrint('Failed to load chat list image: ${chat.otherUserImageUrl}');
                }
              : null,
          child: chat.otherUserImageUrl == null || chat.otherUserImageUrl!.isEmpty
              ? const Icon(Icons.person, size: 28)
              : null,
        ),
      ),
      title: Text(
        chat.otherUserName ?? 'مستخدم',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        chat.lastMessage ?? 'لا توجد رسائل',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight:
                  chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
            ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (chat.lastMessageTime != null)
            Text(
              _formatTime(chat.lastMessageTime!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: chat.unreadCount > 0
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
            ),
          if (chat.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                chat.unreadCount.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chat.chatId,
              currentUserId: currentUserId,
              otherUserId: chat.otherUserId,
              otherUserName: chat.otherUserName,
              otherUserImageUrl: chat.otherUserImageUrl,
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'أمس';
    } else if (difference.inDays < 7) {
      // This week - show day name
      final days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      return days[timestamp.weekday % 7];
    } else {
      // Older - show date
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
