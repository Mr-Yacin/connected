# FCM (Firebase Cloud Messaging) - Complete Guide

## ❓ Your Question: "Don't need anything on app, just cloud function?"

### Answer: **NO! You need BOTH app-side AND Cloud Function**

Here's why:

---

## 🔄 Complete FCM Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                      COMPLETE FCM FLOW                            │
└──────────────────────────────────────────────────────────────────┘

Step 1: APP INITIALIZATION
┌─────────────────┐
│   Flutter App   │
│   (User B)      │
└────────┬────────┘
         │
         │ 1. Request notification permission
         │ 2. Get FCM token from Firebase
         ▼
    "cXYz123abc..."  <-- FCM Token (unique per device)
         │
         │ 3. Save to Firestore
         ▼
┌─────────────────┐
│   Firestore     │
│   users/userB   │
│   {             │
│     fcmToken:   │
│     "cXYz..."   │
│   }             │
└─────────────────┘


Step 2: MESSAGE SENT
┌─────────────────┐
│   User A App    │
│   (Sender)      │
└────────┬────────┘
         │
         │ Sends message
         ▼
┌─────────────────┐
│   Firestore     │
│   chats/chat1/  │
│   messages/msg1 │
└────────┬────────┘
         │
         │ Triggers Cloud Function
         ▼


Step 3: CLOUD FUNCTION
┌─────────────────────────────────────┐
│   sendPushNotification Function     │
│                                     │
│  1. Get recipient from chat doc     │
│  2. Read fcmToken from Firestore    │ <-- NEEDS TOKEN FROM APP!
│  3. Get sender's name               │
│  4. Send to FCM servers             │
└────────┬────────────────────────────┘
         │
         │ HTTP POST to fcm.googleapis.com
         ▼
┌─────────────────┐
│  FCM Servers    │
│  (Google)       │
└────────┬────────┘
         │
         │ Push notification
         ▼
┌─────────────────┐
│   User B App    │
│   (Recipient)   │
│                 │
│  📱 "New msg!"  │
└─────────────────┘
```

---

## 🔑 Key Components

### 1. APP SIDE (Required!)

#### A. Get FCM Token
```dart
// In NotificationService
final fcmToken = await FirebaseMessaging.instance.getToken();
```

#### B. Save Token to Firestore
```dart
// After user logs in
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .update({'fcmToken': token});
```

#### C. Handle Incoming Notifications
```dart
// Foreground
FirebaseMessaging.onMessage.listen((message) {
  // Show notification
});

// Background
FirebaseMessaging.onBackgroundMessage(handler);

// Tap
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  // Navigate to chat
});
```

---

### 2. CLOUD FUNCTION SIDE

#### Read FCM Token from Firestore
```javascript
// In sendPushNotification function
const recipientDoc = await db.collection('users').doc(recipientId).get();
const fcmToken = recipientDoc.data().fcmToken;

if (!fcmToken) {
  console.log('No FCM token for user');
  return; // Can't send notification!
}
```

#### Send to FCM
```javascript
await messaging.send({
  token: fcmToken,  // <-- FROM APP!
  notification: {
    title: 'John Doe',
    body: 'Hello!'
  }
});
```

---

## ❌ What Happens Without App Setup?

```
User B logs in
  ↓
No FCM token saved to Firestore
  ↓
User A sends message
  ↓
Cloud Function triggers
  ↓
Looks for fcmToken in Firestore
  ↓
fcmToken is NULL ❌
  ↓
Function logs: "No FCM token for user"
  ↓
NO NOTIFICATION SENT ❌
```

---

## ✅ What Happens With Complete Setup?

```
User B logs in
  ↓
App gets FCM token: "cXYz123abc..."
  ↓
Saves to Firestore: users/userB/fcmToken
  ↓
User A sends message
  ↓
Cloud Function triggers
  ↓
Reads fcmToken from Firestore: "cXYz123abc..."
  ↓
Sends to FCM servers with token
  ↓
FCM delivers to User B's device ✅
  ↓
User B sees notification 🎉
```

---

## 📝 Implementation Checklist

### ✅ App Side (Already Implemented!)

- [x] `NotificationService` created
- [x] Request notification permissions
- [x] Get FCM token
- [x] Save token to Firestore on login
- [x] Refresh token on updates
- [x] Delete token on logout
- [x] Handle foreground messages
- [x] Handle background messages
- [x] Handle notification taps

### ✅ Cloud Function Side (Already Implemented!)

- [x] `sendPushNotification` function
- [x] Read fcmToken from Firestore
- [x] Get sender's display name
- [x] Send notification via FCM
- [x] Error handling

### ⚠️ What You Need to Do

1. **Deploy Cloud Functions**
   ```bash
   firebase deploy --only functions
   ```

2. **Run Flutter App**
   ```bash
   flutter run
   ```

3. **Test**
   - Login as User A
   - Login as User B on different device
   - Send message from A to B
   - User B should get notification!

---

## 🔧 Configuration Required

### Android (`android/app/src/main/AndroidManifest.xml`)

Already configured in your project:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### iOS (`ios/Runner/Info.plist`)

No additional config needed - handled by firebase_messaging package.

---

## 🧪 Testing FCM

### 1. Check Token Saved

```dart
// After login, check Firestore
Firebase Console > Firestore > users > {userId}
Should see: fcmToken: "cXYz123abc..."
```

### 2. Test Cloud Function

```bash
# Send test message in app
# Then check logs
firebase functions:log --only sendPushNotification

