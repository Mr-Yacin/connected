import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/user_list_screen.dart';
import '../providers/follow_provider.dart';

/// Screen to display following list
class FollowingListScreen extends ConsumerWidget {
  final String userId;
  final String userName;

  const FollowingListScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UserListScreen(
      title: 'متابعة $userName',
      userId: userId,
      userName: userName,
      userIdsFetcher: (uid) => ref.read(followRepositoryProvider).getFollowing(uid),
      emptyMessage: 'لا يوجد متابعة',
      emptyIcon: Icons.person_add_outlined,
      errorPrefix: 'فشل في تحميل المتابعة',
    );
  }
}
