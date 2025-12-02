import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/discovery_filters.dart';
import '../../../../services/analytics/analytics_events.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../discovery/presentation/screens/shuffle_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../stories/presentation/widgets/story_bar_widget.dart';
import '../../../stories/presentation/widgets/stories_grid_widget.dart';
import '../../../stories/presentation/widgets/story_filter_bottom_sheet.dart';
import '../../../stories/presentation/screens/story_camera_screen.dart';
import '../widgets/bottom_nav_bar.dart';

/// Main home screen with bottom navigation
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  DiscoveryFilters _activeFilters = DiscoveryFilters();

  @override
  void initState() {
    super.initState();
    // Track initial screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsEventsProvider).trackScreenView('home_screen');
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryFilterBottomSheet(
        initialFilters: _activeFilters,
        onApply: (filters) {
          setState(() {
            _activeFilters = filters;
          });
        },
      ),
    );
  }

  void _onTabChanged(int index) {
    final analytics = ref.read(analyticsEventsProvider);
    
    // Track tab changes
    final tabs = ['home', 'shuffle', 'chat', 'profile'];
    analytics.trackTabChanged(
      fromTab: tabs[_currentIndex],
      toTab: tabs[index],
    );
    
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          // This shouldn't happen due to auth guard, but handle it gracefully
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeTab(user.uid),
                const ShuffleScreen(),
                ChatListScreen(currentUserId: user.uid),
                const ProfileScreen(),
              ],
            ),
            bottomNavigationBar: BottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onTabChanged,
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('حدث خطأ: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab(String userId) {
    return SafeArea(
      child: Column(
        children: [
          // App bar with title, filter, and add icon
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Filter button on the left
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list, size: 28),
                      onPressed: _showFilterBottomSheet,
                      tooltip: 'تصفية القصص',
                    ),
                    // Filter indicator badge
                    if (_activeFilters.hasActiveFilters)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Title in the center
                Text(
                  'القصص',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Add story button on the right
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 28),
                  onPressed: () {
                    // Navigate to story camera
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoryCameraScreen(userId: userId),
                      ),
                    );
                  },
                  tooltip: 'إضافة قصة',
                ),
              ],
            ),
          ),

          // Story bar - Horizontal scroll (Mine and Following)
          StoryBarWidget(currentUserId: userId),

          const Divider(),

          // Stories Grid - Main content with filters
          Expanded(
            child: StoriesGridWidget(
              key: ValueKey(_activeFilters.hashCode),
              currentUserId: userId,
              filters: _activeFilters,
            ),
          ),
        ],
      ),
    );
  }
}
