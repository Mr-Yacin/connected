/**
 * Firebase Cloud Functions for Push Notifications
 * 
 * Deploy with: firebase deploy --only functions
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Send notification when a new message is created
 */
export const onNewMessage = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    const { chatId } = context.params;

    try {
      // Get chat document to find participants
      const chatDoc = await admin
        .firestore()
        .collection("chats")
        .doc(chatId)
        .get();

      if (!chatDoc.exists) {
        console.log("Chat not found:", chatId);
        return null;
      }

      const chat = chatDoc.data();
const receiverId = chat?.participants?.find(
        (id: string) => id !== message.senderId
      );

      if (!receiverId) {
        console.log("Receiver not found");
        return null;
      }

      // Get sender and receiver details
      const [senderDoc, receiverDoc] = await Promise.all([
        admin.firestore().collection("users").doc(message.senderId).get(),
        admin.firestore().collection("users").doc(receiverId).get(),
      ]);

      const sender = senderDoc.data();
      const receiver = receiverDoc.data();

      if (!receiver?.fcmToken) {
        console.log("Receiver has no FCM token");
        return null;
      }

      // Prepare notification body based on message type
      let notificationBody = "";
      switch (message.type) {
        case "text":
          notificationBody = message.text;
          break;
        case "voice":
          notificationBody = "🎤 رسالة صوتية";
          break;
        case "image":
          notificationBody = "📷 صورة";
          break;
        default:
          notificationBody = "رسالة جديدة";
      }

      // Send notification
      const payload = {
        token: receiver.fcmToken,
        notification: {
          title: sender?.name || "رسالة جديدة",
          body: notificationBody,
        },
        data: {
          type: "new_message",
          chatId: chatId,
          senderId: message.senderId,
          otherUserId: message.senderId,
          otherUserName: sender?.name || "",
          otherUserImageUrl: sender?.profileImageUrl || "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high" as const,
          notification: {
            channelId: "messages",
            sound: "default",
            priority: "high" as const,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: (receiver.unreadCount || 0) + 1,
            },
          },
        },
      };

      await admin.messaging().send(payload);
      console.log("✅ Message notification sent to:", receiverId);

      // Update unread count
      await admin
        .firestore()
        .collection("users")
        .doc(receiverId)
        .update({
          unreadCount: admin.firestore.FieldValue.increment(1),
        });

      return null;
    } catch (error) {
      console.error("Error sending message notification:", error);
      return null;
    }
  });

/**
 * Send notification when someone replies to a story
 */
export const onStoryReply = functions.firestore
  .document("stories/{storyId}/replies/{replyId}")
  .onCreate(async (snapshot, context) => {
    const reply = snapshot.data();
    const { storyId } = context.params;

    try {
      // Get story to find owner
      const storyDoc = await admin
        .firestore()
        .collection("stories")
        .doc(storyId)
        .get();

      if (!storyDoc.exists) {
        console.log("Story not found:", storyId);
        return null;
      }

      const story = storyDoc.data();

      // Don't notify if replying to own story
      if (story?.userId === reply.senderId) {
        console.log("User replied to own story, no notification");
        return null;
      }

      // Get replier and owner details
      const [replierDoc, ownerDoc] = await Promise.all([
        admin.firestore().collection("users").doc(reply.senderId).get(),
        admin.firestore().collection("users").doc(story.userId).get(),
      ]);

      const replier = replierDoc.data();
      const owner = ownerDoc.data();

      if (!owner?.fcmToken) {
        console.log("Story owner has no FCM token");
        return null;
      }

      // Send notification
      await admin.messaging().send({
        token: owner.fcmToken,
        notification: {
          title: `رد ${replier?.name || "شخص ما"} على قصتك`,
          body: reply.text || "رد جديد",
        },
        data: {
          type: "story_reply",
          storyId: storyId,
          userId: story.userId,
          senderId: reply.senderId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high" as const,
          notification: {
            channelId: "stories",
          },
        },
      });

      console.log("✅ Story reply notification sent to:", story.userId);
      return null;
    } catch (error) {
      console.error("Error sending story reply notification:", error);
      return null;
    }
  });

