# مستند التصميم - تطبيق التواصل الاجتماعي

## نظرة عامة

تطبيق تواصل اجتماعي مبني باستخدام Flutter للواجهة الأمامية و Firebase كخدمة خلفية (BaaS). يتبع التطبيق معمارية Feature-First مع إدارة الحالة باستخدام Riverpod، مما يضمن قابلية التوسع والصيانة.

## البنية المعمارية

### النمط المعماري

نستخدم **Clean Architecture** مع **Feature-First Structure**:

```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   ├── profile/
│   ├── chat/
│   ├── discovery/
│   ├── stories/
│   └── moderation/
└── services/
    ├── firebase_service.dart
    ├── storage_service.dart
    └── notification_service.dart
```

### طبقات النظام

1. **Presentation Layer**: شاشات Flutter و Widgets
2. **Domain Layer**: منطق الأعمال و Use Cases
3. **Data Layer**: Repositories و Models
4. **Services Layer**: خدمات Firebase والخدمات المشتركة

## المكونات والواجهات

### 1. وحدة التوثيق (Auth Feature)

**المكونات الرئيسية:**

- `AuthRepository`: واجهة للتعامل مع Firebase Authentication
- `PhoneAuthUseCase`: منطق إرسال OTP والتحقق منه
- `AuthProvider`: إدارة حالة التوثيق باستخدام Riverpod
- `PhoneInputScreen`: شاشة إدخال رقم الهاتف
- `OtpVerificationScreen`: شاشة التحقق من OTP

**الواجهات:**

```dart
abstract class AuthRepository {
  Future<void> sendOtp(String phoneNumber);
  Future<UserCredential> verifyOtp(String verificationId, String otp);
  Future<void> signOut();
  Stream<User?> authStateChanges();
}
```

### 2. وحدة الملف الشخصي (Profile Feature)

**المكونات الرئيسية:**

- `ProfileRepository`: إدارة بيانات الملف الشخصي في Firestore
- `ImageBlurService`: تطبيق تأثير التمويه على الصور
- `ProfileProvider`: إدارة حالة الملف الشخصي
- `ProfileScreen`: شاشة عرض وتعديل الملف الشخصي

**الواجهات:**

```dart
abstract class ProfileRepository {
  Future<UserProfile> getProfile(String userId);
  Future<void> updateProfile(UserProfile profile);
  Future<String> uploadProfileImage(File image);
  Future<String> generateAnonymousLink(String userId);
}
```

### 3. وحدة الدردشة (Chat Feature)

**المكونات الرئيسية:**

- `ChatRepository`: إدارة الرسائل في Firestore
- `VoiceRecorderService`: تسجيل الرسائل الصوتية
- `ChatProvider`: إدارة حالة المحادثات
- `ChatListScreen`: قائمة المحادثات
- `ChatScreen`: شاشة المحادثة الفردية

**الواجهات:**

```dart
abstract class ChatRepository {
  Stream<List<Message>> getMessages(String chatId);
  Future<void> sendTextMessage(String chatId, String text);
  Future<void> sendVoiceMessage(String chatId, File audioFile);
  Future<void> markAsRead(String chatId, String messageId);
}
```

### 4. وحدة الاستكشاف (Discovery Feature)

**المكونات الرئيسية:**

- `DiscoveryRepository`: جلب المستخدمين العشوائيين
- `FilterService`: تطبيق فلاتر البحث
- `DiscoveryProvider`: إدارة حالة الاستكشاف
- `ShuffleScreen`: شاشة الشفل

**الواجهات:**

```dart
abstract class DiscoveryRepository {
  Future<UserProfile> getRandomUser(DiscoveryFilters filters);
  Future<List<UserProfile>> getFilteredUsers(DiscoveryFilters filters);
}
```

### 5. وحدة القصص (Stories Feature)

**المكونات الرئيسية:**

- `StoryRepository`: إدارة القصص في Firestore
- `StoryExpirationService`: حذف القصص المنتهية
- `StoryProvider`: إدارة حالة القصص
- `StoryBarWidget`: شريط القصص في الشاشة الرئيسية
- `StoryViewScreen`: شاشة عرض القصة

**الواجهات:**

```dart
abstract class StoryRepository {
  Future<void> createStory(Story story);
  Stream<List<Story>> getActiveStories();
  Future<void> deleteExpiredStories();
  Future<void> recordView(String storyId, String viewerId);
}
```

