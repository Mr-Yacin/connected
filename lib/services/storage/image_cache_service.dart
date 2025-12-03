import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import '../monitoring/error_logging_service.dart';

/// Service for caching images to improve performance
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  /// Custom cache manager with 7-day cache duration and 100MB size limit
  /// Note: flutter_cache_manager uses maxNrOfCacheObjects to limit cache size.
  /// The 100MB limit is enforced through the getCacheSize monitoring method.
  static final CacheManager cacheManager = CacheManager(
    Config(
      'social_connect_cache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: 'social_connect_cache'),
      fileService: HttpFileService(),
    ),
  );

  /// Maximum cache size in bytes (100MB)
  static const int maxCacheSize = 100 * 1024 * 1024;

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
            child: const Center(child: CircularProgressIndicator()),
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
    return CachedNetworkImageProvider(imageUrl, cacheManager: cacheManager);
  }

  /// Precache an image
  Future<void> precacheCachedImage(
    BuildContext context,
    String imageUrl,
  ) async {
    try {
      await precacheImage(
        CachedNetworkImageProvider(imageUrl, cacheManager: cacheManager),
        context,
      );
    } catch (e, stackTrace) {
      // Log error but don't throw - precaching is not critical
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to precache image: $imageUrl',
        screen: 'ImageCacheService',
        operation: 'precacheCachedImage',
      );
    }
  }

  /// Clear all cached images
  Future<void> clearCache() async {
    try {
      await cacheManager.emptyCache();
    } catch (e, stackTrace) {
      // Log error with full context
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to clear image cache',
        screen: 'ImageCacheService',
        operation: 'clearCache',
      );
      rethrow;
    }
  }

  /// Remove a specific cached image
  Future<void> removeFromCache(String imageUrl) async {
    try {
      await cacheManager.removeFile(imageUrl);
    } catch (e, stackTrace) {
      // Log error with full context
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to remove image from cache: $imageUrl',
        screen: 'ImageCacheService',
        operation: 'removeFromCache',
      );
      rethrow;
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cachePath = '${cacheDir.path}/social_connect_cache';
      final dir = Directory(cachePath);

      if (!await dir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      // Return 0 if unable to calculate cache size
      return 0;
    }
  }

  /// Check if cache size exceeds the maximum limit and clean if necessary
  Future<void> enforceCacheSizeLimit() async {
    try {
      final currentSize = await getCacheSize();
      
      if (currentSize > maxCacheSize) {
        // Clear cache if it exceeds the limit
        // flutter_cache_manager will automatically remove oldest files
        // based on stalePeriod and maxNrOfCacheObjects
        await cacheManager.emptyCache();
      }
    } catch (e) {
      // Silently fail if unable to enforce cache size limit
    }
  }
}
