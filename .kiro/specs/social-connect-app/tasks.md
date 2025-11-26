# خطة التنفيذ - تطبيق التواصل الاجتماعي

## نظرة عامة

هذه خطة تنفيذ تدريجية لبناء تطبيق التواصل الاجتماعي. كل مهمة تبني على المهام السابقة.

---

## المهام

- [x] 1. إعداد البنية الأساسية للمشروع





  - إنشاء مشروع Flutter جديد مع البنية Feature-First
  - إضافة dependencies الأساسية (firebase_core, firebase_auth, cloud_firestore, firebase_storage, riverpod, faker)
  - إعداد Firebase للمشروع (Android & iOS)
  - إنشاء هيكل المجلدات: core/, features/, services/
  - إعداد ملفات الثيم الأساسية مع دعم RTL و Dark Mode
  - _Requirements: 7.1, 7.2, 7.3_

- [x] 2. بناء نماذج البيانات الأساسية





  - إنشاء UserProfile model مع toJson/fromJson
  - إنشاء Message model مع toJson/fromJson
  - إنشاء Story model مع toJson/fromJson
  - إنشاء Report model مع toJson/fromJson
  - إنشاء DiscoveryFilters model مع toJson/fromJson
  - إضافة enums للأنواع (MessageType, StoryType, ReportType, ReportStatus)
  - _Requirements: 2.1, 3.1, 5.1, 6.2_

- [ ]* 2.1 كتابة اختبارات وحدة لنماذج البيانات
  - اختبار toJson/fromJson لجميع النماذج
  - اختبار الحالات الحدية (null values, missing fields)
  - _Requirements: 2.1, 3.1, 5.1, 6.2_

- [x] 3. تنفيذ وحدة التوثيق (Auth Feature)








- [x] 3.1 إنشاء AuthRepository و Firebase implementation

  - تنفيذ sendOtp() للتحقق من رقم الهاتف
  - تنفيذ verifyOtp() للتحقق من رمز OTP
  - تنفيذ signOut() لتسجيل الخروج
  - تنفيذ authStateChanges() stream
  - إضافة rate limiting logic (3 محاولات / 5 دقائق)
  - إضافة OTP resend cooldown (60 ثانية)
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ]* 3.2 كتابة اختبار خاصية: OTP verification success
  - **Property 1: OTP verification success creates or authenticates user**
  - **Validates: Requirements 1.2**

- [ ]* 3.3 كتابة اختبار خاصية: Rate limiting
  - **Property 2: Rate limiting after failed attempts**
  - **Validates: Requirements 1.3**

- [ ]* 3.4 كتابة اختبار خاصية: OTP resend cooldown
  - **Property 3: OTP resend cooldown**


  - **Validates: Requirements 1.4**

- [x] 3.5 بناء واجهة المستخدم للتوثيق


  - إنشاء PhoneInputScreen مع validation
  - إنشاء OtpVerificationScreen مع countdown timer
  - إنشاء AuthProvider باستخدام Riverpod
  - ربط الشاشات بـ AuthRepository
  - إضافة معالجة الأخطاء وعرض الرسائل بالعربية
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 4. Checkpoint - التأكد من نجاح جميع الاختبارات




  - التأكد من نجاح جميع الاختبارات، استشر المستخدم إذا ظهرت أسئلة.

- [x] 5. تنفيذ وحدة الملف الشخصي (Profile Feature)






- [x] 5.1 إنشاء ProfileRepository و Firestore implementation


  - تنفيذ getProfile() لجلب بيانات المستخدم
  - تنفيذ updateProfile() لتحديث البيانات
  - تنفيذ uploadProfileImage() لرفع الصور إلى Storage
  - تنفيذ generateAnonymousLink() لتوليد رابط فريد
  - _Requirements: 2.1, 2.3, 2.4, 2.5_

- [x] 5.2 إنشاء ImageBlurService


  - تنفيذ applyBlur() لتطبيق تأثير blur على الصور
  - دعم مستويات blur مختلفة
  - _Requirements: 2.2_

- [ ]* 5.3 كتابة اختبار خاصية: Profile image upload
  - **Property 4: Profile image upload updates URL**
  - **Validates: Requirements 2.1**

- [ ]* 5.4 كتابة اختبار خاصية: Blur effect
  - **Property 5: Blur effect application**
  - **Validates: Requirements 2.2**

