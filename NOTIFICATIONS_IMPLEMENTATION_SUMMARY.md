# ملخص إضافة الإشعارات الناقصة

## التاريخ: 4 ديسمبر 2025

---

## الإشعارات المضافة

### 1. ✅ إعجاب بالستوري (Story Like)
**Firebase Function:** `onStoryLike`
- **Trigger:** `stories/{storyId}` - onUpdate
- **الوصف:** يرسل إشعار عند إعجاب شخص بستوريك
- **البيانات:**
  - `type: "story_like"`
  - `storyId`: معرف الستوري
  - `userId`: صاحب الستوري
  - `likerId`: الشخص الذي أعجب
- **الرسالة:** "❤️ إعجاب بقصتك - أعجب [الاسم] بقصتك"
- **Channel:** `stories`

**الآلية:**
- يراقب تحديثات `likedBy` array في الستوري
- يكتشف المستخدمين الجدد في القائمة
- يرسل إشعار للمستخدم الأول الجديد فقط (لتجنب spam)
- لا يرسل إشعار إذا أعجب الشخص بستوريه الخاص

---

### 2. ✅ متابع جديد (New Follower)
**Firebase Function:** `onNewFollower`
- **Trigger:** `users/{userId}/followers/{followerId}` - onCreate
- **الوصف:** يرسل إشعار عند متابعة شخص لك
- **البيانات:**
  - `type: "new_follower"`
  - `followerId`: المتابع الجديد
  - `userId`: الشخص الذي تمت متابعته
- **الرسالة:** "👤 متابع جديد - [الاسم] بدأ بمتابعتك"
- **Channel:** `social`

**الآلية:**
- يراقب إضافة مستندات جديدة في subcollection `followers`
- يرسل إشعار فوري عند المتابعة
- لا يرسل إشعار إذا تابع الشخص نفسه (حماية)

---

### 3. ✅ ستوري جديدة من متابَع (New Story from Following)
**Firebase Function:** `onNewStoryFromFollowing`
- **Trigger:** `stories/{storyId}` - onCreate
- **الوصف:** يرسل إشعار لجميع المتابعين عند نشر ستوري جديدة
- **البيانات:**
  - `type: "new_story"`
  - `storyId`: معرف الستوري
  - `userId`: صاحب الستوري
  - `creatorName`: اسم الناشر
- **الرسالة:** "📸 قصة جديدة - [الاسم] نشر قصة جديدة"
- **Channel:** `stories`

**الآلية:**
- يراقب إنشاء ستوريز جديدة
- يجلب جميع المتابعين من `users/{userId}/followers`
- يرسل إشعار لكل متابع لديه FCM token
- يستخدم `Promise.allSettled` لإرسال الإشعارات بشكل متوازي
- يسجل عدد الإشعارات الناجحة

---

### 4. ✅ زيارة البروفايل (Profile View) - موجودة مسبقاً
**Firebase Function:** `onProfileView`
- **Trigger:** `profile_views/{viewId}` - onCreate
- **الوصف:** يرسل إشعار عند زيارة شخص لبروفايلك (إذا مفعّل)
- **البيانات:**
  - `type: "profile_view"`
  - `viewerId`: الزائر
- **الرسالة:** "👀 زار ملفك الشخصي - [الاسم] شاهد ملفك الشخصي"
- **Channel:** `general`

**ملاحظة:** هذه الميزة تحتاج:
- إنشاء `profile_views` collection في Firestore
- إضافة كود في التطبيق لتسجيل الزيارات
- إعداد في البروفايل لتفعيل/تعطيل الإشعارات

---

## التحديثات في التطبيق

### 1. Notification Service Enhanced
**الملف:** `lib/services/external/notification_service_enhanced.dart`

**التحديثات:**
```dart
case 'story_like':
  // Navigate to story view
  _navigationCallback!('/stories', {...});
  break;

case 'new_story':
  // Navigate to story view
  _navigationCallback!('/stories', {...});
  break;
```

**الوظيفة:**
- معالجة الإشعارات الجديدة
- التنقل للستوري عند الضغط على الإشعار
- التنقل للبروفايل عند الضغط على إشعار متابع جديد

---

## الإشعارات الكاملة (بعد التحديث)

### ✅ الإشعارات الشغالة:
1. **رسالة جديدة** (new_message) - موجودة مسبقاً
2. **رد على ستوري** (story_reply) - موجودة مسبقاً
3. **إعجاب بستوري** (story_like) - ✨ جديدة
4. **متابع جديد** (new_follower) - ✨ جديدة
5. **ستوري جديدة من متابَع** (new_story) - ✨ جديدة
6. **زيارة بروفايل** (profile_view) - موجودة (تحتاج تفعيل)

---

## Notification Channels

