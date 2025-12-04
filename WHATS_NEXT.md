# ما التالي؟ 🚀

## التاريخ: 4 ديسمبر 2025

---

## ✅ ما تم إنجازه

### 1. إعدادات الإشعارات في UI ✅
- ✅ قسم "الإشعارات" في شاشة الإعدادات
- ✅ Switch للتحكم في إشعارات زيارة البروفايل
- ✅ حفظ الإعدادات في Firestore
- ✅ معالجة الأخطاء
- ✅ رسائل التأكيد
- ✅ لا crashes
- ✅ كود نظيف واحترافي

### 2. البنية التحتية ✅
- ✅ نموذج UserProfile مع حقل settings
- ✅ UserDataService.updateNotificationSetting()
- ✅ SettingsNotifier.updateNotificationSetting()
- ✅ Firestore Rules تسمح بالتحديث
- ✅ StateProvider للحالة المحلية

---

## ⚠️ ما هو مطلوب للعمل الكامل

### المرحلة 1: تسجيل زيارات البروفايل 🎯

**الأولوية:** عالية جداً

**المطلوب:**
1. إنشاء service لتسجيل الزيارات
2. استدعاء الـ service عند فتح البروفايل
3. حفظ الزيارات في Firestore collection `profile_views`

**الكود المطلوب:**

```dart
// 1. في lib/services/profile_view_service.dart
class ProfileViewService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> recordProfileView(String profileUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid == profileUserId) {
      return; // لا تسجل زيارة المستخدم لنفسه
    }

    // سجل الزيارة
    await _firestore.collection('profile_views').add({
      'viewerId': currentUser.uid,
      'profileUserId': profileUserId,
      'viewedAt': FieldValue.serverTimestamp(),
    });

    // تحقق من إعدادات الإشعارات
    final profileDoc = await _firestore
        .collection('users')
        .doc(profileUserId)
        .get();
    
    final notifyOnProfileView = 
        profileDoc.data()?['settings']?['notifyOnProfileView'] ?? false;

    // إذا كانت الإشعارات مفعلة، أرسل إشعار
    if (notifyOnProfileView) {
      await _sendProfileViewNotification(
        viewerId: currentUser.uid,
        profileUserId: profileUserId,
      );
    }
  }

  Future<void> _sendProfileViewNotification({
    required String viewerId,
    required String profileUserId,
  }) async {
    // سيتم تنفيذه في المرحلة 2
    print('TODO: Send notification to $profileUserId about view from $viewerId');
  }
}

// 2. في ProfileScreen
@override
void initState() {
  super.initState();
  
  // سجل الزيارة
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null && currentUserId != widget.userId) {
      ref.read(profileViewServiceProvider).recordProfileView(widget.userId);
    }
  });
}
```

**الخطوات:**
1. أنشئ `lib/services/profile_view_service.dart`
2. أضف provider في `lib/services/providers.dart`
3. استدعِ الـ service في `ProfileScreen`
4. اختبر تسجيل الزيارات في Firestore

---

### المرحلة 2: Firebase Cloud Messaging (FCM) 📱

**الأولوية:** عالية

**المطلوب:**
1. إعداد FCM في Firebase Console
2. إضافة ملفات التكوين للتطبيق
3. حفظ FCM token عند تسجيل الدخول
4. تحديث FCM token عند التغيير

**الخطوات:**

#### 1. إعداد Firebase Console
```
1. اذهب إلى Firebase Console
2. اختر مشروعك
3. اذهب إلى Project Settings
4. اذهب إلى Cloud Messaging
5. فعّل Cloud Messaging API
```

#### 2. إضافة ملفات التكوين

