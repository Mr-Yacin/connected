import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

/// Utility class for building Firestore queries with common filtering patterns.
/// 
/// Eliminates duplicate query building logic across repositories.
class QueryBuilder {
  final FirebaseFirestore _firestore;

  QueryBuilder({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get base users collection query
  Query getUsersQuery() => _firestore.collection('users');

  /// Build query with active users filter
  Query activeUsersQuery({Query? baseQuery}) {
    final query = baseQuery ?? getUsersQuery();
    return query.where('isActive', isEqualTo: true);
  }

  /// Build query excluding specific user
  Query excludeUser(String userId, {Query? baseQuery}) {
    final query = baseQuery ?? getUsersQuery();
    return query.where('id', isNotEqualTo: userId);
  }

  /// Build query filtering by country
  Query filterByCountry(String? country, {Query? baseQuery}) {
    final query = baseQuery ?? getUsersQuery();
    if (country == null || country.isEmpty) return query;
    return query.where('country', isEqualTo: country);
  }

  /// Build query filtering by gender
  Query filterByGender(String? gender, {Query? baseQuery}) {
    final query = baseQuery ?? getUsersQuery();
    if (gender == null || gender.isEmpty) return query;
    return query.where('gender', isEqualTo: gender);
  }

  /// Build comprehensive user discovery query
  /// 
  /// Applies optimal indexed filters in the correct order
  Query buildDiscoveryQuery({
    required String currentUserId,
    String? country,
    String? gender,
    int limit = 100,
  }) {
    Query query = getUsersQuery();

    // Apply indexed filters in optimal order
    query = query.where('isActive', isEqualTo: true);

    if (country != null && country.isNotEmpty) {
      query = query.where('country', isEqualTo: country);
    }

    if (gender != null && gender.isNotEmpty) {
      query = query.where('gender', isEqualTo: gender);
    }

    query = query.where('id', isNotEqualTo: currentUserId);
    query = query.limit(limit);

    return query;
  }

  /// Build query for followers
  Query buildFollowersQuery(String userId) {
    return _firestore
        .collection('follows')
        .where('followingId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true);
  }

  /// Build query for following
  Query buildFollowingQuery(String userId) {
    return _firestore
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true);
  }

  /// Build query for likes received
  Query buildLikesReceivedQuery(String userId) {
    return _firestore
        .collection('likes')
        .where('toUserId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true);
  }

  /// Build query for likes given
  Query buildLikesGivenQuery(String userId) {
    return _firestore
        .collection('likes')
        .where('fromUserId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true);
  }

  /// Build query for chat list
  Query buildChatListQuery(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true);
  }

  /// Build query for messages in a chat
  Query buildMessagesQuery(String chatId, {bool descending = false}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: descending);
  }

  /// Build paginated messages query
  Query buildPaginatedMessagesQuery(
    String chatId, {
    int limit = 50,
    DateTime? lastMessageTimestamp,
  }) {
    var query = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (lastMessageTimestamp != null) {
      query = query.startAfter([Timestamp.fromDate(lastMessageTimestamp)]);
    }

    return query;
  }

  /// Build query for blocked users
  Query buildBlockedUsersQuery(String userId) {
    return _firestore
        .collection('blocks')
        .where('blockerId', isEqualTo: userId);
  }

  /// Build query for pending reports
  Query buildPendingReportsQuery() {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true);
  }

  /// Apply age filter to user profiles (client-side filtering)
  List<UserProfile> applyAgeFilter(
    List<UserProfile> profiles, {
    int? minAge,
    int? maxAge,
  }) {
    if (minAge == null && maxAge == null) return profiles;

    return profiles.where((profile) {
      if (profile.age == null) return false;
      if (minAge != null && profile.age! < minAge) return false;
      if (maxAge != null && profile.age! > maxAge) return false;
      return true;
    }).toList();
  }

  /// Apply last active filter to user profiles (client-side filtering)
  List<UserProfile> applyLastActiveFilter(
    List<UserProfile> profiles, {
    int? lastActiveWithinHours,
  }) {
    if (lastActiveWithinHours == null) return profiles;

    final cutoffTime = DateTime.now().subtract(
      Duration(hours: lastActiveWithinHours),
    );

    return profiles.where((profile) {
      return profile.lastActive.isAfter(cutoffTime);
    }).toList();
  }

  /// Apply exclusion filter (client-side filtering)
  List<UserProfile> applyExclusionFilter(
    List<UserProfile> profiles, {
    List<String> excludedUserIds = const [],
  }) {
    if (excludedUserIds.isEmpty) return profiles;

    return profiles.where((profile) {
      return !excludedUserIds.contains(profile.id);
    }).toList();
  }

  /// Apply all client-side filters at once
  List<UserProfile> applyClientSideFilters(
    List<UserProfile> profiles, {
    int? minAge,
    int? maxAge,
    int? lastActiveWithinHours,
    List<String> excludedUserIds = const [],
  }) {
    var filtered = profiles;

    // Apply age filter
    filtered = applyAgeFilter(filtered, minAge: minAge, maxAge: maxAge);

    // Apply last active filter
    filtered = applyLastActiveFilter(
      filtered,
      lastActiveWithinHours: lastActiveWithinHours,
    );

    // Apply exclusion filter
    filtered = applyExclusionFilter(filtered, excludedUserIds: excludedUserIds);

    return filtered;
  }

  /// Build paginated query with cursor
  Query applyPagination(
    Query query, {
    required int pageSize,
    DocumentSnapshot? lastDocument,
  }) {
    var paginatedQuery = query.limit(pageSize + 1); // Fetch one extra to check if more exist

    if (lastDocument != null) {
      paginatedQuery = paginatedQuery.startAfterDocument(lastDocument);
    }

    return paginatedQuery;
  }

  /// Check if query results have more pages
  bool hasMorePages(List<DocumentSnapshot> docs, int requestedPageSize) {
    return docs.length > requestedPageSize;
  }

  /// Get actual page results (excluding the extra document for pagination check)
  List<DocumentSnapshot> getPageResults(
    List<DocumentSnapshot> docs,
    int requestedPageSize,
  ) {
    if (docs.length > requestedPageSize) {
      return docs.take(requestedPageSize).toList();
    }
    return docs;
  }
}

/// Extension methods for Query to make filtering more fluent
extension QueryExtensions on Query {
  /// Add active filter
  Query whereActive() => where('isActive', isEqualTo: true);

  /// Exclude user by ID
  Query excludingUser(String userId) => where('id', isNotEqualTo: userId);

  /// Filter by country if provided
  Query byCountry(String? country) {
    if (country == null || country.isEmpty) return this;
    return where('country', isEqualTo: country);
  }

  /// Filter by gender if provided
  Query byGender(String? gender) {
    if (gender == null || gender.isEmpty) return this;
    return where('gender', isEqualTo: gender);
  }
}
