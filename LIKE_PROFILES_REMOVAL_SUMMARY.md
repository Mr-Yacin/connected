# ملخص حذف ميزة Like Profiles

## التاريخ: 4 ديسمبر 2025

## السبب
تم حذف ميزة "الإعجاب بالبروفايلات" (Like Profiles) لأنها مكررة مع ميزة "المتابعة" (Follow). 
التطبيق الآن يعتمد فقط على Follow للتفاعل مع البروفايلات.

---

## الملفات المحذوفة

### 1. Repositories & Domain
- ✅ `lib/features/discovery/data/repositories/firestore_like_repository.dart`
- ✅ `lib/features/discovery/domain/repositories/like_repository.dart`

### 2. Providers
- ✅ `lib/features/discovery/presentation/providers/like_provider.dart`

### 3. Screens
- ✅ `lib/features/discovery/presentation/screens/likes_list_screen.dart`

### 4. Models
- ✅ `lib/core/models/like.dart`

---

## الملفات المعدّلة

### 1. User Profile Model
**الملف:** `lib/core/models/user_profile.dart`
- ❌ حذف: `likesCount` field
- ✅ تم تحديث: `toJson()`, `fromJson()`, `copyWith()`, `==`, `hashCode`

### 2. User Card Widget
**الملف:** `lib/features/discovery/presentation/widgets/user_card.dart`
- ❌ حذف: `onLike` callback
- ❌ حذف: `isLiked` parameter
- ❌ حذف: زر "إعجاب" من UI
- ❌ حذف: عرض `likesCount` من الإحصائيات

### 3. Shuffle Screen
**الملف:** `lib/features/discovery/presentation/screens/shuffle_screen.dart`
- ❌ حذف: `import like_provider`
- ❌ حذف: `_handleLike()` method
- ❌ حذف: `likeState` و `isLiked` variables
- ❌ حذف: استدعاءات `likeProvider`

### 4. Profile Screen
**الملف:** `lib/features/profile/presentation/screens/profile_screen.dart`
- ❌ حذف: `_buildViewLikesButton()` method
- ❌ حذف: عرض `likesCount` من الإحصائيات
- ❌ حذف: زر "عرض الإعجابات"

### 5. App Router
**الملف:** `lib/core/navigation/app_router.dart`
- ❌ حذف: `import LikesListScreen`
- ❌ حذف: `/likes` route

### 6. Firestore Rules
**الملف:** `firestore.rules`
- ❌ حذف: `likes` collection rules بالكامل
- ❌ حذف: `likesCount` من allowed updates في users collection
- ✅ تم الإبقاء على: `followerCount` و `followingCount` فقط

### 7. Firebase Functions
**الملف:** `functions/notifications.ts`
- ❌ حذف: `onNewLike` function (كانت للمنشورات وليست موجودة أصلاً)

---

## الميزات المتبقية (بعد الحذف)

### ✅ التفاعلات المتاحة:
1. **Follow/Unfollow** - متابعة البروفايلات
2. **Chat** - المحادثات
3. **View Profile** - عرض البروفايل
4. **Stories** - الستوريز (مع like/reply/view)

### ✅ الإحصائيات المتبقية في البروفايل:
- `followerCount` - عدد المتابعين
- `followingCount` - عدد المتابَعين

---

## التأثير على قاعدة البيانات

### Collections المحذوفة (يجب حذفها يدوياً):
```
/likes/{likeId}
```

### Fields المحذوفة من users:
```
likesCount: number
```

**ملاحظة:** البيانات الموجودة في Firestore لن تُحذف تلقائياً. يجب حذفها يدوياً إذا أردت تنظيف قاعدة البيانات.

---

## الخطوات التالية

### 1. تنظيف قاعدة البيانات (اختياري):
```javascript
// في Firebase Console أو Cloud Functions
const likesSnapshot = await db.collection('likes').get();
const batch = db.batch();
likesSnapshot.docs.forEach(doc => batch.delete(doc.ref));
await batch.commit();

// حذف likesCount من users
const usersSnapshot = await db.collection('users').get();
const userBatch = db.batch();
usersSnapshot.docs.forEach(doc => {
  userBatch.update(doc.ref, { likesCount: FieldValue.delete() });
});
await userBatch.commit();
```

### 2. Deploy Firebase Rules:
```bash
firebase deploy --only firestore:rules
```

### 3. Deploy Firebase Functions:
```bash
firebase deploy --only functions
```

### 4. Test التطبيق:
- ✅ Shuffle screen يعمل بدون أخطاء
- ✅ Profile screen يعرض الإحصائيات الصحيحة
- ✅ Follow/Unfollow يعمل بشكل صحيح
- ✅ لا توجد أخطاء في Diagnostics

---

## الإشعارات المطلوبة (الخطوة التالية)

بعد حذف Like Profiles، الإشعارات المطلوبة هي:

### ✅ موجودة:
1. رسالة جديدة (new message)
2. رد على ستوري (story reply)

### ❌ ناقصة:
3. إعجاب بستوري (story like)
4. متابعة جديدة (new follower)
5. زيارة بروفايل (profile visit)
6. ستوري جديدة من متابَع (new story from following)

---

## ملاحظات

- ✅ جميع الملفات تم تحديثها بنجاح
- ✅ لا توجد أخطاء في Diagnostics
- ✅ التطبيق جاهز للتشغيل
- ⚠️ يجب deploy Firebase Rules و Functions
- ⚠️ يجب تنظيف قاعدة البيانات يدوياً (اختياري)