### 6. وحدة الأمان (Moderation Feature)

**المكونات الرئيسية:**

- `ModerationRepository`: إدارة البلاغات والحظر
- `BlockService`: منطق الحظر
- `ReportService`: منطق الإبلاغ
- `ModerationProvider`: إدارة حالة الأمان

**الواجهات:**

```dart
abstract class ModerationRepository {
  Future<void> blockUser(String userId, String blockedUserId);
  Future<void> reportContent(Report report);
  Future<List<Report>> getPendingReports();
  Future<void> takeAction(String reportId, ModerationAction action);
}
```

## نماذج البيانات

### UserProfile

```dart
class UserProfile {
  final String id;
  final String phoneNumber;
  final String? name;
  final int? age;
  final String? country;
  final String? dialect;
  final String? profileImageUrl;
  final bool isImageBlurred;
  final String? anonymousLink;
  final DateTime createdAt;
  final DateTime lastActive;
  
  UserProfile({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.age,
    this.country,
    this.dialect,
    this.profileImageUrl,
    this.isImageBlurred = false,
    this.anonymousLink,
    required this.createdAt,
    required this.lastActive,
  });
  
  Map<String, dynamic> toJson();
  factory UserProfile.fromJson(Map<String, dynamic> json);
}
```

### Message

```dart
class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final MessageType type; // text, voice
  final String content; // text or audio URL
  final DateTime timestamp;
  final bool isRead;
  
  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });
  
  Map<String, dynamic> toJson();
  factory Message.fromJson(Map<String, dynamic> json);
}
```

### Story

```dart
class Story {
  final String id;
  final String userId;
  final String mediaUrl;
  final StoryType type; // image, video
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewerIds;
  
  Story({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
    this.viewerIds = const [],
  });
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  Map<String, dynamic> toJson();
  factory Story.fromJson(Map<String, dynamic> json);
}
```

### Report

```dart
class Report {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String? reportedContentId;
  final ReportType type; // user, message, story
  final String reason;
  final ReportStatus status; // pending, reviewed, resolved
  final DateTime createdAt;
  final String? moderatorNotes;
  
  Report({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    this.reportedContentId,
    required this.type,
    required this.reason,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.moderatorNotes,
  });
  
  Map<String, dynamic> toJson();
  factory Report.fromJson(Map<String, dynamic> json);
}
```

### DiscoveryFilters

```dart
class DiscoveryFilters {
  final String? country;
  final String? dialect;
  final int? minAge;
  final int? maxAge;
  final List<String> excludedUserIds;
  
  DiscoveryFilters({
    this.country,
    this.dialect,
    this.minAge,
    this.maxAge,
    this.excludedUserIds = const [],
  });
  
  Map<String, dynamic> toJson();
}
```


## خصائص الصحة (Correctness Properties)

*الخاصية هي سمة أو سلوك يجب أن يكون صحيحاً عبر جميع عمليات التنفيذ الصالحة للنظام - في الأساس، بيان رسمي حول ما يجب أن يفعله النظام. تعمل الخصائص كجسر بين المواصفات المقروءة للإنسان وضمانات الصحة القابلة للتحقق آلياً.*

### خصائص وحدة التوثيق

**Property 1: OTP verification success creates or authenticates user**
*لأي* رقم هاتف صالح ورمز OTP صحيح، التحقق من الرمز يجب أن ينتج عنه إما إنشاء حساب جديد أو تسجيل دخول ناجح
**Validates: Requirements 1.2**

**Property 2: Rate limiting after failed attempts**
*لأي* مستخدم، بعد 3 محاولات OTP فاشلة متتالية، المحاولة الرابعة يجب أن تُرفض حتى مرور 5 دقائق
**Validates: Requirements 1.3**

**Property 3: OTP resend cooldown**
*لأي* طلب إعادة إرسال OTP، الطلب يجب أن يُرفض إذا لم يمر 60 ثانية على الطلب السابق
**Validates: Requirements 1.4**

### خصائص وحدة الملف الشخصي

**Property 4: Profile image upload updates URL**
*لأي* ملف صورة صالح، رفع الصورة يجب أن يؤدي إلى تحديث profileImageUrl في الملف الشخصي
**Validates: Requirements 2.1**

