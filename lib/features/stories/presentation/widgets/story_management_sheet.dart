import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/models/story.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../providers/story_provider.dart';

/// Bottom sheet for managing own stories (delete, view insights, share)
/// 
/// This widget provides three management options:
/// 1. View Insights - Shows story statistics (views, likes, replies, time remaining)
/// 2. Share Story - Shares the story using the share_plus package
/// 3. Delete Story - Deletes the story with confirmation dialog
/// 
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (context) => StoryManagementSheet(
///     story: story,
///     currentUserId: currentUserId,
///   ),
/// );
/// ```
class StoryManagementSheet extends ConsumerWidget {
  final Story story;
  final String currentUserId;
  final VoidCallback? onDeleted;

  const StoryManagementSheet({
    super.key,
    required this.story,
    required this.currentUserId,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'إدارة القصة',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // View Insights Option
          _ManagementOption(
            icon: Icons.bar_chart_rounded,
            label: 'عرض الإحصائيات',
            subtitle: '${story.viewerIds.length} مشاهدة • ${story.likedBy.length} إعجاب • ${story.replyCount} رد',
            onTap: () {
              // Don't close bottom sheet, show dialog on top
              _showInsightsDialog(context);
            },
          ),
          const SizedBox(height: 12),

          // Share Option
          _ManagementOption(
            icon: Icons.share_rounded,
            label: 'مشاركة القصة',
            subtitle: 'شارك القصة مع الآخرين',
            onTap: () {
              // Close bottom sheet before sharing (share dialog is external)
              Navigator.pop(context);
              _shareStory(context);
            },
          ),
          const SizedBox(height: 12),

          // Delete Option
          _ManagementOption(
            icon: Icons.delete_rounded,
            label: 'حذف القصة',
            subtitle: 'حذف القصة نهائياً',
            isDestructive: true,
            onTap: () {
              // Capture repository before showing confirmation
              final repository = ref.read(storyRepositoryProvider);
              // Don't close bottom sheet, show dialog on top
              _showDeleteConfirmation(context, repository, ref);
            },
          ),

          SizedBox(
            height: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom,
          ),
        ],
      ),
    );
  }

  /// Show insights dialog with detailed statistics
  void _showInsightsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
              value: _getTimeRemaining(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Close insights dialog
              Navigator.pop(dialogContext);
              // Close bottom sheet
              Navigator.pop(context);
            },
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  /// Calculate time remaining until story expires
  String _getTimeRemaining() {
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

  /// Share story using share_plus package
  void _shareStory(BuildContext context) {
    try {
      Share.share(
        'شاهد قصتي على التطبيق!\n${story.mediaUrl}',
        subject: 'قصة من التطبيق',
      );
    } catch (e) {
      SnackbarHelper.showError(
        context,
        'فشل في مشاركة القصة: ${e.toString()}',
      );
    }
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, dynamic repository, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, child) => AlertDialog(
          title: const Text(
            'حذف القصة',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'هل أنت متأكد من حذف هذه القصة؟ لا يمكن التراجع عن هذا الإجراء.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Close confirmation dialog
                Navigator.pop(dialogContext);
                // Close bottom sheet
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                // Close confirmation dialog
                Navigator.pop(dialogContext);
                // Close bottom sheet
                Navigator.pop(context);
                // Delete story
                _deleteStory(context, repository, ref);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  /// Delete story from repository
  Future<void> _deleteStory(BuildContext context, dynamic repository, WidgetRef ref) async {
    print('🗑️ Starting story deletion: ${story.id}');
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      print('🗑️ Calling repository.deleteStory()');
      await repository.deleteStory(story.id);
      print('✅ Story deleted successfully from repository');

      // Invalidate providers to refresh UI
      // We need to use a Consumer or get a new ref from context
      print('🔄 Invalidating providers');
      ref.invalidate(activeStoriesProvider);
      ref.invalidate(userStoriesProvider(currentUserId));

      // Close loading dialog
      if (context.mounted) {
        print('🚪 Closing loading dialog');
        Navigator.pop(context);
      }

      // Call the onDeleted callback if provided
      if (onDeleted != null) {
        print('📞 Calling onDeleted callback');
        onDeleted!();
      }

      if (context.mounted) {
        print('✅ Showing success message');
        SnackbarHelper.showSuccess(context, 'تم حذف القصة بنجاح');
      }
    } catch (e) {
      print('❌ Error deleting story: $e');
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        SnackbarHelper.showError(
          context,
          'فشل في حذف القصة: ${e.toString()}',
        );
      }
    }
  }
}

/// Management option widget
class _ManagementOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ManagementOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive ? AppColors.error : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDestructive ? AppColors.error : null,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

/// Insight row widget for displaying statistics
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
