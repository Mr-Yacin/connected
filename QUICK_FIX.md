# 🚨 QUICK FIX GUIDE - Exposed Firebase Keys

## ⚠️ DO THIS NOW (5 Minutes)

### Step 1: Regenerate API Keys (MOST IMPORTANT!)

1. **Open Google Cloud Console:**
   👉 https://console.cloud.google.com/apis/credentials?project=social-connect-app-57fc0

2. **For EACH of these keys, click and REGENERATE:**
   - ❌ `AIzaSyC8rF8vN5lwCu1--GXTkRfEE` (Web/Windows)
   - ❌ `AIzaSyA6u4wr94SUN6uwWD3gIqvx0H1gmUqd7Us` (Android)
   - ❌ `AIzaSyBTUpp5v-ZOYrWCYtyq79tF6KXpPGlAujE` (iOS/macOS)

3. **Add restrictions to each new key:**
   - Android: Restrict to your app package name
   - iOS: Restrict to your bundle ID
   - Web: Restrict to your domain

---

### Step 2: Update Your Local Config

```bash
# Option A: Automatic (Recommended)
flutterfire configure

# Option B: Manual
# Edit lib/firebase_options.dart and replace the old keys with new ones
```

---

### Step 3: Test Your App

```bash
flutter run
# Make sure authentication and Firebase features still work
```

---

### Step 4: Clean Git History (Removes exposed keys from GitHub)

```bash
# Run the cleanup script
.\cleanup-git-history.ps1

# Then force push
git push origin --force --all
```

---

### Step 5: Verify

1. ✅ Check that old URL returns 404:
   https://github.com/Mr-Yacin/connected/blob/068cab74b23c6d0dd1114f6f87d1db8fb4b78e9f/lib/firebase_options.dart

2. ✅ Check that `lib/firebase_options.dart` doesn't appear in any commit on GitHub

3. ✅ Monitor Google Cloud Console for unusual activity:
   https://console.cloud.google.com/apis/dashboard?project=social-connect-app-57fc0

---

## ✅ Files Changed

- ✅ `.gitignore` - Now blocks `firebase_options.dart`
- ✅ `SECURITY_FIX_README.md` - Full detailed guide
- ✅ `lib/firebase_options.dart.template` - Template for team members
- ✅ `cleanup-git-history.ps1` - Script to clean Git history

---

## 📞 Need Help?

- Read the full guide: `SECURITY_FIX_README.md`
- Firebase Security Docs: https://firebase.google.com/docs/projects/api-keys
- Contact Google Cloud Support if you see unauthorized usage

---

**Priority:** 🔴 **CRITICAL - Do this before continuing development!**
