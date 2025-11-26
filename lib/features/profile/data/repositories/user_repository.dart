import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/exceptions/app_exceptions.dart';

/// Repository for managing user profiles in Firestore
class UserRepository {
  final FirebaseFirestore _firestore;
  static const String _usersCollection = 'users';

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get user profile by user ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      if (userId.isEmpty) {
        throw ValidationException('معرف المستخدم مطلوب');
      }

      final doc = await _firestore.collection(_usersCollection).doc(userId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return UserProfile.fromJson(doc.data()!);
    } catch (e, stackTrace) {
      if (e is ValidationException) rethrow;

      throw AppException('حدث خطأ أثناء جلب ملف المستخدم');
    }
  }

  /// Check if user profile exists in Firestore
  Future<bool> userProfileExists(String userId) async {
    try {
      if (userId.isEmpty) return false;

      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Check if user profile is complete (has all required fields)
  Future<bool> isProfileComplete(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      
      if (profile == null) return false;

      // Check if all required fields are present
      return profile.name != null &&
          profile.name!.isNotEmpty &&
          profile.age != null &&
          profile.gender != null &&
          profile.gender!.isNotEmpty &&
          profile.country != null &&
          profile.country!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Create a new user profile
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      if (profile.id.isEmpty) {
        throw ValidationException('معرف المستخدم مطلوب');
      }

      await _firestore
          .collection(_usersCollection)
          .doc(profile.id)
          .set(profile.toJson());
    } catch (e) {
      if (e is ValidationException) rethrow;

      throw AppException('حدث خطأ أثناء إنشاء ملف المستخدم');
    }
  }

  /// Update user profile with new data
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      if (userId.isEmpty) {
        throw ValidationException('معرف المستخدم مطلوب');
      }

      // Always update lastActive when modifying profile
      data['lastActive'] = DateTime.now().toIso8601String();

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update(data);
    } catch (e) {
      if (e is ValidationException) rethrow;

      throw AppException('حدث خطأ أثناء تحديث ملف المستخدم');
    }
  }

  /// Create or update user profile
  Future<void> upsertUserProfile(UserProfile profile) async {
    try {
      final exists = await userProfileExists(profile.id);

      if (exists) {
        await updateUserProfile(profile.id, profile.toJson());
      } else {
        await createUserProfile(profile);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update last active timestamp
  Future<void> updateLastActive(String userId) async {
    try {
      if (userId.isEmpty) return;

      await _firestore.collection(_usersCollection).doc(userId).update({
        'lastActive': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Don't throw, this is not critical
    }
  }

  /// Stream user profile changes
  Stream<UserProfile?> watchUserProfile(String userId) {
    try {
      if (userId.isEmpty) {
        return Stream.value(null);
      }

      return _firestore
          .collection(_usersCollection)
          .doc(userId)
          .snapshots()
          .map((doc) {
        if (!doc.exists || doc.data() == null) {
          return null;
        }
        return UserProfile.fromJson(doc.data()!);
      });
    } catch (e) {
      return Stream.value(null);
    }
  }
}
