import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/discovery_provider.dart';
import '../widgets/user_card.dart';
import '../widgets/filter_bottom_sheet.dart';

/// Screen for discovering random users (Shuffle feature)
class ShuffleScreen extends ConsumerStatefulWidget {
  const ShuffleScreen({super.key});

  @override
  ConsumerState<ShuffleScreen> createState() => _ShuffleScreenState();
}

class _ShuffleScreenState extends ConsumerState<ShuffleScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize with current user ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
        ref.read(discoveryProvider.notifier).setCurrentUserId(currentUser.uid);
        ref.read(discoveryProvider.notifier).getRandomUser();
      }
    });
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
          ref.read(discoveryProvider.notifier).getRandomUser();
        },
      ),
    );
  }

  void _handleLike() {
    // TODO: Implement like functionality (could save to favorites)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم الإعجاب!')),
    );
    _loadNextUser();
  }

  void _handleSkip() {
    ref.read(discoveryProvider.notifier).skipCurrentUser();
    _loadNextUser();
  }

  void _handleChat() {
    final currentUser = ref.read(discoveryProvider).currentUser;
    if (currentUser != null) {
      // TODO: Navigate to chat screen with this user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('بدء محادثة مع ${currentUser.name ?? "المستخدم"}')),
      );
    }
  }

  void _loadNextUser() {
    ref.read(discoveryProvider.notifier).getRandomUser();
  }

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(discoveryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الشفل'),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Filter indicator
              if (discoveryState.filters.hasActiveFilters)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
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
                      Text(
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
                          ref.read(discoveryProvider.notifier).getRandomUser();
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
              const SizedBox(height: 16),
              
              // Main content
              Expanded(
                child: _buildContent(discoveryState, isDark),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: discoveryState.currentUser != null &&
              !discoveryState.isLoading
          ? FloatingActionButton.extended(
              onPressed: _loadNextUser,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.shuffle),
              label: const Text('شفل'),
            )
          : null,
    );
  }

  Widget _buildContent(DiscoveryState state, bool isDark) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
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
              onPressed: _loadNextUser,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (state.currentUser == null) {
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

    return Center(
      child: SingleChildScrollView(
        child: UserCard(
          user: state.currentUser!,
          onLike: _handleLike,
          onSkip: _handleSkip,
          onChat: _handleChat,
        ),
      ),
    );
  }
}
