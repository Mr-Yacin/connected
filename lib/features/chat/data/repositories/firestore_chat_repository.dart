import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/message.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../../../services/error_logging_service.dart';

/// Firestore implementation of ChatRepository
class FirestoreChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Uuid _uuid;

  FirestoreChatRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
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
        return snapshot.docs
            .map((doc) => Message.fromJson(doc.data()))
            .toList();
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
        final messages = snapshot.docs
            .map((doc) => Message.fromJson(doc.data()))
            .toList();
        // Reverse to show oldest first
        return messages.reversed.toList();
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
    try {
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

      // Save message to Firestore
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(message.toJson());

      // Update chat metadata
      await _updateChatMetadata(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        lastMessage: text,
        lastMessageTime: message.timestamp,
      );
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to send text message',
        screen: 'ChatScreen',
        operation: 'sendTextMessage',
        collection: 'chats/$chatId/messages',
      );
      throw AppException('فشل في إرسال الرسالة: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error sending text message',
        screen: 'ChatScreen',
        operation: 'sendTextMessage',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<void> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required File audioFile,
  }) async {
    try {
      // Upload audio file to Firebase Storage
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

      // Save message to Firestore
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(message.toJson());

      // Update chat metadata
      await _updateChatMetadata(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        lastMessage: '🎤 رسالة صوتية',
        lastMessageTime: message.timestamp,
      );
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logStorageError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to send voice message',
        screen: 'ChatScreen',
        operation: 'sendVoiceMessage',
      );
      throw AppException('فشل في إرسال الرسالة الصوتية: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error sending voice message',
        screen: 'ChatScreen',
        operation: 'sendVoiceMessage',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<void> markAsRead(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true});
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to mark message as read',
        screen: 'ChatScreen',
        operation: 'markAsRead',
        collection: 'chats/$chatId/messages',
        documentId: messageId,
      );
      throw AppException('فشل في تحديث حالة الرسالة: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error marking message as read',
        screen: 'ChatScreen',
        operation: 'markAsRead',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      // OPTIMIZED: Reset unread count for user when opening chat
      await _firestore.collection('chats').doc(chatId).set({
        'unreadCount.$userId': 0,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to mark chat as read',
        screen: 'ChatScreen',
        operation: 'markChatAsRead',
        collection: 'chats',
        documentId: chatId,
      );
      throw AppException('فشل في تحديث حالة المحادثة: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error marking chat as read',
        screen: 'ChatScreen',
        operation: 'markChatAsRead',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<List<ChatPreview>> getChatList(String userId) async {
    try {
      // Get all chats where user is a participant
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .get();

      final chatPreviews = <ChatPreview>[];

      for (final doc in chatsSnapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] as List);
        final otherUserId =
            participants.firstWhere((id) => id != userId, orElse: () => '');

        if (otherUserId.isEmpty) continue;

        // Get other user's profile
        final userDoc =
            await _firestore.collection('users').doc(otherUserId).get();
        final userData = userDoc.data();

        // OPTIMIZED: Read unread count directly from denormalized field
        final unreadCountMap = data['unreadCount'] as Map<String, dynamic>?;
        final unreadCount = unreadCountMap?[userId] as int? ?? 0;

        chatPreviews.add(ChatPreview(
          chatId: doc.id,
          otherUserId: otherUserId,
          otherUserName: userData?['name'] as String?,
          otherUserImageUrl: userData?['profileImageUrl'] as String?,
          lastMessage: data['lastMessage'] as String?,
          lastMessageTime: data['lastMessageTime'] != null
              ? (data['lastMessageTime'] as Timestamp).toDate()
              : null,
          unreadCount: unreadCount,
        ));
      }

      return chatPreviews;
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get chat list',
        screen: 'ChatListScreen',
        operation: 'getChatList',
        collection: 'chats',
      );
      throw AppException('فشل في جلب قائمة المحادثات: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error getting chat list',
        screen: 'ChatListScreen',
        operation: 'getChatList',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
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
          final participants = List<String>.from(data['participants'] as List);
          final otherUserId =
              participants.firstWhere((id) => id != userId, orElse: () => '');

          if (otherUserId.isEmpty) continue;

          // Get other user's profile
          final userDoc =
              await _firestore.collection('users').doc(otherUserId).get();
          final userData = userDoc.data();

          // OPTIMIZED: Read unread count directly from denormalized field
          final unreadCountMap = data['unreadCount'] as Map<String, dynamic>?;
          final unreadCount = unreadCountMap?[userId] as int? ?? 0;

          chatPreviews.add(ChatPreview(
            chatId: doc.id,
            otherUserId: otherUserId,
            otherUserName: userData?['name'] as String?,
            otherUserImageUrl: userData?['profileImageUrl'] as String?,
            lastMessage: data['lastMessage'] as String?,
            lastMessageTime: data['lastMessageTime'] != null
                ? (data['lastMessageTime'] as Timestamp).toDate()
                : null,
            unreadCount: unreadCount,
          ));
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

  /// Upload voice message to Firebase Storage
  Future<String> _uploadVoiceMessage(String chatId, File audioFile) async {
    try {
      final fileName = '${_uuid.v4()}.m4a';
      final ref = _storage.ref().child('voice_messages/$chatId/$fileName');

      final uploadTask = await ref.putFile(audioFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logStorageError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to upload voice message',
        screen: 'ChatScreen',
        operation: '_uploadVoiceMessage',
        filePath: 'voice_messages/$chatId',
      );
      throw AppException('فشل في رفع الرسالة الصوتية: ${e.message}');
    }
  }

  /// Update chat metadata (last message, timestamp, participants)
  Future<void> _updateChatMetadata({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String lastMessage,
    required DateTime lastMessageTime,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [senderId, receiverId],
        'lastMessage': lastMessage,
        'lastMessageTime': Timestamp.fromDate(lastMessageTime),
        'updatedAt': FieldValue.serverTimestamp(),
        // OPTIMIZED: Increment unread count for receiver
        'unreadCount.$receiverId': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to update chat metadata',
        screen: 'ChatScreen',
        operation: '_updateChatMetadata',
        collection: 'chats',
        documentId: chatId,
      );
      throw AppException('فشل في تحديث بيانات المحادثة: ${e.message}');
    }
  }
}
