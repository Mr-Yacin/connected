import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';

/// Widget for message input with text and voice recording
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
  bool _isRecording = false;
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

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
    });

    await ref.read(chatNotifierProvider.notifier).startRecording();
  }

  Future<void> _stopRecording() async {
    final audioFile =
        await ref.read(chatNotifierProvider.notifier).stopRecording();

    setState(() {
      _isRecording = false;
    });

    if (audioFile != null) {
      await ref.read(chatNotifierProvider.notifier).sendVoiceMessage(
            chatId: widget.chatId,
            senderId: widget.senderId,
            receiverId: widget.receiverId,
            audioFile: audioFile,
          );
    }
  }

  Future<void> _cancelRecording() async {
    await ref.read(chatNotifierProvider.notifier).cancelRecording();

    setState(() {
      _isRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Text input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالة...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        textDirection: TextDirection.rtl,
                        maxLines: null,
                        enabled: !_isRecording,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button or voice recording button
            if (_isRecording)
              Row(
                children: [
                  // Cancel button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: _cancelRecording,
                  ),
                  // Stop recording button
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _stopRecording,
                  ),
                ],
              )
            else if (_hasText)
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: _sendTextMessage,
              )
            else
              GestureDetector(
                onLongPress: _startRecording,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
