# Cloud Functions - Week 3 Implementation

This directory contains Cloud Functions for the Social Connect app, implementing automated backend operations.

## Functions Overview

### 1. onMessageSent
**Trigger:** Firestore onCreate for `chats/{chatId}/messages/{messageId}`  
**Purpose:** Automatically update chat metadata when a new message is sent

**Updates:**
- `lastMessage`: Text of the latest message
- `lastMessageTime`: Timestamp of the latest message  
- `unreadCount`: Increments for the recipient

**Why Cloud Functions?**
- **Reliability:** Server-side execution ensures updates happen even if sender's app crashes
- **Security:** Admin privileges to update any document
- **Atomicity:** Guaranteed execution with Firestore triggers

---

### 2. sendPushNotification
**Trigger:** Firestore onCreate for `chats/{chatId}/messages/{messageId}`  
**Purpose:** Send push notification to recipient when new message arrives

**Flow:**
1. Get recipient's FCM token from users collection
2. Get sender's display name
3. Send notification via FCM

**Why Cloud Functions?**
- **FCM Server Key:** Only server-side code can access FCM server keys
- **Security:** Client apps cannot send arbitrary push notifications
- **Reliability:** Server-side ensures delivery even if sender goes offline

---

### 3. cleanupExpiredStories
**Trigger:** Scheduled (every 1 hour via Pub/Sub)  
**Purpose:** Delete stories older than 24 hours

**Process:**
1. Query stories with `createdAt < 24 hours ago`
2. Delete story documents
3. Delete associated media files from Storage
4. Update user's `activeStoryCount`

**Why Cloud Functions?**
- **Automation:** Runs automatically without client intervention
- **Server Time:** Uses accurate server timestamps (no client time manipulation)
- **Batch Processing:** Efficiently processes thousands of stories
- **Storage Cleanup:** Only server can efficiently delete Storage files

---

### 4. updateUserMetrics
**Trigger:** HTTPS callable function  
**Purpose:** Update user activity metrics and analytics

**Metrics Tracked:**
- `lastActiveAt`: Last activity timestamp
- `messageCount`: Total messages sent
- `storyCount`: Total stories created
- `profileViewCount`: Profile view count

**Why Cloud Functions?**
- **Trusted Increment:** Server-side ensures accurate counts (client can't cheat)
- **Centralized Analytics:** Single source of truth for metrics
- **Security:** Only server can update sensitive metrics

---

### 5. onUserCreated
**Trigger:** Firestore onCreate for `users/{userId}`  
**Purpose:** Initialize new user document with default values

**Sets Up:**
- Default metrics (all counts = 0)
- Welcome notification
- Analytics event

**Why Cloud Functions?**
- **Guaranteed Initialization:** Ensures all users have required fields
- **Consistent Defaults:** Same initialization for all users
- **Welcome Experience:** Automated onboarding

---

## Image Optimization (Optional - Requires ImageMagick)

### optimizeImage
**Trigger:** Storage onFinalize for uploaded images  
**Purpose:** Create optimized versions and thumbnails

**Process:**
1. Download original image
2. Create thumbnail (200x200, WebP)
3. Create optimized version (max 1920px, WebP)
4. Upload optimized versions
5. Update Firestore with URLs

**Benefits:**
- **Bandwidth Savings:** WebP reduces file size by 25-35%
- **Faster Loading:** Thumbnails load instantly
- **Cost Reduction:** Less bandwidth = lower costs
- **Better UX:** Responsive images for all screen sizes

**Requirements:**
- ImageMagick installed on Cloud Functions environment
- Additional cost: ~$50/month for image processing

---

## Deployment

### Initial Setup

1. **Install Dependencies:**
   ```bash
   cd functions
   npm install
   ```

2. **Configure Firebase Project:**
   ```bash
   firebase use social-connect-app-57fc0
   ```

3. **Deploy Functions:**
   ```bash
   firebase deploy --only functions
   ```

### Deploy Specific Function

```bash
firebase deploy --only functions:onMessageSent
firebase deploy --only functions:sendPushNotification
firebase deploy --only functions:cleanupExpiredStories
```

### Testing Locally

```bash
cd functions
npm run serve
```

This starts the Firebase Emulator Suite for local testing.

---

## Cost Estimation

### Expected Monthly Costs (10K Active Users)

| Function | Invocations/Month | Cost/1M | Monthly Cost |
|----------|-------------------|---------|--------------|
| onMessageSent | 500K | $0.40 | $0.20 |
| sendPushNotification | 500K | $0.40 | $0.20 |
| cleanupExpiredStories | 720 (hourly) | $0.40 | ~$0 |
| updateUserMetrics | 100K | $0.40 | $0.04 |
| onUserCreated | 1K | $0.40 | ~$0 |
| **Total** | - | - | **~$0.50** |

**Note:** FCM (push notifications) is free for unlimited messages.

### At 100K Users

| Function | Invocations/Month | Monthly Cost |
|----------|-------------------|--------------|
| onMessageSent | 5M | $2.00 |
| sendPushNotification | 5M | $2.00 |
| cleanupExpiredStories | 720 | ~$0 |
| updateUserMetrics | 1M | $0.40 |
| onUserCreated | 10K | ~$0 |
| **Total** | - | **~$4.40** |

---

## Environment Variables

Set environment variables for production:

```bash
firebase functions:config:set app.url="https://socialconnect.app"
firebase functions:config:set notification.default_icon="https://socialconnect.app/icon.png"
```

---

## Monitoring

### View Logs

```bash
firebase functions:log
```

### Filter by Function

```bash
firebase functions:log --only onMessageSent
```

### Real-time Logs

```bash
firebase functions:log --follow
```

---

## Best Practices

1. **Error Handling:** All functions include try-catch blocks
2. **Logging:** Comprehensive logging for debugging
3. **Idempotency:** Functions can be safely retried
4. **Batching:** Use batch writes for efficiency
5. **Timeouts:** Functions timeout after 540s (max for Cloud Functions)

---

## Performance Optimization

### Current Configuration

- **Memory:** 256MB (default) for most functions
- **Timeout:** 60s (default) for most functions
- **CPU:** 1 vCPU (default)

### Image Optimization (if enabled)

- **Memory:** 2GB (requires more for ImageMagick)
- **Timeout:** 540s (max allowed)
- **CPU:** 2 vCPU

---

## Troubleshooting

### Function Not Triggering

1. Check Firestore triggers are enabled
2. Verify collection/document paths
3. Check function deployment status: `firebase functions:list`

### Push Notifications Not Sending

1. Verify FCM token exists in user document
2. Check FCM server key in Firebase Console
3. Verify notification payload format

### Story Cleanup Not Working

1. Check Pub/Sub schedule configuration
2. Verify Cloud Scheduler is enabled in GCP
3. Check function logs for errors

---

## Security

- Functions run with admin privileges
- No client-side access to function code
- Secure environment variables
- Validated input parameters
- Rate limiting (built-in Cloud Functions)

---

## Next Steps (Week 4+)

1. **Add more analytics events**
2. **Implement email notifications** (SendGrid/Mailgun)
3. **Add content moderation** (Cloud Vision API)
4. **Implement batch processing** for scaling
5. **Add Redis caching** for frequently accessed data

---

## Support

For issues or questions:
1. Check Firebase Console > Functions > Logs
2. Review function code in `index.js`
3. Test locally with Firebase Emulator
4. Check Firebase documentation: https://firebase.google.com/docs/functions
