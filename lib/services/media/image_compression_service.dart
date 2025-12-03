import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../monitoring/error_logging_service.dart';

/// Provider for ImageCompressionService
final imageCompressionServiceProvider = Provider<ImageCompressionService>((
  ref,
) {
  return ImageCompressionService();
});

/// Service for compressing images
class ImageCompressionService {
  /// Compress image file with configurable dimensions
  /// Returns the compressed file, or the original file if compression fails
  Future<File> compressImage(
    File file, {
    int quality = 85,
    int maxWidth = 1920,
    int maxHeight = 1920,
  }) async {
    try {
      final filePath = file.absolute.path;
      final fileExtension = p.extension(filePath);
      final fileName = p.basenameWithoutExtension(filePath);

      // Create target path for compressed image
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path,
        '${fileName}_compressed$fileExtension',
      );

      // Check if target file already exists and delete it
      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      // Compress
      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
      );

      if (result != null) {
        return File(result.path);
      } else {
        return file;
      }
    } catch (e, stackTrace) {
      // If compression fails, return original file
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Image compression failed',
        screen: 'ImageCompressionService',
        operation: 'compressImage',
      );
      return file;
    }
  }

  /// Compress image for stories (optimized dimensions)
  /// Uses 1080x1920 dimensions for optimal story display
  Future<File> compressForStory(File file) {
    return compressImage(
      file,
      quality: 85,
      maxWidth: 1080,
      maxHeight: 1920,
    );
  }

  /// Compress image for profile photo (smaller dimensions)
  /// Uses 512x512 dimensions for profile photos
  Future<File> compressForProfile(File file) {
    return compressImage(
      file,
      quality: 90,
      maxWidth: 512,
      maxHeight: 512,
    );
  }
}
