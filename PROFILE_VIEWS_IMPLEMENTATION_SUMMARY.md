# ملخص تفعيل Profile Views

## التاريخ: 4 ديسمبر 2025

---

## نظرة عامة

تم تفعيل ميزة تتبع زيارات البروفايل مع إشعارات اختيارية. المستخدم يقدر يشوف مين زار بروفايله ويتحكم في استلام الإشعارات.

---

## التغييرات المنفذة

### 1. ✅ Firestore Rules
**الملف:** `firestore.rules`

**Rules المضافة:**
```javascript
// Profile Views collection
match /profile_views/{viewId} {
  // Only profile owner can read their views
  allow read: if request.auth != null && 
                 request.auth.uid == resource.data.profileUserId;
  
  // Anyone authenticated can create profile views
  allow create: if request.auth != null && 
                   request.auth.uid == request.resource.data.viewerId &&
                   // Prevent viewing own profile
                   request.resource.data.viewerId != request.resource.data.profileUserId &&
                   request.resource.data.keys().hasAll(['viewerId', 'profileUserId', 'viewedAt']);
  
  // Profile views cannot be updated or deleted
  allow update, delete: if false;
}
```

**الحماية:**
- ✅ فقط صاحب البروفايل يقدر يقرأ زياراته
- ✅ أي مستخدم يقدر يسجل زيارة
- ✅ منع تسجيل زيارة للبروفايل الخاص
- ✅ منع التعديل أو الحذف

---

### 2. ✅ Profile View Service
**الملف:** `lib/services/analytics/profile_view_service.dart`

**الميزات:**
```dart
class ProfileViewService {
  // Record a profile view
  Future<void> recordProfileView(String profileUserId);
  
  // Get profile views for a user
  Future<List<String>> getProfileViews(String userId);
  
  // Get profile view count
  Future<int> getProfileViewCount(String userId);
  
  // Clear cache
  void clearCache();
}
```

**الآلية:**
1. **Session Cache** - يمنع تسجيل زيارات مكررة في نفس الجلسة
2. **Auto-skip Own Profile** - لا يسجل زيارة للبروفايل الخاص
3. **Silent Fail** - الأخطاء لا توقف التطبيق
4. **Firestore Trigger** - يشغل Firebase Function تلقائياً

---

### 3. ✅ UserProfile Model Update
**الملف:** `lib/core/models/user_profile.dart`

**التحديثات:**
```dart
class UserProfile {
  // ... existing fields
  final Map<String, dynamic>? settings;
  
  // Helper getter
  bool get notifyOnProfileView => settings?['notifyOnProfileView'] ?? false;
}
```

**Settings Structure:**
```dart
{
  'notifyOnProfileView': true/false,  // تفعيل/تعطيل الإشعارات
  // يمكن إضافة إعدادات أخرى مستقبلاً
}
```

---

### 4. ✅ Firebase Function
**الملف:** `functions/notifications.ts`

**Function موجودة مسبقاً:**
```typescript
export const onProfileView = functions.firestore
  .document("profile_views/{viewId}")
  .onCreate(async (snapshot, context) => {
    // Check if notifications enabled
    if (!owner?.settings?.notifyOnProfileView) {
      return null;
    }
    
    // Send notification
    await admin.messaging().send({
      token: owner.fcmToken,
      notification: {
        title: "👀 زار ملفك الشخصي",
        body: `${viewer?.name} شاهد ملفك الشخصي`,
      },
      // ...
    });
  });
```

---

## كيفية الاستخدام

### 1. تسجيل زيارة البروفايل