### Android Channels:
```typescript
messages: {
  - new_message
}

stories: {
  - story_reply
  - story_like
  - new_story
}

social: {
  - new_follower
}

general: {
  - profile_view
}
```

---

## الخطوات المطلوبة للتفعيل

### 1. Deploy Firebase Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

### 2. إنشاء Notification Channels في التطبيق
يجب إضافة channels في Android:
```dart
// في main.dart أو notification_service.dart
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel messagesChannel = AndroidNotificationChannel(
  'messages',
  'Messages',
  description: 'Notifications for new messages',
  importance: Importance.high,
);

const AndroidNotificationChannel storiesChannel = AndroidNotificationChannel(
  'stories',
  'Stories',
  description: 'Notifications for story interactions',
  importance: Importance.high,
);

const AndroidNotificationChannel socialChannel = AndroidNotificationChannel(
  'social',
  'Social',
  description: 'Notifications for social interactions',
  importance: Importance.high,
);

const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
  'general',
  'General',
  description: 'General notifications',
  importance: Importance.defaultImportance,
);
```

### 3. إضافة flutter_local_notifications
```yaml
# في pubspec.yaml
dependencies:
  flutter_local_notifications: ^17.0.0
```

### 4. تفعيل Profile Views (اختياري)
إذا تبي تفعّل إشعارات زيارة البروفايل:

**أ. إنشاء collection في Firestore:**
```
/profile_views/{viewId}
  - viewerId: string
  - profileUserId: string
  - viewedAt: timestamp
```

**ب. إضافة كود في ProfileScreen:**
```dart
Future<void> _recordProfileView(String profileUserId) async {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null || currentUserId == profileUserId) return;
  
  await FirebaseFirestore.instance.collection('profile_views').add({
    'viewerId': currentUserId,
    'profileUserId': profileUserId,
    'viewedAt': FieldValue.serverTimestamp(),
  });
}
```

**ج. إضافة إعداد في Settings:**
```dart
// في user profile
settings: {
  notifyOnProfileView: true/false
}
```

---

## الأداء والتحسينات

### Story Like Notification:
- ✅ يستخدم `onUpdate` بدلاً من `onCreate` لمراقبة التغييرات
- ✅ يرسل إشعار واحد فقط للإعجاب الأول (يمنع spam)
- ✅ يتحقق من التغييرات في `likedBy` array

### New Follower Notification:
- ✅ يستخدم subcollection trigger للأداء الأفضل
- ✅ إشعار فوري عند المتابعة
- ✅ لا يحتاج query إضافية

### New Story Notification:
- ✅ يرسل الإشعارات بشكل متوازي (`Promise.allSettled`)
- ⚠️ قد يكون بطيء إذا كان عدد المتابعين كبير جداً (>1000)
- 💡 **تحسين مستقبلي:** استخدام FCM Topics للمتابعين الكثيرين

---

## الاختبار

### 1. اختبار Story Like:
```
1. المستخدم A ينشر ستوري
2. المستخدم B يعجب بالستوري
3. المستخدم A يستلم إشعار "❤️ إعجاب بقصتك"
```

### 2. اختبار New Follower:
```
1. المستخدم A موجود
2. المستخدم B يتابع المستخدم A
3. المستخدم A يستلم إشعار "👤 متابع جديد"
```

### 3. اختبار New Story:
```
1. المستخدم A لديه متابعين (B, C, D)
2. المستخدم A ينشر ستوري جديدة
3. جميع المتابعين (B, C, D) يستلمون إشعار "📸 قصة جديدة"
```

---

## الملاحظات المهمة

### ⚠️ Profile Views:
- هذه الميزة **غير مفعّلة** حالياً
- تحتاج إنشاء `profile_views` collection
- تحتاج إضافة كود لتسجيل الزيارات
- تحتاج إعداد في البروفايل للتحكم

### ⚠️ Local Notifications:
- حالياً الإشعارات تظهر فقط في background/terminated
- لعرضها في foreground، يجب إضافة `flutter_local_notifications`
- راجع TODO في `notification_service_enhanced.dart` السطر 123

### 💡 تحسينات مستقبلية:
1. استخدام FCM Topics للستوريز (بدلاً من إرسال فردي)
2. Batch notifications (تجميع الإشعارات المتشابهة)
3. Rate limiting (منع spam الإشعارات)
4. User preferences (السماح للمستخدم بتعطيل أنواع معينة)

---

## الخلاصة

✅ **تم إضافة 3 إشعارات جديدة:**
- Story Like
- New Follower  
- New Story from Following

✅ **الإشعارات الكاملة الآن: 6 أنواع**

⚠️ **يحتاج Deploy:**
- Firebase Functions
- Firestore Rules (إذا أضفت profile_views)

⚠️ **يحتاج تطوير في التطبيق:**
- flutter_local_notifications للـ foreground
- Notification channels setup
- Profile views tracking (اختياري)
