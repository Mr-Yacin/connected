import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/models/story.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../services/monitoring/app_logger.dart';
import '../../../../services/monitoring/error_logging_service.dart';
import '../providers/story_provider.dart';
import 'common/story_stats_row.dart';
import 'story_insights_dialog.dart';

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
            subtitle: StoryStatsText.formatStatsText(
              viewCount: story.viewerIds.length,
              likeCount: story.likedBy.length,
              replyCount: story.replyCount,
            ),
            onTap: () {
              // Don't close bottom sheet, show dialog on top
              showStoryInsightsDialog(
                context: context,
                story: story,
              );
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
    // Get the ScaffoldMessenger before showing dialogs
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
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
              onPressed: () async {
                // Close confirmation dialog
                Navigator.pop(dialogContext);
                // Close bottom sheet
                Navigator.pop(context);
                // Delete story
                await _deleteStory(scaffoldMessenger, repository, ref);
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
  Future<void> _deleteStory(ScaffoldMessengerState scaffoldMessenger, dynamic repository, WidgetRef ref) async {
    AppLogger.debug('Starting story deletion: ${story.id}');
    
    try {
      AppLogger.debug('Calling repository.deleteStory()');
      await repository.deleteStory(story.id);
      AppLogger.debug('Story deleted successfully from repository');
    } catch (e, stackTrace) {
      ErrorLoggingService.logFirestoreError(
        e,
        stackTrace: stackTrace,
        context: 'Error deleting story',
        screen: 'StoryManagementSheet',
        operation: 'deleteStory',
        collection: 'stories',
        documentId: story.id,
      );
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('فشل في حذف القصة: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return; // Exit early on error
    }

    // Only continue if deletion was successful
    try {
      // Invalidate providers to refresh UI
      AppLogger.debug('Invalidating providers');
      ref.invalidate(activeStoriesProvider);
      ref.invalidate(userStoriesProvider(currentUserId));
      ref.invalidate(followingStoriesProvider);

      // Call the onDeleted callback if provided
      if (onDeleted != null) {
        AppLogger.debug('Calling onDeleted callback');
        onDeleted!();
      }

      AppLogger.debug('Showing success message');
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('تم حذف القصة بنجاح'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Error during post-deletion cleanup',
        screen: 'StoryManagementSheet',
        operation: 'postDeletionCleanup',
      );
      // Still show success since the story was deleted
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('تم حذف القصة بنجاح'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
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


