# Week 3 Deployment Guide - Step by Step

This guide walks you through deploying Week 3 infrastructure components step by step.

---

## 📋 Pre-Deployment Checklist

Before deploying, ensure you have:

- [ ] Firebase CLI installed (`npm install -g firebase-tools`)
- [ ] Logged into Firebase (`firebase login`)
- [ ] Selected correct project (`firebase use social-connect-app-57fc0`)
- [ ] Node.js 18+ installed
- [ ] Flutter SDK installed
- [ ] Git repository up to date

---

## 🚀 Deployment Steps

### Step 1: Install Cloud Functions Dependencies

```bash
cd functions
npm install
```

**Expected Output:**
```
added 234 packages in 15s
```

**Verify:**
```bash
npm list
```

Should show:
- firebase-admin@^12.0.0
- firebase-functions@^5.0.0

---

### Step 2: Test Functions Locally (Optional but Recommended)

```bash
# Start Firebase Emulator
npm run serve
```

**Expected Output:**
```
✔ functions[us-central1-onMessageSent]: http function initialized
✔ functions[us-central1-sendPushNotification]: http function initialized
✔ functions[us-central1-cleanupExpiredStories]: scheduled function initialized
```

**Test in Browser:**
- Emulator UI: http://localhost:4000
- Functions: http://localhost:5001

**Stop Emulator:** Press `Ctrl+C`

---

### Step 3: Deploy Storage Rules

```bash
# From project root
firebase deploy --only storage
```

**Expected Output:**
```
✔ Deploy complete!

Project Console: https://console.firebase.google.com/project/social-connect-app-57fc0/overview
```

**Verify:**
1. Go to Firebase Console > Storage > Rules
2. Should see updated rules with WebP support and thumbs folders

---

### Step 4: Deploy Cloud Functions

```bash
firebase deploy --only functions
```

**Expected Output:**
```
=== Deploying to 'social-connect-app-57fc0'...

i  deploying functions
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudbuild.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
✔  functions: required API cloudbuild.googleapis.com is enabled
i  functions: preparing codebase default for deployment
i  functions: updating Node.js 18 function onMessageSent(us-central1)...
i  functions: updating Node.js 18 function sendPushNotification(us-central1)...
i  functions: updating Node.js 18 function cleanupExpiredStories(us-central1)...
i  functions: updating Node.js 18 function updateUserMetrics(us-central1)...
i  functions: updating Node.js 18 function onUserCreated(us-central1)...

✔  functions[onMessageSent(us-central1)] Successful update operation.
✔  functions[sendPushNotification(us-central1)] Successful update operation.
✔  functions[cleanupExpiredStories(us-central1)] Successful update operation.
✔  functions[updateUserMetrics(us-central1)] Successful update operation.
✔  functions[onUserCreated(us-central1)] Successful update operation.

✔  Deploy complete!
```

**Deployment Time:** ~3-5 minutes

---

### Step 5: Enable Cloud Scheduler

The `cleanupExpiredStories` function requires Cloud Scheduler.

**Option A: Auto-Enable (Recommended)**

Cloud Scheduler will auto-enable when the scheduled function deploys.

**Option B: Manual Enable**

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: `social-connect-app-57fc0`
3. Search for "Cloud Scheduler API"
4. Click "Enable"

**Verify:**
```bash
gcloud scheduler jobs list --project=social-connect-app-57fc0
```

Should show:
```
ID: cleanupExpiredStories
SCHEDULE: every 1 hours
TIME_ZONE: UTC
```

---

### Step 6: Update Flutter App

```bash
# From project root
flutter pub get
```

**Expected Output:**
```
Running "flutter pub get" in connected...
Resolving dependencies...
+ firebase_analytics 11.3.5
+ firebase_performance 0.10.0+8
Changed 2 dependencies!
```

---

### Step 7: Test Flutter App Locally

```bash
flutter run
```

**Verify:**
1. App starts without errors
2. Check logs for:
   ```
   Firebase Performance Monitoring initialized
   Firebase Analytics initialized
   ```

---

### Step 8: Deploy Firebase Hosting (Web Only)

If you have a web version:

```bash
# Build Flutter web
flutter build web --release

# Deploy to hosting
firebase deploy --only hosting
```

**Expected Output:**
```
✔ hosting[social-connect-app-57fc0]: file upload complete
✔ hosting[social-connect-app-57fc0]: version finalized
✔ hosting[social-connect-app-57fc0]: release complete

Deploy complete!
Hosting URL: https://social-connect-app-57fc0.web.app
```

---

## ✅ Post-Deployment Verification

### Verify Cloud Functions

```bash
firebase functions:list
```

