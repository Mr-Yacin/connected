import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Service for applying blur effects to images
class ImageBlurService {
  /// Apply blur effect to an image
  /// 
  /// [imageFile] - The image file to blur
  /// [blurLevel] - The intensity of the blur (default: 10, range: 1-50)
  /// Returns a new File with the blurred image
  Future<File> applyBlur(File imageFile, {int blurLevel = 10}) async {
    try {
      // Validate blur level
      if (blurLevel < 1 || blurLevel > 50) {
        throw ArgumentError('Blur level must be between 1 and 50');
      }

      // Read the image file
      final bytes = await imageFile.readAsBytes();
      
      // Decode the image
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('فشل في قراءة الصورة');
      }

      // Apply Gaussian blur
      final blurred = img.gaussianBlur(image, radius: blurLevel);

      // Encode the blurred image
      final blurredBytes = img.encodeJpg(blurred, quality: 85);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final blurredFile = File('${tempDir.path}/blurred_$timestamp.jpg');
      await blurredFile.writeAsBytes(blurredBytes);

      return blurredFile;
    } catch (e) {
      throw Exception('فشل في تطبيق التمويه: $e');
    }
  }

  /// Apply blur effect to image bytes
  /// 
  /// [imageBytes] - The image bytes to blur
  /// [blurLevel] - The intensity of the blur (default: 10, range: 1-50)
  /// Returns blurred image bytes
  Future<Uint8List> applyBlurToBytes(Uint8List imageBytes, {int blurLevel = 10}) async {
    try {
      // Validate blur level
      if (blurLevel < 1 || blurLevel > 50) {
        throw ArgumentError('Blur level must be between 1 and 50');
      }

      // Decode the image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('فشل في قراءة الصورة');
      }

      // Apply Gaussian blur
      final blurred = img.gaussianBlur(image, radius: blurLevel);

      // Encode the blurred image
      final blurredBytes = img.encodeJpg(blurred, quality: 85);

      return Uint8List.fromList(blurredBytes);
    } catch (e) {
      throw Exception('فشل في تطبيق التمويه: $e');
    }
  }
}
