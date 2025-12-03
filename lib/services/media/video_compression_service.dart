import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_compress/video_compress.dart';
import '../monitoring/error_logging_service.dart';

/// Provider for VideoCompressionService
final videoCompressionServiceProvider = Provider<VideoCompressionService>((
  ref,
) {
  return VideoCompressionService();
});

/// Service for compressing videos
class VideoCompressionService {
  /// Compress video file
  /// Returns the compressed file, or the original file if compression fails
  Future<File> compressVideo(
    File file, {
    VideoQuality quality = VideoQuality.DefaultQuality,
  }) async {
    try {
      // Check if video is already compressed or small enough?
      // For now, just compress.

      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: quality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (mediaInfo != null && mediaInfo.file != null) {
        return mediaInfo.file!;
      } else {
        return file;
      }
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Video compression failed',
        screen: 'VideoCompressionService',
        operation: 'compressVideo',
      );
      return file;
    }
  }

  /// Generate thumbnail from video
  Future<File?> getThumbnail(File file) async {
    try {
      return await VideoCompress.getFileThumbnail(
        file.path,
        quality: 50,
        position: -1, // Middle of video
      );
    } catch (e, stackTrace) {
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Thumbnail generation failed',
        screen: 'VideoCompressionService',
        operation: 'getThumbnail',
      );
      return null;
    }
  }

  /// Cancel compression
  Future<void> cancelCompression() async {
    await VideoCompress.cancelCompression();
  }

  /// Dispose
  Future<void> dispose() async {
    await VideoCompress.deleteAllCache();
  }
}