- [ ]* 5.5 كتابة اختبار خاصية: Anonymous link uniqueness
  - **Property 6: Anonymous link uniqueness**
  - **Validates: Requirements 2.3**

- [ ]* 5.6 كتابة اختبار خاصية: Profile update round trip
  - **Property 7: Profile update round trip**
  - **Validates: Requirements 2.5**


- [x] 5.7 بناء واجهة المستخدم للملف الشخصي

  - إنشاء ProfileScreen لعرض وتعديل البيانات
  - إضافة image picker لاختيار الصورة
  - إضافة toggle للتمويه
  - إضافة حقول النموذج (الاسم، العمر، الدولة، اللهجة)
  - إنشاء ProfileProvider باستخدام Riverpod
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 6. Checkpoint - التأكد من نجاح جميع الاختبارات




  - التأكد من نجاح جميع الاختبارات، استشر المستخدم إذا ظهرت أسئلة.

- [x] 7. تنفيذ وحدة الدردشة (Chat Feature)







- [x] 7.1 إنشاء ChatRepository و Firestore implementation

  - تنفيذ getMessages() stream للرسائل في الوقت الفعلي
  - تنفيذ sendTextMessage() لإرسال رسائل نصية
  - تنفيذ sendVoiceMessage() لإرسال رسائل صوتية
  - تنفيذ markAsRead() لتحديد الرسائل كمقروءة
  - تنفيذ getChatList() لجلب قائمة المحادثات
  - _Requirements: 3.1, 3.2, 3.3, 3.5_


- [x] 7.2 إنشاء VoiceRecorderService

  - تنفيذ startRecording() لبدء التسجيل
  - تنفيذ stopRecording() لإيقاف التسجيل وحفظ الملف
  - تنفيذ playAudio() لتشغيل الرسائل الصوتية
  - _Requirements: 3.2_


- [x] 7.3 إنشاء NotificationService

  - إعداد Firebase Cloud Messaging
  - تنفيذ sendNotification() لإرسال إشعارات
  - معالجة الإشعارات في الخلفية والمقدمة
  - _Requirements: 3.4_

- [ ]* 7.4 كتابة اختبار خاصية: Message sending
  - **Property 8: Message sending adds to chat**
  - **Validates: Requirements 3.1**

- [ ]* 7.5 كتابة اختبار خاصية: Voice message URL
  - **Property 9: Voice message has valid URL**
  - **Validates: Requirements 3.2**

- [ ]* 7.6 كتابة اختبار خاصية: Real-time streaming
  - **Property 10: Real-time message streaming**
  - **Validates: Requirements 3.3**

- [ ]* 7.7 كتابة اختبار خاصية: Message ordering
  - **Property 11: Message chronological ordering**
  - **Validates: Requirements 3.5**

- [x] 7.8 بناء واجهة المستخدم للدردشة


  - إنشاء ChatListScreen لعرض قائمة المحادثات
  - إنشاء ChatScreen لعرض المحادثة الفردية
  - إضافة MessageBubble widget للرسائل
  - إضافة VoiceMessageWidget للرسائل الصوتية
  - إضافة MessageInputBar مع زر التسجيل
  - إنشاء ChatProvider باستخدام Riverpod
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 8. Checkpoint - التأكد من نجاح جميع الاختبارات





  - التأكد من نجاح جميع الاختبارات، استشر المستخدم إذا ظهرت أسئلة.

- [x] 9. تنفيذ وحدة الاستكشاف (Discovery Feature)






- [x] 9.1 إنشاء DiscoveryRepository و Firestore implementation


  - تنفيذ getRandomUser() لجلب مستخدم عشوائي
  - تنفيذ getFilteredUsers() مع دعم الفلاتر المتعددة
  - تنفيذ منطق استثناء المستخدمين المحظورين
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 9.2 إنشاء FilterService


  - تنفيذ applyCountryFilter()
  - تنفيذ applyDialectFilter()
  - تنفيذ applyMultipleFilters() مع AND logic
  - _Requirements: 4.2, 4.3, 4.4_

- [ ]* 9.3 كتابة اختبار خاصية: Country filter
  - **Property 12: Country filter matching**
  - **Validates: Requirements 4.2**

- [ ]* 9.4 كتابة اختبار خاصية: Dialect filter
  - **Property 13: Dialect filter matching**
  - **Validates: Requirements 4.3**

- [ ]* 9.5 كتابة اختبار خاصية: Multiple filters
  - **Property 14: Multiple filters conjunction**
  - **Validates: Requirements 4.4**

