import '../../../../core/models/report.dart';
import '../../../../core/models/enums.dart';

/// Repository interface for moderation operations
abstract class ModerationRepository {
  /// Block a user
  /// 
  /// [userId] - The ID of the user performing the block
  /// [blockedUserId] - The ID of the user being blocked
  Future<void> blockUser(String userId, String blockedUserId);

  /// Unblock a user
  /// 
  /// [userId] - The ID of the user performing the unblock
  /// [blockedUserId] - The ID of the user being unblocked
  Future<void> unblockUser(String userId, String blockedUserId);

  /// Get list of blocked users for a specific user
  /// 
  /// [userId] - The ID of the user whose blocked list to retrieve
  /// Returns a list of blocked user IDs
  Future<List<String>> getBlockedUsers(String userId);

  /// Report content (user, message, or story)
  /// 
  /// [report] - The report object containing all details
  Future<void> reportContent(Report report);

  /// Get all pending reports (for moderators)
  /// 
  /// Returns a list of reports with pending status
  Future<List<Report>> getPendingReports();

  /// Take action on a report
  /// 
  /// [reportId] - The ID of the report
  /// [newStatus] - The new status to set (reviewed or resolved)
  /// [moderatorNotes] - Optional notes from the moderator
  Future<void> takeAction(
    String reportId,
    ReportStatus newStatus, {
    String? moderatorNotes,
  });
}
