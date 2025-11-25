import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../../services/error_logging_service.dart';

/// Firestore implementation of ProfileRepository
class FirestoreProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Uuid _uuid;

  FirestoreProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    Uuid? uuid,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _uuid = uuid ?? const Uuid();

  @override
  Future<UserProfile> getProfile(String userId) async {
    print("DEBUG: Repository getProfile called for $userId");
    try {
      print("DEBUG: Fetching doc from Firestore...");
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw AppException(
                'انتهت مهلة الاتصال. يرجى التحقق من الإنترنت.',
              );
            },
          );
      print("DEBUG: Doc fetched. Exists: ${doc.exists}");

      if (!doc.exists) {
        print("DEBUG: Doc does not exist");
        throw AppException('الملف الشخصي غير موجود');
      }

      print("DEBUG: Parsing JSON...");
      final data = Map<String, dynamic>.from(doc.data() ?? {});
      data['id'] ??= userId;
      data['phoneNumber'] ??= data['phone'] ?? '';
      final profile = UserProfile.fromJson(data);
      print("DEBUG: JSON parsed successfully");
      return profile;
    } on FirebaseException catch (e, stackTrace) {
      print("DEBUG: FirebaseException: $e");
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get user profile',
        screen: 'ProfileScreen',
        operation: 'getProfile',
        collection: 'users',
        documentId: userId,
      );
      throw AppException('فشل في جلب الملف الشخصي: ${e.message}');
    } catch (e, stackTrace) {
      print("DEBUG: General Exception: $e");
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error getting profile',
        screen: 'ProfileScreen',
        operation: 'getProfile',
      );
      if (e is AppException) rethrow;
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.id)
          .update(profile.toJson());
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to update user profile',
        screen: 'ProfileScreen',
        operation: 'updateProfile',
        collection: 'users',
        documentId: profile.id,
      );
      throw AppException('فشل في تحديث الملف الشخصي: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error updating profile',
        screen: 'ProfileScreen',
        operation: 'updateProfile',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<String> uploadProfileImage(String userId, File image) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId/profile.jpg');
      final uploadTask = await ref.putFile(image);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logStorageError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to upload profile image',
        screen: 'ProfileScreen',
        operation: 'uploadProfileImage',
        filePath: 'profile_images/$userId/profile.jpg',
      );
      throw AppException('فشل في رفع صورة الملف الشخصي: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error uploading profile image',
        screen: 'ProfileScreen',
        operation: 'uploadProfileImage',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<String> generateAnonymousLink(String userId) async {
    try {
      // Generate a unique anonymous link ID
      final anonymousLinkId = _uuid.v4();

      // Store the mapping in Firestore
      await _firestore.collection('anonymous_links').doc(anonymousLinkId).set({
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return anonymousLinkId;
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to generate anonymous link',
        screen: 'ProfileScreen',
        operation: 'generateAnonymousLink',
        collection: 'anonymous_links',
      );
      throw AppException('فشل في إنشاء الرابط المجهول: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error generating anonymous link',
        screen: 'ProfileScreen',
        operation: 'generateAnonymousLink',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<void> createProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.id)
          .set(profile.toJson(), SetOptions(merge: true));
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to create user profile',
        screen: 'AuthScreen',
        operation: 'createProfile',
        collection: 'users',
        documentId: profile.id,
      );
      throw AppException('فشل في إنشاء الملف الشخصي: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error creating profile',
        screen: 'AuthScreen',
        operation: 'createProfile',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<bool> profileExists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<UserProfile> getProfileByAnonymousLink(String anonymousLink) async {
    try {
      // Get the user ID from the anonymous link
      final linkDoc = await _firestore
          .collection('anonymous_links')
          .doc(anonymousLink)
          .get();

      if (!linkDoc.exists) {
        throw AppException('الرابط غير صالح أو منتهي الصلاحية');
      }

      final userId = linkDoc.data()!['userId'] as String;

      // Get the user profile
      return await getProfile(userId);
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get profile by anonymous link',
        screen: 'AnonymousProfileScreen',
        operation: 'getProfileByAnonymousLink',
        collection: 'anonymous_links',
        documentId: anonymousLink,
      );
      throw AppException('فشل في جلب الملف الشخصي: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error getting profile by anonymous link',
        screen: 'AnonymousProfileScreen',
        operation: 'getProfileByAnonymousLink',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }
}
