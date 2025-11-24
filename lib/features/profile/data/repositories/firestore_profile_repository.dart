import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/repositories/profile_repository.dart';

/// Firestore implementation of ProfileRepository
class FirestoreProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Uuid _uuid;

  FirestoreProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _uuid = uuid ?? const Uuid();

  @override
  Future<UserProfile> getProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        throw AppException('المستخدم غير موجود');
      }
      
      return UserProfile.fromJson(doc.data()!);
    } on FirebaseException catch (e) {
      throw AppException('فشل في جلب بيانات المستخدم: ${e.message}');
    } catch (e) {
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    try {
      // Update lastActive timestamp
      final updatedProfile = profile.copyWith(
        lastActive: DateTime.now(),
      );
      
      await _firestore
          .collection('users')
          .doc(profile.id)
          .set(updatedProfile.toJson(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw AppException('فشل في تحديث البيانات: ${e.message}');
    } catch (e) {
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<String> uploadProfileImage(String userId, File image) async {
    try {
      // Create a unique filename
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('profile_images/$userId/$fileName');
      
      // Upload the file
      final uploadTask = await ref.putFile(image);
      
      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw AppException('فشل في رفع الصورة: ${e.message}');
    } catch (e) {
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<String> generateAnonymousLink(String userId) async {
    try {
      // Generate a unique link using UUID
      final uniqueId = _uuid.v4();
      final anonymousLink = 'social-connect://profile/$uniqueId';
      
      // Store the mapping in Firestore
      await _firestore.collection('anonymous_links').doc(uniqueId).set({
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return anonymousLink;
    } on FirebaseException catch (e) {
      throw AppException('فشل في توليد الرابط: ${e.message}');
    } catch (e) {
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }
}