**في ProfileScreen:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/analytics/profile_view_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  
  @override
  void initState() {
    super.initState();
    
    // Record profile view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null && currentUserId != widget.userId) {
        ref.read(profileViewServiceProvider).recordProfileView(widget.userId);
      }
    });
  }
}
```

**ملاحظات:**
- ✅ يتم التسجيل تلقائياً عند زيارة البروفايل
- ✅ لا يسجل إذا كان البروفايل الخاص
- ✅ لا يسجل مرتين في نفس الجلسة

---

### 2. عرض عدد الزيارات

**في ProfileScreen:**
```dart
FutureBuilder<int>(
  future: ref.read(profileViewServiceProvider).getProfileViewCount(userId),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return SizedBox();
    
    return Row(
      children: [
        Icon(Icons.visibility, size: 20),
        SizedBox(width: 4),
        Text('${snapshot.data} زيارة'),
      ],
    );
  },
)
```

---

### 3. عرض قائمة الزوار

**شاشة جديدة (اختياري):**
```dart
class ProfileViewersScreen extends ConsumerWidget {
  final String userId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<String>>(
      future: ref.read(profileViewServiceProvider).getProfileViews(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        
        final viewerIds = snapshot.data!;
        
        return ListView.builder(
          itemCount: viewerIds.length,
          itemBuilder: (context, index) {
            return UserListTile(userId: viewerIds[index]);
          },
        );
      },
    );
  }
}
```

---

### 4. إعدادات الإشعارات

**في SettingsScreen:**
```dart
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
    
    // Update local state
    setState(() {
      profile = profile.copyWith(
        settings: {...?profile.settings, 'notifyOnProfileView': value},
      );
    });
  },
)
```

---

## Firestore Structure

### Collection: profile_views
```javascript
{
  viewerId: "user123",           // المستخدم الذي زار
  profileUserId: "user456",      // صاحب البروفايل
  viewedAt: Timestamp            // وقت الزيارة
}
```

### Collection: users (settings field)
```javascript
{
  // ... existing fields
  settings: {
    notifyOnProfileView: true,   // تفعيل الإشعارات
    // يمكن إضافة إعدادات أخرى
  }
}
```

---

## الأداء والتحسينات

### ✅ نقاط القوة:
1. **Session Cache** - يمنع duplicate writes
2. **Silent Fail** - لا يؤثر على تجربة المستخدم
3. **Indexed Queries** - سريعة وفعالة
4. **Optional Notifications** - المستخدم يتحكم

### ⚠️ نقاط الضعف:
1. **No Deduplication** - قد يسجل نفس الزائر عدة مرات (في جلسات مختلفة)
2. **No Expiry** - البيانات تبقى للأبد
3. **No Pagination** - قد يكون بطيء مع زيارات كثيرة

### 💡 تحسينات مستقبلية:

#### 1. Deduplication (منع التكرار)
```dart
// تسجيل زيارة واحدة فقط كل 24 ساعة
Future<void> recordProfileView(String profileUserId) async {
  final cacheKey = '${viewerId}_$profileUserId';
  
  // Check last view time
  final lastView = await _getLastViewTime(cacheKey);
  if (lastView != null && 
      DateTime.now().difference(lastView).inHours < 24) {
    return; // Skip - already viewed today
  }
  
  // Record view
  await _firestore.collection('profile_views').add({...});
  
  // Update cache
  await _saveLastViewTime(cacheKey, DateTime.now());
}
```

#### 2. Data Expiry (حذف البيانات القديمة)
```typescript
// Firebase Function - تشغيل يومي
export const cleanupOldProfileViews = functions.pubsub
  .schedule('0 0 * * *')
  .onRun(async () => {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 30); // 30 days ago
    
    const oldViews = await admin.firestore()
      .collection('profile_views')
      .where('viewedAt', '<', cutoffDate)
      .get();
    
    const batch = admin.firestore().batch();
    oldViews.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  });
```

#### 3. Pagination (تقسيم النتائج)
```dart
Future<List<String>> getProfileViews(
  String userId, {
  int limit = 20,
  DocumentSnapshot? startAfter,
}) async {
  var query = _firestore
      .collection('profile_views')
      .where('profileUserId', isEqualTo: userId)
      .orderBy('viewedAt', descending: true)
      .limit(limit);
  
  if (startAfter != null) {
    query = query.startAfterDocument(startAfter);
  }
  
  final snapshot = await query.get();
  return snapshot.docs.map((doc) => doc.data()['viewerId']).toList();
}
```

---

## الاختبار

### 1. اختبار تسجيل الزيارة
```
السيناريو:
1. المستخدم A يفتح بروفايل المستخدم B
2. يتم تسجيل زيارة في profile_views
3. المستخدم B يستلم إشعار (إذا مفعّل)

التحقق:
✅ Document موجود في profile_views
✅ viewerId = A
✅ profileUserId = B
✅ viewedAt = الآن
```

### 2. اختبار منع الزيارة المكررة
```
السيناريو:
1. المستخدم A يفتح بروفايل المستخدم B
2. المستخدم A يغلق ويفتح البروفايل مرة ثانية
3. لا يتم تسجيل زيارة ثانية

التحقق:
✅ فقط document واحد في profile_views
✅ لا يوجد إشعار ثاني
```

### 3. اختبار الإعدادات
```
السيناريو:
1. المستخدم B يعطّل إشعارات الزيارة
2. المستخدم A يزور بروفايل المستخدم B
3. يتم تسجيل الزيارة لكن بدون إشعار

التحقق:
✅ Document موجود في profile_views
✅ لا يوجد إشعار
```

---

## الخطوات المتبقية

### 1. ⚠️ Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### 2. ⚠️ Deploy Firebase Functions
```bash
cd functions
firebase deploy --only functions
```

### 3. ⚠️ إضافة UI في ProfileScreen
- عرض عدد الزيارات
- زر لعرض قائمة الزوار
- إضافة في SettingsScreen

### 4. ⚠️ اختبار على أجهزة حقيقية
- تسجيل الزيارات
- الإشعارات
- الإعدادات

---

## الخلاصة

✅ **تم إنجازه:**
- Firestore Rules للـ profile_views
- ProfileViewService كامل
- UserProfile model محدث
- Firebase Function موجودة مسبقاً

⚠️ **يحتاج تنفيذ:**
- Deploy Firestore Rules
- Deploy Firebase Functions
- إضافة UI في التطبيق
- اختبار شامل

💡 **الميزة:**
- اختيارية تماماً
- لا تؤثر على الأداء
- المستخدم يتحكم بالكامل
- سهلة التوسع مستقبلاً
