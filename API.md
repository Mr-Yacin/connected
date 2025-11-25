# API Documentation

This document describes the data models, Firebase collections, and API patterns used in the Social Connect App.

## 📊 Data Models

### UserProfile

Represents a user's profile information.

**Firestore Collection**: `users`

```dart
class UserProfile {
  final String id;                    // User's unique ID (matches Firebase Auth UID)
  final String phoneNumber;           // Phone number (E.164 format)
  final String name;                  // Display name
  final int age;                      // User's age
  final String country;               // Country name
  final String dialect;               // Language/dialect
  final String profileImageUrl;       // Profile image URL (Firebase Storage)
  final String gender;                // 'male' or 'female'
  final bool isActive;                // Online status
  final bool isImageBlurred;          // Whether profile image is blurred
  final String anonymousLink;         // UUID for anonymous profile sharing
  final DateTime createdAt;           // Account creation timestamp
  final DateTime lastActive;          // Last activity timestamp
  final bool? verified;               // Profile verification status (optional)
  final String? verificationStatus;   // 'pending', 'approved', 'rejected' (optional)
  final String? rejectionReason;      // Reason for rejection (optional)
  final String? adminNotes;           // Admin notes (optional)
  final DateTime? verificationDate;   // Verification timestamp (optional)
}
```

**Security Rules**:
- Users can read their own profile
- Users can update their own profile (except admin fields)
- Admins can read/write all profiles
- Anonymous links allow public read access

### Message

Represents a chat message between users.

**Firestore Collection**: `chats/{chatId}/messages`

```dart
class Message {
  final String id;                    // Message unique ID
  final String senderId;              // Sender's user ID
  final String receiverId;            // Receiver's user ID
  final String? text;                 // Text content (optional)
  final String? audioUrl;             // Audio message URL (optional)
  final int? audioDuration;           // Audio duration in seconds (optional)
  final DateTime timestamp;           // Message timestamp
  final bool isRead;                  // Read status
  final MessageType type;             // 'text' or 'audio'
}
```

**Security Rules**:
- Only chat participants can read messages
- Only authenticated users can send messages
- Users can only send messages to their chat

### Chat

Represents a chat conversation between two users.

**Firestore Collection**: `chats`

```dart
class Chat {
  final String id;                    // Chat unique ID
  final List<String> participants;    // List of participant user IDs (always 2)
  final String? lastMessage;          // Last message text
  final DateTime lastMessageTime;     // Last message timestamp
  final Map<String, int> unreadCount; // Unread count per user
}
```

**Composite Index Required**:
```
Collection: chats
Fields: participants (Array), lastMessageTime (Descending)
```

**Security Rules**:
- Only participants can read the chat
- Participants can update unread counts
- System creates new chats

### Story

Represents a user's story (24-hour temporary content).

**Firestore Collection**: `stories`

```dart
class Story {
  final String id;                    // Story unique ID
  final String userId;                // Story owner's user ID
  final String mediaUrl;              // Image/video URL
  final String mediaType;             // 'image' or 'video'
  final DateTime createdAt;           // Creation timestamp
  final DateTime expiresAt;           // Expiration timestamp (24h after creation)
  final List<String> viewedBy;        // List of user IDs who viewed
  final int viewCount;                // Total view count
}
```

**Security Rules**:
- Users can read stories from their connections
- Users can create their own stories
- Users can update viewedBy list
- Stories auto-delete after 24 hours (client-side cleanup)

### Report

Represents a content moderation report.

**Firestore Collection**: `reports`

```dart
class Report {
  final String id;                    // Report unique ID
  final String reporterId;            // Reporter's user ID
  final String reportedUserId;        // Reported user's ID
  final String? reportedMessageId;    // Reported message ID (optional)
  final String? reportedStoryId;      // Reported story ID (optional)
  final String reason;                // Report reason
  final String? description;          // Additional details (optional)
  final DateTime createdAt;           // Report timestamp
  final ReportStatus status;          // 'pending', 'reviewed', 'resolved'
  final String? adminNotes;           // Admin notes (optional)
}
```

**Security Rules**:
- Users can create reports
- Only admins can read/update reports

### DiscoveryFilters

Represents user's discovery preferences.

**Firestore Collection**: `users/{userId}/preferences`

```dart
class DiscoveryFilters {
  final String? country;              // Filter by country (optional)
  final int? minAge;                  // Minimum age (optional)
  final int? maxAge;                  // Maximum age (optional)
  final String? gender;               // Filter by gender (optional)
  final bool showActiveOnly;          // Show only active users
}
```

## 🔥 Firebase Collections Structure

```
firestore/
├── users/                          # User profiles
│   ├── {userId}/                   # User document
│   │   └── preferences/            # User preferences subcollection
│   │       └── discovery           # Discovery filters
│
├── chats/                          # Chat conversations
│   └── {chatId}/                   # Chat document
│       └── messages/               # Messages subcollection
│           └── {messageId}         # Message document
│
├── stories/                        # User stories
│   └── {storyId}                   # Story document
│
└── reports/                        # Moderation reports
    └── {reportId}                  # Report document
```

## 🔐 Authentication

### Phone Authentication Flow

1. **Request OTP**
   ```dart
   await FirebaseAuth.instance.verifyPhoneNumber(
     phoneNumber: phoneNumber,
     verificationCompleted: (credential) {},
     verificationFailed: (error) {},
     codeSent: (verificationId, resendToken) {},
     codeAutoRetrievalTimeout: (verificationId) {},
   );
   ```

