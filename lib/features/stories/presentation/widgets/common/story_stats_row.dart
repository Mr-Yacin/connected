import 'package:flutter/material.dart';

/// Reusable story statistics row widget
/// 
/// Displays view count, like count, and reply count with icons.
/// Supports two display modes:
/// - Icon mode: Shows icons with numbers (default)
/// - Text mode: Shows numbers with Arabic labels
/// 
/// Usage:
/// ```dart
/// // Icon mode (for overlays)
/// StoryStatsRow(
///   viewCount: story.viewerIds.length,
///   likeCount: story.likedBy.length,
///   replyCount: story.replyCount,
/// )
/// 
/// // Text mode (for summaries)
/// StoryStatsRow.withLabels(
///   viewCount: story.viewerIds.length,
///   likeCount: story.likedBy.length,
///   replyCount: story.replyCount,
/// )
/// ```
class StoryStatsRow extends StatelessWidget {
  /// Number of views
  final int viewCount;
  
  /// Number of likes
  final int likeCount;
  
  /// Number of replies
  final int replyCount;
  
  /// Size of the icons
  final double iconSize;
  
  /// Font size for the numbers
  final double fontSize;
  
  /// Color for icons and text
  final Color color;
  
  /// Whether to show text labels (e.g., "مشاهدة", "إعجاب")
  final bool showLabels;
  
  /// Spacing between stat items
  final double spacing;
  
  /// Whether to hide replies when count is 0
  final bool hideZeroReplies;

  const StoryStatsRow({
    super.key,
    required this.viewCount,
    required this.likeCount,
    required this.replyCount,
    this.iconSize = 14,
    this.fontSize = 11,
    this.color = Colors.white,
    this.showLabels = false,
    this.spacing = 12,
    this.hideZeroReplies = true,
  });

  /// Constructor for text mode with labels
  const StoryStatsRow.withLabels({
    super.key,
    required this.viewCount,
    required this.likeCount,
    required this.replyCount,
    this.iconSize = 14,
    this.fontSize = 11,
    this.color = Colors.white,
    this.spacing = 12,
    this.hideZeroReplies = true,
  }) : showLabels = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStat(
          icon: Icons.visibility,
          count: viewCount,
          label: showLabels ? 'مشاهدة' : null,
        ),
        SizedBox(width: spacing),
        _buildStat(
          icon: Icons.favorite,
          count: likeCount,
          label: showLabels ? 'إعجاب' : null,
        ),
        if (!hideZeroReplies || replyCount > 0) ...[
          SizedBox(width: spacing),
          _buildStat(
            icon: Icons.message,
            count: replyCount,
            label: showLabels ? 'رد' : null,
          ),
        ],
      ],
    );
  }

  /// Builds a single stat item (icon + count + optional label)
  Widget _buildStat({
    required IconData icon,
    required int count,
    String? label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: iconSize),
        const SizedBox(width: 4),
        Text(
          label != null ? '$count $label' : '$count',
          style: TextStyle(
            color: color,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}

/// Extension for creating formatted stats text (for subtitles)
extension StoryStatsText on StoryStatsRow {
  /// Returns a formatted text string for stats
  /// Example: "5 مشاهدة • 3 إعجاب • 2 رد"
  static String formatStatsText({
    required int viewCount,
    required int likeCount,
    required int replyCount,
  }) {
    return '$viewCount مشاهدة • $likeCount إعجاب • $replyCount رد';
  }
}
