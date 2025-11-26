# Week 3 - Quick Start Guide

**Status:** ✅ Implementation Complete  
**Time to Deploy:** ~15 minutes  
**Cost:** ~$1.50/month (10K users)

---

## 🚀 Deploy in 5 Commands

```bash
# 1. Install dependencies
cd functions && npm install

# 2. Deploy storage rules
firebase deploy --only storage

# 3. Deploy Cloud Functions
firebase deploy --only functions

# 4. Update Flutter app
cd .. && flutter pub get

# 5. Run app
flutter run
```

**That's it!** Your infrastructure is live.

---

## 📋 What Was Deployed

### 5 Cloud Functions

| Function | Purpose | Trigger |
|----------|---------|---------|
| **onMessageSent** | Update chat metadata | New message created |
| **sendPushNotification** | Send FCM notifications | New message created |
| **cleanupExpiredStories** | Delete old stories | Every 1 hour |
| **updateUserMetrics** | Track analytics | HTTPS call |
| **onUserCreated** | Initialize users | New user created |

### 2 New Services

- **Performance Monitoring** - Automatic app tracking
- **Firebase Analytics** - Event logging

---

## ✅ Verify Deployment

```bash
# Check functions deployed
firebase functions:list

# View logs
firebase functions:log --limit 10

# Test in app
# 1. Send a message → Check push notification
# 2. Create a story → Check auto-deletion after 24h
# 3. View performance data in Firebase Console
```

---

## 📊 Expected Results

### Chat Functionality
- ✅ `lastMessage` auto-updates
- ✅ `unreadCount` auto-increments
- ✅ Push notifications sent to recipient

### Stories
- ✅ Auto-delete after 24 hours
- ✅ `activeStoryCount` auto-updates
- ✅ Media files removed from Storage

### Performance
- ✅ App traces in Firebase Console
- ✅ Screen views tracked
- ✅ Custom events logged

---

## 💰 Cost Estimate

**10K Active Users:**
- Cloud Functions: $0.50/month
- Firebase Hosting: $1.00/month
- FCM: FREE
- Performance: FREE
- Analytics: FREE

**Total: ~$1.50/month** ✅

---

## 🐛 Quick Troubleshooting

### Functions not deploying?
```bash
gcloud services enable cloudfunctions.googleapis.com
firebase deploy --only functions
```

### Push notifications not working?
- Check FCM token exists in user document
- Verify app has notification permissions
- Enable Firebase Cloud Messaging API in GCP

### Story cleanup not running?
```bash
gcloud services enable cloudscheduler.googleapis.com
gcloud scheduler jobs run firebase-schedule-cleanupExpiredStories
```

---

## 📚 Full Documentation

- **Implementation Details:** `docs/WEEK3_IMPLEMENTATION.md`
- **Deployment Guide:** `docs/DEPLOYMENT_GUIDE_WEEK3.md`
- **Functions Reference:** `functions/README.md`
- **Scaling Strategy:** `docs/SCALING_ROADMAP.md`
- **Summary:** `WEEK3_COMPLETE.md`

---

## 🎯 Next Steps

1. **Monitor for 24 hours**
   - Check function logs
   - Verify costs
   - Test all features

2. **Performance test**
   - Send 100 messages
   - Create 50 stories
   - Check response times

3. **Scale when ready**
   - Follow `docs/SCALING_ROADMAP.md`
   - Plan migration at 50K users
   - Execute at 100K users

---

**Ready to deploy? Run the 5 commands above! 🚀**

Questions? Check the full docs or Firebase Console logs.
