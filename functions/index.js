const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function: onMessageSent
 * Trigger: Firestore onCreate for chats/{chatId}/messages/{messageId}
 * Purpose: Update chat metadata when a new message is sent
 *
 * Updates:
 * - lastMessage: The text of the latest message
 * - lastMessageTime: Timestamp of the latest message
 * - unreadCount: Increment for the recipient
 */
exports.onMessageSent = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const chatId = context.params.chatId;
    const messageId = context.params.messageId;

    try {
      console.log(`Processing message ${messageId} in chat ${chatId}`);

      // Get chat document
      const chatRef = db.collection("chats").doc(chatId);
      const chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        console.warn(`Chat ${chatId} does not exist`);
        return null;
      }

      const chatData = chatDoc.data();
      const senderId = messageData.senderId;
      const recipientId = chatData.participants.find(
        (id) => id !== senderId,
      );

      // Prepare update data
      const updateData = {
        lastMessage: messageData.text || "[Media]",
        lastMessageTime: messageData.timestamp ||
          admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
      };

      // Increment unread count for recipient using server-side field value
      updateData[`unreadCount.${recipientId}`] =
        admin.firestore.FieldValue.increment(1);

      // Update chat document
      await chatRef.update(updateData);

      console.log(`Updated chat ${chatId} metadata successfully`);
      return {success: true};
    } catch (error) {
      console.error("Error updating chat metadata:", error);
      return {success: false, error: error.message};
    }
  });

/**
 * Cloud Function: sendPushNotification
 * Trigger: Firestore onCreate for chats/{chatId}/messages/{messageId}
 * Purpose: Send push notification to recipient when new message arrives
 *
 * Flow:
 * 1. Get recipient's FCM token from users collection
 * 2. Get sender's display name
 * 3. Send notification via FCM
 */
