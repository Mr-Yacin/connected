import 'package:flutter/material.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget to display a user profile card in discovery
class UserCard extends StatelessWidget {
  final UserProfile user;
  final VoidCallback? onLike;
  final VoidCallback? onSkip;
  final VoidCallback? onChat;

  const UserCard({
    Key? key,
    required this.user,
    this.onLike,
    this.onSkip,
    this.onChat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
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
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
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
            
            // Country and Dialect
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
                ],
                if (user.country != null && user.dialect != null)
                  const SizedBox(width: 16),
                if (user.dialect != null) ...[
                  Icon(
                    Icons.language,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user.dialect!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Skip Button
                _ActionButton(
                  icon: Icons.close,
                  color: AppColors.error,
                  onPressed: onSkip,
                ),
                
                // Like Button
                _ActionButton(
                  icon: Icons.favorite,
                  color: AppColors.secondary,
                  onPressed: onLike,
                ),
                
                // Chat Button
                _ActionButton(
                  icon: Icons.chat_bubble,
                  color: AppColors.primary,
                  onPressed: onChat,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.color,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Icon(
            icon,
            color: color,
            size: 32,
          ),
        ),
      ),
    );
  }
}
