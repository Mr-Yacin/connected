# حالة إعدادات الإشعارات 📊

## التاريخ: 4 ديسمبر 2025

---

## ✅ ما تم إنجازه

### 1. البنية التحتية للإعدادات ✅
- [x] حقل `settings` في نموذج `UserProfile`
- [x] Getter `notifyOnProfileView` للوصول السريع
- [x] دعم JSON serialization كامل

### 2. الخدمات ✅
- [x] `UserDataService.updateNotificationSetting()` - تحديث Firestore
- [x] `SettingsNotifier.updateNotificationSetting()` - إدارة الحالة
- [x] معالجة الأخطاء الكاملة
- [x] التحقق من المستخدم الحالي

### 3. واجهة المستخدم ✅
- [x] قسم "الإشعارات" في شاشة الإعدادات
- [x] Switch للتحكم في إشعارات زيارة البروفايل
- [x] أيقونة العين (visibility_outlined)
- [x] عنوان ووصف واضح
- [x] رسائل تأكيد عند التحديث
- [x] رسائل خطأ واضحة
- [x] تصميم متناسق مع التطبيق

### 4. الأمان ✅
- [x] Firestore Rules تسمح بتحديث `settings`
- [x] التحقق من صلاحيات المستخدم
- [x] منع تعديل إعدادات الآخرين

### 5. الكود ✅
- [x] لا توجد أخطاء في getDiagnostics
- [x] الكود نظيف ومنظم
- [x] التعليقات واضحة
- [x] يتبع best practices

---

## ⚠️ ما هو مطلوب

### 1. ميزة تسجيل زيارات البروفايل ❌
**الحالة:** غير منفذة

**المطلوب:**
```dart
// في ProfileService أو ProfileRepository
Future<void> recordProfileView({
  required String viewerId,
  required String profileUserId,
}) async {
  // 1. تحقق من أن المستخدم لا يزور بروفايله الخاص
  if (viewerId == profileUserId) return;
  
  // 2. سجل الزيارة في Firestore
  await _firestore.collection('profile_views').add({
    'viewerId': viewerId,
    'profileUserId': profileUserId,
    'viewedAt': FieldValue.serverTimestamp(),
  });
  
  // 3. تحقق من إعدادات الإشعارات للمستخدم المزار
  final profileUser = await _firestore
      .collection('users')
      .doc(profileUserId)
      .get();
  
  final notifyOnProfileView = 
      profileUser.data()?['settings']?['notifyOnProfileView'] ?? false;
  
  // 4. إذا كانت الإشعارات مفعلة، أرسل إشعار
  if (notifyOnProfileView) {
    await sendProfileViewNotification(
      viewerId: viewerId,
      profileUserId: profileUserId,
    );
  }
}
```

**الاستخدام:**
```dart
// في ProfileScreen عند فتح البروفايل
@override
void initState() {
  super.initState();
  
  // سجل الزيارة
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId != null && currentUserId != widget.userId) {
    ref.read(profileServiceProvider).recordProfileView(
      viewerId: currentUserId,
      profileUserId: widget.userId,
    );
  }
}
```

### 2. إرسال الإشعارات ❌
**الحالة:** غير منفذة

**المطلوب:**
```dart
// في NotificationService
Future<void> sendProfileViewNotification({
  required String viewerId,
  required String profileUserId,
}) async {
  // 1. احصل على معلومات الزائر
  final viewer = await _firestore
      .collection('users')
      .doc(viewerId)
      .get();
  
  final viewerName = viewer.data()?['name'] ?? 'مستخدم';
  
  // 2. احصل على FCM token للمستخدم المزار
  final profileUser = await _firestore
      .collection('users')
      .doc(profileUserId)
      .get();
  
  final fcmToken = profileUser.data()?['fcmToken'];
  
  if (fcmToken == null) return;
  
  // 3. أرسل الإشعار عبر FCM
  await _messaging.send(
    token: fcmToken,
    notification: FCMNotification(
      title: 'زيارة جديدة',
      body: '$viewerName زار ملفك الشخصي',
    ),
    data: {
      'type': 'profile_view',
      'viewerId': viewerId,
      'profileUserId': profileUserId,
    },
  );
}
```

### 3. Firebase Cloud Messaging Setup ❌
**الحالة:** غير معروفة

**المطلوب:**
- تكوين FCM في Firebase Console
- إضافة google-services.json (Android)
- إضافة GoogleService-Info.plist (iOS)
- تكوين FCM في التطبيق
- حفظ FCM token في Firestore

