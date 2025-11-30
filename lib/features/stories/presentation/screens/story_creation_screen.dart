import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../services/analytics_events.dart';
import '../../../../services/crashlytics_service.dart';
import '../providers/story_provider.dart';

/// Screen for creating a new story
class StoryCreationScreen extends ConsumerStatefulWidget {
  final String userId;

  const StoryCreationScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<StoryCreationScreen> createState() =>
      _StoryCreationScreenState();
}

class _StoryCreationScreenState extends ConsumerState<StoryCreationScreen> {
  File? _selectedMedia;
  StoryType _storyType = StoryType.image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    
    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsEventsProvider).trackScreenView('story_creation_screen');
    });
    
    // Reset state when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storyCreationProvider.notifier).reset();
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedMedia = File(image.path);
          _storyType = StoryType.image;
        });
      }
    } catch (e) {
      _showError('فشل في اختيار الصورة: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedMedia = File(photo.path);
          _storyType = StoryType.image;
        });
      }
    } catch (e) {
      _showError('فشل في التقاط الصورة: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );

      if (video != null) {
        setState(() {
          _selectedMedia = File(video.path);
          _storyType = StoryType.video;
        });
      }
    } catch (e) {
      _showError('فشل في اختيار الفيديو: $e');
    }
  }

  Future<void> _createStory() async {
    if (_selectedMedia == null) {
      _showError('الرجاء اختيار صورة أو فيديو');
      return;
    }

    try {
      await ref.read(storyCreationProvider.notifier).createStory(
            userId: widget.userId,
            mediaFile: _selectedMedia!,
            type: _storyType,
          );

      // Check if story was created successfully
      final state = ref.read(storyCreationProvider);
      if (state.createdStory != null) {
        // Track story creation event
        await ref.read(analyticsEventsProvider).trackStoryCreated(
          storyId: state.createdStory!.id,
          mediaType: _storyType.toString(),
        );
        
        if (mounted) {
          Navigator.pop(context);
          SnackbarHelper.showSuccess(context, 'تم نشر القصة بنجاح');
        }
      } else if (state.error != null) {
        _showError(state.error!);
      }
    } catch (e, stackTrace) {
      await ref.read(crashlyticsServiceProvider).logError(
        e,
        stackTrace,
        reason: 'Failed to create story',
        information: [
          'screen: story_creation_screen',
          'userId: ${widget.userId}',
          'storyType: ${_storyType.toString()}',
        ],
      );
      _showError('فشل في إنشاء القصة');
    }
  }

  void _showError(String message) {
    if (mounted) {
      SnackbarHelper.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyCreationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء قصة'),
        actions: [
          if (_selectedMedia != null)
            TextButton(
              onPressed: state.isLoading ? null : _createStory,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: _selectedMedia == null
          ? _buildMediaSelector()
          : _buildMediaPreview(),
    );
  }

  Widget _buildMediaSelector() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_library,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'اختر صورة أو فيديو لقصتك',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('التقاط صورة'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo),
            label: const Text('اختيار صورة'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.videocam),
            label: const Text('اختيار فيديو'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Stack(
      children: [
        // Media preview
        Center(
          child: _storyType == StoryType.image
              ? Image.file(
                  _selectedMedia!,
                  fit: BoxFit.contain,
                )
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 80,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'معاينة الفيديو',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
        ),

        // Change media button
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedMedia = null;
                });
              },
              icon: const Icon(Icons.change_circle),
              label: const Text('تغيير'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
