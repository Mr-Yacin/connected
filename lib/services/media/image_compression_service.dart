import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Provider for ImageCompressionService
final imageCompressionServiceProvider = Provider<ImageCompressionService>((
  ref,
) {
  return ImageCompressionService();
});

/// Service for compressing images
class ImageCompressionService {
  /// Compress image file
  /// Returns the compressed file, or the original file if compression fails
  Future<File> compressImage(File file, {int quality = 85}) async {
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
        minWidth: 1920, // Resize if larger than Full HD
        minHeight: 1920,
      );

      if (result != null) {
        return File(result.path);
      } else {
        return file;
      }
    } catch (e) {
      // If compression fails, return original file
      print('Image compression failed: $e');
      return file;
    }
  }
}
