import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to merge duplicate chat documents created by the old chatId generation
/// 
/// This script identifies duplicate chats (e.g., "new_userA" and "new_userB" for the same conversation)
/// and merges them into a single chat with the new deterministic ID format.
/// 
/// IMPORTANT: Run this script AFTER deploying the ChatUtils.generateChatId() fix
/// 
/// Usage:
/// 1. Ensure Firebase is initialized in your app
/// 2. Run this script from a Flutter app context (not standalone)
/// 3. Monitor the console for progress and errors
/// 
/// What it does:
/// 1. Scans all chat documents with "new_" prefix
/// 2. Groups them by participant pairs
/// 3. Merges messages from duplicate chats into the correct chat
/// 4. Deletes the duplicate chat documents
/// 5. Updates chat metadata (last message, unread counts, etc.)

class DuplicateChatMerger {
  final FirebaseFirestore _firestore;
  
  DuplicateChatMerger({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Main method to find and merge duplicate chats
  Future<void> mergeDuplicateChats() async {
    print('🔍 Starting duplicate chat detection...');
    
    try {
      // Get all chats
      final chatsSnapshot = await _firestore.collection('chats').get();
      print('📊 Found ${chatsSnapshot.docs.length} total chats');
      
      // Group chats by participant pairs
      final Map<String, List<DocumentSnapshot>> chatsByParticipants = {};
      
      for (final doc in chatsSnapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] as List);
        
        if (participants.length != 2) {
          print('⚠️  Skipping chat ${doc.id} - invalid participants count');
          continue;
        }
        
        // Create a sorted key for the participant pair
        final sortedParticipants = List<String>.from(participants)..sort();
        final key = '${sortedParticipants[0]}_${sortedParticipants[1]}';
        
        if (!chatsByParticipants.containsKey(key)) {
          chatsByParticipants[key] = [];
        }
        chatsByParticipants[key]!.add(doc);
      }
      
      print('👥 Found ${chatsByParticipants.length} unique participant pairs');
      
      // Find duplicates
      int duplicateCount = 0;
      int mergedCount = 0;
      
      for (final entry in chatsByParticipants.entries) {
        final participantKey = entry.key;
        final chats = entry.value;
        
        if (chats.length > 1) {
          duplicateCount++;
          print('\n🔄 Found duplicate chats for participants: $participantKey');
          print('   Chat IDs: ${chats.map((c) => c.id).join(", ")}');
          
          try {
            await _mergeChatGroup(participantKey, chats);
            mergedCount++;
            print('   ✅ Successfully merged');
          } catch (e) {
            print('   ❌ Failed to merge: $e');
          }
        }
      }
      
      print('\n📈 Summary:');
      print('   Total chats: ${chatsSnapshot.docs.length}');
      print('   Duplicate groups found: $duplicateCount');
      print('   Successfully merged: $mergedCount');
      print('   Failed: ${duplicateCount - mergedCount}');
      
    } catch (e, stackTrace) {
      print('❌ Error during migration: $e');
      print(stackTrace);
    }
  }
  
  /// Merge a group of duplicate chats into one
  Future<void> _mergeChatGroup(
    String participantKey,
    List<DocumentSnapshot> chats,
  ) async {
    // Use the participant key as the new chat ID (already sorted)
    final newChatId = participantKey;
    
    // Check if a chat with the new ID already exists
    final existingChat = chats.firstWhere(
      (chat) => chat.id == newChatId,
      orElse: () => chats.first,
    );
    
    final targetChatId = existingChat.id == newChatId ? newChatId : newChatId;
    
    // Collect all messages from all duplicate chats
    final allMessages = <Map<String, dynamic>>[];
    DateTime? latestMessageTime;
    String? latestMessage;
    final Map<String, int> unreadCounts = {};
    
    for (final chat in chats) {
      final chatData = chat.data() as Map<String, dynamic>;
      
      // Track latest message
      final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
      if (lastMessageTime != null) {
        final messageDate = lastMessageTime.toDate();
        if (latestMessageTime == null || messageDate.isAfter(latestMessageTime)) {
          latestMessageTime = messageDate;
          latestMessage = chatData['lastMessage'] as String?;
        }
      }
      
      // Aggregate unread counts
      final chatUnreadCounts = chatData['unreadCount'] as Map<String, dynamic>?;
      if (chatUnreadCounts != null) {
        chatUnreadCounts.forEach((userId, count) {
          unreadCounts[userId] = (unreadCounts[userId] ?? 0) + (count as int);
        });
      }
      
      // Get all messages from this chat
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chat.id)
          .collection('messages')
          .get();
      
      for (final messageDoc in messagesSnapshot.docs) {
        allMessages.add({
          'id': messageDoc.id,
          'data': messageDoc.data(),
        });
      }
    }
    