/**
 * Send notification when someone likes a post
 */
export const onNewLike = functions.firestore
  .document("likes/{likeId}")
  .onCreate(async (snapshot, context) => {
    const like = snapshot.data();

    try {
      // Get post to find owner
      const postDoc = await admin
        .firestore()
        .collection("posts")
        .doc(like.postId)
        .get();

      if (!postDoc.exists) {
        console.log("Post not found:", like.postId);
        return null;
      }

      const post = postDoc.data();

      // Don't notify if liking own post
      if (post?.userId === like.userId) {
        console.log("User liked own post, no notification");
        return null;
      }

      // Get liker and owner details
      const [likerDoc, ownerDoc] = await Promise.all([
        admin.firestore().collection("users").doc(like.userId).get(),
        admin.firestore().collection("users").doc(post.userId).get(),
      ]);

      const liker = likerDoc.data();
      const owner = ownerDoc.data();

      if (!owner?.fcmToken) {
        console.log("Post owner has no FCM token");
        return null;
      }

      // Send notification
      await admin.messaging().send({
        token: owner.fcmToken,
        notification: {
          title: "❤️ إعجاب جديد",
          body: `أعجب ${liker?.name || "شخص ما"} بمنشورك`,
        },
        data: {
          type: "new_like",
          postId: like.postId,
          likerId: like.userId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          notification: {
            channelId: "likes",
          },
        },
      });

      console.log("✅ Like notification sent to:", post.userId);
      return null;
    } catch (error) {
      console.error("Error sending like notification:", error);
      return null;
    }
  });

/**
 * Send notification when someone views your profile
 * (Only if enabled in user settings)
 */
export const onProfileView = functions.firestore
  .document("profile_views/{viewId}")
  .onCreate(async (snapshot, context) => {
    const view = snapshot.data();

    try {
      // Get profile owner settings
      const ownerDoc = await admin
        .firestore()
        .collection("users")
        .doc(view.profileUserId)
        .get();

      const owner = ownerDoc.data();

      // Check if profile view notifications are enabled
      if (!owner?.settings?.notifyOnProfileView) {
        console.log("Profile view notifications disabled for user");
        return null;
      }

      if (!owner?.fcmToken) {
        console.log("Profile owner has no FCM token");
        return null;
      }

      // Get viewer details
      const viewerDoc = await admin
        .firestore()
        .collection("users")
        .doc(view.viewerId)
        .get();

      const viewer = viewerDoc.data();

      // Send notification
      await admin.messaging().send({
        token: owner.fcmToken,
        notification: {
          title: "👀 زار ملفك الشخصي",
          body: `${viewer?.name || "شخص ما"} شاهد ملفك الشخصي`,
        },
        data: {
          type: "profile_view",
          viewerId: view.viewerId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          notification: {
            channelId: "general",
          },
        },
      });

      console.log("✅ Profile view notification sent to:", view.profileUserId);
      return null;
    } catch (error) {
      console.error("Error sending profile view notification:", error);
      return null;
    }
  });

/**
 * Clean up expired FCM tokens
 * Run daily at midnight
 */
export const cleanupExpiredTokens = functions.pubsub
  .schedule("0 0 * * *")
  .timeZone("Asia/Riyadh")
  .onRun(async () => {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - 60); // 60 days ago

      const expiredTokensQuery = await admin
        .firestore()
        .collection("users")
        .where("fcmTokenUpdatedAt", "<", cutoffDate)
        .get();

      const batch = admin.firestore().batch();
      let count = 0;

      expiredTokensQuery.forEach((doc) => {
        batch.update(doc.ref, {
          fcmToken: admin.firestore.FieldValue.delete(),
          fcmTokenUpdatedAt: admin.firestore.FieldValue.delete(),
        });
        count++;
      });

      await batch.commit();
      console.log(`✅ Cleaned up ${count} expired FCM tokens`);
      return null;
    } catch (error) {
      console.error("Error cleaning up expired tokens:", error);
      return null;
    }
  });
