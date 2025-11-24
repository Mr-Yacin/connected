import 'dart:io';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/exceptions/app_exceptions.dart';

/// Service for recording and playing voice messages
class VoiceRecorderService {
  final AudioRecorder _recorder;
  final AudioPlayer _player;
  
  bool _isRecording = false;
  String? _currentRecordingPath;

  VoiceRecorderService({
    AudioRecorder? recorder,
    AudioPlayer? player,
  })  : _recorder = recorder ?? AudioRecorder(),
        _player = player ?? AudioPlayer();

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Start recording audio
  Future<void> startRecording() async {
    try {
      // Check if we have permission
      if (!await _recorder.hasPermission()) {
        throw PermissionException('لا توجد صلاحية للوصول إلى الميكروفون');
      }

      // Get temporary directory for storing the recording
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/voice_message_$timestamp.m4a';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      if (e is PermissionException) {
        rethrow;
      }
      throw AppException('فشل في بدء التسجيل: $e');
    }
  }

  /// Stop recording and return the audio file
  Future<File> stopRecording() async {
    try {
      if (!_isRecording) {
        throw AppException('لا يوجد تسجيل نشط');
      }

      // Stop recording
      final path = await _recorder.stop();
      _isRecording = false;

      if (path == null || path.isEmpty) {
        throw AppException('فشل في حفظ التسجيل');
      }

      final file = File(path);
      if (!await file.exists()) {
        throw AppException('ملف التسجيل غير موجود');
      }

      _currentRecordingPath = null;
      return file;
    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      if (e is AppException) {
        rethrow;
      }
      throw AppException('فشل في إيقاف التسجيل: $e');
    }
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;

        // Delete the temporary file
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
          _currentRecordingPath = null;
        }
      }
    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      throw AppException('فشل في إلغاء التسجيل: $e');
    }
  }

  /// Play audio from URL
  Future<void> playAudio(String audioUrl) async {
    try {
      await _player.play(UrlSource(audioUrl));
    } catch (e) {
      throw AppException('فشل في تشغيل الرسالة الصوتية: $e');
    }
  }

  /// Play audio from local file
  Future<void> playAudioFile(File audioFile) async {
    try {
      await _player.play(DeviceFileSource(audioFile.path));
    } catch (e) {
      throw AppException('فشل في تشغيل الملف الصوتي: $e');
    }
  }

  /// Pause audio playback
  Future<void> pauseAudio() async {
    try {
      await _player.pause();
    } catch (e) {
      throw AppException('فشل في إيقاف التشغيل مؤقتاً: $e');
    }
  }

  /// Resume audio playback
  Future<void> resumeAudio() async {
    try {
      await _player.resume();
    } catch (e) {
      throw AppException('فشل في استئناف التشغيل: $e');
    }
  }

  /// Stop audio playback
  Future<void> stopAudio() async {
    try {
      await _player.stop();
    } catch (e) {
      throw AppException('فشل في إيقاف التشغيل: $e');
    }
  }

  /// Get current playback position
  Stream<Duration> get positionStream => _player.onPositionChanged;

  /// Get audio duration
  Stream<Duration?> get durationStream => _player.onDurationChanged;

  /// Get player state
  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;

  /// Dispose resources
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await cancelRecording();
      }
      await _player.dispose();
      _recorder.dispose();
    } catch (e) {
      // Ignore disposal errors
    }
  }
}
