import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../services/analytics/analytics_events.dart';
import '../../../../services/monitoring/crashlytics_service.dart';
import '../providers/story_provider.dart';
import '../../data/models/camera_filter.dart';
import '../widgets/filter_carousel_widget.dart';

/// Professional story camera screen with modern UI/UX
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
    with WidgetsBindingObserver, TickerProviderStateMixin {
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

  // Filter state
  CameraFilter _selectedFilter = CameraFilter.none;
  bool _showFilters = false;
  double _filterIntensity = 1.0;

  // Animation controllers
  late AnimationController _recordingAnimationController;
  late AnimationController _buttonScaleController;
  late Animation<double> _recordingPulse;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize animations
    _recordingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _buttonScaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _recordingPulse = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _recordingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _buttonScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _buttonScaleController,
        curve: Curves.easeInOut,
      ),
    );

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
    _recordingAnimationController.dispose();
    _buttonScaleController.dispose();
    _cameraController?.dispose();
    _videoController?.dispose();
    // Reset orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
        _showError('الكاميرا غير متاحة');
        return;
      }

      // ✅ FIX: Add bounds check to prevent crash
      if (_currentCameraIndex >= _cameras!.length) {
        _currentCameraIndex = 0;
      }

      _cameraController = CameraController(
        _cameras![_currentCameraIndex],
        ResolutionPreset.veryHigh,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(_flashMode);

      // Lock device orientation to portrait
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _showError('Failed to initialize camera');
      await ref.read(crashlyticsServiceProvider).logError(
            e,
            StackTrace.current,
            reason: 'Failed to initialize camera',
          );
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isInitialized = false;
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    });

    await _cameraController?.dispose();
    await _initializeCamera();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;

    HapticFeedback.lightImpact();
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

    if (_isProcessing) return;

    HapticFeedback.mediumImpact();
    _buttonScaleController.forward().then((_) => _buttonScaleController.reverse());

    setState(() {
      _isProcessing = true;
    });

    try {
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
      _showError('فشل في التقاط الصورة');
    }
  }

  Future<void> _startVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isRecording) return;

    HapticFeedback.mediumImpact();

    try {
      await _cameraController!.startVideoRecording();
      setState(() => _isRecording = true);

      ref.read(analyticsEventsProvider).performanceService.trackEvent(
            'story_video_recording_started',
            parameters: {'source': 'camera'},
          );
    } catch (e) {
      _showError('Failed to start recording');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_cameraController == null || !_isRecording) return;

    HapticFeedback.mediumImpact();

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
          if (mounted) {
            setState(() {});
            // ✅ FIX: Add null check before using video controller
            if (_videoController != null && _videoController!.value.isInitialized) {
              _videoController!.play();
              _videoController!.setLooping(true);
            }
          }
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
      _showError('فشل في إيقاف التسجيل');
    }
  }

  Future<void> _pickFromGallery() async {
    HapticFeedback.lightImpact();
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
      _showError('فشل في اختيار الوسائط');
    }
  }

  Future<void> _createStory() async {
    if (_capturedMedia == null || _mediaType == null) return;

    HapticFeedback.mediumImpact();

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
          SnackbarHelper.showSuccess(context, 'Story published successfully');
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
      SnackbarHelper.showError(context, message);
    }
  }

  void _discardMedia() {
    HapticFeedback.lightImpact();
    setState(() {
      _capturedMedia = null;
      _mediaType = null;
      _selectedFilter = CameraFilter.none;
    });
    _videoController?.dispose();
    _videoController = null;
  }

  void _toggleFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _onFilterSelected(CameraFilter filter) {
    setState(() {
      _selectedFilter = filter;
      // Reset intensity when changing filters
      if (filter.id != 'none') {
        _filterIntensity = 1.0;
      }
    });

    // Track filter usage
    ref.read(analyticsEventsProvider).performanceService.trackEvent(
          'camera_filter_selected',
          parameters: {'filter': filter.id},
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_capturedMedia != null) {
      return _buildPreviewScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: _isInitialized ? _buildCameraScreen() : _buildLoadingScreen(),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A1A), Colors.black],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'جاري تهيئة الكاميرا...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraScreen() {
    if (_cameraController == null) {
      return const Center(
        child: Text(
          'Camera not available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    
    // Camera aspect ratio is width/height, but we need to handle it properly
    var cameraRatio = _cameraController!.value.aspectRatio;
    
    // For portrait mode, invert the camera ratio if needed
    if (cameraRatio > 1) {
      cameraRatio = 1 / cameraRatio;
    }
    
    // Calculate scale to fill the screen
    var scale = deviceRatio / cameraRatio;
    
    // If scale is less than 1, invert it to ensure we fill the screen
    if (scale < 1) {
      scale = 1 / scale;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview - Full screen with proper aspect ratio and filter
        Center(
          child: FilterPreviewWidget(
            filter: _selectedFilter,
            intensity: _filterIntensity,
            child: Transform.scale(
              scale: scale,
              child: AspectRatio(
                aspectRatio: cameraRatio,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),
        ),

        // Gradient overlays for better UI contrast
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 200,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 250,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Top controls
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close button
              _buildGlassButton(
                icon: Icons.close_rounded,
                onPressed: () => Navigator.pop(context),
              ),

              const Spacer(),

              // Flash toggle
              if (_currentCameraIndex == 0)
                _buildGlassButton(
                  icon: _flashMode == FlashMode.off
                      ? Icons.flash_off_rounded
                      : _flashMode == FlashMode.auto
                          ? Icons.flash_auto_rounded
                          : Icons.flash_on_rounded,
                  onPressed: _toggleFlash,
                  isActive: _flashMode != FlashMode.off,
                ),

              const SizedBox(width: 12),

              // Camera flip
              if (_cameras != null && _cameras!.length > 1)
                _buildGlassButton(
                  icon: Icons.flip_camera_ios_rounded,
                  onPressed: _toggleCamera,
                ),
            ],
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 32,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Filter carousel
              if (_showFilters)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FilterCarouselWidget(
                    selectedFilter: _selectedFilter,
                    onFilterSelected: _onFilterSelected,
                  ),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gallery button
                  _buildBottomIconButton(
                    icon: Icons.photo_library_rounded,
                    onPressed: _pickFromGallery,
                  ),

                  // Capture/Record button
                  _buildCaptureButton(),

                  // Filter button
                  _buildBottomIconButton(
                    icon: Icons.filter_vintage_rounded,
                    onPressed: _toggleFilters,
                    isActive: _showFilters,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Recording indicator
        if (_isRecording)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
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
            ),
          ),

        // Instructions
        if (!_isRecording && !_isProcessing)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 140,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'اضغط للصورة • اضغط مع الاستمرار للفيديو',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(30),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.3),
              width: isActive ? 2 : 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(28),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _isRecording ? null : _takePicture,
      onLongPressStart: (_) => _startVideoRecording(),
      onLongPressEnd: (_) => _stopVideoRecording(),
      child: AnimatedBuilder(
        animation: _isRecording ? _recordingPulse : _buttonScale,
        builder: (context, child) {
          return Transform.scale(
            scale: _isRecording ? _recordingPulse.value : _buttonScale.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isRecording
                        ? Colors.red.withValues(alpha: 0.5)
                        : AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: _isRecording ? BorderRadius.circular(8) : null,
                    gradient: _isRecording
                        ? const LinearGradient(
                            colors: [Colors.red, Colors.redAccent],
                          )
                        : AppColors.primaryGradient,
                  ),
                  child: _isProcessing
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewScreen() {
    final state = ref.watch(storyCreationProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Media preview - Full screen with filter applied
          Center(
            child: FilterPreviewWidget(
              filter: _selectedFilter,
              intensity: _filterIntensity,
              child: _mediaType == StoryType.image
                  ? Image.file(
                      _capturedMedia!,
                      fit: BoxFit.contain,
                    )
                  : (_videoController != null && _videoController!.value.isInitialized)
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        )
                      : Container(
                          color: Colors.black,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 16),
                                Text(
                                  'جاري تحميل الفيديو...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ),

          // Gradient overlays
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                _buildGlassButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: state.isLoading ? () {} : _discardMedia,
                ),

                // Filter button
                _buildGlassButton(
                  icon: Icons.filter_vintage_rounded,
                  onPressed: state.isLoading ? () {} : _toggleFilters,
                  isActive: _showFilters || _selectedFilter.id != 'none',
                ),
              ],
            ),
          ),

          // Filter carousel in preview mode
          if (_showFilters)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 120,
              left: 0,
              right: 0,
              child: FilterCarouselWidget(
                selectedFilter: _selectedFilter,
                onFilterSelected: _onFilterSelected,
                previewImage: _mediaType == StoryType.image
                    ? Image.file(_capturedMedia!, fit: BoxFit.cover)
                    : null,
              ),
            ),

          // Play/pause button for video
          if (_mediaType == StoryType.video && _videoController != null && _videoController!.value.isInitialized)
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _videoController!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),

          // Action buttons at bottom
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 32,
            right: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Discard button
                Expanded(
                  child: _buildFloatingActionButton(
                    icon: Icons.close_rounded,
                    label: 'تجاهل',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
                    ),
                    onPressed: state.isLoading ? () {} : _discardMedia,
                    isDisabled: state.isLoading,
                  ),
                ),

                const SizedBox(width: 16),

                // Publish button
                Expanded(
                  child: _buildFloatingActionButton(
                    icon: Icons.check_rounded,
                    label: state.isLoading ? 'جاري النشر...' : 'نشر',
                    gradient: AppColors.primaryGradient,
                    onPressed: state.isLoading ? () {} : _createStory,
                    isLoading: state.isLoading,
                    isDisabled: state.isLoading,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isDisabled = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: isDisabled ? null : gradient,
            color: isDisabled ? Colors.grey.shade800 : null,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : onPressed,
              borderRadius: BorderRadius.circular(30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