**Expected Output:**
```
┌─────────────────────────┬────────────┬─────────┐
│ Function                │ Region     │ Runtime │
├─────────────────────────┼────────────┼─────────┤
│ onMessageSent           │ us-central1│ nodejs18│
│ sendPushNotification    │ us-central1│ nodejs18│
│ cleanupExpiredStories   │ us-central1│ nodejs18│
│ updateUserMetrics       │ us-central1│ nodejs18│
│ onUserCreated           │ us-central1│ nodejs18│
└─────────────────────────┴────────────┴─────────┘
```

---

### Test onMessageSent Function

1. **Send a test message:**
   - Open app
   - Log in as User A
   - Send message to User B

2. **Verify in Firestore:**
   - Go to Firebase Console > Firestore
   - Open the chat document
   - Should see:
     - `lastMessage`: Your message text
     - `lastMessageTime`: Recent timestamp
     - `unreadCount.{userB_id}`: Incremented

3. **Check function logs:**
   ```bash
   firebase functions:log --only onMessageSent --limit 5
   ```

   Should show:
   ```
   Processing message msg123 in chat chat456
   Updated chat chat456 metadata successfully
   ```

---

### Test sendPushNotification Function

1. **Setup:**
   - Ensure FCM token is saved in user document
   - Recipient device has app installed
   - Recipient is logged out or app is closed

2. **Send test message:**
   - Log in as User A
   - Send message to User B

3. **Verify:**
   - User B's device should receive push notification
   - Notification should show:
     - Title: User A's name
     - Body: Message text
   - Tapping notification should open app to chat

4. **Check function logs:**
   ```bash
   firebase functions:log --only sendPushNotification --limit 5
   ```

   Should show:
   ```
   Sending push notification for chat chat456
   Push notification sent successfully: projects/.../messages/0:1234567890
   ```

---

### Test cleanupExpiredStories Function

**Option 1: Wait 1 Hour**

The function runs automatically every hour.

**Option 2: Manual Trigger (Recommended for Testing)**

```bash
gcloud scheduler jobs run firebase-schedule-cleanupExpiredStories-us-central1 \
  --project=social-connect-app-57fc0
```

**Verify:**
```bash
firebase functions:log --only cleanupExpiredStories --limit 5
```

Should show:
```
Starting expired stories cleanup
Found 5 expired stories
Deleted 5 expired stories
Deleted media file: stories/user123/story456.jpg
```

---

### Test updateUserMetrics Function

**Test with Flutter app:**

```dart
// Add to any screen
final functions = FirebaseFunctions.instance;
final result = await functions.httpsCallable('updateUserMetrics').call({
  'userId': currentUser.id,
  'metricType': 'message',
  'incrementBy': 1,
});

print(result.data); // Should print: {success: true}
```

**Verify in Firestore:**
- Open user document
- Check `messageCount` incremented
- Check `lastActiveAt` updated

---

### Test onUserCreated Function

1. **Create new user:**
   - Open app
   - Sign up with new phone number

2. **Verify in Firestore:**
   - Open newly created user document
   - Should have:
     - `messageCount`: 0
     - `storyCount`: 0
     - `profileViewCount`: 0
     - `activeStoryCount`: 0
     - `friendCount`: 0
     - `createdAt`: Timestamp
     - `lastActiveAt`: Timestamp

3. **Check notifications:**
   - Open notifications collection
   - Should see welcome notification for new user

---

### Monitor Performance

1. **Firebase Console > Performance**
   - Should see automatic traces:
     - App start time
     - Screen rendering
     - Network requests

2. **Check custom traces:**
   - Navigate through app
   - Go to Performance > Custom traces
   - Should see any custom traces you added

---

### Monitor Analytics

1. **Firebase Console > Analytics > Events**
   - Should see events:
     - `screen_view`
     - `message_sent` (if implemented)
     - `story_created` (if implemented)

2. **Real-time Users:**
   - Go to Analytics > Realtime
   - Should see active users count

---

## 🐛 Common Issues & Solutions

### Issue 1: Function deployment fails

**Error:**
```
Error: Failed to create function onMessageSent
```

**Solution:**
```bash
# Enable required APIs
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# Retry deployment
firebase deploy --only functions
```

---

### Issue 2: Cloud Scheduler not creating

**Error:**
```
Deployment error: Cloud Scheduler API is not enabled
```

**Solution:**
```bash
# Enable Cloud Scheduler API
gcloud services enable cloudscheduler.googleapis.com

# Re-deploy function
firebase deploy --only functions:cleanupExpiredStories
```

---

### Issue 3: Push notifications not working

