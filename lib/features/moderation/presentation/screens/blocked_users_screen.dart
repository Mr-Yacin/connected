import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/data/repositories/firestore_profile_repository.dart';
import '../providers/moderation_provider.dart';

/// Screen for managing blocked users
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('المستخدمون المحظورون')),
        body: const Center(child: Text('يجب تسجيل الدخول أولاً')),
      );
    }

    final blockedUsersAsync = ref.watch(blockedUsersProvider(currentUser.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('المستخدمون المحظورون'),
      ),
      body: blockedUsersAsync.when(
        data: (blockedUserIds) {
          if (blockedUserIds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا يوجد مستخدمون محظورون',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: blockedUserIds.length,
            itemBuilder: (context, index) {
              final blockedUserId = blockedUserIds[index];
              return _BlockedUserTile(
                userId: currentUser.uid,
                blockedUserId: blockedUserId,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('حدث خطأ: ${error.toString()}'),
        ),
      ),
    );
  }
}

/// Tile widget for a blocked user
class _BlockedUserTile extends ConsumerWidget {
  final String userId;
  final String blockedUserId;

  const _BlockedUserTile({
    required this.userId,
    required this.blockedUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileRepository = FirestoreProfileRepository();

    return FutureBuilder(
      future: profileRepository.getProfile(blockedUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('جاري التحميل...'),
          );
        }

        final profile = snapshot.data!;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty
                ? NetworkImage(profile.profileImageUrl!)
                : null,
            onBackgroundImageError: profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty
                ? (exception, stackTrace) {
                    debugPrint('Failed to load blocked user image: ${profile.profileImageUrl}');
                  }
                : null,
            child: profile.profileImageUrl == null || profile.profileImageUrl!.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(profile.name ?? 'مستخدم'),
          subtitle: Text(profile.country ?? ''),
          trailing: ElevatedButton(
            onPressed: () async {
              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('إلغاء الحظر'),
                  content: Text('هل تريد إلغاء حظر ${profile.name ?? 'هذا المستخدم'}؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('نعم'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref
                    .read(moderationProvider.notifier)
                    .unblockUser(userId, blockedUserId);

                if (context.mounted) {
                  // Refresh the list
                  ref.invalidate(blockedUsersProvider(userId));
                  SnackbarHelper.showSuccess(context, 'تم إلغاء الحظر');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('إلغاء الحظر', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }
}
