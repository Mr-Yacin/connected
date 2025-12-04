# منع الزيارات المكررة ✅

## التاريخ: 4 ديسمبر 2025

---

## 🎯 المشكلة

بدون فحص الزيارات المكررة:
- ❌ كل مرة يفتح المستخدم البروفايل، تُسجل زيارة جديدة
- ❌ إذا فتح البروفايل 10 مرات في دقيقة، تُسجل 10 زيارات
- ❌ إشعارات spam للمستخدم المزار
- ❌ بيانات غير دقيقة

---

## ✅ الحل

### منع الزيارات المكررة خلال ساعة واحدة

**القاعدة:**
> إذا زار المستخدم نفس البروفايل خلال الساعة الأخيرة، لا تسجل زيارة جديدة

---

## 📝 التنفيذ

### 1. Method للفحص

```dart
/// Check if this is a duplicate view within the last hour
Future<bool> _isDuplicateView({
  required String viewerId,
  required String profileUserId,
}) async {
  try {
    // Get views from the last hour
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    
    final snapshot = await _firestore
        .collection('profile_views')
        .where('viewerId', isEqualTo: viewerId)
        .where('profileUserId', isEqualTo: profileUserId)
        .orderBy('viewedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return false; // No previous views
    }

    // Check if the last view was within the last hour
    final lastView = snapshot.docs.first.data();
    final viewedAt = lastView['viewedAt'] as Timestamp?;
    
    if (viewedAt == null) {
      return false; // No timestamp, allow new view
    }

    final lastViewTime = viewedAt.toDate();
    final isRecent = lastViewTime.isAfter(oneHourAgo);

    return isRecent;
  } catch (e) {
    print('Error checking duplicate view: $e');
    return false; // On error, allow the view
  }
}
```

### 2. استخدام في recordProfileView

```dart
Future<void> recordProfileView(String profileUserId) async {
  try {
    final currentUser = _auth.currentUser;
    
    if (currentUser == null || currentUser.uid == profileUserId) {
      return;
    }

    // ✅ Check for duplicates
    final isDuplicate = await _isDuplicateView(
      viewerId: currentUser.uid,
      profileUserId: profileUserId,
    );

    if (isDuplicate) {
      print('Duplicate view detected - skipping');
      return;
    }

    // Record the view
    await _firestore.collection('profile_views').add({
      'viewerId': currentUser.uid,
      'profileUserId': profileUserId,
      'viewedAt': FieldValue.serverTimestamp(),
    });

    // Send notification if enabled
    await _checkAndSendNotification(
      viewerId: currentUser.uid,
      profileUserId: profileUserId,
    );
  } catch (e) {
    print('Error recording profile view: $e');
  }
}
```

---

## 🔍 كيف يعمل

### السيناريو 1: زيارة جديدة ✅
```
1. User A يزور بروفايل User B (أول مرة)
   ↓
2. _isDuplicateView() يبحث عن زيارات سابقة
   ↓
3. لا يوجد زيارات → isDuplicate = false
   ↓
4. تُسجل الزيارة ✅
   ↓
5. يُرسل إشعار (إذا مفعل) ✅
```

### السيناريو 2: زيارة مكررة (خلال ساعة) ❌
```
1. User A يزور بروفايل User B (مرة ثانية بعد 10 دقائق)
   ↓
2. _isDuplicateView() يبحث عن زيارات سابقة
   ↓
3. يوجد زيارة قبل 10 دقائق → isDuplicate = true
   ↓
4. لا تُسجل الزيارة ❌
   ↓
5. لا يُرسل إشعار ❌
```

### السيناريو 3: زيارة بعد ساعة ✅
```
1. User A يزور بروفايل User B (بعد ساعة ونصف)
   ↓
2. _isDuplicateView() يبحث عن زيارات سابقة
   ↓
3. آخر زيارة كانت قبل ساعة ونصف → isDuplicate = false
   ↓
4. تُسجل الزيارة ✅
   ↓
5. يُرسل إشعار (إذا مفعل) ✅
```

---

## 📊 Firestore Indexes

### Index 1: للفحص عن الزيارات المكررة
```json
{
  "collectionGroup": "profile_views",
  "fields": [
    { "fieldPath": "viewerId", "order": "ASCENDING" },
    { "fieldPath": "profileUserId", "order": "ASCENDING" },
    { "fieldPath": "viewedAt", "order": "DESCENDING" }
  ]
}
```

**الاستخدام:**
```dart
.where('viewerId', isEqualTo: viewerId)
.where('profileUserId', isEqualTo: profileUserId)
.orderBy('viewedAt', descending: true)
```

### Index 2: لقراءة زيارات البروفايل
```json
{
  "collectionGroup": "profile_views",
  "fields": [
    { "fieldPath": "profileUserId", "order": "ASCENDING" },
    { "fieldPath": "viewedAt", "order": "DESCENDING" }
  ]
}
```

