import 'package:flutter/material.dart';
import '../../../../core/models/story.dart';
import '../../../../core/theme/app_colors.dart';

/// Reusable story insights dialog that displays detailed statistics
/// 
/// Shows:
/// - View count
/// - Like count
/// - Reply count
/// - Time remaining until expiration
/// 
/// Usage:
/// ```dart
/// showStoryInsightsDialog(
///   context: context,
///   story: story,
/// );
/// ```
void showStoryInsightsDialog({
  required BuildContext context,
  required Story story,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => StoryInsightsDialog(story: story),
  );
}

/// Story insights dialog widget
class StoryInsightsDialog extends StatelessWidget {
  final Story story;

  const StoryInsightsDialog({
    super.key,
    required this.story,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'إحصائيات القصة',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InsightRow(
            icon: Icons.visibility_rounded,
            label: 'المشاهدات',
            value: '${story.viewerIds.length}',
          ),
          const SizedBox(height: 16),
          _InsightRow(
            icon: Icons.favorite_rounded,
            label: 'الإعجابات',
            value: '${story.likedBy.length}',
          ),
          const SizedBox(height: 16),
          _InsightRow(
            icon: Icons.reply_rounded,
            label: 'الردود',
            value: '${story.replyCount}',
          ),
          const SizedBox(height: 16),
          _InsightRow(
            icon: Icons.access_time_rounded,
            label: 'تنتهي في',
            value: _getTimeRemaining(story),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  /// Calculate time remaining until story expires
  static String _getTimeRemaining(Story story) {
    final now = DateTime.now();
    final remaining = story.expiresAt.difference(now);

    if (remaining.isNegative) {
      return 'منتهية';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    if (hours > 0) {
      return '$hours ساعة و $minutes دقيقة';
    } else {
      return '$minutes دقيقة';
    }
  }
}

/// Insight row widget for displaying individual statistics
class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
      ],
    );
  }
}