**Android:**
- تأكد من وجود `google-services.json` في `android/app/`
- أضف في `android/app/build.gradle`:
```gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

**iOS:**
- تأكد من وجود `GoogleService-Info.plist` في `ios/Runner/`
- أضف capabilities في Xcode

#### 3. إضافة Package
```yaml
# pubspec.yaml
dependencies:
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
```

#### 4. إنشاء NotificationService
```dart
// lib/services/notification_service.dart
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // طلب الأذونات
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // احصل على FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveFCMToken(token);
    }

    // استمع للتحديثات
    _messaging.onTokenRefresh.listen(_saveFCMToken);
  }

  Future<void> _saveFCMToken(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
```

#### 5. استدعاء في main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(MyApp());
}
```

---

### المرحلة 3: إرسال الإشعارات 📨

**الأولوية:** متوسطة

**الخيار 1: من التطبيق مباشرة (بسيط)**

```dart
// في ProfileViewService
Future<void> _sendProfileViewNotification({
  required String viewerId,
  required String profileUserId,
}) async {
  // احصل على معلومات الزائر
  final viewerDoc = await _firestore
      .collection('users')
      .doc(viewerId)
      .get();
  final viewerName = viewerDoc.data()?['name'] ?? 'مستخدم';

  // احصل على FCM token للمستخدم المزار
  final profileDoc = await _firestore
      .collection('users')
      .doc(profileUserId)
      .get();
  final fcmToken = profileDoc.data()?['fcmToken'];

  if (fcmToken == null) return;

  // أرسل الإشعار عبر HTTP
  // ملاحظة: يحتاج Server Key من Firebase Console
  final response = await http.post(
    Uri.parse('https://fcm.googleapis.com/fcm/send'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'key=YOUR_SERVER_KEY', // من Firebase Console
    },
    body: jsonEncode({
      'to': fcmToken,
      'notification': {
        'title': 'زيارة جديدة',
        'body': '$viewerName زار ملفك الشخصي',
      },
      'data': {
        'type': 'profile_view',
        'viewerId': viewerId,
        'profileUserId': profileUserId,
      },
    }),
  );
}
```

**الخيار 2: Cloud Functions (احترافي)**

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.onProfileView = functions.firestore
  .document('profile_views/{viewId}')
  .onCreate(async (snap, context) => {
    const view = snap.data();
    
    // احصل على إعدادات المستخدم
    const profileDoc = await admin.firestore()
      .collection('users')
      .doc(view.profileUserId)
      .get();
    
    const notifyOnProfileView = 
      profileDoc.data()?.settings?.notifyOnProfileView ?? false;
    
    if (!notifyOnProfileView) return;
    
    // احصل على FCM token
    const fcmToken = profileDoc.data()?.fcmToken;
    if (!fcmToken) return;
    
    // احصل على اسم الزائر
    const viewerDoc = await admin.firestore()
      .collection('users')
      .doc(view.viewerId)
      .get();
    
    const viewerName = viewerDoc.data()?.name ?? 'مستخدم';
    
    // أرسل الإشعار
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'زيارة جديدة',
        body: `${viewerName} زار ملفك الشخصي`,
      },
      data: {
        type: 'profile_view',
        viewerId: view.viewerId,
        profileUserId: view.profileUserId,
      },
    });
  });
```

---

## 📋 خطة العمل الموصى بها

### الأسبوع 1: تسجيل الزيارات
- [ ] يوم 1-2: إنشاء ProfileViewService
- [ ] يوم 3: دمج مع ProfileScreen
- [ ] يوم 4-5: اختبار وتصحيح الأخطاء

### الأسبوع 2: FCM Setup
- [ ] يوم 1-2: إعداد Firebase Console
- [ ] يوم 3: إضافة packages وملفات التكوين
- [ ] يوم 4: إنشاء NotificationService
- [ ] يوم 5: اختبار FCM tokens

### الأسبوع 3: إرسال الإشعارات
- [ ] يوم 1-3: تنفيذ إرسال الإشعارات
- [ ] يوم 4-5: اختبار شامل

---

## 🎯 الأولويات

### عالية جداً (افعلها الآن!)
1. ✅ إعدادات الإشعارات في UI - **مكتمل**
2. ⚠️ تسجيل زيارات البروفايل - **التالي**

### عالية (قريباً)
3. ⚠️ إعداد FCM
4. ⚠️ حفظ FCM tokens

### متوسطة (لاحقاً)
5. ⚠️ إرسال الإشعارات
6. ⚠️ معالجة الإشعارات عند الاستلام

### منخفضة (اختياري)
7. ⚠️ إشعارات أخرى (رسائل، متابعة، إلخ)
8. ⚠️ إعدادات إشعارات متقدمة

---

## 💡 نصائح مهمة

### 1. ابدأ بسيط
- نفذ تسجيل الزيارات أولاً
- اختبر في Firestore
- ثم أضف الإشعارات

### 2. اختبر كل مرحلة
- لا تنتقل للمرحلة التالية قبل اختبار الحالية
- استخدم Firebase Console للتحقق
- اختبر على أجهزة حقيقية

### 3. استخدم Cloud Functions
- أكثر أماناً
- أسهل للصيانة
- لا تكشف Server Keys

### 4. معالجة الأخطاء
- دائماً أضف try-catch
- سجل الأخطاء في Crashlytics
- أظهر رسائل واضحة للمستخدم

---

## 📚 موارد مفيدة

### Firebase Documentation
- [FCM Setup](https://firebase.google.com/docs/cloud-messaging/flutter/client)
- [Cloud Functions](https://firebase.google.com/docs/functions)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

### Flutter Packages
- [firebase_messaging](https://pub.dev/packages/firebase_messaging)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

### Tutorials
- [FCM with Flutter](https://www.youtube.com/watch?v=k0zGEbiDJcQ)
- [Cloud Functions Tutorial](https://www.youtube.com/watch?v=DYfP-UIKxH0)

---

## 🎉 الخلاصة

### ✅ أنجزنا:
- إعدادات الإشعارات في UI
- حفظ الإعدادات في Firestore
- كود نظيف واحترافي
- لا crashes

### 🎯 التالي:
1. **تسجيل زيارات البروفايل** (ابدأ هنا!)
2. إعداد FCM
3. إرسال الإشعارات

### 💪 أنت جاهز!
لديك الآن أساس قوي. ابدأ بتسجيل الزيارات، وسيكون باقي العمل سهلاً!

---

## 🚀 ابدأ الآن!

**الخطوة الأولى:**
```bash
# أنشئ ملف جديد
touch lib/services/profile_view_service.dart
```

**ثم اتبع الكود في "المرحلة 1" أعلاه!**

حظاً موفقاً! 🎯
