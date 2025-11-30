# 🔐 How to Add API Key Restrictions - Step by Step

## Why Add Restrictions?

API key restrictions ensure that even if someone gets your key, they can't use it from unauthorized apps or domains. This is your **second line of defense**.

---

## Step-by-Step Guide

### 1️⃣ **Open Google Cloud Console**

👉 **Go to:** https://console.cloud.google.com/apis/credentials?project=social-connect-app-57fc0

Make sure you're logged in with the correct Google account.

---

### 2️⃣ **Find Your API Keys**

On the "Credentials" page, you'll see a list of API keys. Look for:
- Browser key (Web/Windows)
- Android key  
- iOS key

Each key will have a name like "Browser key (auto created by Firebase)" or "Android key (auto created by Firebase)".

---

### 3️⃣ **Restrict EACH Key**

Click on **each key name** to open its settings, then follow the specific instructions below:

---

## 🌐 **For Web/Windows API Key**

### Step 1: Click on your Web/Browser key

### Step 2: Application Restrictions
1. Under "Application restrictions", select: **"HTTP referrers (web sites)"**
2. Click **"+ Add an item"**
3. Add these referrers (one by one):
   ```
   social-connect-app-57fc0.firebaseapp.com/*
   social-connect-app-57fc0.web.app/*
   localhost:*
   ```
4. Click **"Done"**

### Step 3: API Restrictions
1. Under "API restrictions", select: **"Restrict key"**
2. Select these APIs (scroll through the list):
   - ✅ Firebase Authentication API
   - ✅ Cloud Firestore API  
   - ✅ Cloud Storage JSON API
   - ✅ Firebase Cloud Messaging API
   - ✅ Identity Toolkit API
   - ✅ Token Service API
3. Click **"OK"**

### Step 4: Save
Click the blue **"Save"** button at the top or bottom of the page.

---

## 🤖 **For Android API Key**

### Step 1: Click on your Android key

### Step 2: Application Restrictions
1. Under "Application restrictions", select: **"Android apps"**
2. Click **"+ Add an item"**
3. Enter:
   - **Package name:** `com.socialconnect.socialConnectApp`
   - **SHA-1 certificate fingerprint:** (see below how to get this)
4. Click **"Done"**

#### 📝 How to Get Your SHA-1 Fingerprint:

**Option A: For Debug/Development (Easy)**
```bash
cd android
./gradlew signingReport
```
Look for the **debug** keystore SHA-1 and copy it.

**Option B: For Release (If you have a release keystore)**
```bash
keytool -list -v -keystore path/to/your-release-key.keystore -alias your-key-alias
```
Copy the SHA-1 fingerprint.

**Option C: From Google Play Console (If published)**
1. Go to Google Play Console → Your App → Setup → App integrity
2. Copy the SHA-1 certificate fingerprint

### Step 3: API Restrictions
1. Under "API restrictions", select: **"Restrict key"**
2. Select these APIs:
   - ✅ Firebase Authentication API
   - ✅ Cloud Firestore API
   - ✅ Cloud Storage JSON API
   - ✅ Firebase Cloud Messaging API
   - ✅ Identity Toolkit API
   - ✅ Token Service API
3. Click **"OK"**

### Step 4: Save
Click the blue **"Save"** button.

---

## 🍎 **For iOS API Key**

### Step 1: Click on your iOS key

### Step 2: Application Restrictions
1. Under "Application restrictions", select: **"iOS apps"**
2. Click **"+ Add an item"**
3. Enter:
   - **Bundle ID:** `com.socialconnect.socialConnectApp`
4. Click **"Done"**

### Step 3: API Restrictions
1. Under "API restrictions", select: **"Restrict key"**
2. Select these APIs:
   - ✅ Firebase Authentication API
   - ✅ Cloud Firestore API
   - ✅ Cloud Storage JSON API
   - ✅ Firebase Cloud Messaging API
   - ✅ Identity Toolkit API
   - ✅ Token Service API
3. Click **"OK"**

### Step 4: Save
Click the blue **"Save"** button.

---

## 🎯 **Quick Verification**

After adding restrictions, verify they were applied:

1. Go back to the credentials list
2. Each key should now show:
   - "Android apps" or "iOS apps" or "HTTP referrers" under restrictions
   - "Restricted key" under API restrictions

---

## ⚠️ **Important Notes**

### 1. **Testing After Restrictions**
After adding restrictions, **test your app** to make sure it still works:
```bash
flutter run
```

### 2. **Common Issues**

**"API key not valid" error?**
- ✅ Make sure you added the correct package name/bundle ID
- ✅ For Android, make sure you added the correct SHA-1 fingerprint
- ✅ Wait 5-10 minutes for restrictions to take effect

**App works locally but not in production?**
- ✅ For Android, make sure you added BOTH debug AND release SHA-1 fingerprints
- ✅ For Web, make sure you added your production domain

### 3. **Multiple SHA-1 Fingerprints**
For Android, you can (and should) add multiple SHA-1 fingerprints:
- Debug fingerprint (for local testing)
- Release fingerprint (for production)
- Google Play signing fingerprint (if using Play App Signing)

Just click "+ Add an item" again for the same package name with different SHA-1.

---

## 📋 **Checklist**

Mark these off as you complete them:

- [ ] Opened Google Cloud Console credentials page
- [ ] Restricted Web/Windows API key with HTTP referrers
- [ ] Restricted Android API key with package name + SHA-1
- [ ] Restricted iOS API key with bundle ID
- [ ] Added API restrictions to all keys (Firebase APIs only)
- [ ] Saved all changes
- [ ] Tested app - Firebase auth works
- [ ] Tested app - Firestore works
- [ ] Tested app - Storage works

---

## 🆘 **Still Stuck?**

### Visual Guide Link:
📹 Watch this video: [How to Restrict Firebase API Keys](https://www.youtube.com/results?search_query=how+to+restrict+firebase+api+keys)

### Support:
- Firebase Documentation: https://firebase.google.com/docs/projects/api-keys
- Google Cloud Support: https://cloud.google.com/support

---

**Last Updated:** 2025-11-30  
**Project:** social-connect-app-57fc0  