2. **Verify OTP**
   ```dart
   final credential = PhoneAuthProvider.credential(
     verificationId: verificationId,
     smsCode: smsCode,
   );
   await FirebaseAuth.instance.signInWithCredential(credential);
   ```

3. **Create User Profile**
   ```dart
   await FirebaseFirestore.instance
     .collection('users')
     .doc(user.uid)
     .set(userProfile.toJson());
   ```

### Anonymous Links

Users can share their profile anonymously using a UUID link:

```dart
// Generate anonymous link
final anonymousLink = Uuid().v4();

// Access profile via anonymous link
final profile = await FirebaseFirestore.instance
  .collection('users')
  .where('anonymousLink', isEqualTo: anonymousLink)
  .limit(1)
  .get();
```

## 📡 Real-time Listeners

### Chat Messages

```dart
FirebaseFirestore.instance
  .collection('chats')
  .doc(chatId)
  .collection('messages')
  .orderBy('timestamp', descending: true)
  .snapshots()
  .listen((snapshot) {
    // Handle new messages
  });
```

### User Status

```dart
FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .snapshots()
  .listen((snapshot) {
    // Handle user status changes
  });
```

### Stories

```dart
FirebaseFirestore.instance
  .collection('stories')
  .where('expiresAt', isGreaterThan: DateTime.now())
  .orderBy('expiresAt')
  .orderBy('createdAt', descending: true)
  .snapshots()
  .listen((snapshot) {
    // Handle active stories
  });
```

## 🗄️ Storage Structure

```
storage/
├── profiles/                       # Profile images
│   └── {userId}/
│       └── profile.jpg
│
├── stories/                        # Story media
│   └── {userId}/
│       └── {storyId}.jpg
│
└── messages/                       # Voice messages
    └── {chatId}/
        └── {messageId}.m4a
```

### Upload Profile Image

```dart
final ref = FirebaseStorage.instance
  .ref()
  .child('profiles/${userId}/profile.jpg');

await ref.putFile(imageFile);
final url = await ref.getDownloadURL();
```

## 🔍 Queries

### Discovery Query

```dart
Query query = FirebaseFirestore.instance.collection('users');

if (filters.country != null) {
  query = query.where('country', isEqualTo: filters.country);
}

if (filters.gender != null) {
  query = query.where('gender', isEqualTo: filters.gender);
}

if (filters.minAge != null) {
  query = query.where('age', isGreaterThanOrEqualTo: filters.minAge);
}

if (filters.maxAge != null) {
  query = query.where('age', isLessThanOrEqualTo: filters.maxAge);
}

if (filters.showActiveOnly) {
  query = query.where('isActive', isEqualTo: true);
}

final users = await query.get();
```

### User Chats

```dart
final chats = await FirebaseFirestore.instance
  .collection('chats')
  .where('participants', arrayContains: currentUserId)
  .orderBy('lastMessageTime', descending: true)
  .get();
```

## 🛡️ Security Rules

### Firestore Rules

See [firestore.rules](../firestore.rules) for complete rules.

**Key Principles**:
- Users can only read/write their own data
- Chat participants can access their chats
- Anonymous links allow public profile access
- Admins have elevated permissions
- File size and type validations

### Storage Rules

See [storage.rules](../storage.rules) for complete rules.

**Key Principles**:
- Users can upload to their own folders
- File size limits (5MB for images, 10MB for audio)
- Content type validation
- Public read for profile images (with anonymous links)

## 📊 Indexes

### Required Composite Indexes

1. **Chats by participants and time**
   ```
   Collection: chats
   Fields: participants (Array), lastMessageTime (Descending)
   ```

2. **Stories by expiration and creation**
   ```
   Collection: stories
   Fields: expiresAt (Ascending), createdAt (Descending)
   ```

3. **Messages by timestamp**
   ```
   Collection: chats/{chatId}/messages
   Fields: timestamp (Descending)
   ```

## 🔄 State Management (Riverpod)

### Providers Pattern

```dart
@riverpod
class UserProfile extends _$UserProfile {
  @override
  Future<UserProfileModel?> build(String userId) async {
    return await _userRepository.getProfile(userId);
  }
}
```

### Usage

```dart
final userProfile = ref.watch(userProfileProvider(userId));

userProfile.when(
  data: (profile) => ProfileWidget(profile: profile),
  loading: () => LoadingWidget(),
  error: (error, stack) => ErrorWidget(error),
);
```

## 🚀 Performance Optimization

### Image Caching

```dart
CachedNetworkImage(
  imageUrl: profileImageUrl,
  placeholder: (context, url) => ShimmerWidget(),
  errorWidget: (context, url, error) => ErrorIcon(),
  cacheKey: userId,
);
```

### Pagination

```dart
final lastDoc = await FirebaseFirestore.instance
  .collection('users')
  .orderBy('createdAt', descending: true)
  .limit(20)
  .get()
  .then((snapshot) => snapshot.docs.last);

final nextPage = await FirebaseFirestore.instance
  .collection('users')
  .orderBy('createdAt', descending: true)
  .startAfterDocument(lastDoc)
  .limit(20)
  .get();
```

## 📱 Offline Support

Firebase automatically handles offline data caching:

```dart
// Enable offline persistence (enabled by default)
await FirebaseFirestore.instance
  .settings = const Settings(persistenceEnabled: true);

// Check connectivity
final connectivity = await Connectivity().checkConnectivity();
```

## 🧪 Testing

### Mock Data

Use the [Mock Data Uploader](../tool/README.md) tool for testing.

### Test Users

Create test users with specific properties for different test scenarios:
- Verified users
- Unverified users
- Blocked users
- Users with different ages, countries, genders

---

**For implementation details, see the code in `lib/features/` directories.**
