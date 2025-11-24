import 'enums.dart';

/// Report model representing a content moderation report
class Report {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String? reportedContentId;
  final ReportType type;
  final String reason;
  final ReportStatus status;
  final DateTime createdAt;
  final String? moderatorNotes;

  Report({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    this.reportedContentId,
    required this.type,
    required this.reason,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.moderatorNotes,
  });

  /// Convert Report to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reportedContentId': reportedContentId,
      'type': type.name,
      'reason': reason,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'moderatorNotes': moderatorNotes,
    };
  }

  /// Create Report from JSON (Firestore document)
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      reporterId: json['reporterId'] as String,
      reportedUserId: json['reportedUserId'] as String,
      reportedContentId: json['reportedContentId'] as String?,
      type: ReportType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReportType.user,
      ),
      reason: json['reason'] as String,
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      moderatorNotes: json['moderatorNotes'] as String?,
    );
  }

  /// Create a copy of Report with updated fields
  Report copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    String? reportedContentId,
    ReportType? type,
    String? reason,
    ReportStatus? status,
    DateTime? createdAt,
    String? moderatorNotes,
  }) {
    return Report(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reportedContentId: reportedContentId ?? this.reportedContentId,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      moderatorNotes: moderatorNotes ?? this.moderatorNotes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Report &&
        other.id == id &&
        other.reporterId == reporterId &&
        other.reportedUserId == reportedUserId &&
        other.reportedContentId == reportedContentId &&
        other.type == type &&
        other.reason == reason &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.moderatorNotes == moderatorNotes;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      reporterId,
      reportedUserId,
      reportedContentId,
      type,
      reason,
      status,
      createdAt,
      moderatorNotes,
    );
  }
}