### 4. Cloud Functions (اختياري) ⚠️
**الحالة:** غير منفذة

**المطلوب:**
```javascript
// في Firebase Cloud Functions
exports.onProfileView = functions.firestore
  .document('profile_views/{viewId}')
  .onCreate(async (snap, context) => {
    const view = snap.data();
    
    // احصل على إعدادات المستخدم
    const profileUser = await admin.firestore()
      .collection('users')
      .doc(view.profileUserId)
      .get();
    
    const notifyOnProfileView = 
      profileUser.data()?.settings?.notifyOnProfileView ?? false;
    
    if (!notifyOnProfileView) return;
    
    // احصل على FCM token
    const fcmToken = profileUser.data()?.fcmToken;
    if (!fcmToken) return;
    
    // احصل على اسم الزائر
    const viewer = await admin.firestore()
      .collection('users')
      .doc(view.viewerId)
      .get();
    
    const viewerName = viewer.data()?.name ?? 'مستخدم';
    
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

## 📋 خطة التنفيذ

### المرحلة 1: تسجيل الزيارات
1. إنشاء `ProfileViewService`
2. إضافة method `recordProfileView()`
3. استدعاء الـ method عند فتح البروفايل
4. اختبار تسجيل الزيارات في Firestore

### المرحلة 2: إعداد FCM
1. تكوين FCM في Firebase Console
2. إضافة ملفات التكوين للتطبيق
3. تهيئة FCM في التطبيق
4. حفظ FCM token عند تسجيل الدخول
5. اختبار استلام الإشعارات

### المرحلة 3: إرسال الإشعارات
1. إنشاء `NotificationService`
2. إضافة method `sendProfileViewNotification()`
3. ربط الـ method مع `recordProfileView()`
4. اختبار إرسال الإشعارات

### المرحلة 4: Cloud Functions (اختياري)
1. إنشاء Cloud Function لإرسال الإشعارات
2. Deploy الـ function
3. اختبار الـ function
4. مراقبة الـ logs

---

## 🎯 الخلاصة

### ✅ جاهز:
- إعدادات الإشعارات في UI
- حفظ الإعدادات في Firestore
- قراءة الإعدادات من Firestore
- معالجة الأخطاء

### ⚠️ مطلوب:
- تسجيل زيارات البروفايل
- إعداد FCM
- إرسال الإشعارات
- Cloud Functions (اختياري)

### 📊 نسبة الإنجاز:
- **البنية التحتية:** 100% ✅
- **واجهة المستخدم:** 100% ✅
- **الوظائف الأساسية:** 40% ⚠️
- **الإشعارات:** 0% ❌

---

## 💡 توصيات

### للتطوير السريع:
1. ابدأ بتسجيل الزيارات (سهل)
2. أضف FCM setup (متوسط)
3. أضف إرسال الإشعارات (متوسط)
4. أضف Cloud Functions لاحقاً (اختياري)

### للإنتاج:
1. استخدم Cloud Functions لإرسال الإشعارات
2. أضف rate limiting لمنع spam
3. أضف caching للإعدادات
4. أضف analytics لتتبع الاستخدام

### للأمان:
1. تحقق من الصلاحيات في كل خطوة
2. استخدم Firestore Rules بشكل صحيح
3. لا تكشف FCM tokens
4. استخدم HTTPS فقط

---

## 📝 ملاحظات

### الإيجابيات:
- البنية التحتية قوية ✅
- الكود نظيف ومنظم ✅
- معالجة الأخطاء شاملة ✅
- التصميم جميل ✅

### التحديات:
- تسجيل الزيارات غير منفذ ⚠️
- FCM غير مكون ⚠️
- الإشعارات غير مرسلة ⚠️

### الفرص:
- يمكن إضافة إعدادات إشعارات أخرى بسهولة
- البنية قابلة للتوسع
- الكود قابل للصيانة

---

## 🔗 روابط مفيدة

### Firebase:
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Cloud Functions](https://firebase.google.com/docs/functions)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

### Flutter:
- [firebase_messaging package](https://pub.dev/packages/firebase_messaging)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

---

## ✅ الخطوة التالية

**الأولوية الأولى:** تنفيذ تسجيل زيارات البروفايل

```dart
// 1. إنشاء ProfileViewService
// 2. إضافة recordProfileView()
// 3. استدعاء الـ method في ProfileScreen
// 4. اختبار التسجيل في Firestore
```

بعد ذلك، يمكن إضافة FCM وإرسال الإشعارات.
