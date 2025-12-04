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
 * Send notification when someone likes your story
 */
export const onStoryLike = functions.firestore
  .document("stories/{storyId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const { storyId } = context.params;

    try {
      // Check if likedBy array was updated
      const beforeLikes = before.likedBy || [];
      const afterLikes = after.likedBy || [];

      // Find new likes (users who weren't in before but are in after)
      const newLikes = afterLikes.filter(
        (userId: string) => !beforeLikes.includes(userId)
      );

      if (newLikes.length === 0) {
        // No new likes, skip notification
        return null;
      }

      // Get the first new liker (most recent)
      const likerId = newLikes[0];

      // Don't notify if liking own story
      if (after.userId === likerId) {
        console.log("User liked own story, no notification");
        return null;
      }

      // Get liker and owner details
      const [likerDoc, ownerDoc] = await Promise.all([
        admin.firestore().collection("users").doc(likerId).get(),
        admin.firestore().collection("users").doc(after.userId).get(),
      ]);

      const liker = likerDoc.data();
      const owner = ownerDoc.data();

      if (!owner?.fcmToken) {
        console.log("Story owner has no FCM token");
        return null;
      }

      // Send notification
      await admin.messaging().send({
        token: owner.fcmToken,
        notification: {
          title: "❤️ إعجاب بقصتك",
          body: `أعجب ${liker?.name || "شخص ما"} بقصتك`,
        },
        data: {
          type: "story_like",
          storyId: storyId,
          userId: after.userId,
          likerId: likerId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high" as const,
          notification: {
            channelId: "stories",
          },
        },
      });

      console.log("✅ Story like notification sent to:", after.userId);
      return null;
    } catch (error) {
      console.error("Error sending story like notification:", error);
      return null;
    }
  });

/**
 * Send notification when someone follows you
 */
export const onNewFollower = functions.firestore
  .document("users/{userId}/followers/{followerId}")
  .onCreate(async (snapshot, context) => {
    const { userId, followerId } = context.params;

    try {
      // Don't notify if following yourself (shouldn't happen but just in case)
      if (userId === followerId) {
        console.log("User followed themselves, no notification");
        return null;
      }

      // Get follower and user details
      const [followerDoc, userDoc] = await Promise.all([
        admin.firestore().collection("users").doc(followerId).get(),
        admin.firestore().collection("users").doc(userId).get(),
      ]);

      const follower = followerDoc.data();
      const user = userDoc.data();

      if (!user?.fcmToken) {
        console.log("User has no FCM token");
        return null;
      }

      // Send notification
      await admin.messaging().send({
        token: user.fcmToken,
        notification: {
          title: "👤 متابع جديد",
          body: `${follower?.name || "شخص ما"} بدأ بمتابعتك`,
        },
        data: {
          type: "new_follower",
          followerId: followerId,
          userId: userId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high" as const,
          notification: {
            channelId: "social",
          },
        },
      });

      console.log("✅ New follower notification sent to:", userId);
      return null;
    } catch (error) {
      console.error("Error sending new follower notification:", error);
      return null;
    }
  });

/**
 * Send notification when someone you follow posts a new story
 */
export const onNewStoryFromFollowing = functions.firestore
  .document("stories/{storyId}")
  .onCreate(async (snapshot, context) => {
    const story = snapshot.data();
    const { storyId } = context.params;

    try {
      // Get all followers of the story creator
      const followersSnapshot = await admin
        .firestore()
        .collection("users")
        .doc(story.userId)
        .collection("followers")
        .get();

      if (followersSnapshot.empty) {
        console.log("Story creator has no followers");
        return null;
      }

      // Get story creator details
      const creatorDoc = await admin
        .firestore()
        .collection("users")
        .doc(story.userId)
        .get();

      const creator = creatorDoc.data();

      // Prepare notification payload
      const notificationPayload = {
        notification: {
          title: "📸 قصة جديدة",
          body: `${creator?.name || "شخص ما"} نشر قصة جديدة`,
        },
        data: {
          type: "new_story",
          storyId: storyId,
          userId: story.userId,
          creatorName: creator?.name || "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high" as const,
          notification: {
            channelId: "stories",
          },
        },
      };

      // Send notification to each follower
      const notifications: Promise<string>[] = [];
      
      for (const followerDoc of followersSnapshot.docs) {
        const followerId = followerDoc.id;

        // Get follower's FCM token
        const followerUserDoc = await admin
          .firestore()
          .collection("users")
          .doc(followerId)
          .get();

        const followerUser = followerUserDoc.data();

        if (followerUser?.fcmToken) {
          notifications.push(
            admin.messaging().send({
              ...notificationPayload,
              token: followerUser.fcmToken,
            })
          );
        }
      }

      // Send all notifications in parallel
      const results = await Promise.allSettled(notifications);
      const successCount = results.filter((r) => r.status === "fulfilled").length;

      console.log(
        `✅ New story notifications sent: ${successCount}/${notifications.length}`
      );
      return null;
    } catch (error) {
      console.error("Error sending new story notifications:", error);
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