- [ ]* 9.6 كتابة اختبار خاصية: Blocked users exclusion
  - **Property 15: Blocked users exclusion**
  - **Validates: Requirements 4.5**

- [x] 9.7 بناء واجهة المستخدم للاستكشاف


  - إنشاء ShuffleScreen لعرض المستخدمين العشوائيين
  - إضافة FilterBottomSheet للفلاتر
  - إضافة UserCard widget لعرض بطاقة المستخدم
  - إضافة أزرار التفاعل (إعجاب، تخطي، محادثة)
  - إنشاء DiscoveryProvider باستخدام Riverpod
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 10. Checkpoint - التأكد من نجاح جميع الاختبارات




  - التأكد من نجاح جميع الاختبارات، استشر المستخدم إذا ظهرت أسئلة.

- [x] 11. تنفيذ وحدة القصص (Stories Feature)





- [x] 11.1 إنشاء StoryRepository و Firestore implementation


  - تنفيذ createStory() لإنشاء قصة جديدة
  - تنفيذ getActiveStories() stream للقصص النشطة
  - تنفيذ deleteExpiredStories() لحذف القصص المنتهية
  - تنفيذ recordView() لتسجيل المشاهدات
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 11.2 إنشاء StoryExpirationService


  - تنفيذ scheduled job لحذف القصص المنتهية كل ساعة
  - تنفيذ isExpired() للتحقق من انتهاء القصة
  - _Requirements: 5.2_

- [ ]* 11.3 كتابة اختبار خاصية: Story expiration time
  - **Property 16: Story expiration time**
  - **Validates: Requirements 5.1**

- [ ]* 11.4 كتابة اختبار خاصية: Expired stories exclusion
  - **Property 17: Expired stories exclusion**
  - **Validates: Requirements 5.2**

- [ ]* 11.5 كتابة اختبار خاصية: Story view recording
  - **Property 18: Story view recording**
  - **Validates: Requirements 5.3**

- [ ]* 11.6 كتابة اختبار خاصية: Stories ordering
  - **Property 19: Stories chronological ordering**
  - **Validates: Requirements 5.4**

- [x] 11.7 بناء واجهة المستخدم للقصص


  - إنشاء StoryBarWidget للشريط الأفقي في الشاشة الرئيسية
  - إنشاء StoryViewScreen لعرض القصة بملء الشاشة
  - إضافة StoryCreationScreen لإنشاء قصة جديدة
  - إضافة progress indicators للقصص
  - إضافة gesture detection للتنقل بين القصص
  - إنشاء StoryProvider باستخدام Riverpod
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 12. Checkpoint - التأكد من نجاح جميع الاختبارات





  - التأكد من نجاح جميع الاختبارات، استشر المستخدم إذا ظهرت أسئلة.

- [ ] 13. تنفيذ وحدة الأمان (Moderation Feature)






- [x] 13.1 إنشاء ModerationRepository و Firestore implementation


  - تنفيذ blockUser() لحظر مستخدم
  - تنفيذ unblockUser() لإلغاء الحظر
  - تنفيذ getBlockedUsers() لجلب قائمة المحظورين
  - تنفيذ reportContent() لإنشاء بلاغ
  - تنفيذ getPendingReports() للمشرفين
  - تنفيذ takeAction() لاتخاذ إجراء على بلاغ
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 13.2 إنشاء BlockService


  - تنفيذ isBlocked() للتحقق من الحظر
  - تنفيذ preventAccess() لمنع الوصول للمحتوى
  - دمج منطق الحظر مع Chat و Profile
  - _Requirements: 6.1_

- [ ]* 13.3 كتابة اختبار خاصية: Block prevents access
  - **Property 20: Block prevents access**
  - **Validates: Requirements 6.1**

- [ ]* 13.4 كتابة اختبار خاصية: Report creation
  - **Property 21: Report creation with pending status**
  - **Validates: Requirements 6.2**

- [ ]* 13.5 كتابة اختبار خاصية: Report action updates status
  - **Property 22: Report action updates status**
  - **Validates: Requirements 6.4**

