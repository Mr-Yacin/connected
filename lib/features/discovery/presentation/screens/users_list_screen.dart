import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/chat_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/discovery_provider.dart';
import '../widgets/filter_bottom_sheet.dart';

/// Screen for browsing users with pagination
class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Initialize with current user ID and load first page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
        ref.read(discoveryProvider.notifier).setCurrentUserId(currentUser.uid);
        ref.read(discoveryProvider.notifier).loadUsers();
      }
    });

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when reaching 80% of scroll
      ref.read(discoveryProvider.notifier).loadMoreUsers();
    }
  }

  void _showFilterBottomSheet() {
    final currentFilters = ref.read(discoveryProvider).filters;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialFilters: currentFilters,
        onApply: (filters) {
          ref.read(discoveryProvider.notifier).updateFilters(filters);
          ref.read(discoveryProvider.notifier).loadUsers();
        },
      ),
    );
  }

  void _handleUserTap(String userId, String userName, String? imageUrl) {
    final loggedInUser = ref.read(currentUserProvider).value;
    if (loggedInUser != null) {
      // Generate deterministic chat ID to prevent duplicates
      final chatId = ChatUtils.generateChatId(loggedInUser.uid, userId);
      context.push(
        '/chat/$chatId?currentUserId=${loggedInUser.uid}&otherUserId=$userId&otherUserName=${Uri.encodeComponent(userName)}&otherUserImageUrl=${Uri.encodeComponent(imageUrl ?? "")}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(discoveryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('اكتشف المستخدمين'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
            tooltip: 'الفلاتر',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter indicator
            if (discoveryState.filters.hasActiveFilters)
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.filter_alt,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'الفلاتر نشطة',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        ref.read(discoveryProvider.notifier).resetFilters();
                        ref.read(discoveryProvider.notifier).loadUsers();
                      },
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

            // Main content
            Expanded(child: _buildContent(discoveryState, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(DiscoveryState state, bool isDark) {
    if (state.isLoading && state.discoveredUsers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.discoveredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(discoveryProvider.notifier).loadUsers();
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (state.discoveredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'لا يوجد مستخدمين متاحين',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'جرب تغيير الفلاتر أو العودة لاحقاً',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showFilterBottomSheet,
              icon: const Icon(Icons.filter_list),
              label: const Text('تعديل الفلاتر'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(discoveryProvider.notifier).loadUsers();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        itemCount: state.discoveredUsers.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.discoveredUsers.length) {
            // Loading indicator at the end
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: state.isLoadingMore
                    ? const CircularProgressIndicator()
                    : const SizedBox.shrink(),
              ),
            );
          }

          final user = state.discoveredUsers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12.0),
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? Text(
                        user.name?.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
              title: Text(
                user.name ?? 'مستخدم',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Row(
                children: [
                  if (user.age != null) ...[
                    Icon(Icons.cake, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${user.age} سنة'),
                    const SizedBox(width: 12),
                  ],
                  if (user.country != null) ...[
                    Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(user.country!),
                  ],
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                color: AppColors.primary,
                onPressed: () => _handleUserTap(
                  user.id,
                  user.name ?? 'مستخدم',
                  user.profileImageUrl,
                ),
              ),
              onTap: () => _handleUserTap(
                user.id,
                user.name ?? 'مستخدم',
                user.profileImageUrl,
              ),
            ),
          );
        },
      ),
    );
  }
}
