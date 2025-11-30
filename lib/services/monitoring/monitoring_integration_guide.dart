// Firebase Monitoring Integration Guide
// 
// This file demonstrates how to integrate Firebase Performance Monitoring,
// Crashlytics, and Analytics into your Flutter app.
// 
// ============================================================================
// SETUP CHECKLIST
// ============================================================================
// 
// ✅ 1. Added dependencies to pubspec.yaml:
//    - firebase_performance: ^0.10.0+8
//    - firebase_analytics: ^11.3.5
//    - firebase_crashlytics: ^4.1.3
// 
// ✅ 2. Updated Android build.gradle.kts files with plugins
// 
// ✅ 3. Initialized services in main.dart
// 
// ============================================================================
// USAGE EXAMPLES
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_connect_app/services/analytics/analytics_events.dart';
import 'package:social_connect_app/services/monitoring/performance_service.dart';
import 'package:social_connect_app/services/monitoring/crashlytics_service.dart';

/// Example 1: Track screen views
class ExampleScreenTracking extends ConsumerStatefulWidget {
  const ExampleScreenTracking({super.key});

  @override
  ConsumerState<ExampleScreenTracking> createState() => _ExampleScreenTrackingState();
}

class _ExampleScreenTrackingState extends ConsumerState<ExampleScreenTracking> {
  @override
  void initState() {
    super.initState();
    // Track screen view when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsEventsProvider).trackScreenView('example_screen');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Example Screen')),
      body: const Center(child: Text('Content')),
    );
  }
}

/// Example 2: Track user actions with error handling
class ExampleUserActionTracking extends ConsumerWidget {
  const ExampleUserActionTracking({super.key});

  Future<void> _handlePostCreation(WidgetRef ref, BuildContext context) async {
    final analytics = ref.read(analyticsEventsProvider);
    final crashlytics = ref.read(crashlyticsServiceProvider);
    
    try {
      // Your post creation logic here
      final postId = 'post_123';
      
      // Track successful post creation
      await analytics.trackPostCreated(
        postId: postId,
        contentType: 'text',
        hasImage: false,
        hasLocation: true,
      );
      
      // Log to Crashlytics for debugging
      await crashlytics.log('Post created successfully: $postId');
      
    } catch (error, stackTrace) {
      // Track error
      await analytics.trackError(
        errorType: 'post_creation_error',
        errorMessage: error.toString(),
        location: 'ExampleUserActionTracking',
        stackTrace: stackTrace,
      );
      
      // Show error to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _handlePostCreation(ref, context),
      child: const Text('Create Post'),
    );
  }
}

/// Example 3: Track performance of async operations
class ExamplePerformanceTracking extends ConsumerWidget {
  const ExamplePerformanceTracking({super.key});

  Future<void> _loadDataWithPerformanceTracking(WidgetRef ref) async {
    final performance = ref.read(performanceServiceProvider);
    
    // Use the trackPerformance extension method
    await performance.trackPerformance(
      'load_user_data',
      () async {
        // Simulate data loading
        await Future.delayed(const Duration(seconds: 2));
        
        // Your actual data loading logic here
        return 'Data loaded';
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _loadDataWithPerformanceTracking(ref),
      child: const Text('Load Data'),
    );
  }
}

/// Example 4: Track image upload with performance metrics
class ExampleImageUploadTracking extends ConsumerWidget {
  const ExampleImageUploadTracking({super.key});

  Future<void> _uploadImage(WidgetRef ref) async {
    final analytics = ref.read(analyticsEventsProvider);
    final startTime = DateTime.now();
    
    try {
      // Your image upload logic here
      final fileSizeBytes = 1024 * 500; // 500 KB
      
      // Simulate upload
      await Future.delayed(const Duration(seconds: 3));
      
      final uploadDuration = DateTime.now().difference(startTime);
      
      // Track upload metrics
      await analytics.trackImageUpload(
        location: 'profile_picture',
        fileSizeBytes: fileSizeBytes,
        uploadDuration: uploadDuration,
      );
      
    } catch (error, stackTrace) {
      await analytics.trackError(
        errorType: 'image_upload_error',
        errorMessage: error.toString(),
        location: 'ExampleImageUploadTracking',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _uploadImage(ref),
      child: const Text('Upload Image'),
    );
  }
}

/// Example 5: Track user authentication
class ExampleAuthTracking extends ConsumerWidget {
  const ExampleAuthTracking({super.key});

  Future<void> _handleLogin(WidgetRef ref, String userId) async {
    final analytics = ref.read(analyticsEventsProvider);
    
    await analytics.trackLogin(
      method: 'phone',
      userId: userId,
    );
  }

  Future<void> _handleSignUp(WidgetRef ref, String userId) async {
    final analytics = ref.read(analyticsEventsProvider);
    
    await analytics.trackSignUp(
      method: 'phone',
      userId: userId,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _handleLogin(ref, 'user_123'),
          child: const Text('Login'),
        ),
        ElevatedButton(
          onPressed: () => _handleSignUp(ref, 'user_123'),
          child: const Text('Sign Up'),
        ),
      ],
    );
  }
}

/// Example 6: Set custom user properties
class ExampleUserProperties extends ConsumerStatefulWidget {
  const ExampleUserProperties({super.key});

  @override
  ConsumerState<ExampleUserProperties> createState() => _ExampleUserPropertiesState();
}

class _ExampleUserPropertiesState extends ConsumerState<ExampleUserProperties> {
  @override
  void initState() {
    super.initState();
    _setUserProperties();
  }

  Future<void> _setUserProperties() async {
    final performance = ref.read(performanceServiceProvider);
    final crashlytics = ref.read(crashlyticsServiceProvider);
    
    // Set user properties for analytics
    await performance.setUserProperties(
      userId: 'user_123',
      age: '25-34',
      gender: 'male',
      country: 'SA',
    );
    
    // Set user info for Crashlytics
    await crashlytics.setUserInfo(
      userId: 'user_123',
      email: 'user@example.com',
      name: 'Test User',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

/// ============================================================================
/// INTEGRATION CHECKLIST FOR YOUR SCREENS
/// ============================================================================
/// 
/// For each screen in your app, consider adding:
/// 
/// 1. SCREEN VIEW TRACKING:
///    - Add trackScreenView() in initState() or build()
/// 
/// 2. USER ACTION TRACKING:
///    - Track button clicks, form submissions, etc.
///    - Use appropriate event methods from AnalyticsEvents
/// 
/// 3. ERROR HANDLING:
///    - Wrap async operations in try-catch
///    - Log errors to Crashlytics with trackError()
/// 
/// 4. PERFORMANCE TRACKING:
///    - Use trackPerformance() for long-running operations
///    - Track image uploads, data fetching, etc.
/// 
/// 5. CUSTOM KEYS:
///    - Set relevant custom keys for debugging
///    - Example: current screen, user state, etc.
/// 
/// ============================================================================
/// FIREBASE CONSOLE SETUP
/// ============================================================================
/// 
/// After implementation, enable these services in Firebase Console:
/// 
/// 1. Go to Firebase Console (https://console.firebase.google.com)
/// 2. Select your project
/// 3. Navigate to:
///    - Analytics → Dashboard (automatically enabled)
///    - Crashlytics → Enable Crashlytics
///    - Performance → Enable Performance Monitoring
/// 
/// 4. Wait 24-48 hours for initial data to appear
/// 
/// ============================================================================
