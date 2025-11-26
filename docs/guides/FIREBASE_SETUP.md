# إعداد Firebase للمشروع

## الخطوات المطلوبة

### 1. إنشاء مشروع Firebase

1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. انقر على "Add project" أو "إضافة مشروع"
3. أدخل اسم المشروع: `social-connect-app`
4. اتبع الخطوات لإنشاء المشروع

### 2. تفعيل الخدمات المطلوبة

في Firebase Console، قم بتفعيل:

- **Authentication**: اذهب إلى Authentication > Sign-in method > Phone
- **Cloud Firestore**: اذهب إلى Firestore Database > Create database
- **Storage**: اذهب إلى Storage > Get started

### 3. إعداد التطبيق للمنصات

#### تثبيت FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

#### تكوين Firebase للمشروع

```bash
flutterfire configure
```

سيقوم هذا الأمر بـ:
- إنشاء ملف `firebase_options.dart` بالإعدادات الصحيحة
- تكوين Android و iOS تلقائياً

### 4. إعداد Android

سيتم إعداد Android تلقائياً عند تشغيل `flutterfire configure`، لكن تأكد من:

1. الملف `android/app/google-services.json` موجود
2. في `android/build.gradle.kts`:
```kotlin
dependencies {
    classpath("com.google.gms:google-services:4.4.0")
}
```

3. في `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

### 5. إعداد iOS

سيتم إعداد iOS تلقائياً عند تشغيل `flutterfire configure`، لكن تأكد من:

1. الملف `ios/Runner/GoogleService-Info.plist` موجود
2. افتح `ios/Runner.xcworkspace` في Xcode
3. تأكد من إضافة GoogleService-Info.plist إلى المشروع

### 6. قواعد الأمان

بعد إعداد Firebase، قم بتطبيق قواعد الأمان من ملف التصميم:

#### Firestore Security Rules

اذهب إلى Firestore Database > Rules والصق القواعد من `design.md`

#### Storage Security Rules

اذهب إلى Storage > Rules والصق القواعد من `design.md`

### 7. التحقق من الإعداد

بعد إكمال الخطوات، قم بتشغيل:

```bash
flutter run
```

يجب أن يعمل التطبيق بدون أخطاء Firebase.

## ملاحظات

- الملف الحالي `lib/firebase_options.dart` هو ملف مؤقت للسماح بالتطوير
- يجب استبداله بالملف الذي يتم إنشاؤه من `flutterfire configure`
- لا تشارك ملفات الإعدادات (google-services.json, GoogleService-Info.plist) في Git
