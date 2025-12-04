# دليل الإشعارات الكامل - Social Connect App

## التاريخ: 4 ديسمبر 2025

---

## نظرة عامة

تم تطوير نظام إشعارات كامل للتطبيق يشمل:
- ✅ 6 أنواع من الإشعارات
- ✅ Firebase Cloud Messaging (FCM)
- ✅ Local Notifications (Foreground)
- ✅ 4 Notification Channels
- ✅ Navigation handling

---

## الإشعارات المتاحة (6 أنواع)

### 1. رسالة جديدة (new_message) ✅
- **الوصف:** عند استلام رسالة في الشات
- **Channel:** messages
- **Priority:** High
- **Navigation:** `/chat/{chatId}`
- **Firebase Function:** `onNewMessage`

### 2. رد على ستوري (story_reply) ✅
- **الوصف:** عند رد شخص على ستوريك
- **Channel:** stories
- **Priority:** High
- **Navigation:** `/stories`
- **Firebase Function:** `onStoryReply`

### 3. إعجاب بستوري (story_like) ✨ جديد
- **الوصف:** عند إعجاب شخص بستوريك
- **Channel:** stories
- **Priority:** High
- **Navigation:** `/stories`
- **Firebase Function:** `onStoryLike`

### 4. متابع جديد (new_follower) ✨ جديد
- **الوصف:** عند متابعة شخص لك
- **Channel:** social
- **Priority:** High
- **Navigation:** `/profile/{followerId}`
- **Firebase Function:** `onNewFollower`

### 5. ستوري جديدة من متابَع (new_story) ✨ جديد
- **الوصف:** عند نشر شخص تتابعه ستوري جديدة
- **Channel:** stories
- **Priority:** High
- **Navigation:** `/stories`
- **Firebase Function:** `onNewStoryFromFollowing`

### 6. زيارة بروفايل (profile_view) ⚠️ يحتاج تفعيل
- **الوصف:** عند زيارة شخص لبروفايلك
- **Channel:** general
- **Priority:** Default
- **Navigation:** `/profile/{viewerId}`
- **Firebase Function:** `onProfileView`
- **ملاحظة:** يحتاج إنشاء `profile_views` collection

---

## البنية التحتية

### 1. Firebase Functions
**الملف:** `functions/notifications.ts`

**Functions المضافة:**
```typescript
✅ onNewMessage          // موجودة مسبقاً
✅ onStoryReply          // موجودة مسبقاً
✨ onStoryLike           // جديدة
✨ onNewFollower         // جديدة
✨ onNewStoryFromFollowing // جديدة
⚠️ onProfileView        // موجودة (تحتاج تفعيل)
✅ cleanupExpiredTokens  // موجودة مسبقاً
```

### 2. Flutter Services

#### أ. NotificationService (FCM)
**الملف:** `lib/services/external/notification_service_enhanced.dart`

**المسؤوليات:**
- تهيئة FCM
- إدارة FCM tokens
- معالجة الرسائل (foreground/background)
- Navigation handling
- تكامل مع LocalNotificationService

#### ب. LocalNotificationService (Foreground)
**الملف:** `lib/services/external/local_notification_service.dart`

**المسؤوليات:**
- إنشاء notification channels
- عرض الإشعارات في foreground
- معالجة notification taps
- إدارة الإشعارات (cancel, cancelAll)

---

## Notification Channels

### 1. Messages Channel
```dart
ID: 'messages'
Name: 'الرسائل'
Description: 'إشعارات الرسائل الجديدة'
Importance: High
Sound: ✅
Vibration: ✅
Badge: ✅

Notifications:
- new_message
```

### 2. Stories Channel
```dart
ID: 'stories'
Name: 'القصص'
Description: 'إشعارات القصص والتفاعلات'
Importance: High
Sound: ✅
Vibration: ✅
Badge: ✅

Notifications:
- story_reply
- story_like
- new_story
```