exports.sendPushNotification = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const chatId = context.params.chatId;

    try {
      console.log(`Sending push notification for chat ${chatId}`);

      // Get chat document to find recipient
      const chatRef = db.collection("chats").doc(chatId);
      const chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        console.warn(`Chat ${chatId} does not exist`);
        return null;
      }

      const chatData = chatDoc.data();
      const senderId = messageData.senderId;
      const recipientId = chatData.participants.find(
        (id) => id !== senderId,
      );

      // Get recipient's FCM token
      const recipientDoc = await db.collection("users")
        .doc(recipientId).get();

      if (!recipientDoc.exists) {
        console.warn(`Recipient ${recipientId} does not exist`);
        return null;
      }

      const recipientData = recipientDoc.data();
      const fcmToken = recipientData.fcmToken;

      if (!fcmToken) {
        console.info(`Recipient ${recipientId} has no FCM token`);
        return null;
      }

      // Get sender's display name
      const senderDoc = await db.collection("users").doc(senderId).get();
      const senderName = senderDoc.exists ?
        senderDoc.data().displayName || "Someone" :
        "Someone";

      // Prepare notification payload
      const messageText = messageData.text || "📷 Photo";
      const payload = {
        notification: {
          title: senderName,
          body: messageText,
        },
        data: {
          chatId: chatId,
          senderId: senderId,
          type: "new_message",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        token: fcmToken,
        android: {
          priority: "high",
          notification: {
            channelId: "messages",
            sound: "default",
            priority: "high",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      // Send notification
      const response = await messaging.send(payload);
      console.log(`Push notification sent successfully: ${response}`);

      return {success: true, messageId: response};
    } catch (error) {
      console.error("Error sending push notification:", error);
      return {success: false, error: error.message};
    }
  });

/**
 * Cloud Function: cleanupExpiredStories
 * Trigger: Scheduled (every 1 hour)
 * Purpose: Delete stories that are older than 24 hours
 *
 * Flow:
 * 1. Query stories with createdAt < 24 hours ago
 * 2. Delete story documents
 * 3. Delete associated media files from Storage
 * 4. Update user's activeStoryCount
 */
exports.cleanupExpiredStories = functions.pubsub
  .schedule("every 1 hours")
  .timeZone("UTC")
  .onRun(async (context) => {
    try {
      console.log("Starting expired stories cleanup");

      const now = admin.firestore.Timestamp.now();
      const twentyFourHoursAgo = admin.firestore.Timestamp.fromMillis(
        now.toMillis() - (24 * 60 * 60 * 1000),
      );

      // Query expired stories
      const expiredStoriesQuery = db.collection("stories")
        .where("createdAt", "<", twentyFourHoursAgo);

      const expiredStoriesSnapshot = await expiredStoriesQuery.get();

      if (expiredStoriesSnapshot.empty) {
        console.log("No expired stories found");
        return {success: true, deletedCount: 0};
      }

      console.log(`Found ${expiredStoriesSnapshot.size} expired stories`);

      const batch = db.batch();
      const userStoryCountUpdates = {};
      const mediaUrls = [];

      // Process each expired story
      expiredStoriesSnapshot.docs.forEach((doc) => {
        const storyData = doc.data();

        // Add to batch delete
        batch.delete(doc.ref);

        // Track user story count updates
        const userId = storyData.userId;
        userStoryCountUpdates[userId] =
          (userStoryCountUpdates[userId] || 0) + 1;

        // Collect media URLs for deletion
        if (storyData.mediaUrl) {
          mediaUrls.push(storyData.mediaUrl);
        }
      });

      // Update user activeStoryCount
      for (const [userId, count] of Object.entries(userStoryCountUpdates)) {
        const userRef = db.collection("users").doc(userId);
        batch.update(userRef, {
          activeStoryCount: admin.firestore.FieldValue.increment(-count),
        });
      }

      // Commit batch
      await batch.commit();
      console.log(`Deleted ${expiredStoriesSnapshot.size} expired stories`);

      // Delete media files from Storage
      if (mediaUrls.length > 0) {
        const bucket = admin.storage().bucket();

        for (const mediaUrl of mediaUrls) {
          try {
            // Extract file path from URL
            const filePath = mediaUrl.split("/o/")[1]?.split("?")[0];
            if (filePath) {
              const decodedPath = decodeURIComponent(filePath);
              await bucket.file(decodedPath).delete();
              console.log(`Deleted media file: ${decodedPath}`);
            }
          } catch (error) {
            console.warn(`Failed to delete media file: ${mediaUrl}`, error);
          }
        }
      }

      return {
        success: true,
        deletedCount: expiredStoriesSnapshot.size,
        mediaFilesDeleted: mediaUrls.length,
      };
    } catch (error) {
      console.error("Error cleaning up expired stories:", error);
      return {success: false, error: error.message};
    }
  });

/**
 * Cloud Function: updateUserMetrics
 * Trigger: HTTPS callable
 * Purpose: Update user activity metrics and analytics
 *
 * Metrics tracked:
 * - lastActiveAt: Last time user was active
 * - messageCount: Total messages sent
 * - storyCount: Total stories created
 * - profileViewCount: Times profile was viewed
 */
exports.updateUserMetrics = functions.https.onCall(async (data, context) => {
  const {userId, metricType, incrementBy = 1} = data;

  if (!userId || !metricType) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "userId and metricType are required",
    );
  }

  try {
    const userRef = db.collection("users").doc(userId);
    const updateData = {
      lastActiveAt: admin.firestore.Timestamp.now(),
    };

    // Update specific metric
    switch (metricType) {
    case "message":
      updateData.messageCount =
          admin.firestore.FieldValue.increment(incrementBy);
      break;
    case "story":
      updateData.storyCount =
          admin.firestore.FieldValue.increment(incrementBy);
      break;
    case "profileView":
      updateData.profileViewCount =
          admin.firestore.FieldValue.increment(incrementBy);
      break;
    default:
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Unknown metric type: ${metricType}`,
      );
    }

    await userRef.update(updateData);

    console.log(`Updated ${metricType} metric for user ${userId}`);
    return {success: true};
  } catch (error) {
    console.error("Error updating user metrics:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * Cloud Function: onUserCreated
 * Trigger: Firestore onCreate for users/{userId}
 * Purpose: Initialize user document with default values
 *
 * Sets up:
 * - Default metrics (messageCount, storyCount, etc.)
 * - Welcome notification
 * - Analytics event
 */
exports.onUserCreated = functions.firestore
  .document("users/{userId}")
  .onCreate(async (snap, context) => {
    const userData = snap.data();
    const userId = context.params.userId;

    try {
      console.log(`Initializing new user ${userId}`);

      const userRef = db.collection("users").doc(userId);

      // Set default metrics
      await userRef.update({
        messageCount: 0,
        storyCount: 0,
        profileViewCount: 0,
        activeStoryCount: 0,
        friendCount: 0,
        createdAt: userData.createdAt || admin.firestore.Timestamp.now(),
        lastActiveAt: admin.firestore.Timestamp.now(),
      });

      // Create welcome notification
      await db.collection("notifications").add({
        userId: userId,
        type: "welcome",
        title: "Welcome to Social Connect!",
        body: "Start connecting with people who share your interests.",
        read: false,
        createdAt: admin.firestore.Timestamp.now(),
      });

      console.log(`User ${userId} initialized successfully`);
      return {success: true};
    } catch (error) {
      console.error("Error initializing user:", error);
      return {success: false, error: error.message};
    }
  });
