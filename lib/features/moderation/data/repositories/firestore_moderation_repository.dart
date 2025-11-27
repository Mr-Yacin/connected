import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/report.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/data/base_firestore_repository.dart';
import '../../domain/repositories/moderation_repository.dart';

/// Firestore implementation of ModerationRepository
class FirestoreModerationRepository extends BaseFirestoreRepository 
    implements ModerationRepository {
  final FirebaseFirestore _firestore;

  FirestoreModerationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> blockUser(String userId, String blockedUserId) async {
    return handleFirestoreVoidOperation(
      operation: () async {
        await _firestore.collection('blocks').add({
          'blockerId': userId,
          'blockedUserId': blockedUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      },
      operationName: 'blockUser',
      screen: 'ProfileScreen',
      arabicErrorMessage: 'فشل في حظر المستخدم',
      collection: 'blocks',
    );
  }

  @override
  Future<void> unblockUser(String userId, String blockedUserId) async {
    return handleFirestoreVoidOperation(
      operation: () async {
        final snapshot = await _firestore
            .collection('blocks')
            .where('blockerId', isEqualTo: userId)
            .where('blockedUserId', isEqualTo: blockedUserId)
            .get();

        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      },
      operationName: 'unblockUser',
      screen: 'BlockedUsersScreen',
      arabicErrorMessage: 'فشل في إلغاء حظر المستخدم',
      collection: 'blocks',
    );
  }

  @override
  Future<List<String>> getBlockedUsers(String userId) async {
    return handleFirestoreOperation(
      operation: () async {
        final snapshot = await _firestore
            .collection('blocks')
            .where('blockerId', isEqualTo: userId)
            .get();

        return snapshot.docs
            .map((doc) => doc.data()['blockedUserId'] as String)
            .toList();
      },
      operationName: 'getBlockedUsers',
      screen: 'BlockedUsersScreen',
      arabicErrorMessage: 'فشل في جلب قائمة المستخدمين المحظورين',
      collection: 'blocks',
    );
  }

  @override
  Future<void> reportContent(Report report) async {
    return handleFirestoreVoidOperation(
      operation: () async {
        await _firestore.collection('reports').add(report.toJson());
      },
      operationName: 'reportContent',
      screen: 'ProfileScreen',
      arabicErrorMessage: 'فشل في الإبلاغ عن المحتوى',
      collection: 'reports',
    );
  }

  @override
  Future<List<Report>> getPendingReports() async {
    return handleFirestoreOperation(
      operation: () async {
        final snapshot = await _firestore
            .collection('reports')
            .where('status', isEqualTo: ReportStatus.pending.name)
            .orderBy('timestamp', descending: true)
            .get();

        return mapQuerySnapshot(
          snapshot: snapshot,
          fromJson: Report.fromJson,
        );
      },
      operationName: 'getPendingReports',
      screen: 'ModerationScreen',
      arabicErrorMessage: 'فشل في جلب البلاغات المعلقة',
      collection: 'reports',
    );
  }

  @override
  Future<void> takeAction(
    String reportId,
    ReportStatus newStatus, {
    String? moderatorNotes,
  }) async {
    return handleFirestoreVoidOperation(
      operation: () async {
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
      },
      operationName: 'takeAction',
      screen: 'ModerationScreen',
      arabicErrorMessage: 'فشل في اتخاذ إجراء على البلاغ',
      collection: 'reports',
      documentId: reportId,
    );
  }
}
