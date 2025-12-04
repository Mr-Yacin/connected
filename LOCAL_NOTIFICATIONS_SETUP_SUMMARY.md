# ملخص إعداد Local Notifications (Foreground Notifications)

## التاريخ: 4 ديسمبر 2025

---

## المشكلة
الإشعارات كانت تظهر فقط عندما التطبيق في background أو terminated. عند فتح التطبيق (foreground)، الإشعارات لا تظهر.

## الحل
إضافة `flutter_local_notifications` لعرض الإشعارات في foreground.

---

## التغييرات المنفذة

### 1. ✅ إضافة Package
```yaml
# pubspec.yaml
dependencies:
  flutter_local_notifications: ^19.5.0
```

**الحزم المضافة:**
- `flutter_local_notifications: ^19.5.0`
- `flutter_local_notifications_linux: ^6.0.0`
- `flutter_local_notifications_platform_interface: ^9.1.0`
- `flutter_local_notifications_windows: ^1.0.3`
- `timezone: ^0.10.1`

---

### 2. ✅ إنشاء Local Notification Service
**الملف:** `lib/services/external/local_notification_service.dart`

**الميزات:**
- ✅ تهيئة plugin مع Android و iOS settings
- ✅ إنشاء 4 notification channels:
  - `messages` - للرسائل (high priority)
  - `stories` - للستوريز (high priority)
  - `social` - للتفاعلات الاجتماعية (high priority)
  - `general` - للإشعارات العامة (default priority)
- ✅ عرض الإشعارات مع BigTextStyle
- ✅ معالجة notification taps
- ✅ إلغاء الإشعارات

**الـ Channels:**
```dart
messages: {
  name: 'الرسائل',
  description: 'إشعارات الرسائل الجديدة',
  importance: High,
  sound: ✅,
  vibration: ✅,
  badge: ✅
}

stories: {
  name: 'القصص',
  description: 'إشعارات القصص والتفاعلات',
  importance: High,
  sound: ✅,
  vibration: ✅,
  badge: ✅
}

social: {
  name: 'التفاعلات الاجتماعية',
  description: 'إشعارات المتابعين والتفاعلات',
  importance: High,
  sound: ✅,
  vibration: ✅,
  badge: ✅
}

general: {
  name: 'عام',
  description: 'إشعارات عامة',
  importance: Default,
  sound: ✅,
  vibration: ❌,
  badge: ✅
}
```

---

### 3. ✅ تحديث Notification Service Enhanced
**الملف:** `lib/services/external/notification_service_enhanced.dart`

**التحديثات:**

#### أ. إضافة LocalNotificationService
```dart
class NotificationService {
  final LocalNotificationService? _localNotificationService;
  
  NotificationService({
    LocalNotificationService? localNotificationService,
  }) : _localNotificationService = localNotificationService;
}
```

#### ب. تهيئة Local Notifications
```dart
Future<void> initialize() async {
  // Initialize local notifications first
  if (_localNotificationService != null) {
    await _localNotificationService!.initialize();
  }
  // ... rest of initialization
}
```

#### ج. عرض الإشعارات في Foreground
```dart
void _handleForegroundMessage(RemoteMessage message) {
  final notification = message.notification;
  if (notification != null && _localNotificationService != null) {
    final channelId = _getChannelIdForType(message.data['type']);
    
    _localNotificationService!.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: notification.title ?? 'إشعار جديد',
      body: notification.body ?? '',
      channelId: channelId,
    );
  }
}
```

#### د. تحديد Channel حسب نوع الإشعار
```dart
String _getChannelIdForType(String type) {
  switch (type) {
    case 'new_message':
      return 'messages';
    case 'story_reply':
    case 'story_like':
    case 'new_story':
      return 'stories';
    case 'new_follower':
      return 'social';
    case 'profile_view':
    default:
      return 'general';
  }
}
```

#### هـ. تحديث Provider
```dart
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final localNotificationService = ref.watch(localNotificationServiceProvider);
  return NotificationService(
    localNotificationService: localNotificationService,
  );
});
```

---

## كيف يعمل النظام

### 1. عند تشغيل التطبيق:
```
1. NotificationService.initialize() يُستدعى
2. LocalNotificationService.initialize() يُستدعى أولاً
3. يتم إنشاء 4 notification channels في Android
4. يتم تهيئة FCM وطلب الأذونات
5. يتم الاستماع للرسائل
```