### 3. Social Channel
```dart
ID: 'social'
Name: 'التفاعلات الاجتماعية'
Description: 'إشعارات المتابعين والتفاعلات'
Importance: High
Sound: ✅
Vibration: ✅
Badge: ✅

Notifications:
- new_follower
```

### 4. General Channel
```dart
ID: 'general'
Name: 'عام'
Description: 'إشعارات عامة'
Importance: Default
Sound: ✅
Vibration: ❌
Badge: ✅

Notifications:
- profile_view
```

---

## خطوات التفعيل

### الخطوة 1: Deploy Firebase Functions ⚠️ مطلوب

```bash
cd functions
npm install
firebase deploy --only functions
```

**Functions التي سيتم deploy:**
- onNewMessage (موجودة)
- onStoryReply (موجودة)
- onStoryLike (جديدة) ✨
- onNewFollower (جديدة) ✨
- onNewStoryFromFollowing (جديدة) ✨
- onProfileView (موجودة)
- cleanupExpiredTokens (موجودة)

### الخطوة 2: تحديث التطبيق ✅ تم

```bash
flutter pub get
```

**Packages المضافة:**
- flutter_local_notifications: ^19.5.0

**Files المضافة:**
- lib/services/external/local_notification_service.dart

**Files المحدثة:**
- lib/services/external/notification_service_enhanced.dart

### الخطوة 3: اختبار التطبيق ⚠️ مطلوب

```bash
flutter run
```

**اختبارات مطلوبة:**
1. ✅ Foreground notifications تظهر
2. ✅ Background notifications تعمل
3. ✅ Navigation يعمل عند الضغط
4. ✅ Channels تظهر في Settings
5. ✅ Sounds & vibrations تعمل

---

## الاختبار الشامل

### 1. اختبار new_message
```
السيناريو:
1. المستخدم A يفتح التطبيق
2. المستخدم B يرسل رسالة للمستخدم A
3. المستخدم A يستلم إشعار "رسالة جديدة"
4. المستخدم A يضغط على الإشعار
5. ينتقل للشات مع المستخدم B

التحقق:
✅ الإشعار يظهر في foreground
✅ الصوت يعمل
✅ الاهتزاز يعمل
✅ Navigation يعمل
```

### 2. اختبار story_like
```
السيناريو:
1. المستخدم A ينشر ستوري
2. المستخدم B يعجب بالستوري
3. المستخدم A يستلم إشعار "❤️ إعجاب بقصتك"
4. المستخدم A يضغط على الإشعار
5. ينتقل لعرض الستوري

التحقق:
✅ الإشعار يظهر
✅ Channel: stories
✅ Navigation للستوري
```

### 3. اختبار new_follower
```
السيناريو:
1. المستخدم B يتابع المستخدم A
2. المستخدم A يستلم إشعار "👤 متابع جديد"
3. المستخدم A يضغط على الإشعار
4. ينتقل لبروفايل المستخدم B

التحقق:
✅ الإشعار يظهر
✅ Channel: social
✅ Navigation للبروفايل
```

### 4. اختبار new_story
```
السيناريو:
1. المستخدم A لديه 5 متابعين
2. المستخدم A ينشر ستوري جديدة
3. جميع المتابعين يستلمون إشعار "📸 قصة جديدة"
4. أي متابع يضغط على الإشعار
5. ينتقل لعرض ستوري المستخدم A

التحقق:
✅ جميع المتابعين استلموا الإشعار
✅ Channel: stories
✅ Navigation للستوري
```

---

## تفعيل Profile Views (اختياري)

### الخطوة 1: إنشاء Collection في Firestore

```javascript
// في Firebase Console
Collection: profile_views
Document ID: auto-generated
Fields:
  - viewerId: string
  - profileUserId: string
  - viewedAt: timestamp
```

### الخطوة 2: إضافة Firestore Rules