**Property 5: Blur effect application**
*لأي* ملف شخصي مع isImageBlurred = true، الصورة المعروضة للآخرين يجب أن تحتوي على تأثير blur
**Validates: Requirements 2.2**

**Property 6: Anonymous link uniqueness**
*لأي* مستخدمين مختلفين، الروابط المجهولة المولدة يجب أن تكون فريدة ومختلفة
**Validates: Requirements 2.3**

**Property 7: Profile update round trip**
*لأي* ملف شخصي، تحديث البيانات ثم قراءتها مباشرة يجب أن يعيد نفس البيانات المحدثة
**Validates: Requirements 2.5**

### خصائص وحدة الدردشة

**Property 8: Message sending adds to chat**
*لأي* رسالة نصية، إرسالها يجب أن يزيد عدد الرسائل في المحادثة بمقدار واحد
**Validates: Requirements 3.1**

**Property 9: Voice message has valid URL**
*لأي* رسالة صوتية مرسلة، الرسالة يجب أن تكون من نوع voice وتحتوي على URL صالح للملف الصوتي
**Validates: Requirements 3.2**

**Property 10: Real-time message streaming**
*لأي* محادثة نشطة، إضافة رسالة جديدة يجب أن تظهر فوراً في Stream للمستقبل
**Validates: Requirements 3.3**

**Property 11: Message chronological ordering**
*لأي* قائمة رسائل، الرسائل يجب أن تكون مرتبة حسب timestamp من الأقدم للأحدث
**Validates: Requirements 3.5**

### خصائص وحدة الاستكشاف

**Property 12: Country filter matching**
*لأي* فلتر بحث بدولة محددة، جميع المستخدمين المعادين يجب أن يكونوا من تلك الدولة
**Validates: Requirements 4.2**

**Property 13: Dialect filter matching**
*لأي* فلتر بحث بلهجة محددة، جميع المستخدمين المعادين يجب أن يتحدثوا تلك اللهجة
**Validates: Requirements 4.3**

**Property 14: Multiple filters conjunction**
*لأي* مجموعة فلاتر متعددة، جميع المستخدمين المعادين يجب أن يطابقوا كل الفلاتر المحددة
**Validates: Requirements 4.4**

**Property 15: Blocked users exclusion**
*لأي* نتائج استكشاف، المستخدمين المحظورين يجب ألا يظهروا في النتائج
**Validates: Requirements 4.5**

### خصائص وحدة القصص

**Property 16: Story expiration time**
*لأي* قصة منشورة، تاريخ الانتهاء (expiresAt) يجب أن يساوي تاريخ الإنشاء (createdAt) + 24 ساعة
**Validates: Requirements 5.1**

**Property 17: Expired stories exclusion**
*لأي* قائمة قصص نشطة، القصص التي مر عليها أكثر من 24 ساعة يجب ألا تظهر في القائمة
**Validates: Requirements 5.2**

**Property 18: Story view recording**
*لأي* قصة، مشاهدتها من قبل مستخدم يجب أن تضيف معرف المستخدم إلى viewerIds
**Validates: Requirements 5.3**

**Property 19: Stories chronological ordering**
*لأي* قائمة قصص، القصص يجب أن تكون مرتبة حسب createdAt من الأحدث للأقدم
**Validates: Requirements 5.4**

### خصائص وحدة الأمان

**Property 20: Block prevents access**
*لأي* مستخدمين A و B، إذا حظر A المستخدم B، فإن B يجب ألا يستطيع إرسال رسائل لـ A أو رؤية ملفه الشخصي
**Validates: Requirements 6.1**

**Property 21: Report creation with pending status**
*لأي* بلاغ جديد، البلاغ يجب أن يُحفظ بحالة pending ويحتوي على جميع التفاصيل المطلوبة
**Validates: Requirements 6.2**

**Property 22: Report action updates status**
*لأي* بلاغ، اتخاذ إجراء عليه يجب أن يحدث حالته من pending إلى reviewed أو resolved
**Validates: Requirements 6.4**

**Property 23: Account deletion removes all data**
*لأي* مستخدم، حذف حسابه يجب أن يحذف جميع بياناته الشخصية والمحتوى المرتبط به (رسائل، قصص، بلاغات)
**Validates: Requirements 8.3**

