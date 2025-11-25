import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/report.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/repositories/moderation_repository.dart';
import '../../../../services/error_logging_service.dart';

/// Firestore implementation of ModerationRepository
class FirestoreModerationRepository implements ModerationRepository {
  final FirebaseFirestore _firestore;

  FirestoreModerationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> blockUser(String userId, String blockedUserId) async {
    try {
      await _firestore.collection('blocks').add({
        'blockerId': userId,
        'blockedUserId': blockedUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to block user',
        screen: 'ProfileScreen',
        operation: 'blockUser',
        collection: 'blocks',
      );
      throw AppException('فشل في حظر المستخدم: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error blocking user',
        screen: 'ProfileScreen',
        operation: 'blockUser',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<void> unblockUser(String userId, String blockedUserId) async {
    try {
      final snapshot = await _firestore
          .collection('blocks')
          .where('blockerId', isEqualTo: userId)
          .where('blockedUserId', isEqualTo: blockedUserId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to unblock user',
        screen: 'BlockedUsersScreen',
        operation: 'unblockUser',
        collection: 'blocks',
      );
      throw AppException('فشل في إلغاء حظر المستخدم: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error unblocking user',
        screen: 'BlockedUsersScreen',
        operation: 'unblockUser',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('blocks')
          .where('blockerId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['blockedUserId'] as String)
          .toList();
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get blocked users',
        screen: 'BlockedUsersScreen',
        operation: 'getBlockedUsers',
        collection: 'blocks',
      );
      throw AppException('فشل في جلب قائمة المستخدمين المحظورين: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error getting blocked users',
        screen: 'BlockedUsersScreen',
        operation: 'getBlockedUsers',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<void> reportContent(Report report) async {
    try {
      await _firestore.collection('reports').add(report.toJson());
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to report content',
        screen: 'ProfileScreen',
        operation: 'reportContent',
        collection: 'reports',
      );
      throw AppException('فشل في الإبلاغ عن المحتوى: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error reporting content',
        screen: 'ProfileScreen',
        operation: 'reportContent',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<List<Report>> getPendingReports() async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('status', isEqualTo: ReportStatus.pending.name)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Report.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get pending reports',
        screen: 'ModerationScreen',
        operation: 'getPendingReports',
        collection: 'reports',
      );
      throw AppException('فشل في جلب البلاغات المعلقة: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error getting pending reports',
        screen: 'ModerationScreen',
        operation: 'getPendingReports',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }

  @override
  Future<void> takeAction(
    String reportId,
    ReportStatus newStatus, {
    String? moderatorNotes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (moderatorNotes != null) {
        updateData['moderatorNotes'] = moderatorNotes;
      }

      await _firestore
          .collection('reports')
          .doc(reportId)
          .update(updateData);
    } on FirebaseException catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to take action on report',
        screen: 'ModerationScreen',
        operation: 'takeAction',
        collection: 'reports',
        documentId: reportId,
      );
      throw AppException('فشل في اتخاذ إجراء على البلاغ: ${e.message}');
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Unexpected error taking action on report',
        screen: 'ModerationScreen',
        operation: 'takeAction',
      );
      throw AppException('حدث خطأ غير متوقع: $e');
    }
  }
}