### 2. عند استلام إشعار (Foreground):
```
1. FCM يستلم RemoteMessage
2. _handleForegroundMessage() يُستدعى
3. يتم تحديد channel حسب نوع الإشعار
4. LocalNotificationService.showNotification() يُستدعى
5. الإشعار يظهر في notification bar
```

### 3. عند الضغط على الإشعار:
```
1. _onNotificationTapped() يُستدعى
2. payload يُمرر للـ navigation callback
3. المستخدم ينتقل للشاشة المناسبة
```

---

## Notification Mapping

| نوع الإشعار | Channel | Priority | Sound | Vibration |
|-------------|---------|----------|-------|-----------|
| new_message | messages | High | ✅ | ✅ |
| story_reply | stories | High | ✅ | ✅ |
| story_like | stories | High | ✅ | ✅ |
| new_story | stories | High | ✅ | ✅ |
| new_follower | social | High | ✅ | ✅ |
| profile_view | general | Default | ✅ | ❌ |

---

## الأذونات المطلوبة

### Android (AndroidManifest.xml)
```xml
<!-- Already included by flutter_local_notifications -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
```

### iOS (Info.plist)
```xml
<!-- Already handled by firebase_messaging -->
```

---

## الاختبار

### 1. اختبار Foreground Notification:
```
1. افتح التطبيق
2. اطلب من مستخدم آخر إرسال رسالة
3. يجب أن يظهر إشعار في notification bar
4. اضغط على الإشعار
5. يجب أن ينتقل للشات
```

### 2. اختبار Channels:
```
1. افتح Settings > Apps > [App Name] > Notifications
2. يجب أن تشاهد 4 channels:
   - الرسائل
   - القصص
   - التفاعلات الاجتماعية
   - عام
3. كل channel يمكن تعطيله/تفعيله بشكل منفصل
```

### 3. اختبار أنواع الإشعارات:
```
✅ new_message → messages channel
✅ story_reply → stories channel
✅ story_like → stories channel
✅ new_story → stories channel
✅ new_follower → social channel
✅ profile_view → general channel
```

---

## الميزات

### ✅ المزايا:
1. **Foreground Notifications** - الإشعارات تظهر حتى لو التطبيق مفتوح
2. **Organized Channels** - المستخدم يقدر يتحكم في كل نوع
3. **BigTextStyle** - النصوص الطويلة تظهر كاملة
4. **Priority Management** - الإشعارات المهمة لها أولوية عالية
5. **Sound & Vibration** - تنبيهات صوتية وحسية
6. **Badge Count** - عداد الإشعارات على الأيقونة

### ⚠️ الملاحظات:
1. **iOS Permissions** - يجب طلب الأذونات من المستخدم
2. **Android 13+** - يحتاج POST_NOTIFICATIONS permission
3. **Channel Settings** - المستخدم يقدر يعطل channels معينة
4. **Background** - الإشعارات في background تُعرض بواسطة FCM مباشرة

---

## التحسينات المستقبلية

### 💡 اقتراحات:
1. **Notification Actions** - إضافة أزرار (Reply, Mark as Read)
2. **Grouped Notifications** - تجميع الإشعارات المتشابهة
3. **Custom Sounds** - أصوات مخصصة لكل channel
4. **Notification Images** - عرض صور في الإشعارات
5. **Scheduled Notifications** - إشعارات مجدولة
6. **Notification History** - سجل الإشعارات في التطبيق

---

## الأخطاء الشائعة وحلولها

### 1. الإشعارات لا تظهر في Foreground
**الحل:**
- تأكد من تهيئة LocalNotificationService
- تأكد من إنشاء الـ channels
- تحقق من الأذونات

### 2. Channel لا يظهر في Settings
**الحل:**
- امسح بيانات التطبيق
- أعد تثبيت التطبيق
- تأكد من استدعاء createNotificationChannel

### 3. الصوت لا يعمل
**الحل:**
- تحقق من إعدادات الجهاز
- تأكد من channel importance = High
- تحقق من Do Not Disturb mode

### 4. الإشعار لا يفتح الشاشة الصحيحة
**الحل:**
- تأكد من payload صحيح
- تحقق من navigation callback
- راجع _processNotificationNavigation

---

## الخلاصة

✅ **تم إضافة:**
- Local Notification Service
- 4 Notification Channels
- Foreground notification handling
- Channel-based routing

✅ **النتيجة:**
- الإشعارات تظهر في foreground
- المستخدم يقدر يتحكم في الإشعارات
- تجربة مستخدم أفضل

⚠️ **يحتاج:**
- اختبار على أجهزة حقيقية
- تحسين notification actions (مستقبلاً)
- إضافة notification history (مستقبلاً)
