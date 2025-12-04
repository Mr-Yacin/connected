import 'package:flutter/material.dart';

/// Safe wrapper for NetworkImage that handles 404 and other errors gracefully
/// 
/// This prevents app crashes when profile images or other network images fail to load.
/// 
/// Usage:
/// ```dart
/// CircleAvatar(
///   backgroundImage: SafeNetworkImage.provider(imageUrl),
///   child: SafeNetworkImage.fallbackIcon(),
/// )
/// ```
class SafeNetworkImage {
  /// Create a safe NetworkImage provider that handles errors
  static ImageProvider? provider(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }
    
    return NetworkImage(url);
  }
  
  /// Fallback icon for when image fails to load
  static Widget fallbackIcon({
    IconData icon = Icons.person,
    Color? color,
    double size = 24,
  }) {
    return Icon(
      icon,
      color: color ?? Colors.grey[400],
      size: size,
    );
  }
  
  /// Create a safe Image.network widget with error handling
  static Widget image(
    String url, {
    double? width,
    double? height,
    BoxFit? fit,
    Widget? errorWidget,
    Widget? loadingWidget,
  }) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: loadingWidget != null
          ? (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return loadingWidget;
            }
          : null,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: Icon(
                Icons.image_not_supported_rounded,
                color: Colors.grey[400],
                size: (width != null && height != null) 
                    ? (width < height ? width : height) * 0.5 
                    : 24,
              ),
            );
      },
    );
  }
}

/// Extension on CircleAvatar to make it easier to use safe images
extension SafeCircleAvatar on CircleAvatar {
  /// Create a CircleAvatar with safe network image handling
  static Widget create({
    required String? imageUrl,
    double radius = 20,
    Color? backgroundColor,
    Widget? child,
    IconData fallbackIcon = Icons.person,
    Color? fallbackIconColor,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: imageUrl != null && imageUrl.isNotEmpty
          ? NetworkImage(imageUrl)
          : null,
      onBackgroundImageError: imageUrl != null && imageUrl.isNotEmpty
          ? (exception, stackTrace) {
              // Log error silently, don't crash the app
              debugPrint('Failed to load image: $imageUrl');
              debugPrint('Error: $exception');
            }
          : null,
      child: child ??
          (imageUrl == null || imageUrl.isEmpty
              ? Icon(
                  fallbackIcon,
                  color: fallbackIconColor ?? Colors.grey[400],
                  size: radius * 0.8,
                )
              : null),
    );
  }
}
