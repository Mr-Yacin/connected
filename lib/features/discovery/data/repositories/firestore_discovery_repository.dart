import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/models/discovery_filters.dart';
import '../../../../core/data/base_firestore_repository.dart';
import '../../domain/repositories/discovery_repository.dart';
import 'dart:math';

/// Firestore implementation of DiscoveryRepository
class FirestoreDiscoveryRepository extends BaseFirestoreRepository 
    implements DiscoveryRepository {
  final FirebaseFirestore _firestore;
  final Random _random;

  FirestoreDiscoveryRepository({
    FirebaseFirestore? firestore,
    Random? random,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _random = random ?? Random();

  @override
  Future<UserProfile?> getRandomUser(
    String currentUserId,
    DiscoveryFilters filters,
  ) async {
    return handleFirestoreOperation(
      operation: () async {
        final result = await getFilteredUsersPaginated(currentUserId, filters);
        if (result.users.isEmpty) return null;
        return result.users[_random.nextInt(result.users.length)];
      },
      operationName: 'getRandomUser',
      screen: 'ShuffleScreen',
      arabicErrorMessage: 'فشل في جلب مستخدم عشوائي',
      collection: 'users',
    );
  }

  @override
  Future<List<UserProfile>> getFilteredUsers(
    String currentUserId,
    DiscoveryFilters filters,
  ) async {
    return handleFirestoreOperation(
      operation: () async {
        Query query = _buildBaseQuery(currentUserId, filters);
        query = query.limit(100);

        final snapshot = await query.get();
        var profiles = mapQuerySnapshot(
          snapshot: snapshot,
          fromJson: UserProfile.fromJson,
        );

        return _applyClientSideFilters(profiles, filters);
      },
      operationName: 'getFilteredUsers',
      screen: 'ShuffleScreen',
      arabicErrorMessage: 'فشل في جلب المستخدمين',
      collection: 'users',
    );
  }

  @override
  Future<PaginatedUsers> getFilteredUsersPaginated(
    String currentUserId,
    DiscoveryFilters filters,
  ) async {
    return handleFirestoreOperation(
      operation: () async {
        Query query = _buildBaseQuery(currentUserId, filters);

        if (filters.lastDocument != null) {
          query = query.startAfterDocument(filters.lastDocument!);
        }

        query = query.limit(filters.pageSize + 1);

        final snapshot = await query.get();
        final hasMore = snapshot.docs.length > filters.pageSize;
        final docs = hasMore 
            ? snapshot.docs.take(filters.pageSize).toList()
            : snapshot.docs;
        
        var profiles = docs
            .map((doc) => UserProfile.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        profiles = _applyClientSideFilters(profiles, filters);

        final updatedFilters = docs.isNotEmpty
            ? filters.copyWith(lastDocument: docs.last)
            : filters;

        return PaginatedUsers(
          users: profiles,
          hasMore: hasMore,
          updatedFilters: updatedFilters,
        );
      },
      operationName: 'getFilteredUsersPaginated',
      screen: 'ShuffleScreen',
      arabicErrorMessage: 'فشل في جلب المستخدمين',
      collection: 'users',
    );
  }

  /// Builds base query with indexed filters
  Query _buildBaseQuery(String currentUserId, DiscoveryFilters filters) {
    Query query = _firestore.collection('users');
    
    query = query.where('isActive', isEqualTo: true);
    
    if (filters.country != null && filters.country!.isNotEmpty) {
      query = query.where('country', isEqualTo: filters.country);
    }

    if (filters.gender != null && filters.gender!.isNotEmpty) {
      query = query.where('gender', isEqualTo: filters.gender);
    }
    
    query = query.where('id', isNotEqualTo: currentUserId);
    
    return query;
  }

  /// Applies client-side filters (age, last active, exclusions)
  List<UserProfile> _applyClientSideFilters(
    List<UserProfile> profiles,
    DiscoveryFilters filters,
  ) {
    var filtered = profiles;

    // Apply age filter
    if (filters.minAge != null || filters.maxAge != null) {
      filtered = filtered.where((profile) {
        if (profile.age == null) return false;
        if (filters.minAge != null && profile.age! < filters.minAge!) return false;
        if (filters.maxAge != null && profile.age! > filters.maxAge!) return false;
        return true;
      }).toList();
    }

    // Apply last active filter
    if (filters.lastActiveWithinHours != null) {
      final cutoffTime = DateTime.now().subtract(
        Duration(hours: filters.lastActiveWithinHours!),
      );
      filtered = filtered.where((profile) {
        return profile.lastActive.isAfter(cutoffTime);
      }).toList();
    }

    // Exclude specified user IDs
    if (filters.excludedUserIds.isNotEmpty) {
      filtered = filtered.where((profile) {
        return !filters.excludedUserIds.contains(profile.id);
      }).toList();
    }

    return filtered;
  }
}
