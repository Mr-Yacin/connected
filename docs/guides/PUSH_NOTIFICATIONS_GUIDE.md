# 🔔 Push Notifications Complete Guide

## Quick Start

### 1. Firebase CLI Setup
```bash
npm install -g firebase-tools
firebase login
```

### 2. Initialize & Deploy Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

---

## 📱 Current Setup Status

✅ **Already Configured:**
- Firebase Cloud Messaging (FCM) initialized in `main.dart`
- FCM token saved to Firestore user document
- Handlers for foreground/background messages
- Notification tap handling
- Permission requests

---

## 🔧 Client-Side Implementation

### 1. Update Notification Service

**File:** `lib/services/external/notification_service.dart`

Add navigation callback capability:

```dart
import 'package:go_router/go_router.dart';

typedef NotificationTapCallback = void Function(String route, Map<String, String> params);

class NotificationService {
  NotificationTapCallback? _onNotificationTap;
  
  void setNavigationCallback(NotificationTapCallback callback) {
    _onNotificationTap = callback;
  }

  /// Handle notification tap - Route based on type
  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'] as String?;
    
    if (_onNotificationTap == null) return;
    
    switch (type) {
      case 'new_message':
        final chatId = message.data['chatId'] ?? '';
        final otherUserId = message.data['otherUserId'] ?? '';
        final otherUserName = message.data['otherUserName'] ?? '';
        final otherUserImageUrl = message.data['otherUserImageUrl'] ?? '';
        _onNotificationTap!(
          '/chat/$chatId',
          {
            'currentUserId': _auth.currentUser?.uid ?? '',
            'otherUserId': otherUserId,
            'otherUserName': otherUserName,
            'otherUserImageUrl': otherUserImageUrl,
          },
        );
        break;
        
      case 'story_reply':
        final storyId = message.data['storyId'] ?? '';
        _onNotificationTap!('/story/$storyId', {});
        break;
        
      case 'new_like':
        final postId = message.data['postId'] ?? '';
        _onNotificationTap!('/post/$postId', {});
        break;
        
      case 'profile_view':
        final viewerId = message.data['viewerId'] ?? '';
        _onNotificationTap!('/profile/$viewerId', {});
        break;
        
      default:
        _onNotificationTap!('/home', {});
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    
    // Show local notification (requires flutter_local_notifications)
    _showLocalNotification(
      title: notification?.title ?? 'إشعار جديد',
      body: notification?.body ?? '',
      payload: data,
    );
  }
}
```

### 2. Setup in main.dart

```dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final notificationService = ref.watch(notificationServiceProvider);
    
    // Setup notification navigation callback
    notificationService.setNavigationCallback((route, params) {
      router.push(route, extra: params);
    });
    
    return MaterialApp.router(
      routerConfig: router,
      // ... rest of config
    );
  }
}
```

### 3. Token Management

**After Login:**
```dart
final notificationService = ref.read(notificationServiceProvider);
await notificationService.refreshAndSaveToken();
```

**Before Logout:**
```dart
final notificationService = ref.read(notificationServiceProvider);
await notificationService.deleteToken();
```

---

## 🚀 Backend Implementation (Cloud Functions)

### 1. New Message Notification

**File:** `functions/src/notifications/messageNotifications.ts`

```javascript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const onNewMessage = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    const { chatId } = context.params;
    
    // Get chat participants
    const chatDoc = await admin.firestore()
      .collection("chats")
      .doc(chatId)
      .get();
    
    if (!chatDoc.exists) return;
    
    const chat = chatDoc.data();
    const receiverId = chat.participants.find(
      (id: string) => id !== message.senderId
    );
    
    if (!receiverId) return;
    
    // Get sender and receiver details
    const [senderDoc, receiverDoc] = await Promise.all([
      admin.firestore().collection("users").doc(message.senderId).get(),
      admin.firestore().collection("users").doc(receiverId).get(),
    ]);
    
    const sender = senderDoc.data();
    const receiver = receiverDoc.data();
    
    if (!receiver?.fcmToken) return;
    
    // Send notification
    await admin.messaging().send({
      token: receiver.fcmToken,
      notification: {
        title: sender?.name || "رسالة جديدة",
        body: message.type === "text" 
          ? message.text 
          : message.type === "voice"
          ? "🎤 رسالة صوتية"
          : "📷 صورة",
      },
      data: {
        type: "new_message",
        chatId: chatId,
        senderId: message.senderId,
        otherUserId: message.senderId,
        otherUserName: sender?.name || "",
        otherUserImageUrl: sender?.profileImageUrl || "",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "messages",
          sound: "default",
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
    });
    
    // Update unread count
    await admin.firestore()
      .collection("users")
      .doc(receiverId)
      .update({
        unreadCount: admin.firestore.FieldValue.increment(1),
      });
  });
```

### 2. Story Reply Notification

