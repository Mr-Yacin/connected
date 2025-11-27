import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/user_list_screen.dart';
import '../../../../core/models/like.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/like_provider.dart';

/// Screen to display users who liked the current user
/// 
/// This screen is now refactored to use the generic UserListScreen widget,
/// eliminating code duplication and improving maintainability.
class LikesListScreen extends ConsumerWidget {
  const LikesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return UserListScreen(
      title: 'الإعجابات',
      userId: currentUser.uid,
      userName: currentUser.displayName ?? 'مستخدم',
      userIdsFetcher: (userId) async {
        // Fetch likes and extract user IDs
        final likes = await ref.read(likeProvider.notifier).getLikes(userId);
        return likes.map((like) => like.fromUserId).toList();
      },
      emptyMessage: 'لا يوجد إعجابات بعد\n\nعندما يعجب أحد بك، سيظهر هنا',
      emptyIcon: Icons.favorite_border,
      errorPrefix: 'فشل في تحميل الإعجابات',
      showCountBadge: true,
    );
  }
}
