import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/models/report.dart';
import '../../../../core/models/enums.dart';
import '../../domain/repositories/moderation_repository.dart';

/// Firestore implementation of ModerationRepository
class FirestoreModerationRepository implements ModerationRepository {
  final FirebaseFirestore _firestore;

  FirestoreModerationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> blockUser(String userId, String blockedUserId) async {
    try {
      // Validate inputs
      if (userId.isEmpty || blockedUserId.isEmpty) {
        throw ValidationException('معرفات المستخدمين مطلوبة');
      }

      if (userId == blockedUserId) {
        throw ValidationException('لا يمكنك حظر نفسك');
      }

      // Create block document
      final blockId = '${userId}_$blockedUserId';
      await _firestore.collection('blocks').doc(blockId).set({
        'blockerId': userId,
        'blockedUserId': blockedUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw AppException('فشل حظر المستخدم: ${e.toString()}');
    }
  }

  @override
  Future<void> unblockUser(String userId, String blockedUserId) async {
    try {
      // Validate inputs
      if (userId.isEmpty || blockedUserId.isEmpty) {
        throw ValidationException('معرفات المستخدمين مطلوبة');
      }

      // Delete block document
      final blockId = '${userId}_$blockedUserId';
      await _firestore.collection('blocks').doc(blockId).delete();
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw AppException('فشل إلغاء حظر المستخدم: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      // Validate input
      if (userId.isEmpty) {
        throw ValidationException('معرف المستخدم مطلوب');
      }

      // Query blocks where this user is the blocker
      final querySnapshot = await _firestore
          .collection('blocks')
          .where('blockerId', isEqualTo: userId)
          .get();

      // Extract blocked user IDs
      return querySnapshot.docs
          .map((doc) => doc.data()['blockedUserId'] as String)
          .toList();
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw AppException('فشل جلب قائمة المحظورين: ${e.toString()}');
    }
  }

  @override
  Future<void> reportContent(Report report) async {
    try {
      // Validate report
      if (report.reporterId.isEmpty || report.reportedUserId.isEmpty) {
        throw ValidationException('معرفات المستخدمين مطلوبة');
      }

      if (report.reason.trim().isEmpty) {
        throw ValidationException('سبب البلاغ مطلوب');
      }

      // Save report to Firestore
      await _firestore.collection('reports').doc(report.id).set(report.toJson());
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw AppException('فشل إنشاء البلاغ: ${e.toString()}');
    }
  }

  @override
  Future<List<Report>> getPendingReports() async {
    try {
      // Query reports with pending status
      final querySnapshot = await _firestore
          .collection('reports')
          .where('status', isEqualTo: ReportStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();

      // Convert to Report objects
      return querySnapshot.docs
          .map((doc) => Report.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw AppException('فشل جلب البلاغات المعلقة: ${e.toString()}');
    }
  }

  @override
  Future<void> takeAction(
    String reportId,
    ReportStatus newStatus, {
    String? moderatorNotes,
  }) async {
    try {
      // Validate inputs
      if (reportId.isEmpty) {
        throw ValidationException('معرف البلاغ مطلوب');
      }

      if (newStatus == ReportStatus.pending) {
        throw ValidationException('لا يمكن تغيير الحالة إلى معلق');
      }

      // Update report status and notes
      final updateData = <String, dynamic>{
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (moderatorNotes != null && moderatorNotes.isNotEmpty) {
        updateData['moderatorNotes'] = moderatorNotes;
      }

      await _firestore.collection('reports').doc(reportId).update(updateData);
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw AppException('فشل اتخاذ إجراء على البلاغ: ${e.toString()}');
    }
  }
}
