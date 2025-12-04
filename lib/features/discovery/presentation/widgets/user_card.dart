import 'package:flutter/material.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget to display a user profile card in discovery
class UserCard extends StatelessWidget {
  final UserProfile user;
  final VoidCallback? onFollow;
  final VoidCallback? onChat;
  final VoidCallback? onViewProfile;
  final bool isFollowing;

  const UserCard({
    super.key,
    required this.user,
    this.onFollow,
    this.onChat,
    this.onViewProfile,
    this.isFollowing = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onViewProfile,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Image
              CircleAvatar(
                radius: 80,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                onBackgroundImageError: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                    ? (exception, stackTrace) {
                        debugPrint('Failed to load user card image: ${user.profileImageUrl}');
                      }
                    : null,
                child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 80,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              const SizedBox(height: 24),
              
              // Name
              Text(
                user.name ?? 'مستخدم',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Age
              if (user.age != null)
                Text(
                  '${user.age} سنة',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                ),
              const SizedBox(height: 16),
              
              // Country and Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (user.country != null) ...[
                    Icon(
                      Icons.location_on,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.country!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 16),
                  ],
                  // Followers count
                  Icon(
                    Icons.people,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${user.followerCount}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Follow Button
                  _ActionButton(
                    icon: isFollowing ? Icons.person_remove_outlined : Icons.person_add_outlined,
                    color: isFollowing ? Colors.grey : Colors.blue,
                    label: isFollowing ? 'متابع' : 'متابعة',
                    onPressed: onFollow,
                    isFilled: isFollowing,
                  ),
                  
                  // Chat Button
                  _ActionButton(
                    icon: Icons.chat_bubble,
                    color: AppColors.primary,
                    label: 'محادثة',
                    onPressed: onChat,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onPressed;
  final bool isFilled;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    this.onPressed,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isFilled ? color : color.withValues(alpha: 0.1),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Icon(
                icon,
                color: isFilled ? Colors.white : color,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