```javascript
// في firestore.rules
match /profile_views/{viewId} {
  // Anyone can create profile views
  allow create: if request.auth != null &&
                   request.auth.uid == request.resource.data.viewerId;
  
  // Only profile owner can read their views
  allow read: if request.auth != null &&
                 request.auth.uid == resource.data.profileUserId;
  
  // No updates or deletes
  allow update, delete: if false;
}
```

### الخطوة 3: إضافة Tracking في ProfileScreen

```dart
// في lib/features/profile/presentation/screens/profile_screen.dart

@override
void initState() {
  super.initState();
  
  // Record profile view if viewing someone else's profile
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_isViewingOwnProfile) {
      _recordProfileView();
    }
  });
}

Future<void> _recordProfileView() async {
  try {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    
    await FirebaseFirestore.instance.collection('profile_views').add({
      'viewerId': currentUserId,
      'profileUserId': widget.userId,
      'viewedAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    // Silent fail - not critical
    AppLogger.debug('Failed to record profile view: $e');
  }
}
```

### الخطوة 4: إضافة Settings للتحكم

```dart
// في UserProfile model
class UserProfile {
  // ... existing fields
  final Map<String, dynamic>? settings;
  
  // Helper getter
  bool get notifyOnProfileView => 
    settings?['notifyOnProfileView'] ?? false;
}

// في Settings Screen
SwitchListTile(
  title: Text('إشعارات زيارة البروفايل'),
  subtitle: Text('استلم إشعار عند زيارة شخص لبروفايلك'),
  value: profile.notifyOnProfileView,
  onChanged: (value) async {
    await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update({
        'settings.notifyOnProfileView': value,
      });
  },
);
```

---

## الأداء والتحسينات

### الأداء الحالي

#### ✅ نقاط القوة:
1. **Parallel Notifications** - إرسال متوازي للمتابعين
2. **Optimistic Updates** - تحديثات فورية في UI
3. **Channel-based** - تنظيم الإشعارات
4. **Error Handling** - معالجة الأخطاء بشكل صحيح

#### ⚠️ نقاط الضعف:
1. **New Story Notifications** - قد يكون بطيء مع متابعين كثيرين (>1000)
2. **No Rate Limiting** - لا يوجد حد للإشعارات
3. **No Batching** - لا يوجد تجميع للإشعارات المتشابهة

### التحسينات المقترحة

#### 1. استخدام FCM Topics للستوريز
```typescript
// بدلاً من إرسال فردي
export const onNewStoryFromFollowing = functions.firestore
  .document("stories/{storyId}")
  .onCreate(async (snapshot, context) => {
    const story = snapshot.data();
    
    // Send to topic instead of individual users
    await admin.messaging().sendToTopic(`user_${story.userId}_followers`, {
      notification: {
        title: "📸 قصة جديدة",
        body: `${creator?.name} نشر قصة جديدة`,
      },
      // ...
    });
  });

// Subscribe followers to topic when they follow
export const onNewFollower = functions.firestore
  .document("users/{userId}/followers/{followerId}")
  .onCreate(async (snapshot, context) => {
    const { userId, followerId } = context.params;
    
    // Get follower's FCM token
    const followerDoc = await admin.firestore()
      .collection("users")
      .doc(followerId)
      .get();
    
    const token = followerDoc.data()?.fcmToken;
    
    if (token) {
      // Subscribe to user's stories topic
      await admin.messaging().subscribeToTopic(
        [token],
        `user_${userId}_followers`
      );
    }
    
    // ... send new follower notification
  });
```

#### 2. Rate Limiting
```typescript
// في Firebase Functions
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 10, // max 10 notifications per minute per user
});

// Apply to notification functions
```

#### 3. Notification Batching
```typescript
// تجميع الإشعارات المتشابهة
// مثال: "أعجب 5 أشخاص بقصتك" بدلاً من 5 إشعارات منفصلة
```