**الاستخدام:**
```dart
.where('profileUserId', isEqualTo: userId)
.orderBy('viewedAt', descending: true)
```

---

## 🎨 المزايا

### 1. منع Spam ✅
- لا إشعارات متكررة
- تجربة مستخدم أفضل
- لا إزعاج

### 2. بيانات دقيقة ✅
- كل زيارة فريدة
- إحصائيات صحيحة
- تحليلات موثوقة

### 3. Performance ✅
- استعلام واحد فقط
- limit(1) للسرعة
- index محسّن

### 4. Error Handling ✅
- إذا فشل الفحص، تُسجل الزيارة
- لا crashes
- silent fail

---

## 🧪 الاختبار

### اختبار 1: زيارة جديدة ✅
```
الخطوات:
1. User A يزور بروفايل User B (أول مرة)
2. تحقق من Firestore

النتيجة:
✅ تُسجل الزيارة
✅ يُرسل إشعار
```

### اختبار 2: زيارة مكررة فورية ✅
```
الخطوات:
1. User A يزور بروفايل User B
2. فوراً يغلق ويفتح البروفايل مرة أخرى
3. تحقق من Firestore

النتيجة:
✅ لا تُسجل زيارة جديدة
✅ لا يُرسل إشعار
✅ عدد الزيارات = 1
```

### اختبار 3: زيارة بعد 30 دقيقة ✅
```
الخطوات:
1. User A يزور بروفايل User B
2. انتظر 30 دقيقة
3. افتح البروفايل مرة أخرى
4. تحقق من Firestore

النتيجة:
✅ لا تُسجل زيارة جديدة (لم تمر ساعة)
✅ لا يُرسل إشعار
✅ عدد الزيارات = 1
```

### اختبار 4: زيارة بعد ساعة ونصف ✅
```
الخطوات:
1. User A يزور بروفايل User B
2. انتظر ساعة ونصف
3. افتح البروفايل مرة أخرى
4. تحقق من Firestore

النتيجة:
✅ تُسجل زيارة جديدة (مرت أكثر من ساعة)
✅ يُرسل إشعار
✅ عدد الزيارات = 2
```

---

## ⚙️ التخصيص

### تغيير المدة الزمنية

**حالياً:** ساعة واحدة
```dart
final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
```

**لتغييرها:**

#### 30 دقيقة:
```dart
final thirtyMinutesAgo = DateTime.now().subtract(const Duration(minutes: 30));
```

#### 24 ساعة:
```dart
final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
```

#### 5 دقائق (للاختبار):
```dart
final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
```

---

## 📊 الإحصائيات

### قبل التحديث:
```
User A يزور User B 10 مرات في 5 دقائق
→ 10 زيارات مسجلة ❌
→ 10 إشعارات ❌
```

### بعد التحديث:
```
User A يزور User B 10 مرات في 5 دقائق
→ 1 زيارة مسجلة ✅
→ 1 إشعار ✅
```

---

## 🔍 التحقق

### في Firebase Console:

```
profile_views/
  ├─ view1/
  │   ├─ viewerId: "userA"
  │   ├─ profileUserId: "userB"
  │   └─ viewedAt: 10:00 AM
  │
  ├─ view2/  (بعد ساعتين)
  │   ├─ viewerId: "userA"
  │   ├─ profileUserId: "userB"
  │   └─ viewedAt: 12:00 PM
  │
  └─ ... (لا زيارات مكررة خلال الساعة)
```

---

## 💡 نصائح

### 1. اختر المدة المناسبة
- **قصيرة جداً (5 دقائق):** قد تسجل زيارات كثيرة
- **طويلة جداً (24 ساعة):** قد تفوت زيارات حقيقية
- **موصى به: 1 ساعة** ✅

### 2. راقب الأداء
- استخدم Firebase Performance Monitoring
- تحقق من سرعة الاستعلامات
- راقب عدد القراءات

### 3. اختبر جيداً
- اختبر مع مستخدمين حقيقيين
- جرب سيناريوهات مختلفة
- تحقق من الإحصائيات

---

## ✅ قائمة التحقق

- [x] Method `_isDuplicateView()` منشأة
- [x] دمج مع `recordProfileView()`
- [x] Firestore indexes مضافة
- [x] Error handling موجود
- [x] لا diagnostics errors
- [x] Performance محسّن (limit 1)
- [x] Silent fail عند الخطأ

---

## 🎉 النتيجة

**منع الزيارات المكررة مفعّل!** ✅

الآن:
- ✅ لا زيارات مكررة خلال ساعة
- ✅ لا spam notifications
- ✅ بيانات دقيقة
- ✅ Performance محسّن

**جرب الآن:**
1. زر بروفايل شخص
2. أغلق وافتح البروفايل مرة أخرى
3. تحقق من Firestore - يجب أن ترى زيارة واحدة فقط! ✅

🎯 **جاهز للمرحلة 2 (FCM)!**
