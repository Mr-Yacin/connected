import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';

/// Screen for individual chat conversation
class ChatScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesStreamProvider(chatId));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Profile image
            CircleAvatar(
              radius: 20,
              backgroundImage: otherUserImageUrl != null
                  ? NetworkImage(otherUserImageUrl!)
                  : null,
              child: otherUserImageUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            // User name
            Expanded(
              child: Text(
                otherUserName ?? 'مستخدم',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show options menu
            },
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
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: false,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    // Mark message as read if it's from the other user
                    if (!isMe && !message.isRead) {
                      Future.microtask(() {
                        ref
                            .read(chatNotifierProvider.notifier)
                            .markAsRead(chatId, message.id);
                      });
                    }

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
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
                      'حدث خطأ في تحميل الرسائل',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(messagesStreamProvider(chatId));
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
            chatId: chatId,
            senderId: currentUserId,
            receiverId: otherUserId,
          ),
        ],
      ),
    );
  }
}
