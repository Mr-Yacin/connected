import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/models/enums.dart';
import '../../../../services/analytics_events.dart';
import '../../../../services/crashlytics_service.dart';
import '../providers/story_provider.dart';

/// Camera-first story creation screen (TikTok/Instagram style)
class StoryCameraScreen extends ConsumerStatefulWidget {
  final String userId;

  const StoryCameraScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<StoryCameraScreen> createState() => _StoryCameraScreenState();
}

class _StoryCameraScreenState extends ConsumerState<StoryCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  int _currentCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  
  File? _capturedMedia;
  StoryType? _mediaType;
  VideoPlayerController? _videoController;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    
    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsEventsProvider).trackScreenView('story_camera_screen');
      ref.read(storyCreationProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        _showError('لا توجد كاميرا متاحة');
        return;
      }

      _cameraController = CameraController(
        _cameras![_currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(_flashMode);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _showError('فشل في تهيئة الكاميرا: $e');
      await ref.read(crashlyticsServiceProvider).logError(
        e,
        StackTrace.current,
        reason: 'Failed to initialize camera',
      );
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _isInitialized = false;
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    });

    await _cameraController?.dispose();
    await _initializeCamera();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;

    FlashMode newMode;
    switch (_flashMode) {
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.off;
        break;
      default:
        newMode = FlashMode.off;
    }

    await _cameraController!.setFlashMode(newMode);
    setState(() {
      _flashMode = newMode;
    });
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() => _isProcessing = true);
      
      final XFile image = await _cameraController!.takePicture();
      
      setState(() {
        _capturedMedia = File(image.path);
        _mediaType = StoryType.image;
        _isProcessing = false;
      });

      // Track capture event
      ref.read(analyticsEventsProvider).performanceService.trackEvent(
        'story_photo_captured',
        parameters: {'source': 'camera'},
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('فشل في التقاط الصورة: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isRecording) return;

    try {
      await _cameraController!.startVideoRecording();
      setState(() => _isRecording = true);
      
      ref.read(analyticsEventsProvider).performanceService.trackEvent(
        'story_video_recording_started',
        parameters: {'source': 'camera'},
      );
    } catch (e) {
      _showError('فشل في بدء تسجيل الفيديو: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_cameraController == null || !_isRecording) return;

    try {
      setState(() => _isProcessing = true);
      
      final XFile video = await _cameraController!.stopVideoRecording();
      
      setState(() {
        _isRecording = false;
        _capturedMedia = File(video.path);
        _mediaType = StoryType.video;
        _isProcessing = false;
      });

      // Initialize video player for preview
      _videoController = VideoPlayerController.file(_capturedMedia!)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
          _videoController!.setLooping(true);
        });

      // Track capture event
      ref.read(analyticsEventsProvider).performanceService.trackEvent(
        'story_video_captured',
        parameters: {'source': 'camera'},
      );
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      _showError('فشل في إيقاف تسجيل الفيديو: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? media = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (media != null) {
        setState(() {
          _capturedMedia = File(media.path);
          _mediaType = StoryType.image;
        });
        
        ref.read(analyticsEventsProvider).performanceService.trackEvent(
          'story_media_selected',
          parameters: {'source': 'gallery'},
        );
      }
    } catch (e) {
      _showError('فشل في اختيار الوسائط: $e');
    }
  }

  Future<void> _createStory() async {
    if (_capturedMedia == null || _mediaType == null) return;

    try {
      setState(() => _isProcessing = true);

      await ref.read(storyCreationProvider.notifier).createStory(
            userId: widget.userId,
            mediaFile: _capturedMedia!,
            type: _mediaType!,
          );

      final state = ref.read(storyCreationProvider);
      if (state.createdStory != null) {
        await ref.read(analyticsEventsProvider).trackStoryCreated(
          storyId: state.createdStory!.id,
          mediaType: _mediaType.toString(),
        );
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم نشر القصة بنجاح')),
          );
        }
      } else if (state.error != null) {
        setState(() => _isProcessing = false);
        _showError(state.error!);
      }
    } catch (e, stackTrace) {
      setState(() => _isProcessing = false);
      await ref.read(crashlyticsServiceProvider).logError(
        e,
        stackTrace,
        reason: 'Failed to create story',
      );
      _showError('فشل في إنشاء القصة');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _discardMedia() {
    setState(() {
      _capturedMedia = null;
      _mediaType = null;
    });
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  Widget build(BuildContext context) {
    // If media is captured, show preview screen
    if (_capturedMedia != null) {
      return _buildPreviewScreen();
    }

    // Otherwise, show camera screen
    return _buildCameraScreen();
  }

  Widget _buildCameraScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Top controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  
                  // Flash toggle
                  if (_isInitialized && _cameras != null && _currentCameraIndex == 0)
                    IconButton(
                      icon: Icon(
                        _flashMode == FlashMode.off
                            ? Icons.flash_off
                            : _flashMode == FlashMode.auto
                                ? Icons.flash_auto
                                : Icons.flash_on,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: _toggleFlash,
                    ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gallery button
                    GestureDetector(
                      onTap: _pickFromGallery,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),

                    // Capture button
                    GestureDetector(
                      onTap: _isProcessing ? null : _takePicture,
                      onLongPressStart: (_) => _startVideoRecording(),
                      onLongPressEnd: (_) => _stopVideoRecording(),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                              color: _isRecording ? Colors.red : Colors.white,
                              borderRadius: _isRecording
                                  ? BorderRadius.circular(8)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Flip camera button
                    if (_cameras != null && _cameras!.length > 1)
                      IconButton(
                        icon: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                          size: 35,
                        ),
                        onPressed: _toggleCamera,
                      )
                    else
                      const SizedBox(width: 50),
                  ],
                ),
              ),
            ),
          ),

          // Recording indicator
          if (_isRecording)
            SafeArea(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fiber_manual_record, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'جاري التسجيل...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Instructions
          if (!_isRecording && !_isProcessing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 120,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'اضغط للصورة • اضغط مطولاً للفيديو',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewScreen() {
    final state = ref.watch(storyCreationProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Media preview
          Center(
            child: _mediaType == StoryType.image
                ? Image.file(
                    _capturedMedia!,
                    fit: BoxFit.contain,
                  )
                : (_videoController != null &&
                        _videoController!.value.isInitialized)
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Discard button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: _isProcessing ? null : _discardMedia,
                  ),
                  
                  // Post button
                  TextButton(
                    onPressed: _isProcessing ? null : _createStory,
                    child: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'نشر',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Play/pause button for video
          if (_mediaType == StoryType.video && _videoController != null)
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