**Checklist:**
- [ ] FCM token exists in user document
- [ ] Firebase Cloud Messaging API enabled
- [ ] App has notification permissions
- [ ] Correct FCM server key configured

**Debug:**
```bash
# Check function logs for errors
firebase functions:log --only sendPushNotification

# Test FCM manually
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "DEVICE_TOKEN",
    "notification": {
      "title": "Test",
      "body": "Test notification"
    }
  }'
```

---

### Issue 4: Functions timing out

**Error:**
```
Function execution took 60001 ms, finished with status: 'timeout'
```

**Solution:**
Update function timeout in `functions/index.js`:

```javascript
exports.myFunction = onDocumentCreated(
  {
    document: "path/{id}",
    timeoutSeconds: 300, // Increase from default 60s
    memory: "512MB"      // Increase memory if needed
  },
  async (event) => {
    // function code
  }
);
```

Re-deploy:
```bash
firebase deploy --only functions:myFunction
```

---

### Issue 5: High function costs

**Monitor costs:**
```bash
# View invocation counts
gcloud functions list --project=social-connect-app-57fc0

# View detailed metrics
gcloud monitoring time-series list \
  --filter='metric.type="cloudfunctions.googleapis.com/function/execution_count"' \
  --project=social-connect-app-57fc0
```

**Optimize:**
1. Reduce function timeout
2. Use appropriate memory allocation
3. Implement request batching
4. Cache frequently accessed data

---

## 📊 Monitoring Dashboard Setup

### Create Custom Dashboard

1. **Go to:** [Google Cloud Console > Monitoring > Dashboards](https://console.cloud.google.com/monitoring/dashboards)

2. **Create Dashboard:**
   - Click "+ CREATE DASHBOARD"
   - Name: "Social Connect Functions"

3. **Add Charts:**

**Chart 1: Function Invocations**
```
Resource Type: Cloud Function
Metric: Execution Count
Aggregation: Sum
Group By: Function Name
```

**Chart 2: Function Errors**
```
Resource Type: Cloud Function
Metric: Execution Error Count
Aggregation: Sum
Group By: Function Name
```

**Chart 3: Execution Time**
```
Resource Type: Cloud Function
Metric: Execution Time
Aggregation: 95th Percentile
Group By: Function Name
```

**Chart 4: Memory Usage**
```
Resource Type: Cloud Function
Metric: Memory Usage
Aggregation: Average
Group By: Function Name
```

---

### Set Up Alerts

**Alert 1: High Error Rate**

```bash
gcloud alpha monitoring policies create \
  --notification-channels=EMAIL_CHANNEL_ID \
  --display-name="Cloud Function Error Rate > 5%" \
  --condition-threshold-value=0.05 \
  --condition-threshold-duration=300s \
  --condition-filter='resource.type="cloud_function"
    AND metric.type="cloudfunctions.googleapis.com/function/execution_error_count"'
```

**Alert 2: High Costs**

1. Go to Cloud Console > Billing > Budgets & Alerts
2. Create budget: $100/month
3. Set alert threshold: 50%, 90%, 100%

---

## 🎯 Success Criteria

Your deployment is successful when:

✅ All 5 functions deployed without errors  
✅ onMessageSent updates chat metadata correctly  
✅ sendPushNotification sends notifications to devices  
✅ cleanupExpiredStories runs hourly and deletes old stories  
✅ updateUserMetrics callable function works  
✅ onUserCreated initializes new users  
✅ Performance monitoring shows data  
✅ Analytics events are logged  
✅ No errors in function logs  
✅ Costs are under $5/month for testing  

---

## 📞 Support

If you encounter issues:

1. **Check logs:**
   ```bash
   firebase functions:log --limit 50
   ```

2. **Check Firebase Console:**
   - Functions > Logs
   - Performance > Traces
   - Analytics > Events

3. **Debug locally:**
   ```bash
   cd functions
   npm run serve
   ```

4. **Review documentation:**
   - `functions/README.md`
   - `docs/WEEK3_IMPLEMENTATION.md`

---

## 🚀 Next Steps

After successful deployment:

1. **Monitor for 24 hours**
   - Check logs regularly
   - Monitor costs
   - Verify all functions working

2. **Load test**
   - Send 100 test messages
   - Create 50 test stories
   - Monitor performance

3. **Optimize if needed**
   - Adjust function memory
   - Implement caching
   - Add error handling

4. **Move to Week 4** (if applicable)
   - Advanced analytics
   - Email notifications
   - Content moderation

---

**Deployment Complete! 🎉**

Your Week 3 infrastructure is now live and ready for production use.

---

*Guide Version: 1.0*  
*Last Updated: 2025-11-26*