    print('   📨 Found ${allMessages.length} total messages to merge');
    
    // Create or update the target chat document
    final participants = participantKey.split('_');
    final chatData = existingChat.data() as Map<String, dynamic>;
    
    await _firestore.collection('chats').doc(targetChatId).set({
      'participants': participants,
      'participantNames': chatData['participantNames'] ?? {},
      'participantImages': chatData['participantImages'] ?? {},
      'lastMessage': latestMessage,
      'lastMessageTime': latestMessageTime != null 
          ? Timestamp.fromDate(latestMessageTime) 
          : FieldValue.serverTimestamp(),
      'unreadCount': unreadCounts,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    // Copy all messages to the target chat
    final batch = _firestore.batch();
    int batchCount = 0;
    
    for (final message in allMessages) {
      final messageRef = _firestore
          .collection('chats')
          .doc(targetChatId)
          .collection('messages')
          .doc(message['id'] as String);
      
      // Update chatId in message data
      final messageData = Map<String, dynamic>.from(message['data'] as Map<String, dynamic>);
      messageData['chatId'] = targetChatId;
      
      batch.set(messageRef, messageData, SetOptions(merge: true));
      batchCount++;
      
      // Firestore batch limit is 500 operations
      if (batchCount >= 500) {
        await batch.commit();
        batchCount = 0;
      }
    }
    
    if (batchCount > 0) {
      await batch.commit();
    }
    
    // Delete duplicate chat documents (except the target)
    for (final chat in chats) {
      if (chat.id != targetChatId) {
        print('   🗑️  Deleting duplicate chat: ${chat.id}');
        
        // Delete all messages in the duplicate chat
        final messagesSnapshot = await _firestore
            .collection('chats')
            .doc(chat.id)
            .collection('messages')
            .get();
        
        final deleteBatch = _firestore.batch();
        for (final messageDoc in messagesSnapshot.docs) {
          deleteBatch.delete(messageDoc.reference);
        }
        await deleteBatch.commit();
        
        // Delete the chat document
        await _firestore.collection('chats').doc(chat.id).delete();
      }
    }
  }
  
  /// Dry run - shows what would be merged without making changes
  Future<void> dryRun() async {
    print('🔍 Running dry run (no changes will be made)...');
    
    try {
      final chatsSnapshot = await _firestore.collection('chats').get();
      print('📊 Found ${chatsSnapshot.docs.length} total chats');
      
      final Map<String, List<String>> duplicateGroups = {};
      
      for (final doc in chatsSnapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] as List);
        
        if (participants.length != 2) continue;
        
        final sortedParticipants = List<String>.from(participants)..sort();
        final key = '${sortedParticipants[0]}_${sortedParticipants[1]}';
        
        if (!duplicateGroups.containsKey(key)) {
          duplicateGroups[key] = [];
        }
        duplicateGroups[key]!.add(doc.id);
      }
      
      final duplicates = duplicateGroups.entries.where((e) => e.value.length > 1);
      
      print('\n📋 Duplicate groups that would be merged:');
      for (final entry in duplicates) {
        print('   Participants: ${entry.key}');
        print('   Chat IDs: ${entry.value.join(", ")}');
        print('   → Would merge into: ${entry.key}\n');
      }
      
      print('Total duplicate groups: ${duplicates.length}');
      
    } catch (e, stackTrace) {
      print('❌ Error during dry run: $e');
      print(stackTrace);
    }
  }
}

/// Example usage:
/// 
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///   
///   final merger = DuplicateChatMerger();
///   
///   // First, run a dry run to see what would be merged
///   await merger.dryRun();
///   
///   // If everything looks good, run the actual merge
///   // await merger.mergeDuplicateChats();
/// }
/// ```
