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
            // Collect chat data and identify which users need profile fetching
            final chatDataList = <Map<String, dynamic>>[];
            final userIdsNeedingFetch = <String>[];

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

              // Check if denormalized data exists
              final participantNames = data['participantNames'] as Map<String, dynamic>?;
              
              final hasDenormalizedData = participantNames != null && 
                                         participantNames.containsKey(otherUserId);

              chatDataList.add({
                'chatId': doc.id,
                'otherUserId': otherUserId,
                'data': data,
                'hasDenormalizedData': hasDenormalizedData,
              });

              // If denormalized data is missing, add to fetch list
              if (!hasDenormalizedData) {
                userIdsNeedingFetch.add(otherUserId);
              }
            }

            // Batch fetch missing user profiles
            final userProfiles = userIdsNeedingFetch.isNotEmpty
                ? await _batchFetchUserProfiles(userIdsNeedingFetch)
                : <String, Map<String, dynamic>?>{};

            // Build chat previews using denormalized data or fetched profiles
            final chatPreviews = <ChatPreview>[];
            for (final chatData in chatDataList) {
              final data = chatData['data'] as Map<String, dynamic>;
              final otherUserId = chatData['otherUserId'] as String;
              final hasDenormalizedData = chatData['hasDenormalizedData'] as bool;

              String? otherUserName;
              String? otherUserImageUrl;

              if (hasDenormalizedData) {
                // Use denormalized data
                final participantNames = data['participantNames'] as Map<String, dynamic>;
                final participantImages = data['participantImages'] as Map<String, dynamic>?;
                
                otherUserName = participantNames[otherUserId] as String?;
                otherUserImageUrl = participantImages?[otherUserId] as String?;
              } else {
                // Fallback to fetched profile data
                final userData = userProfiles[otherUserId];
                otherUserName = userData?['name'] as String?;
                otherUserImageUrl = userData?['profileImageUrl'] as String?;
              }

              // Read unread count directly from denormalized field
              final unreadCountMap =
                  data['unreadCount'] as Map<String, dynamic>?;
              final unreadCount = unreadCountMap?[userId] as int? ?? 0;

              chatPreviews.add(
                ChatPreview(
                  chatId: chatData['chatId'] as String,
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  otherUserImageUrl: otherUserImageUrl,
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

  /// Batch fetch user profiles using Firestore whereIn queries
  /// Handles batching for lists larger than 10 (Firestore limit)
  /// Returns a map of userId to user data
  Future<Map<String, Map<String, dynamic>?>> _batchFetchUserProfiles(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    final profiles = <String, Map<String, dynamic>?>{};

    try {
      // Firestore whereIn limit is 10, so we need to batch
      for (var i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();

        try {
          final snapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();

          for (final doc in snapshot.docs) {
            profiles[doc.id] = doc.data();
          }

          // Mark any users not found in this batch
          for (final userId in batch) {
            if (!profiles.containsKey(userId)) {
              profiles[userId] = null;
            }
          }
        } catch (e, stackTrace) {
          // Log batch query error and fall back to individual queries
          ErrorLoggingService.logFirestoreError(
            e,
            stackTrace: stackTrace,
            context: 'Batch query failed, falling back to individual queries',
            screen: 'ChatListScreen',
            operation: '_batchFetchUserProfiles',
            collection: 'users',
          );

          // Fallback: fetch individually for this batch
          for (final userId in batch) {
            try {
              final userDoc = await _firestore
                  .collection('users')
                  .doc(userId)
                  .get();
              profiles[userId] = userDoc.data();
            } catch (individualError, individualStackTrace) {
              ErrorLoggingService.logFirestoreError(
                individualError,
                stackTrace: individualStackTrace,
                context: 'Individual user fetch failed',
                screen: 'ChatListScreen',
                operation: '_batchFetchUserProfiles',
                collection: 'users',
                documentId: userId,
              );
              profiles[userId] = null;
            }
          }
        }
      }
    } catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to batch fetch user profiles',
        screen: 'ChatListScreen',
        operation: '_batchFetchUserProfiles',
        collection: 'users',
      );
      // Return empty map on complete failure
      return {};
    }

    return profiles;
  }

  /// Build chat previews from snapshot
  /// Uses denormalized data first, falls back to batch fetch if missing
  Future<List<ChatPreview>> _buildChatPreviews(
    QuerySnapshot chatsSnapshot,
    String userId,
  ) async {
    final chatPreviews = <ChatPreview>[];

    // Collect chat data and identify which users need profile fetching
    final chatDataList = <Map<String, dynamic>>[];
    final userIdsNeedingFetch = <String>[];

    for (final doc in chatsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] as List);
      final otherUserId = participants.firstWhere(
        (id) => id != userId,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) continue;

      // Check if denormalized data exists
      final participantNames = data['participantNames'] as Map<String, dynamic>?;
      
      final hasDenormalizedData = participantNames != null && 
                                 participantNames.containsKey(otherUserId);

      chatDataList.add({
        'chatId': doc.id,
        'otherUserId': otherUserId,
        'data': data,
        'hasDenormalizedData': hasDenormalizedData,
      });

      // If denormalized data is missing, add to fetch list
      if (!hasDenormalizedData) {
        userIdsNeedingFetch.add(otherUserId);
      }
    }

    // Batch fetch missing user profiles
    final userProfiles = userIdsNeedingFetch.isNotEmpty
        ? await _batchFetchUserProfiles(userIdsNeedingFetch)
        : <String, Map<String, dynamic>?>{};

    // Build chat previews using denormalized data or fetched profiles
    for (final chatData in chatDataList) {
      final data = chatData['data'] as Map<String, dynamic>;
      final otherUserId = chatData['otherUserId'] as String;
      final hasDenormalizedData = chatData['hasDenormalizedData'] as bool;

      String? otherUserName;
      String? otherUserImageUrl;

      if (hasDenormalizedData) {
        // Use denormalized data
        final participantNames = data['participantNames'] as Map<String, dynamic>;
        final participantImages = data['participantImages'] as Map<String, dynamic>?;
        
        otherUserName = participantNames[otherUserId] as String?;
        otherUserImageUrl = participantImages?[otherUserId] as String?;
      } else {
        // Fallback to fetched profile data
        final userData = userProfiles[otherUserId];
        otherUserName = userData?['name'] as String?;
        otherUserImageUrl = userData?['profileImageUrl'] as String?;
      }

      final unreadCountMap = data['unreadCount'] as Map<String, dynamic>?;
      final unreadCount = unreadCountMap?[userId] as int? ?? 0;

      chatPreviews.add(
        ChatPreview(
          chatId: chatData['chatId'] as String,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          otherUserImageUrl: otherUserImageUrl,
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
  /// Also stores denormalized participant data (names and profile images)
  Future<void> _updateChatMetadata({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String lastMessage,
    required DateTime lastMessageTime,
  }) async {
    return handleFirestoreVoidOperation(
      operation: () async {
        // Fetch participant profiles for denormalization
        final participantProfiles = await _batchFetchUserProfiles([senderId, receiverId]);
        
        final senderData = participantProfiles[senderId];
        final receiverData = participantProfiles[receiverId];
        
        // Build denormalized participant data
        final participantNames = <String, String>{};
        final participantImages = <String, String?>{};
        
        if (senderData != null) {
          participantNames[senderId] = senderData['name'] as String? ?? '';
          participantImages[senderId] = senderData['profileImageUrl'] as String?;
        }
        
        if (receiverData != null) {
          participantNames[receiverId] = receiverData['name'] as String? ?? '';
          participantImages[receiverId] = receiverData['profileImageUrl'] as String?;
        }
        
        await _firestore.collection('chats').doc(chatId).set({
          'participants': [senderId, receiverId],
          'participantNames': participantNames,
          'participantImages': participantImages,
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

  /// Update denormalized participant data in all chats for a specific user
  /// This should be called when a user updates their profile (name or profile image)
  /// Supports background job execution for batch updates
  @override
  Future<void> updateUserDenormalizedData({
    required String userId,
    required String userName,
    String? userImageUrl,
    bool runInBackground = false,
  }) async {
    if (runInBackground) {
      // Run in background without blocking
      _updateUserDenormalizedDataInBackground(
        userId: userId,
        userName: userName,
        userImageUrl: userImageUrl,
      );
      return;
    }

    // Run synchronously
    return handleFirestoreVoidOperation(
      operation: () async {
        await _updateUserDenormalizedDataInBackground(
          userId: userId,
          userName: userName,
          userImageUrl: userImageUrl,
        );
      },
      operationName: 'updateUserDenormalizedData',
      screen: 'ProfileScreen',
      arabicErrorMessage: 'فشل في تحديث بيانات المحادثات',
      collection: 'chats',
    );
  }

  /// Internal method to update denormalized data in background
  Future<void> _updateUserDenormalizedDataInBackground({
    required String userId,
    required String userName,
    String? userImageUrl,
  }) async {
    try {
      // Find all chats where this user is a participant
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      if (chatsSnapshot.docs.isEmpty) {
        return;
      }

      // Batch update all chats (Firestore batch limit is 500 operations)
      final batchSize = 500;
      var batch = _firestore.batch();
      var operationCount = 0;

      for (final doc in chatsSnapshot.docs) {
        // Update the denormalized data for this user
        batch.update(doc.reference, {
          'participantNames.$userId': userName,
          'participantImages.$userId': userImageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        operationCount++;

        // Commit batch when reaching limit
        if (operationCount >= batchSize) {
          await batch.commit();
          batch = _firestore.batch();
          operationCount = 0;
        }
      }

      // Commit remaining operations
      if (operationCount > 0) {
        await batch.commit();
      }
    } catch (e, stackTrace) {
      // Log error but don't throw to prevent blocking profile updates
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to update denormalized user data in chats',
        screen: 'ProfileScreen',
        operation: 'updateUserDenormalizedData',
        collection: 'chats',
      );
    }
  }
}
