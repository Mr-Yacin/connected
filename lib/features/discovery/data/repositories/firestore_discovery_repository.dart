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
      final users = await getFilteredUsers(currentUserId, filters);
      if (users.isEmpty) return null;
      
      return users[_random.nextInt(users.length)];
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
      Query query = _firestore
          .collection('users')
          .where('id', isNotEqualTo: currentUserId)
          .where('isActive', isEqualTo: true);

      // Apply country filter
      if (filters.country != null && filters.country!.isNotEmpty) {
        query = query.where('country', isEqualTo: filters.country);
      }

      // Apply dialect filter
      if (filters.dialect != null && filters.dialect!.isNotEmpty) {
        query = query.where('dialect', isEqualTo: filters.dialect);
      }

      query = query.limit(100); // Get a reasonable batch

      final snapshot = await query.get();
      var profiles = snapshot.docs
          .map((doc) => UserProfile.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply age filter (client-side since Firestore doesn't support range queries well)
      if (filters.minAge != null || filters.maxAge != null) {
        profiles = profiles.where((profile) {
          if (profile.age == null) return false;
          if (filters.minAge != null && profile.age! < filters.minAge!) return false;
          if (filters.maxAge != null && profile.age! > filters.maxAge!) return false;
          return true;
        }).toList();
      }

      // Exclude specified user IDs
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
}
