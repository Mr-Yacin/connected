# 🔐 Security Incident - Exposed API Keys (Nov 30, 2025)

## Status: ✅ RESOLVED

This document consolidates the security incident where Firebase API keys were accidentally exposed in GitHub.

---

## Incident Summary

**Date:** November 30, 2025  
**Issue:** Firebase API keys were committed to public GitHub repository  
**Affected Commit:** `068cab74b23c6d0dd1114f6f87d1db8fb4b78e9f`  
**Status:** Fully resolved and secured

### Exposed Keys (Now Regenerated)
- Web API Key: `AIzaSyC8rF8vN5lwCu1--GXTkRfEE` ✅ Regenerated
- Android API Key: `AIzaSyA6u4wr94SUN6uwWD3gIqvx0H1gmUqd7Us` ✅ Regenerated
- iOS API Key: `AIzaSyBTUpp5v-ZOYrWCYtyq79tF6KXpPGlAujE` ✅ Regenerated

---

## Actions Taken

### ✅ Completed Steps

1. **API Keys Regenerated**
   - All 3 exposed keys regenerated in Google Cloud Console
   - New keys configured with proper restrictions

2. **Local Configuration Updated**
   - Ran `flutterfire configure`
   - New keys deployed to all platforms

3. **Git History Cleaned**
   - Used cleanup script to remove keys from all commits
   - Force pushed cleaned history to GitHub
   - Old commit URL now returns 404 ✅

4. **Prevention Measures**
   - Added `firebase_options.dart` to `.gitignore`
   - Created `firebase_options.dart.template` for team members
   - Documented best practices

5. **API Key Restrictions Applied**
   - Android: Package name + SHA-1 fingerprint
   - iOS: Bundle ID restriction
   - Web: HTTP referrer restrictions
   - API restrictions: Limited to Firebase services only

---

## API Key Restrictions Guide

### Android Key Restrictions
- **Application restrictions:** Android apps
- **Package name:** `com.socialconnect.socialConnectApp`
- **SHA-1 fingerprint:** Required (get via `./gradlew signingReport`)
- **API restrictions:** Firebase services only

### iOS Key Restrictions
- **Application restrictions:** iOS apps
- **Bundle ID:** `com.socialconnect.socialConnectApp`
- **API restrictions:** Firebase services only

### Web/Windows Key Restrictions
- **Application restrictions:** HTTP referrers
- **Allowed referrers:**
  - `social-connect-app-57fc0.firebaseapp.com/*`
  - `social-connect-app-57fc0.web.app/*`
  - `localhost:*` (for testing)
- **API restrictions:** Firebase services only

---

## Verification Checklist

- [✅] All 3 API keys regenerated
- [✅] API key restrictions added
- [✅] Local config updated (`flutterfire configure`)
- [✅] Git history cleaned
- [✅] Force pushed to GitHub
- [✅] Old URL returns 404
- [✅] App tested with new keys
- [✅] Monitoring setup for 24-48 hours
- [✅] No unauthorized usage detected

---

## How to Get SHA-1 Fingerprint

For Android key restrictions:

```bash
# Debug fingerprint
cd android
./gradlew signingReport

# Release fingerprint
keytool -list -v -keystore path/to/release-key.keystore -alias key-alias
```

---

## Lessons Learned

1. **Never commit** `firebase_options.dart` to version control
2. **Always use** `.gitignore` for sensitive configuration files
3. **Review changes** before committing with `git diff`
4. **Restrict API keys** immediately upon creation
5. **Monitor** Google Cloud Console for unusual activity

---

## Future Prevention

### For New Developers
```bash
# 1. Clone repository
git clone https://github.com/Mr-Yacin/connected.git

# 2. Run FlutterFire configure (creates firebase_options.dart locally)
flutterfire configure

# 3. File stays local (gitignored)
```

### Best Practices
- ✅ Use environment variables for sensitive data
- ✅ Run `flutterfire configure` locally
- ✅ Enable GitHub Secret Scanning alerts
- ✅ Review commits before pushing
- ✅ Restrict all API keys immediately

---

## Resources

- **Google Cloud Console:** https://console.cloud.google.com/apis/credentials?project=social-connect-app-57fc0
- **Firebase Console:** https://console.firebase.google.com/project/social-connect-app-57fc0
- **Firebase API Key Security:** https://firebase.google.com/docs/projects/api-keys
- **Git History Cleanup:** https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository

---

**Incident Closed:** November 30, 2025  
**No further action required**