# Should see:
# "Sending push notification for chat chat123"
# "Push notification sent successfully: projects/.../messages/0:123"
```

### 3. Test Manual Notification

```bash
# Get FCM token from Firestore
# Send test notification via curl
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "DEVICE_FCM_TOKEN",
    "notification": {
      "title": "Test",
      "body": "Manual test notification"
    }
  }'
```

Get SERVER_KEY from:
Firebase Console > Project Settings > Cloud Messaging > Server key

---

## 🐛 Common Issues

### Issue 1: No notification received

**Checklist:**
- [ ] FCM token exists in Firestore?
- [ ] App has notification permission?
- [ ] Firebase Cloud Messaging API enabled in GCP?
- [ ] Device has internet connection?
- [ ] App is not in battery saver mode?

**Debug:**
```bash
# Check function logs
firebase functions:log --only sendPushNotification

# Check if token was sent
# Should see: "Push notification sent successfully"
```

### Issue 2: Token not saved to Firestore

**Cause:** User not authenticated when token requested

**Solution:**
```dart
// Refresh token after login
await notificationService.refreshAndSaveToken();
```

### Issue 3: Notification shows but tap doesn't open chat

**Cause:** Navigation not implemented

**Solution:** In your app router, handle pending navigation:
```dart
// After app initializes
final pendingChatId = notificationService.getPendingChatNavigation();
if (pendingChatId != null) {
  router.push('/chat/$pendingChatId');
}
```

---

## 📊 Cost

**FCM is 100% FREE!**
- Unlimited messages
- Unlimited devices
- No quota limits

Only Cloud Function invocations cost money:
- $0.40 per 1 million invocations
- First 2 million FREE per month

---

## 🔒 Security

### Why Cloud Function is Needed

**Can't send from client app because:**
1. ❌ FCM Server Key must stay secret
2. ❌ Client could send to ANY device
3. ❌ Client could spoof sender name
4. ❌ No validation of permissions

**Cloud Function solves this:**
1. ✅ Server key stays on server
2. ✅ Only sends to participants in chat
3. ✅ Gets real sender name from Firestore
4. ✅ Validates user is in chat

---

## 🎯 Summary

### What's Required

| Component | Location | Purpose |
|-----------|----------|---------|
| **FCM Token** | Generated by app | Device identifier |
| **Save Token** | App → Firestore | Make token accessible |
| **Cloud Function** | Firebase | Read token & send notification |
| **Handle Notification** | App | Show & navigate when tapped |

### The Flow

1. **App gets token** (on install/login)
2. **App saves token** to Firestore
3. **Message sent** triggers Cloud Function
4. **Function reads token** from Firestore
5. **Function sends** to FCM servers
6. **FCM delivers** to device
7. **App handles** notification

### Why Both Needed

- **App**: Generate & save token, handle incoming notifications
- **Cloud Function**: Read token, send notifications securely

**You CANNOT skip the app part!** Without the token in Firestore, Cloud Function has nothing to send to.

---

## 📚 Code Files

### Updated Files

1. **lib/services/notification_service.dart**
   - ✅ Get FCM token
   - ✅ Save to Firestore
   - ✅ Handle incoming notifications
   - ✅ Handle navigation

2. **lib/features/auth/presentation/providers/auth_provider.dart**
   - ✅ Save FCM token on login
   - ✅ Delete FCM token on logout

3. **functions/index.js**
   - ✅ sendPushNotification function
   - ✅ Read fcmToken from Firestore
   - ✅ Send via FCM

---

## 🚀 Quick Start

```bash
# 1. Deploy functions
firebase deploy --only functions

# 2. Run app
flutter run

# 3. Login on two devices
Device A: Login as User A
Device B: Login as User B

# 4. Check tokens saved
Firebase Console > Firestore > users
Both users should have fcmToken field

# 5. Send message
Device A: Send message to User B
Device B: Should receive push notification!

# 6. Verify in logs
firebase functions:log --only sendPushNotification
```

---

## ✅ Verification

Your setup is complete when:

- [x] User logs in → FCM token appears in Firestore
- [x] User sends message → Cloud Function triggers
- [x] Cloud Function → Finds recipient's FCM token
- [x] Cloud Function → Sends to FCM successfully
- [x] Recipient → Receives push notification
- [x] Tap notification → App opens to chat
- [x] User logs out → FCM token deleted

---

**Bottom Line:** You need BOTH the app-side setup (get & save token) AND the Cloud Function (read token & send notification). They work together!

---

*Document Version: 1.0*  
*Created: 2025-11-26*
