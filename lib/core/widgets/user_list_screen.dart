import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../theme/app_colors.dart';

/// Generic user list screen that can be reused for followers, following, likes, etc.
/// 
/// This widget eliminates code duplication between similar list screens.
class UserListScreen extends StatefulWidget {
  /// Title to display in the app bar
  final String title;
  
  /// Function to fetch user IDs based on the current user ID
  final Future<List<String>> Function(String userId) userIdsFetcher;
  
  /// Current user ID
  final String userId;
  
  /// Current user name (for display in title)
  final String userName;
  
  /// Optional empty state message
  final String? emptyMessage;
  
  /// Optional error prefix for error messages
  final String? errorPrefix;
  
  /// Optional icon for empty state
  final IconData? emptyIcon;
  
  /// Whether to show count badge in app bar
  final bool showCountBadge;

  const UserListScreen({
    super.key,
    required this.title,
    required this.userIdsFetcher,
    required this.userId,
    required this.userName,
    this.emptyMessage,
    this.errorPrefix,
    this.emptyIcon,
    this.showCountBadge = true,
  });

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _userProfileService = UserProfileService();
  List<UserProfile> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userIds = await widget.userIdsFetcher(widget.userId);
      final profiles = await _userProfileService.fetchMultipleProfiles(userIds);
      
      if (mounted) {
        setState(() {
          _users = profiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: widget.showCountBadge && _users.isNotEmpty
            ? [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_users.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              '${widget.errorPrefix ?? "حدث خطأ"}: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.emptyIcon ?? Icons.people_outline,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              widget.emptyMessage ?? 'لا يوجد مستخدمون',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return _UserListCard(user: user);
        },
      ),
    );
  }
}

/// Card widget for user in list
class _UserListCard extends StatelessWidget {
  final UserProfile user;

  const _UserListCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.push('/profile/${user.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? Icon(Icons.person, size: 32, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? 'مستخدم',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (user.age != null) ...[
                          Icon(Icons.cake_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${user.age} سنة',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                        if (user.age != null && user.country != null)
                          const SizedBox(width: 8),
                        if (user.country != null) ...[
                          Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              user.country!,
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
