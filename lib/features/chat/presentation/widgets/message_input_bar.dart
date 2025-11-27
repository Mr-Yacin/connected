import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/chat_provider.dart';

/// Widget for message input with text
class MessageInputBar extends ConsumerStatefulWidget {
  final String chatId;
  final String senderId;
  final String receiverId;

  const MessageInputBar({
    super.key,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
  });

  @override
  ConsumerState<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends ConsumerState<MessageInputBar> {
  final TextEditingController _textController = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _textController.text.trim().isNotEmpty;
    });
  }

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _hasText = false;
    });

    await ref.read(chatNotifierProvider.notifier).sendTextMessage(
          chatId: widget.chatId,
          senderId: widget.senderId,
          receiverId: widget.receiverId,
          text: text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 16),
              // Text input field
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالة...',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 12,
                    ),
                  ),
                  textDirection: TextDirection.rtl,
                  maxLines: 5,
                  minLines: 1,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              // Send button
              IconButton(
                onPressed: _hasText ? _sendTextMessage : null,
                icon: Icon(
                  Icons.send_rounded,
                  color: _hasText ? AppColors.primary : Colors.grey[400],
                  size: 24,
                ),
                padding: const EdgeInsets.all(8),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