- [x] 13.6 بناء واجهة المستخدم للأمان


  - إضافة Block/Report buttons في ProfileScreen و ChatScreen
  - إنشاء ReportBottomSheet لاختيار سبب البلاغ
  - إنشاء BlockedUsersScreen لإدارة المحظورين
  - إنشاء ModerationDashboard للمشرفين (اختياري)
  - إنشاء ModerationProvider باستخدام Riverpod
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 14. Checkpoint - التأكد من نجاح جميع الاختبارات





  - التأكد من نجاح جميع الاختبارات، استشر المستخدم إذا ظهرت أسئلة.

- [x] 15. تنفيذ إدارة البيانات والإعدادات



- [x] 15.1 إنشاء UserDataService


  - تنفيذ deleteUserAccount() لحذف الحساب
  - تنفيذ deleteUserData() لحذف جميع البيانات المرتبطة
  - تنفيذ exportUserData() لتصدير البيانات (GDPR compliance)
  - _Requirements: 8.3_

- [x] 15.2 إنشاء PreferencesService


  - تنفيذ savePreferences() لحفظ الإعدادات
  - تنفيذ getPreferences() لجلب الإعدادات
  - دعم إعدادات اللغة والوضع المظلم
  - _Requirements: 7.4_

- [ ]* 15.3 كتابة اختبار خاصية: Account deletion
  - **Property 23: Account deletion removes all data**
  - **Validates: Requirements 8.3**

- [ ]* 15.4 كتابة اختبار خاصية: Preferences persistence
  - **Property 24: User preferences persistence**
  - **Validates: Requirements 7.4**

- [x] 15.5 بناء واجهة المستخدم للإعدادات


  - إنشاء SettingsScreen
  - إضافة Language toggle
  - إضافة Dark Mode toggle
  - إضافة Account Management section
  - إضافة Delete Account button مع تأكيد
  - _Requirements: 7.4, 8.3_

- [x] 16. إعداد قواعد الأمان في Firebase

- [x] 16.1 كتابة Firestore Security Rules
  - قواعد users collection
  - قواعد chats و messages collections
  - قواعد stories collection
  - قواعد reports و blocks collections
  - _Requirements: 8.4_

- [x] 16.2 كتابة Storage Security Rules
  - قواعد profile_images
  - قواعد voice_messages
  - قواعد stories media
  - تحديد أحجام الملفات المسموحة
  - _Requirements: 8.2, 8.4_

- [x] 17. بناء الشاشة الرئيسية والتنقل

- [x] 17.1 إنشاء HomeScreen
  - إضافة StoryBarWidget في الأعلى
  - إضافة navigation bar في الأسفل
  - دمج جميع الوحدات (Chat, Discovery, Profile)
  - _Requirements: 5.4_

- [x] 17.2 إعداد Navigation
  - إنشاء AppRouter باستخدام go_router
  - إعداد deep linking للروابط المجهولة
  - إعداد auth guards للشاشات المحمية
  - _Requirements: 2.3_

- [ ] 18. التحسينات النهائية وتحسين التكلفة

- [ ] 18.1 تحسين الأداء للوصول إلى 10K مستخدم
  - إضافة pagination للرسائل والقصص
  - إضافة image caching
  - تحسين Firestore queries مع indexes
  - إضافة loading states و shimmer effects
  - _Requirements: جميع المتطلبات_

- [ ] 18.2 تحسين معالجة الأخطاء
  - إضافة error boundaries
  - تحسين رسائل الخطأ بالعربية
  - إضافة retry logic للعمليات الفاشلة
  - إضافة offline support
  - _Requirements: جميع المتطلبات_

- [ ]* 18.3 كتابة اختبارات تكامل
  - اختبار تدفق التسجيل الكامل
  - اختبار تدفق إرسال رسالة كامل
  - اختبار تدفق نشر قصة كامل
  - اختبار تدفق الحظر والإبلاغ
  - _Requirements: جميع المتطلبات_

- [ ] 19. تحسين التكلفة للوصول إلى 10K مستخدم (الهدف: <$100/شهر)

- [ ] 19.1 تحسين تكلفة Firestore
  - تطبيق استراتيجية الـ pagination في جميع القوائم (20 عنصر لكل صفحة)
  - تقليل عدد Real-time listeners (فقط للدردشة النشطة)
  - استخدام cache للبيانات التي لا تتغير كثيراً (ملفات المستخدمين)
  - تحديد TTL للـ cache (1 ساعة للملفات، 5 دقائق للقوائم)
  - _Target: تقليل Firestore reads من 10M إلى 3M شهرياً_

