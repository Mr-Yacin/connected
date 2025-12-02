import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Reusable circular profile avatar widget for stories feature
/// 
/// Displays a user's profile image with consistent styling:
/// - Circular shape with white border
/// - Shadow effect for depth
/// - Loading placeholder
/// - Error fallback with person icon
/// - Null-safe image URL handling
/// 
/// Usage:
/// ```dart
/// StoryProfileAvatar(
///   profileImageUrl: user.profileImageUrl,
///   size: 40,
///   borderWidth: 2,
/// )
/// ```
class StoryProfileAvatar extends StatelessWidget {
  /// URL of the profile image to display
  final String? profileImageUrl;
  
  /// Size of the avatar (width and height)
  final double size;
  
  /// Width of the white border around the avatar
  final double borderWidth;
  
  /// Color of the border (defaults to white)
  final Color borderColor;
  
  /// Whether to show shadow effect
  final bool showShadow;

  const StoryProfileAvatar({
    super.key,
    this.profileImageUrl,
    this.size = 40,
    this.borderWidth = 2,
    this.borderColor = Colors.white,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: profileImageUrl != null
            ? CachedNetworkImage(
                imageUrl: profileImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildFallbackIcon(),
              )
            : _buildFallbackIcon(),
      ),
    );
  }

  /// Builds the fallback icon when image is unavailable
  Widget _buildFallbackIcon() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        color: Colors.grey[600],
        size: size * 0.6, // Icon size is 60% of avatar size
      ),
    );
  }
}