**Property 24: User preferences persistence**
*لأي* إعدادات مستخدم (لغة، وضع الظلام)، حفظ الإعدادات ثم قراءتها يجب أن يعيد نفس القيم
**Validates: Requirements 7.4**

## معالجة الأخطاء

### استراتيجية معالجة الأخطاء

1. **أخطاء الشبكة والاتصال:**
   - استخدام try-catch blocks حول جميع استدعاءات Firebase
   - عرض رسائل خطأ واضحة بالعربية للمستخدم
   - إعادة المحاولة التلقائية للعمليات الفاشلة (مع حد أقصى 3 محاولات)

2. **أخطاء التحقق من البيانات:**
   - التحقق من صحة المدخلات قبل إرسالها إلى Firebase
   - عرض رسائل توضيحية للمستخدم عن البيانات المطلوبة
   - منع إرسال نماذج غير مكتملة

3. **أخطاء الصلاحيات:**
   - التحقق من صلاحيات المستخدم قبل تنفيذ العمليات الحساسة
   - إعادة توجيه المستخدم لشاشة تسجيل الدخول عند انتهاء الجلسة
   - عرض رسائل واضحة عند محاولة الوصول لمحتوى محظور

4. **أخطاء رفع الملفات:**
   - التحقق من حجم ونوع الملف قبل الرفع
   - عرض progress indicator أثناء الرفع
   - إمكانية إلغاء عملية الرفع

### أنواع الأخطاء المخصصة

```dart
class AppException implements Exception {
  final String message;
  final String? code;
  
  AppException(this.message, {this.code});
}

class AuthException extends AppException {
  AuthException(String message, {String? code}) : super(message, code: code);
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message);
}

class ValidationException extends AppException {
  ValidationException(String message) : super(message);
}

class PermissionException extends AppException {
  PermissionException(String message) : super(message);
}
```

## استراتيجية الاختبار

### نهج الاختبار المزدوج

سنستخدم نهجاً مزدوجاً للاختبار يجمع بين:

1. **اختبارات الوحدة (Unit Tests)**: للتحقق من أمثلة محددة وحالات حدية
2. **اختبارات قائمة على الخصائص (Property-Based Tests)**: للتحقق من الخصائص العامة عبر مدخلات متعددة

هذان النوعان متكاملان ويوفران معاً تغطية شاملة.

### مكتبة الاختبار

سنستخدم **faker** و **test** المدمجة في Flutter للاختبارات القائمة على الخصائص:

```yaml
dev_dependencies:
  test: ^1.24.0
  faker: ^2.1.0
  mockito: ^5.4.0
```

### اختبارات الوحدة

اختبارات الوحدة تغطي:
- أمثلة محددة توضح السلوك الصحيح
- حالات حدية (مدخلات فارغة، قيم حدية، شروط الخطأ)
- نقاط التكامل بين المكونات

مثال:

```dart
test('Empty phone number should throw ValidationException', () {
  expect(
    () => authRepository.sendOtp(''),
    throwsA(isA<ValidationException>()),
  );
});
```

### اختبارات قائمة على الخصائص

**متطلبات الاختبار القائم على الخصائص:**

- كل اختبار يجب أن يُشغل **100 تكرار على الأقل** لضمان تغطية واسعة
- كل اختبار يجب أن يُعلّم بتعليق يشير صراحة إلى الخاصية في مستند التصميم
- صيغة التعليق: `// Feature: social-connect-app, Property X: [نص الخاصية]`
- كل خاصية صحة يجب أن تُنفذ باختبار واحد فقط

مثال:

```dart
// Feature: social-connect-app, Property 7: Profile update round trip
test('Profile update round trip preserves data', () {
  final faker = Faker();
  
  for (int i = 0; i < 100; i++) {
    // Generate random profile data
    final profile = UserProfile(
      id: faker.guid.guid(),
      phoneNumber: faker.phoneNumber.us(),
      name: faker.person.name(),
      age: faker.randomGenerator.integer(60, min: 18),
      country: faker.address.country(),
    );
    
    // Update and read back
    await profileRepository.updateProfile(profile);
    final retrieved = await profileRepository.getProfile(profile.id);
    
    // Verify round trip
    expect(retrieved.name, equals(profile.name));
    expect(retrieved.age, equals(profile.age));
    expect(retrieved.country, equals(profile.country));
  }
});
```