```javascript
export const onStoryReply = functions.firestore
  .document("stories/{storyId}/replies/{replyId}")
  .onCreate(async (snapshot, context) => {
    const reply = snapshot.data();
    const { storyId } = context.params;
    
    const storyDoc = await admin.firestore()
      .collection("stories")
      .doc(storyId)
      .get();
    
    if (!storyDoc.exists) return;
    
    const story = storyDoc.data();
    
    // Don't notify if replying to own story
    if (story.userId === reply.senderId) return;
    
    const [replierDoc, ownerDoc] = await Promise.all([
      admin.firestore().collection("users").doc(reply.senderId).get(),
      admin.firestore().collection("users").doc(story.userId).get(),
    ]);
    
    const replier = replierDoc.data();
    const owner = ownerDoc.data();
    
    if (!owner?.fcmToken) return;
    
    await admin.messaging().send({
      token: owner.fcmToken,
      notification: {
        title: `رد ${replier?.name || "شخص ما"} على قصتك`,
        body: reply.text,
      },
      data: {
        type: "story_reply",
        storyId: storyId,
        senderId: reply.senderId,
      },
    });
  });
```

### 3. Deploy Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:onNewMessage
```

---

## 🧪 Testing

### Get FCM Token

Add temporary button in your app:

```dart
ElevatedButton(
  onPressed: () async {
    final token = ref.read(notificationServiceProvider).fcmToken;
    if (token != null) {
      await Clipboard.setData(ClipboardData(text: token));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('FCM Token copied!')),
      );
      print('FCM Token: $token');
    }
  },
  child: Text('Copy FCM Token'),
)
```

### Test via Firebase Console

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Fill in title and text
4. Target: "FCM registration token"
5. Paste your token
6. Click "Send"

### Test via cURL

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "YOUR_FCM_TOKEN",
    "notification": {
      "title": "رسالة جديدة",
      "body": "لديك رسالة جديدة من أحمد"
    },
    "data": {
      "type": "new_message",
      "chatId": "chat123",
      "otherUserId": "user456",
      "otherUserName": "أحمد",
      "otherUserImageUrl": ""
    }
  }'
```

---

## 📱 Platform Configuration

### Android

**1. Update AndroidManifest.xml**

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
  <!-- FCM -->
  <meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />
  <meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/notification_color" />
  <meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="messages" />
</application>
```

**2. Create colors.xml**

`android/app/src/main/res/values/colors.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_color">#FF6B35</color>
</resources>
```

### iOS

**1. Update Info.plist**

Add to `ios/Runner/Info.plist`:

```xml
<dict>
  <key>UIBackgroundModes</key>
  <array>
    <string>remote-notification</string>
  </array>
</dict>
```

**2. Enable Push in Xcode**

1. Open `ios/Runner.xcworkspace`
2. Select Runner target
3. Go to "Signing & Capabilities"
4. Add "Push Notifications"
5. Add "Background Modes" → Check "Remote notifications"

**3. Upload APNs Certificate**

1. Create APNs certificate in Apple Developer Portal
2. Upload to Firebase Console → Project Settings → Cloud Messaging

---

## 🎨 Notification Channels

```dart
// lib/services/external/notification_channels.dart
class NotificationChannels {
  static const String messages = 'messages';
  static const String stories = 'stories';
  static const String likes = 'likes';
  static const String general = 'general';

  static List<AndroidNotificationChannel> get channels => [
    const AndroidNotificationChannel(
      messages,
      'رسائل',
      description: 'إشعارات الرسائل الجديدة',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('message_sound'),
    ),
    const AndroidNotificationChannel(
      stories,
      'قصص',
      description: 'إشعارات القصص والردود',
      importance: Importance.defaultImportance,
    ),
    const AndroidNotificationChannel(
      likes,
      'إعجابات',
      description: 'إشعارات الإعجابات',
      importance: Importance.low,
      playSound: false,
    ),
  ];
}
```

---

## 🔒 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      
      allow update: if request.auth != null 
        && request.auth.uid == userId
        && request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['fcmToken', 'fcmTokenUpdatedAt', 'unreadCount', 'lastSeen']);
    }
  }
}
```

---

## 🐛 Troubleshooting

### Notifications not received?
1. Check FCM token is saved in Firestore
2. Verify Cloud Function logs: `firebase functions:log`
3. Test with Firebase Console first
4. Verify notification permissions granted

### Navigation not working?
1. Ensure `setNavigationCallback` is called
2. Check notification data includes correct `type`
3. Verify routes match router configuration

### iOS not working?
1. Verify APNs certificate uploaded
2. Test on physical device (simulator can't receive push)
3. Check app signing and provisioning profile

### Android silent notifications?
1. Verify notification channel created
2. Check notification icon exists
3. Verify AndroidManifest.xml metadata

---

## ✅ Implementation Checklist

- [ ] Update `NotificationService` with navigation callback
- [ ] Setup callback in `main.dart`
- [ ] Deploy Cloud Functions
- [ ] Test via Firebase Console
- [ ] Setup notification channels (Android)
- [ ] Add notification icons and sounds
- [ ] Configure iOS APNs
- [ ] Test on physical devices
- [ ] Add notification preferences UI
- [ ] Deploy to production

---

## 🎯 Best Practices

✅ **DO:**
- Test on real devices before production
- Batch notifications to avoid spam
- Personalize notification content
- Respect quiet hours (10 PM - 8 AM)
- Allow users to customize preferences
- Track notification analytics

❌ **DON'T:**
- Send notifications too frequently
- Use generic notification content
- Forget to handle navigation edge cases
- Ignore notification permissions
- Send sensitive data in notifications

---

## 📚 Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Plugin](https://firebase.flutter.dev/docs/messaging/overview)
- [Cloud Functions Documentation](https://firebase.google.com/docs/functions)
