import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/models/discovery_filters.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/repositories/discovery_repository.dart';

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
      // Get filtered users
      final users = await getFilteredUsers(currentUserId, filters);
      
      if (users.isEmpty) {
        return null;
      }
      
      // Return a random user from the filtered list
      final randomIndex = _random.nextInt(users.length);
      return users[randomIndex];
    } on FirebaseException catch (e) {
      throw AppException('فشل في جلب مستخدم عشوائي: ${e.message}');
    } catch (e) {
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<List<UserProfile>> getFilteredUsers(
    String currentUserId,
    DiscoveryFilters filters,
  ) async {
    try {
      // Get blocked users for the current user
      final blockedUserIds = await _getBlockedUserIds(currentUserId);
      
      // Start with base query
      Query<Map<String, dynamic>> query = _firestore.collection('users');
      
      // Apply country filter
      if (filters.country != null) {
        query = query.where('country', isEqualTo: filters.country);
      }
      
      // Apply dialect filter
      if (filters.dialect != null) {
        query = query.where('dialect', isEqualTo: filters.dialect);
      }
      
      // Apply age filters
      if (filters.minAge != null) {
        query = query.where('age', isGreaterThanOrEqualTo: filters.minAge);
      }
      if (filters.maxAge != null) {
        query = query.where('age', isLessThanOrEqualTo: filters.maxAge);
      }
      
      // Execute query
      final snapshot = await query.get();
      
      // Convert to UserProfile and apply exclusion filters
      final allExcludedIds = {
        currentUserId, // Exclude current user
        ...blockedUserIds, // Exclude blocked users
        ...filters.excludedUserIds, // Exclude specified users
      };
      
      final users = snapshot.docs
          .map((doc) => UserProfile.fromJson(doc.data()))
          .where((user) => !allExcludedIds.contains(user.id))
          .toList();
      
      return users;
    } on FirebaseException catch (e) {
      throw AppException('فشل في جلب المستخدمين: ${e.message}');
    } catch (e) {
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  /// Get list of user IDs that the current user has blocked
  Future<Set<String>> _getBlockedUserIds(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('blocks')
          .where('blockerId', isEqualTo: currentUserId)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data()['blockedUserId'] as String)
          .toSet();
    } catch (e) {
      // If blocks collection doesn't exist or error occurs, return empty set
      return {};
    }
  }
}