### تغطية الاختبار

- **Data Models**: اختبارات وحدة لـ toJson/fromJson
- **Repositories**: اختبارات قائمة على الخصائص للعمليات الأساسية
- **Use Cases**: اختبارات وحدة لمنطق الأعمال
- **Providers**: اختبارات وحدة لإدارة الحالة
- **Widgets**: اختبارات widget للمكونات الحرجة

### استراتيجية Mock

- استخدام Mockito لعمل mock للـ repositories في اختبارات use cases
- استخدام fake implementations بسيطة بدلاً من mocks عندما يكون ممكناً
- تجنب mocking Firebase مباشرة - استخدام repositories كطبقة abstraction

## الأمان والخصوصية

### قواعد أمان Firebase

```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User profiles
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Messages
    match /chats/{chatId}/messages/{messageId} {
      allow read: if request.auth != null && 
                     (request.auth.uid in resource.data.participants);
      allow create: if request.auth != null && 
                       request.auth.uid == request.resource.data.senderId;
    }
    
    // Stories
    match /stories/{storyId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
                       request.auth.uid == request.resource.data.userId;
      allow delete: if request.auth != null && 
                       request.auth.uid == resource.data.userId;
    }
    
    // Reports
    match /reports/{reportId} {
      allow read: if request.auth != null && 
                     hasRole('moderator');
      allow create: if request.auth != null;
    }
    
    // Blocks
    match /blocks/{blockId} {
      allow read, write: if request.auth != null && 
                            request.auth.uid == resource.data.blockerId;
    }
  }
}

// Storage Security Rules
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_images/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      request.auth.uid == userId &&
                      request.resource.size < 5 * 1024 * 1024 && // 5MB max
                      request.resource.contentType.matches('image/.*');
    }
    
    match /voice_messages/{chatId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                      request.resource.size < 10 * 1024 * 1024 && // 10MB max
                      request.resource.contentType.matches('audio/.*');
    }
    
    match /stories/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      request.auth.uid == userId &&
                      request.resource.size < 20 * 1024 * 1024; // 20MB max
    }
  }
}
```

### تشفير البيانات

- جميع الاتصالات تتم عبر HTTPS
- Firebase يوفر تشفير البيانات في حالة الراحة (at rest) والنقل (in transit)
- أرقام الهواتف تُخزن بشكل آمن في Firebase Authentication
- الملفات الحساسة تُخزن في Firebase Storage مع قواعد أمان صارمة

### الخصوصية

- المستخدمون يتحكمون في ظهور صورهم (خيار التمويه)
- إمكانية التواصل المجهول عبر الروابط الخاصة
- حذف البيانات الكامل عند حذف الحساب
- عدم مشاركة البيانات الشخصية مع أطراف ثالثة

## الأداء والتحسين

### استراتيجيات التحسين

1. **Lazy Loading**: تحميل البيانات عند الحاجة فقط
2. **Pagination**: تحميل الرسائل والقصص على دفعات
3. **Caching**: استخدام Riverpod للـ caching الذكي للبيانات
4. **Image Optimization**: ضغط الصور قبل الرفع
5. **Indexing**: إنشاء indexes في Firestore للاستعلامات المتكررة

### مؤشرات الأداء المستهدفة

- وقت تحميل الشاشة الرئيسية: < 2 ثانية
- وقت إرسال الرسالة: < 500ms
- وقت تحميل القصص: < 1 ثانية
- استهلاك الذاكرة: < 150MB في المتوسط

## قابلية التوسع

### خطة التوسع المستقبلية

المرحلة الأولى (MVP) تغطي الميزات الأساسية. الميزات المستقبلية المحتملة:

1. **مكالمات صوتية ومرئية**: باستخدام WebRTC أو Agora
2. **المجموعات**: محادثات جماعية
3. **الهدايا الافتراضية**: نظام monetization
4. **الترجمة الفورية**: للتواصل بين لهجات مختلفة
5. **التحقق من الهوية**: علامة verified للحسابات الموثقة
6. **الخريطة**: اكتشاف مستخدمين قريبين جغرافياً

### البنية القابلة للتوسع

- استخدام Feature-First Structure يسهل إضافة ميزات جديدة
- Repositories توفر abstraction layer يسهل تغيير مصدر البيانات
- Clean Architecture تفصل المنطق عن التنفيذ
