import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Service for caching images to improve performance
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  /// Custom cache manager with 7-day cache duration
  static final CacheManager cacheManager = CacheManager(
    Config(
      'social_connect_cache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: 'social_connect_cache'),
      fileService: HttpFileService(),
    ),
  );

  /// Get a cached network image widget
  Widget getCachedImage({
    required String imageUrl,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    double? width,
    double? height,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: cacheManager,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            color: Colors.grey[300],
            child: const Icon(Icons.error, color: Colors.red),
          ),
    );
  }

  /// Get a cached network image provider
  ImageProvider getCachedImageProvider(String imageUrl) {
    return CachedNetworkImageProvider(
      imageUrl,
      cacheManager: cacheManager,
    );
  }

  /// Precache an image
  Future<void> precacheImage(BuildContext context, String imageUrl) async {
    await precacheImage(
      CachedNetworkImageProvider(imageUrl, cacheManager: cacheManager),
      context,
    );
  }

  /// Clear all cached images
  Future<void> clearCache() async {
    await cacheManager.emptyCache();
  }

  /// Remove a specific cached image
  Future<void> removeFromCache(String imageUrl) async {
    await cacheManager.removeFile(imageUrl);
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    try {
      final files = await cacheManager.store.getAllObjects();
      int totalSize = 0;
      for (final file in files) {
        // Get file size from the file system
        final fileInfo = await cacheManager.getFileFromCache(file.key);
        if (fileInfo != null && fileInfo.file.existsSync()) {
          totalSize += await fileInfo.file.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
}