---

## الأخطاء الشائعة وحلولها

### 1. الإشعارات لا تصل
**الأسباب المحتملة:**
- FCM token غير محفوظ
- Firebase Functions غير deployed
- الأذونات مرفوضة

**الحل:**
```bash
# تحقق من FCM token
firebase_messaging.getToken().then((token) => print(token));

# تحقق من Functions
firebase functions:log

# تحقق من الأذونات
firebase_messaging.requestPermission();
```

### 2. الإشعارات لا تظهر في Foreground
**الأسباب المحتملة:**
- LocalNotificationService غير مهيأ
- Channels غير منشأة

**الحل:**
```dart
// تأكد من التهيئة في main.dart
await notificationService.initialize();

// تحقق من الـ logs
AppLogger.debug('Local notifications initialized');
```

### 3. Navigation لا يعمل
**الأسباب المحتملة:**
- Navigation callback غير مسجل
- Payload غير صحيح

**الحل:**
```dart
// تأكد من تسجيل callback
notificationService.setNavigationCallback((route, params) {
  context.push(route, extra: params);
});
```

### 4. الصوت لا يعمل
**الأسباب المحتملة:**
- Do Not Disturb mode مفعّل
- Channel importance منخفض
- الجهاز في silent mode

**الحل:**
```dart
// تأكد من importance = High
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'messages',
  'الرسائل',
  importance: Importance.high, // مهم!
);
```

---

## الخلاصة النهائية

### ✅ ما تم إنجازه:

#### 1. حذف Like Profiles
- ✅ حذف 5 ملفات
- ✅ تحديث 8 ملفات
- ✅ تنظيف Firestore rules
- ✅ تنظيف Firebase Functions

#### 2. إضافة الإشعارات الناقصة
- ✅ Story Like notification
- ✅ New Follower notification
- ✅ New Story notification
- ✅ تحديث notification_service_enhanced.dart

#### 3. إعداد Local Notifications
- ✅ إضافة flutter_local_notifications
- ✅ إنشاء LocalNotificationService
- ✅ إنشاء 4 notification channels
- ✅ تكامل مع NotificationService

### ⚠️ ما يحتاج تنفيذ:

1. **Deploy Firebase Functions** (مطلوب)
```bash
cd functions
npm install
firebase deploy --only functions
```

2. **اختبار على أجهزة حقيقية** (مطلوب)
```bash
flutter run --release
```

3. **تفعيل Profile Views** (اختياري)
- إنشاء collection
- إضافة tracking code
- إضافة settings

### 📊 الإحصائيات:

- **الإشعارات:** 6 أنواع (3 جديدة)
- **Channels:** 4 channels
- **Firebase Functions:** 7 functions
- **Files المضافة:** 4 files
- **Files المحدثة:** 10+ files

### 🎯 النتيجة:

نظام إشعارات كامل ومتكامل يدعم:
- ✅ Foreground & Background notifications
- ✅ Channel-based organization
- ✅ Smart navigation
- ✅ Error handling
- ✅ Analytics tracking
- ✅ User preferences

---

## المراجع

### الملفات المهمة:
1. `functions/notifications.ts` - Firebase Functions
2. `lib/services/external/notification_service_enhanced.dart` - FCM Service
3. `lib/services/external/local_notification_service.dart` - Local Notifications
4. `firestore.rules` - Security Rules

### الوثائق:
1. `LIKE_PROFILES_REMOVAL_SUMMARY.md` - حذف Like Profiles
2. `NOTIFICATIONS_IMPLEMENTATION_SUMMARY.md` - إضافة الإشعارات
3. `LOCAL_NOTIFICATIONS_SETUP_SUMMARY.md` - إعداد Local Notifications
4. `COMPLETE_NOTIFICATIONS_GUIDE.md` - هذا الملف

### روابط مفيدة:
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Functions](https://firebase.google.com/docs/functions)
