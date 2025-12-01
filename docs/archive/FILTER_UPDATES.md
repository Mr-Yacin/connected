# تحديثات نظام الفلترة

## التغييرات المطبقة

### 1. إزالة حقل اللهجة (dialect)
- تمت إزالة حقل `dialect` من `DiscoveryFilters` لأنه غير موجود في نموذج `UserProfile`
- تم تحديث واجهة `FilterBottomSheet` لإزالة dropdown اللهجة
- تم تحديث `filter_service.dart` لإزالة دالة `applyDialectFilter`

### 2. إضافة فلتر الجنس
- إضافة حقل `gender` (String?) إلى `DiscoveryFilters`
- القيم المحتملة: `'male'`, `'female'`, أو `null` للكل
- واجهة المستخدم: 3 أزرار للاختيار (الكل / ذكر / أنثى)
- تطبيق الفلتر في Repository على مستوى query Firestore

### 3. تحديث فلتر العمر إلى RangeSlider
- **النطاق**: من 18 إلى 35+
- **35+**: يعني 35 فما فوق (لا يوجد حد أعلى)
- **السلوك**: عند اختيار 35، يتم تعيين `maxAge = null` للبحث عن جميع الأعمار 35+
- استبدال حقلي النص `minAge` و `maxAge` بـ `RangeSlider`

### 4. إضافة فلتر آخر تواجد
- إضافة حقل `lastActiveWithinHours` (int?) إلى `DiscoveryFilters`
- **القيمة الوحيدة**: 24 ساعة
- واجهة المستخدم: زران للاختيار (أي وقت / آخر 24 ساعة)
- تطبيق الفلتر على مستوى client-side (بعد جلب البيانات)

## الملفات المعدلة

1. **lib/core/models/discovery_filters.dart**
   - إزالة: `dialect`
   - إضافة: `gender`, `lastActiveWithinHours`
   - تحديث: `toJson`, `fromJson`, `copyWith`, `hasActiveFilters`, `==`, `hashCode`

2. **lib/features/discovery/data/repositories/firestore_discovery_repository.dart**
   - تحديث: استبدال فلتر `dialect` بـ `gender`
   - إضافة: فلترة `lastActive` على مستوى client-side

3. **lib/features/discovery/presentation/widgets/filter_bottom_sheet.dart**
   - إزالة: dropdown اللهجة، text fields العمر
   - إضافة: أزرار اختيار الجنس، RangeSlider للعمر، أزرار آخر تواجد
   - تحديث: logic الإرسال لدعم الفلاتر الجديدة

4. **lib/features/discovery/data/services/filter_service.dart**
   - إزالة: `applyDialectFilter`
   - إضافة: `applyGenderFilter`, `applyLastActiveFilter`
   - تحديث: `applyMultipleFilters`

5. **firestore.indexes.json**
   - إزالة: مؤشرات `dialect`
   - إضافة: مؤشرات `gender` المركبة

## Firestore Indexes المطلوبة

لتطبيق التحديثات، تحتاج إلى تحديث indexes في Firestore:

```bash
firebase deploy --only firestore:indexes
```

### المؤشرات الجديدة:
1. `isActive` + `gender` + `id`
2. `isActive` + `country` + `gender` + `id`

## ملاحظات مهمة

### سلوك الفلاتر:
- **الجنس**: إذا كان `null`، يتم عرض جميع الجنسين
- **العمر**: 
  - النطاق الافتراضي: 18-35
  - إذا تم اختيار 35، يتم البحث عن 35+
- **آخر تواجد**: 
  - إذا كان `null`، يتم عرض جميع المستخدمين
  - إذا كان 24، يتم عرض المستخدمين النشطين خلال آخر 24 ساعة فقط

### الأداء:
- فلاتر `country` و `gender` تُطبق على مستوى Firestore query (أسرع)
- فلاتر `age` و `lastActive` تُطبق على مستوى client-side (بعد جلب البيانات)
- الحد الأقصى للنتائج: 100 مستخدم في كل query

## اختبار التحديثات

1. افتح شاشة Shuffle
2. اضغط على زر الفلاتر
3. جرّب الفلاتر التالية:
   - اختر جنساً محدداً أو "الكل"
   - اضبط نطاق العمر باستخدام slider
   - اختر "آخر 24 ساعة" أو "أي وقت"
4. اضغط "تطبيق الفلاتر"
5. تأكد من عرض المستخدمين المطابقين فقط

## استكشاف الأخطاء

### رسالة "لا يوجد مستخدمين بهذه الفلاتر":
- تأكد من وجود مستخدمين في قاعدة البيانات يطابقون الفلاتر
- تأكد من أن حقل `gender` موجود في documents المستخدمين
- تحقق من تطبيق Firestore indexes بشكل صحيح

### أخطاء Firestore Index:
- إذا ظهرت رسالة خطأ index، انسخ الرابط من الخطأ وافتحه لإنشاء index تلقائياً
- أو استخدم `firebase deploy --only firestore:indexes`
