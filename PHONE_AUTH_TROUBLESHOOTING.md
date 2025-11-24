# Phone Authentication Troubleshooting Guide

## Common Issues and Solutions

### 1. Phone Authentication Not Enabled

**Problem**: Firebase returns an error because Phone authentication is not enabled.

**Solution**:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `social-connect-app-57fc0`
3. Go to **Authentication** → **Sign-in method**
4. Find **Phone** in the list
5. Click on it and toggle **Enable**
6. Save changes

### 2. Android: Missing SHA Fingerprints

**Problem**: On Android, you get errors like "operation-not-allowed" or "invalid-app-credential"

**Solution**:

#### Get your SHA-1 and SHA-256 fingerprints:

**For Debug Build:**
```bash
cd android
gradlew signingReport
```

Or using keytool:
```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**For Release Build:**
```bash
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

#### Add fingerprints to Firebase:
1. Go to Firebase Console → Project Settings
2. Scroll down to "Your apps" section
3. Click on your Android app
4. Click "Add fingerprint"
5. Paste your SHA-1 and SHA-256 fingerprints
6. Download the updated `google-services.json`
7. Replace `android/app/google-services.json` with the new file

### 3. iOS: Missing APNs Configuration

**Problem**: On iOS, phone auth doesn't work without APNs (Apple Push Notification service)

**Solution**:
1. You need an Apple Developer account
2. Enable Push Notifications in Xcode:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner → Signing & Capabilities
   - Click "+ Capability" → Push Notifications
3. Upload APNs certificate to Firebase:
   - Go to Firebase Console → Project Settings → Cloud Messaging
   - Upload your APNs Authentication Key or Certificate

**For Development/Testing on iOS**: Use test phone numbers (see below)

### 4. Testing Without Real SMS

**Problem**: You want to test without sending real SMS messages

**Solution**: Add test phone numbers in Firebase Console

1. Go to Firebase Console → Authentication → Sign-in method
2. Scroll down to "Phone numbers for testing"
3. Add test phone numbers with verification codes:
   - Phone: `+1 650-555-1234` → Code: `123456`
   - Phone: `+966 50 000 0000` → Code: `123456`
4. Use these numbers in your app - they will auto-verify without sending SMS

### 5. Rate Limiting / Quota Exceeded

**Problem**: Error "quota-exceeded" or "too-many-requests"

**Solution**:
- Firebase has daily SMS quota limits
- For testing, use test phone numbers (see above)
- For production, you may need to upgrade your Firebase plan
- Wait a few hours before trying again

### 6. Network Issues

**Problem**: Error "network-request-failed"

**Solution**:
- Check your internet connection
- Make sure your device/emulator has internet access
- Try disabling VPN if you're using one
- Check if Firebase services are down: https://status.firebase.google.com/

### 7. Invalid Phone Number Format

**Problem**: Error "invalid-phone-number"

**Solution**:
- Phone number must be in E.164 format: `+[country code][number]`
- Examples:
  - Saudi Arabia: `+966501234567`
  - USA: `+16505551234`
  - Egypt: `+201234567890`
- The app should handle this automatically with the country code selector

## Quick Checklist

Before testing phone authentication:

- [ ] Phone authentication is enabled in Firebase Console
- [ ] For Android: SHA-1 and SHA-256 fingerprints are added
- [ ] For iOS: APNs is configured OR using test phone numbers
- [ ] Test phone numbers are configured (recommended for development)
- [ ] Internet connection is working
- [ ] Phone number is in correct format (+country code + number)

## Testing Steps

1. **Add a test phone number** in Firebase Console (recommended):
   - Phone: `+966500000000`
   - Code: `123456`

2. **Run the app**:
   ```bash
   flutter run
   ```

3. **Enter the test phone number** in the app

4. **Enter the test code** `123456` when prompted

5. **Should work without sending real SMS**

## Getting More Information

To see detailed error messages, check the console output when running:
```bash
flutter run
```

Look for Firebase-related errors in the logs.

## Still Having Issues?

If you're still getting errors:

1. **Check the exact error message** in the console
2. **Verify Firebase project ID** matches in `firebase_options.dart`
3. **Try with a test phone number** first
4. **Check Firebase Console** → Authentication → Users to see if any users were created
5. **Look at Firebase Console** → Authentication → Sign-in method → Phone → Usage to see if requests are being received

## Common Error Messages

| Error Code | Meaning | Solution |
|------------|---------|----------|
| `operation-not-allowed` | Phone auth not enabled | Enable in Firebase Console |
| `invalid-phone-number` | Wrong format | Use E.164 format (+country code) |
| `quota-exceeded` | Too many SMS sent | Use test numbers or wait |
| `invalid-app-credential` | Missing SHA fingerprints (Android) | Add SHA-1/SHA-256 to Firebase |
| `network-request-failed` | No internet | Check connection |
| `too-many-requests` | Rate limited | Wait and try again |
