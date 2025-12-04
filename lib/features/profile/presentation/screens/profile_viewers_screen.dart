import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../services/analytics/profile_view_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/firestore_profile_repository.dart';

/// Screen to display who viewed your profile
class ProfileViewersScreen extends ConsumerStatefulWidget {
  const ProfileViewersScreen({super.key});

  @override
  ConsumerState<ProfileViewersScreen> createState() =>
      _ProfileViewersScreenState();
}

class _ProfileViewersScreenState extends ConsumerState<ProfileViewersScreen> {
  List<String>? _viewerIds;
  Map<String, UserProfile> _viewerProfiles = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadViewers();
  }

  Future<void> _loadViewers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        setState(() {
          _error = 'يجب تسجيل الدخول';
          _isLoading = false;
        });
        return;
      }

      // Get viewer IDs
      final viewerIds = await ref
          .read(profileViewServiceProvider)
          .getProfileViews(currentUser.uid);

      setState(() {
        _viewerIds = viewerIds;
      });

      // Load viewer profiles
      final profileRepo = FirestoreProfileRepository();
      final profiles = <String, UserProfile>{};

      for (final viewerId in viewerIds) {
        try {
          final profile = await profileRepo.getProfile(viewerId);
          if (profile != null) {
            profiles[viewerId] = profile;
          }
        } catch (e) {
          debugPrint('Failed to load profile for $viewerId: $e');
        }
      }

      setState(() {
        _viewerProfiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل في تحميل الزوار: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('من شاهد ملفي'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadViewers,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _viewerIds == null || _viewerIds!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility_off,
                            size: 64,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد زيارات حتى الآن',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'عندما يزور أحد ملفك الشخصي، سيظهر هنا',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadViewers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _viewerIds!.length,
                        itemBuilder: (context, index) {
                          final viewerId = _viewerIds![index];
                          final profile = _viewerProfiles[viewerId];

                          if (profile == null) {
                            return const SizedBox.shrink();
                          }

                          return _buildViewerCard(profile, isDark);
                        },
                      ),
                    ),
    );
  }

  Widget _buildViewerCard(UserProfile profile, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.push('/profile/${profile.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Image
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[300],
                backgroundImage: profile.profileImageUrl != null &&
                        profile.profileImageUrl!.isNotEmpty
                    ? NetworkImage(profile.profileImageUrl!)
                    : null,
                child: profile.profileImageUrl == null ||
                        profile.profileImageUrl!.isEmpty
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),

              // Profile Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name ?? 'مستخدم',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (profile.age != null) ...[
                          Icon(
                            Icons.cake_outlined,
                            size: 16,
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${profile.age} سنة',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                        if (profile.age != null && profile.country != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        if (profile.country != null) ...[
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            profile.country!,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

