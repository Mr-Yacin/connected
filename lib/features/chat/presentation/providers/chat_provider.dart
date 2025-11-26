import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/message.dart';
import '../../data/repositories/firestore_chat_repository.dart';
import '../../data/services/voice_recorder_service.dart';
import '../../domain/repositories/chat_repository.dart';

/// Provider for ChatRepository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FirestoreChatRepository();
});

/// Provider for VoiceRecorderService
final voiceRecorderServiceProvider = Provider<VoiceRecorderService>((ref) {
  return VoiceRecorderService();
});

/// Provider for messages stream (non-paginated - for backward compatibility)
final messagesStreamProvider = StreamProvider.family<List<Message>, String>(
  (ref, chatId) {
    final repository = ref.watch(chatRepositoryProvider);
    return repository.getMessages(chatId);
  },
);

/// Provider for paginated messages stream
final paginatedMessagesStreamProvider = StreamProvider.family<List<Message>, String>(
  (ref, chatId) {
    final repository = ref.watch(chatRepositoryProvider);
    return repository.getMessagesPaginated(
      chatId: chatId,
      limit: 50,
    );
  },
);

/// Provider for chat list stream (real-time updates)
final chatListProvider = StreamProvider.family<List<ChatPreview>, String>(
  (ref, userId) {
    final repository = ref.watch(chatRepositoryProvider);
    return repository.getChatListStream(userId);
  },
);

/// State notifier for chat operations
class ChatNotifier extends StateNotifier<AsyncValue<void>> {
  final ChatRepository _repository;
  final VoiceRecorderService _voiceRecorder;
  
  // Track loaded messages for pagination
  final Map<String, List<Message>> _loadedMessages = {};
  final Map<String, bool> _hasMoreMessages = {};

  ChatNotifier(this._repository, this._voiceRecorder)
      : super(const AsyncValue.data(null));

  /// Send text message
  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.sendTextMessage(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
      );
    });
  }

  /// Send voice message
  Future<void> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required File audioFile,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.sendVoiceMessage(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        audioFile: audioFile,
      );
    });
  }

  /// Mark message as read
  Future<void> markAsRead(String chatId, String messageId) async {
    await _repository.markAsRead(chatId, messageId);
  }

  /// Mark entire chat as read (resets unread count)
  Future<void> markChatAsRead(String chatId, String userId) async {
    await _repository.markChatAsRead(chatId, userId);
  }

  /// Start recording voice message
  Future<void> startRecording() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _voiceRecorder.startRecording();
    });
  }

  /// Stop recording and return audio file
  Future<File?> stopRecording() async {
    try {
      final file = await _voiceRecorder.stopRecording();
      state = const AsyncValue.data(null);
      return file;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    await _voiceRecorder.cancelRecording();
    state = const AsyncValue.data(null);
  }

  /// Play audio
  Future<void> playAudio(String audioUrl) async {
    await _voiceRecorder.playAudio(audioUrl);
  }

  /// Pause audio
  Future<void> pauseAudio() async {
    await _voiceRecorder.pauseAudio();
  }

  /// Stop audio
  Future<void> stopAudio() async {
    await _voiceRecorder.stopAudio();
  }

  /// Check if recording
  bool get isRecording => _voiceRecorder.isRecording;

  /// Load more messages for pagination
  Future<void> loadMoreMessages(String chatId, DateTime lastMessageTimestamp) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final olderMessages = await _repository
          .getMessagesPaginated(
            chatId: chatId,
            limit: 50,
            lastMessageTimestamp: lastMessageTimestamp,
          )
          .first;

      // Track if there are more messages
      _hasMoreMessages[chatId] = olderMessages.isNotEmpty && olderMessages.length >= 50;
      
      // Store loaded messages
      _loadedMessages[chatId] = [
        ...(_loadedMessages[chatId] ?? []),
        ...olderMessages,
      ];
    });
  }

  /// Check if there are more messages to load
  bool hasMoreMessages(String chatId) {
    return _hasMoreMessages[chatId] ?? true;
  }

  /// Get loaded messages count
  int getLoadedMessagesCount(String chatId) {
    return _loadedMessages[chatId]?.length ?? 0;
  }

  /// Clear loaded messages cache
  void clearMessagesCache(String chatId) {
    _loadedMessages.remove(chatId);
    _hasMoreMessages.remove(chatId);
  }
}

/// Provider for ChatNotifier
final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final voiceRecorder = ref.watch(voiceRecorderServiceProvider);
  return ChatNotifier(repository, voiceRecorder);
});
