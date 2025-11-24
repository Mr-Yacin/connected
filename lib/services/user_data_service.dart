import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/exceptions/app_exceptions.dart';

/// Service for managing user data operations including deletion and export
class UserDataService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  UserDataService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  /// Delete user account and all associated data
  /// This marks the account for deletion and schedules data cleanup
  Future<void> deleteUserAccount(String userId) async {
    try {
      // Verify the current user is deleting their own account
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw PermissionException('غير مصرح بحذف هذا الحساب');
      }

      // Delete all user data
      await deleteUserData(userId);

      // Delete the authentication account
      await currentUser.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException('فشل حذف الحساب: ${e.message}', code: e.code);
    } on FirebaseException catch (e) {
      throw AppException('فشل حذف بيانات المستخدم: ${e.message}', code: e.code);
    } catch (e) {
      throw AppException('حدث خطأ أثناء حذف الحساب: $e');
    }
  }

  /// Delete all user data from Firestore and Storage
  /// This includes profile, messages, stories, reports, and blocks
  Future<void> deleteUserData(String userId) async {
    try {
      final batch = _firestore.batch();

      // Delete user profile
      final userDoc = _firestore.collection('users').doc(userId);
      batch.delete(userDoc);

      // Delete user's messages (as sender)
      final sentMessages = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .get();
      for (var doc in sentMessages.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's stories
      final stories = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in stories.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's reports (as reporter)
      final reports = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: userId)
          .get();
      for (var doc in reports.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's blocks (as blocker)
      final blocks = await _firestore
          .collection('blocks')
          .where('blockerId', isEqualTo: userId)
          .get();
      for (var doc in blocks.docs) {
        batch.delete(doc.reference);
      }

      // Commit all deletions
      await batch.commit();

      // Delete user's storage files
      await _deleteUserStorageFiles(userId);
    } on FirebaseException catch (e) {
      throw AppException('فشل حذف البيانات: ${e.message}', code: e.code);
    } catch (e) {
      throw AppException('حدث خطأ أثناء حذف البيانات: $e');
    }
  }

  /// Delete all user files from Firebase Storage
  Future<void> _deleteUserStorageFiles(String userId) async {
    try {
      // Delete profile images
      final profileImagesRef = _storage.ref('profile_images/$userId');
      await _deleteDirectory(profileImagesRef);

      // Delete voice messages
      final voiceMessagesRef = _storage.ref('voice_messages/$userId');
      await _deleteDirectory(voiceMessagesRef);

      // Delete stories media
      final storiesRef = _storage.ref('stories/$userId');
      await _deleteDirectory(storiesRef);
    } catch (e) {
      // Log error but don't throw - storage deletion is best effort
      print('تحذير: فشل حذف بعض الملفات من التخزين: $e');
    }
  }

  /// Recursively delete all files in a storage directory
  Future<void> _deleteDirectory(Reference ref) async {
    try {
      final listResult = await ref.listAll();

      // Delete all files
      for (var item in listResult.items) {
        await item.delete();
      }

      // Recursively delete subdirectories
      for (var prefix in listResult.prefixes) {
        await _deleteDirectory(prefix);
      }
    } catch (e) {
      // Ignore errors for non-existent directories
      if (!e.toString().contains('object-not-found')) {
        rethrow;
      }
    }
  }

  /// Export all user data for GDPR compliance
  /// Returns a JSON-serializable map of all user data
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final exportData = <String, dynamic>{};

      // Export user profile
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        exportData['profile'] = userDoc.data();
      }

      // Export messages
      final sentMessages = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .get();
      exportData['sentMessages'] = sentMessages.docs
          .map((doc) => doc.data())
          .toList();

      final receivedMessages = await _firestore
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .get();
      exportData['receivedMessages'] = receivedMessages.docs
          .map((doc) => doc.data())
          .toList();

      // Export stories
      final stories = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .get();
      exportData['stories'] = stories.docs
          .map((doc) => doc.data())
          .toList();

      // Export reports (as reporter)
      final reports = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: userId)
          .get();
      exportData['reports'] = reports.docs
          .map((doc) => doc.data())
          .toList();

      // Export blocks
      final blocks = await _firestore
          .collection('blocks')
          .where('blockerId', isEqualTo: userId)
          .get();
      exportData['blocks'] = blocks.docs
          .map((doc) => doc.data())
          .toList();

      // Add metadata
      exportData['exportDate'] = DateTime.now().toIso8601String();
      exportData['userId'] = userId;

      return exportData;
    } on FirebaseException catch (e) {
      throw AppException('فشل تصدير البيانات: ${e.message}', code: e.code);
    } catch (e) {
      throw AppException('حدث خطأ أثناء تصدير البيانات: $e');
    }
  }
}
