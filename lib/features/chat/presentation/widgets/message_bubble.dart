import 'package:flutter/material.dart';
import '../../../../core/models/message.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/theme/app_colors.dart';
import 'voice_message_widget.dart';

/// Widget for displaying a message bubble
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message content
            if (message.type == MessageType.text)
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              )
            else if (message.type == MessageType.voice)
              VoiceMessageWidget(
                audioUrl: message.content,
                isMe: isMe,
              )
            else if (message.type == MessageType.storyReply)
              _buildStoryReplyContent(context),

            const SizedBox(height: 5),

            // Timestamp and read status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: isMe ? Colors.white.withValues(alpha: 0.8) : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[ 
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 16,
                    color: message.isRead ? Colors.lightBlue[200] : Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryReplyContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Story preview card (compact Instagram-like design)
        Container(
          decoration: BoxDecoration(
            color: isMe 
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isMe 
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.grey.withValues(alpha: 0.25),
              width: 0.5,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Story thumbnail (smaller and more compact)
                if (message.storyMediaUrl != null && message.storyMediaUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    child: Image.network(
                      message.storyMediaUrl!,
                      width: 40,
                      height: 56,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 40,
                          height: 56,
                          color: isMe 
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey[200],
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isMe ? Colors.white.withValues(alpha: 0.5) : Colors.grey[400],
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Failed to load story image: ${message.storyMediaUrl}');
                        return Container(
                          width: 40,
                          height: 56,
                          color: isMe 
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: isMe 
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.grey[400],
                            size: 20,
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isMe 
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: isMe 
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.grey[400],
                      size: 20,
                    ),
                  ),
                
                // Story label (more compact)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: isMe 
                              ? Colors.white.withValues(alpha: 0.85)
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'القصة',
                          style: TextStyle(
                            color: isMe 
                                ? Colors.white.withValues(alpha: 0.85)
                                : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Reply text (if exists)
        if (message.content.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            message.content,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