- [ ] 19.2 تحسين تكلفة التخزين والباندويث
  - ضغط الصور قبل الرفع (max 1MB لكل صورة)
  - تحويل الصور إلى WebP format
  - إنشاء thumbnails للصور (200x200 للأفاتار، 400x400 للقصص)
  - استخدام lazy loading للصور
  - تفعيل browser caching (7 أيام للصور)
  - _Target: تقليل Storage من 100GB إلى 30GB_
  - _Target: تقليل Bandwidth من 500GB إلى 100GB_

- [ ] 19.3 تحسين Cloud Functions
  - دمج Cloud Functions المتشابهة في function واحدة
  - استخدام batching للعمليات (تحديث metadata كل 5 ثواني بدلاً من كل رسالة)
  - تقليل cold starts بـ keep-alive pings
  - تحسين memory allocation (256MB بدلاً من 512MB)
  - _Target: تقليل invocations من 5M إلى 2M شهرياً_

- [ ] 19.4 مراقبة التكاليف وإنشاء Alerts
  - إنشاء Firebase Budget Alerts
    - Alert عند $50/شهر
    - Alert عند $75/شهر
    - Alert عند $100/شهر
  - إنشاء Dashboard لمراقبة التكاليف اليومية
  - تتبع أكثر العمليات تكلفة
  - إنشاء تقرير شهري بالتكاليف
  - _Target: شفافية كاملة للتكاليف_

- [ ] 19.5 اختبار الحمل والتكلفة
  - إنشاء 1000 مستخدم تجريبي
  - محاكاة نشاط واقعي (50 رسالة/يوم لكل مستخدم)
  - قياس التكلفة الفعلية لـ 1000 مستخدم
  - حساب التكلفة المتوقعة لـ 10,000 مستخدم
  - التحقق من أن التكلفة < $100/شهر
  - _Target: validation للتكاليف المتوقعة_

- [ ] 20. اختبارات الخصائص (Property-Based Tests)

- [ ]* 20.1 اختبارات نماذج البيانات
  - اختبار toJson/fromJson لجميع النماذج (100 iteration)
  - اختبار الحالات الحدية (null values, missing fields)
  - استخدام faker package لبيانات عشوائية
  - _Property: Data serialization round-trip preserves data_

- [ ]* 20.2 اختبارات التوثيق
  - Property 1: OTP verification success creates or authenticates user
  - Property 2: Rate limiting after 3 failed attempts (5 minutes block)
  - Property 3: OTP resend cooldown (60 seconds)
  - _Requirements: 1.2, 1.3, 1.4_

- [ ]* 20.3 اختبارات الملف الشخصي
  - Property 4: Profile image upload updates URL
  - Property 5: Blur effect application
  - Property 6: Anonymous link uniqueness
  - Property 7: Profile update round trip preserves data
  - _Requirements: 2.1, 2.2, 2.3, 2.5_

- [ ]* 20.4 اختبارات الدردشة
  - Property 8: Message sending adds to chat
  - Property 9: Voice message has valid URL
  - Property 10: Real-time message streaming
  - Property 11: Message chronological ordering
  - _Requirements: 3.1, 3.2, 3.3, 3.5_

- [ ]* 20.5 اختبارات الاستكشاف
  - Property 12: Country filter matching
  - Property 13: Dialect filter matching
  - Property 14: Multiple filters conjunction (AND logic)
  - Property 15: Blocked users exclusion from results
  - _Requirements: 4.2, 4.3, 4.4, 4.5_

- [ ]* 20.6 اختبارات القصص
  - Property 16: Story expiration time (24 hours)
  - Property 17: Expired stories exclusion from feed
  - Property 18: Story view recording
  - Property 19: Stories chronological ordering
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ]* 20.7 اختبارات الأمان
  - Property 20: Block prevents access to profile and chat
  - Property 21: Report creation with pending status
  - Property 22: Report action updates status correctly
  - _Requirements: 6.1, 6.2, 6.4_

- [ ]* 20.8 اختبارات إدارة البيانات
  - Property 23: Account deletion removes all user data
  - Property 24: User preferences persistence across sessions
  - _Requirements: 8.3, 7.4_

- [ ] 21. Checkpoint النهائي - التأكد من نجاح جميع الاختبارات
  - التأكد من نجاح جميع الاختبارات
  - التحقق من التكلفة الشهرية < $100
  - قياس أداء التطبيق (response time, loading time)
  - إعداد تقرير نهائي بالإحصائيات
  - استشر المستخدم إذا ظهرت أسئلة
