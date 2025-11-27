import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/user_list_screen.dart';
import '../providers/follow_provider.dart';

/// Screen to display followers list
class FollowersListScreen extends ConsumerWidget {
  final String userId;
  final String userName;

  const FollowersListScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UserListScreen(
      title: 'متابعو $userName',
      userId: userId,
      userName: userName,
      userIdsFetcher: (uid) => ref.read(followRepositoryProvider).getFollowers(uid),
      emptyMessage: 'لا يوجد متابعون',
      emptyIcon: Icons.people_outline,
      errorPrefix: 'فشل في تحميل المتابعين',
    );
  }
}
