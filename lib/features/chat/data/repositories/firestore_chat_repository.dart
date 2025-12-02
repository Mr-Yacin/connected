import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/message.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/data/base_firestore_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../../../services/monitoring/error_logging_service.dart';

/// Firestore implementation of ChatRepository
class FirestoreChatRepository extends BaseFirestoreRepository
    implements ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Uuid _uuid;

  FirestoreChatRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    Uuid? uuid,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _uuid = uuid ?? const Uuid();

  @override
  Stream<List<Message>> getMessages(String chatId) {
    try {
      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) {
                    try {
                      return Message.fromJson(doc.data());
                    } catch (e) {
                      // Log individual message parsing errors
                      ErrorLoggingService.logGeneralError(
                        e,
                        stackTrace: StackTrace.current,
                        context: 'Failed to parse message: ${doc.id}',
                        screen: 'ChatScreen',
                        operation: 'getMessages',
                      );
                      return null;
                    }
                  })
                  .whereType<Message>() // Filter out null values
                  .toList();
            } catch (e, stackTrace) {
              ErrorLoggingService.logGeneralError(
                e,
                stackTrace: stackTrace,
                context: 'Failed to map messages snapshot',
                screen: 'ChatScreen',
                operation: 'getMessages',
              );
              return <Message>[]; // Return empty list on error
            }
          });
    } catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get messages stream',
        screen: 'ChatScreen',
        operation: 'getMessages',
        collection: 'chats/$chatId/messages',
      );
      throw AppException('فشل في جلب الرسائل: $e');
    }
  }

  @override
  Stream<List<Message>> getMessagesPaginated({
    required String chatId,
    int limit = 50,
    DateTime? lastMessageTimestamp,
  }) {
    try {
      var query = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      // If we have a last message timestamp, start after it
      if (lastMessageTimestamp != null) {
        query = query.startAfter([Timestamp.fromDate(lastMessageTimestamp)]);
      }

      return query.snapshots().map((snapshot) {
        try {
          final messages = snapshot.docs
              .map((doc) {
                try {
                  return Message.fromJson(doc.data());
                } catch (e) {
                  // Log individual message parsing errors
                  ErrorLoggingService.logGeneralError(
                    e,
                    stackTrace: StackTrace.current,
                    context: 'Failed to parse message: ${doc.id}',
                    screen: 'ChatScreen',
                    operation: 'getMessagesPaginated',
                  );
                  return null;
                }
              })
              .whereType<Message>() // Filter out null values
              .toList();
          // Reverse to show oldest first
          return messages.reversed.toList();
        } catch (e, stackTrace) {
          ErrorLoggingService.logGeneralError(
            e,
            stackTrace: stackTrace,
            context: 'Failed to map messages snapshot',
            screen: 'ChatScreen',
            operation: 'getMessagesPaginated',
          );
          return <Message>[]; // Return empty list on error
        }
      });
    } catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get paginated messages',
        screen: 'ChatScreen',
        operation: 'getMessagesPaginated',
        collection: 'chats/$chatId/messages',
      );
      throw AppException('فشل في جلب الرسائل: $e');
    }
  }

  @override
  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    return handleFirestoreVoidOperation(
      operation: () async {
        final messageId = _uuid.v4();
        final message = Message(
          id: messageId,
          chatId: chatId,
          senderId: senderId,
          receiverId: receiverId,
          type: MessageType.text,
          content: text,
          timestamp: DateTime.now(),
          isRead: false,
        );

        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .set(message.toJson());

        await _updateChatMetadata(
          chatId: chatId,
          senderId: senderId,
          receiverId: receiverId,
          lastMessage: text,
          lastMessageTime: message.timestamp,
        );
      },
      operationName: 'sendTextMessage',
      screen: 'ChatScreen',
      arabicErrorMessage: 'فشل في إرسال الرسالة',
      collection: 'chats/$chatId/messages',
    );
  }

  @override
  Future<void> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required File audioFile,
  }) async {
    return handleFirestoreVoidOperation(
      operation: () async {
        final audioUrl = await _uploadVoiceMessage(chatId, audioFile);

        final messageId = _uuid.v4();
        final message = Message(
          id: messageId,
          chatId: chatId,
          senderId: senderId,
          receiverId: receiverId,
          type: MessageType.voice,
          content: audioUrl,
          timestamp: DateTime.now(),
          isRead: false,
        );

        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .set(message.toJson());

        await _updateChatMetadata(
          chatId: chatId,
          senderId: senderId,
          receiverId: receiverId,
          lastMessage: '🎤 رسالة صوتية',
          lastMessageTime: message.timestamp,
        );
      },
      operationName: 'sendVoiceMessage',
      screen: 'ChatScreen',
      arabicErrorMessage: 'فشل في إرسال الرسالة الصوتية',
      collection: 'chats/$chatId/messages',
    );
  }

  @override
  Future<void> sendStoryReplyMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
    required String storyId,
    required String storyMediaUrl,
  }) async {
    return handleFirestoreVoidOperation(
      operation: () async {
        final messageId = _uuid.v4();
        final message = Message(
          id: messageId,
          chatId: chatId,
          senderId: senderId,
          receiverId: receiverId,
          type: MessageType.storyReply,
          content: text,
          timestamp: DateTime.now(),
          isRead: false,
          storyId: storyId,
          storyMediaUrl: storyMediaUrl,
        );

        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .set(message.toJson());

        await _updateChatMetadata(
          chatId: chatId,
          senderId: senderId,
          receiverId: receiverId,
          lastMessage: text,
          lastMessageTime: message.timestamp,
        );
      },
      operationName: 'sendStoryReplyMessage',
      screen: 'StoryViewScreen',
      arabicErrorMessage: 'فشل في إرسال الرد على القصة',
      collection: 'chats/$chatId/messages',
    );
  }

  @override
  Future<void> markAsRead(String chatId, String messageId) async {
    return handleFirestoreVoidOperation(
      operation: () async {
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .update({'isRead': true});
      },
      operationName: 'markAsRead',
      screen: 'ChatScreen',
      arabicErrorMessage: 'فشل في تحديث حالة الرسالة',
      collection: 'chats/$chatId/messages',
      documentId: messageId,
    );
  }

  @override
  Future<void> markChatAsRead(String chatId, String userId) async {
    return handleFirestoreVoidOperation(
      operation: () async {
        await _firestore.collection('chats').doc(chatId).update({
          'unreadCount.$userId': 0,
        });
      },
      operationName: 'markChatAsRead',
      screen: 'ChatScreen',
      arabicErrorMessage: 'فشل في تحديث حالة المحادثة',
      collection: 'chats',
      documentId: chatId,
    );
  }

  @override
  Future<List<ChatPreview>> getChatList(String userId) async {
    return handleFirestoreOperation(
      operation: () async {
        final chatsSnapshot = await _firestore
            .collection('chats')
            .where('participants', arrayContains: userId)
            .orderBy('lastMessageTime', descending: true)
            .get();

        return _buildChatPreviews(chatsSnapshot, userId);
      },
      operationName: 'getChatList',
      screen: 'ChatListScreen',
      arabicErrorMessage: 'فشل في جلب قائمة المحادثات',
      collection: 'chats',
    );
  }

  @override
  Stream<List<ChatPreview>> getChatListStream(String userId) {
    try {
      return _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .asyncMap((chatsSnapshot) async {
            final chatPreviews = <ChatPreview>[];

            for (final doc in chatsSnapshot.docs) {
              final data = doc.data();
              final participants = List<String>.from(
                data['participants'] as List,
              );
              final otherUserId = participants.firstWhere(
                (id) => id != userId,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) continue;

              // Get other user's profile
              final userDoc = await _firestore
                  .collection('users')
                  .doc(otherUserId)
                  .get();
              final userData = userDoc.data();

              // OPTIMIZED: Read unread count directly from denormalized field
              final unreadCountMap =
                  data['unreadCount'] as Map<String, dynamic>?;
              final unreadCount = unreadCountMap?[userId] as int? ?? 0;

              chatPreviews.add(
                ChatPreview(
                  chatId: doc.id,
                  otherUserId: otherUserId,
                  otherUserName: userData?['name'] as String?,
                  otherUserImageUrl: userData?['profileImageUrl'] as String?,
                  lastMessage: data['lastMessage'] as String?,
                  lastMessageTime: data['lastMessageTime'] != null
                      ? (data['lastMessageTime'] as Timestamp).toDate()
                      : null,
                  unreadCount: unreadCount,
                ),
              );
            }

            return chatPreviews;
          });
    } catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get chat list stream',
        screen: 'ChatListScreen',
        operation: 'getChatListStream',
        collection: 'chats',
      );
      throw AppException('فشل في جلب قائمة المحادثات: $e');
    }
  }

  /// Build chat previews from snapshot
  Future<List<ChatPreview>> _buildChatPreviews(
    QuerySnapshot chatsSnapshot,
    String userId,
  ) async {
    final chatPreviews = <ChatPreview>[];

    for (final doc in chatsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] as List);
      final otherUserId = participants.firstWhere(
        (id) => id != userId,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) continue;

      final userDoc = await _firestore
          .collection('users')
          .doc(otherUserId)
          .get();
      final userData = userDoc.data();

      final unreadCountMap = data['unreadCount'] as Map<String, dynamic>?;
      final unreadCount = unreadCountMap?[userId] as int? ?? 0;

      chatPreviews.add(
        ChatPreview(
          chatId: doc.id,
          otherUserId: otherUserId,
          otherUserName: userData?['name'] as String?,
          otherUserImageUrl: userData?['profileImageUrl'] as String?,
          lastMessage: data['lastMessage'] as String?,
          lastMessageTime: data['lastMessageTime'] != null
              ? (data['lastMessageTime'] as Timestamp).toDate()
              : null,
          unreadCount: unreadCount,
        ),
      );
    }

    return chatPreviews;
  }

  /// Upload voice message to Firebase Storage
  Future<String> _uploadVoiceMessage(String chatId, File audioFile) async {
    return handleFirestoreOperation(
      operation: () async {
        final fileName = '${_uuid.v4()}.m4a';
        final ref = _storage.ref().child('voice_messages/$chatId/$fileName');

        final uploadTask = await ref.putFile(audioFile);
        return await uploadTask.ref.getDownloadURL();
      },
      operationName: 'uploadVoiceMessage',
      screen: 'ChatScreen',
      arabicErrorMessage: 'فشل في رفع الرسالة الصوتية',
    );
  }

  /// Update chat metadata (last message, timestamp, participants)
  Future<void> _updateChatMetadata({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String lastMessage,
    required DateTime lastMessageTime,
  }) async {
    return handleFirestoreVoidOperation(
      operation: () async {
        await _firestore.collection('chats').doc(chatId).set({
          'participants': [senderId, receiverId],
          'lastMessage': lastMessage,
          'lastMessageTime': Timestamp.fromDate(lastMessageTime),
          'updatedAt': FieldValue.serverTimestamp(),
          'unreadCount.$receiverId': FieldValue.increment(1),
        }, SetOptions(merge: true));
      },
      operationName: 'updateChatMetadata',
      screen: 'ChatScreen',
      arabicErrorMessage: 'فشل في تحديث بيانات المحادثة',
      collection: 'chats',
      documentId: chatId,
    );
  }
}
