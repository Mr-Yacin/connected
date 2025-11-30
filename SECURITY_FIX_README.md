# 🔐 Security Fix: Exposed Firebase API Keys

## ⚠️ **CRITICAL: Immediate Actions Required**

Your Firebase API keys were exposed in your GitHub repository. Follow these steps **immediately**:

---

## 1. **Regenerate ALL Exposed API Keys** (MUST DO FIRST!)

The following keys were exposed and **MUST be regenerated**:
- Web API Key: `AIzaSyC8rF8vN5lwCu1--GXTkRfEE`
- Android API Key: `AIzaSyA6u4wr94SUN6uwWD3gIqvx0H1gmUqd7Us`
- iOS API Key: `AIzaSyBTUpp5v-ZOYrWCYtyq79tF6KXpPGlAujE`

### Steps to Regenerate Keys:

1. **Go to Google Cloud Console:**
   - Visit: https://console.cloud.google.com/apis/credentials?project=social-connect-app-57fc0
   
2. **For EACH exposed API key:**
   - Find the key in the list
   - Click on the key name
   - Click "REGENERATE KEY" or "DELETE" and create a new one
   - Note down the new API key
   - Add appropriate restrictions (see below)

3. **Restrict Your New API Keys:**
   
   **For Android:**
   - Application restrictions: Android apps
   - Add your package name: `com.socialconnect.socialConnectApp`
   - Add your SHA-1 certificate fingerprint
   - API restrictions: Limit to Firebase services only
   
   **For iOS:**
   - Application restrictions: iOS apps
   - Add your bundle ID: `com.socialconnect.socialConnectApp`
   - API restrictions: Limit to Firebase services only
   
   **For Web:**
   - Application restrictions: HTTP referrers
   - Add your domain(s): `social-connect-app-57fc0.firebaseapp.com`
   - API restrictions: Limit to Firebase services only

---

## 2. **Update Your Local Configuration**

After regenerating the keys:

```bash
# Run FlutterFire configure to regenerate firebase_options.dart with NEW keys
flutterfire configure
```

Or manually update `lib/firebase_options.dart` with your new keys (it's now gitignored).

---

## 3. **Clean Git History** (Remove Exposed Keys from GitHub)

⚠️ **WARNING:** This will rewrite Git history. Coordinate with your team!

### Option A: Using BFG Repo-Cleaner (Recommended)

```bash
# Install BFG (if not already installed)
# Download from: https://rtyley.github.io/bfg-repo-cleaner/

# Clone a fresh copy of your repo
git clone --mirror https://github.com/Mr-Yacin/connected.git

# Remove the file from history
java -jar bfg.jar --delete-files firebase_options.dart connected.git

# Clean up
cd connected.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push (⚠️ DANGER: rewrites history!)
git push --force
```

### Option B: Using git-filter-repo

```bash
# Install git-filter-repo
# pip install git-filter-repo

# Remove the file from history
git filter-repo --path lib/firebase_options.dart --invert-paths

# Force push
git push --force --all
```

### Option C: Simple approach (if repo is new/small)

If this is a new repository or you don't have many collaborators:

1. **Delete the GitHub repository** entirely
2. **Create a new repository**
3. **Push your code** (with the fixes already in place)

---

## 4. **Monitor Your Google Cloud Project**

1. **Check Firebase Authentication logs:**
   - https://console.firebase.google.com/project/social-connect-app-57fc0/authentication/users

2. **Check for unauthorized usage:**
   - https://console.cloud.google.com/apis/dashboard?project=social-connect-app-57fc0

3. **Set up budget alerts:**
   - https://console.cloud.google.com/billing
   - Create alerts if usage spikes unexpectedly

---

## 5. **Future Prevention**

✅ **Already Done:**
- Added `firebase_options.dart` to `.gitignore`
- Created `firebase_options.dart.template` for team members

✅ **Best Practices Going Forward:**
- Never commit API keys, secrets, or credentials
- Use environment variables for sensitive data
- Always run `flutterfire configure` locally (don't commit the output)
- Review files before committing with `git diff`
- Consider using GitHub Secret Scanning alerts

---

## 6. **Team Setup Instructions**

For other developers setting up this project:

```bash
# 1. Clone the repository
git clone https://github.com/Mr-Yacin/connected.git

# 2. Run FlutterFire configure (this creates firebase_options.dart locally)
flutterfire configure

# 3. The firebase_options.dart file is gitignored and stays local
```

---

## ✅ **Checklist**

Before continuing development, ensure you've completed:

- [ ] Regenerated ALL exposed API keys in Google Cloud Console
- [ ] Added API key restrictions (Android, iOS, Web)
- [ ] Ran `flutterfire configure` to update local config
- [ ] Cleaned Git history to remove exposed keys
- [ ] Force-pushed the cleaned history to GitHub
- [ ] Verified the keys don't appear in GitHub's web interface
- [ ] Set up Google Cloud budget alerts
- [ ] Deleted this file after completing all steps

---

## 📚 **Resources**

- [Firebase API Key Security](https://firebase.google.com/docs/projects/api-keys)
- [Google Cloud API Key Best Practices](https://cloud.google.com/docs/authentication/api-keys)
- [Git History Cleanup](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)

---

**Last Updated:** 2025-11-30
**Status:** ⚠️ ACTION REQUIRED
