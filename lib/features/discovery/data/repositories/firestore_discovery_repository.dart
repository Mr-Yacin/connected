import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/models/discovery_filters.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../../../../services/error_logging_service.dart';
import 'dart:math';

/// Firestore implementation of DiscoveryRepository
class FirestoreDiscoveryRepository implements DiscoveryRepository {
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
    try {
      // Use paginated query to get users more efficiently
      final result = await getFilteredUsersPaginated(currentUserId, filters);
      if (result.users.isEmpty) return null;
      
      return result.users[_random.nextInt(result.users.length)];
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get random user',
        screen: 'ShuffleScreen',
        operation: 'getRandomUser',
        collection: 'users',
      );
      throw AppException('فشل في جلب مستخدم عشوائي: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error getting random user',
        screen: 'ShuffleScreen',
        operation: 'getRandomUser',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<List<UserProfile>> getFilteredUsers(
    String currentUserId,
    DiscoveryFilters filters,
  ) async {
    try {
      // OPTIMIZED: Use composite indexes for better query performance
      Query query = _firestore.collection('users');
      
      // Start with indexed fields for optimal performance
      query = query.where('isActive', isEqualTo: true);
      
      // Apply country filter (indexed)
      if (filters.country != null && filters.country!.isNotEmpty) {
        query = query.where('country', isEqualTo: filters.country);
      }

      // Apply dialect filter (indexed)
      if (filters.dialect != null && filters.dialect!.isNotEmpty) {
        query = query.where('dialect', isEqualTo: filters.dialect);
      }
      
      // IMPORTANT: Add id filter to prevent duplicate results and use composite index
      query = query.where('id', isNotEqualTo: currentUserId);

      // OPTIMIZED: Limit to 100 users for better performance
      query = query.limit(100);

      final snapshot = await query.get();
      var profiles = snapshot.docs
          .map((doc) => UserProfile.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply age filter (client-side filtering is more efficient for ranges)
      if (filters.minAge != null || filters.maxAge != null) {
        profiles = profiles.where((profile) {
          if (profile.age == null) return false;
          if (filters.minAge != null && profile.age! < filters.minAge!) return false;
          if (filters.maxAge != null && profile.age! > filters.maxAge!) return false;
          return true;
        }).toList();
      }

      // Exclude specified user IDs (client-side)
      if (filters.excludedUserIds.isNotEmpty) {
        profiles = profiles.where((profile) {
          return !filters.excludedUserIds.contains(profile.id);
        }).toList();
      }

      return profiles;
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get filtered users',
        screen: 'ShuffleScreen',
        operation: 'getFilteredUsers',
        collection: 'users',
      );
      throw AppException('فشل في جلب المستخدمين: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error getting filtered users',
        screen: 'ShuffleScreen',
        operation: 'getFilteredUsers',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<PaginatedUsers> getFilteredUsersPaginated(
    String currentUserId,
    DiscoveryFilters filters,
  ) async {
    try {
      // OPTIMIZED: Use composite indexes for better query performance
      Query query = _firestore.collection('users');
      
      // Start with indexed fields for optimal performance
      query = query.where('isActive', isEqualTo: true);
      
      // Apply country filter (indexed)
      if (filters.country != null && filters.country!.isNotEmpty) {
        query = query.where('country', isEqualTo: filters.country);
      }

      // Apply dialect filter (indexed)
      if (filters.dialect != null && filters.dialect!.isNotEmpty) {
        query = query.where('dialect', isEqualTo: filters.dialect);
      }
      
      // IMPORTANT: Add id filter to prevent duplicate results and use composite index
      query = query.where('id', isNotEqualTo: currentUserId);

      // Apply pagination cursor
      if (filters.lastDocument != null) {
        query = query.startAfterDocument(filters.lastDocument!);
      }

      // OPTIMIZED: Fetch one more than pageSize to check if there are more results
      query = query.limit(filters.pageSize + 1);

      final snapshot = await query.get();
      
      // Check if there are more results
      final hasMore = snapshot.docs.length > filters.pageSize;
      
      // Take only the requested pageSize
      final docs = hasMore 
          ? snapshot.docs.take(filters.pageSize).toList()
          : snapshot.docs;
      
      var profiles = docs
          .map((doc) => UserProfile.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply age filter (client-side filtering is more efficient for ranges)
      if (filters.minAge != null || filters.maxAge != null) {
        profiles = profiles.where((profile) {
          if (profile.age == null) return false;
          if (filters.minAge != null && profile.age! < filters.minAge!) return false;
          if (filters.maxAge != null && profile.age! > filters.maxAge!) return false;
          return true;
        }).toList();
      }

      // Exclude specified user IDs (client-side)
      if (filters.excludedUserIds.isNotEmpty) {
        profiles = profiles.where((profile) {
          return !filters.excludedUserIds.contains(profile.id);
        }).toList();
      }

      // Update filters with new lastDocument if we have results
      final updatedFilters = docs.isNotEmpty
          ? filters.copyWith(lastDocument: docs.last)
          : filters;

      return PaginatedUsers(
        users: profiles,
        hasMore: hasMore,
        updatedFilters: updatedFilters,
      );
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get paginated filtered users',
        screen: 'ShuffleScreen',
        operation: 'getFilteredUsersPaginated',
        collection: 'users',
      );
      throw AppException('فشل في جلب المستخدمين: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error getting paginated filtered users',
        screen: 'ShuffleScreen',
        operation: 'getFilteredUsersPaginated',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }
}
