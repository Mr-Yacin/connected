import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_connect_app/core/theme/app_theme.dart';
import 'package:social_connect_app/core/theme/theme_provider.dart';
import 'package:social_connect_app/core/navigation/app_router.dart';
import 'package:social_connect_app/services/external/firebase_service.dart';
import 'package:social_connect_app/services/monitoring/performance_service.dart';
import 'package:social_connect_app/services/monitoring/crashlytics_service.dart';
import 'package:social_connect_app/services/monitoring/error_logging_service.dart';
import 'package:social_connect_app/services/external/notification_service.dart';
import 'package:social_connect_app/core/widgets/error_boundary_widget.dart';

// Global flag to track initialization status
bool _isInitializationComplete = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences first
  SharedPreferences? sharedPreferences;
  try {
    sharedPreferences = await SharedPreferences.getInstance();
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize SharedPreferences: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue with null - app will handle missing preferences
  }

  // Initialize Firebase
  bool firebaseInitialized = false;
  try {
    await FirebaseService.initialize();
    firebaseInitialized = true;
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize Firebase: $e');
    debugPrint('Stack trace: $stackTrace');
    // Cannot continue without Firebase - this is critical
    rethrow;
  }

  // Initialize monitoring services (these handle their own Firebase instances)
  try {
    await CrashlyticsService.initialize();
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize Crashlytics: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue without Crashlytics - not critical for app functionality
  }

  try {
    await PerformanceService.initialize();
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize Performance Service: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue without Performance monitoring - not critical for app functionality
  }

  // Initialize Notification Service
  NotificationService? notificationService;
  try {
    notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize Notification Service: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue without notifications - not critical for app functionality
  }

  // Get service instances for providers (only if Firebase initialized)
  FirebasePerformance? performance;
  FirebaseAnalytics? analytics;
  FirebaseCrashlytics? crashlytics;
  
  if (firebaseInitialized) {
    try {
      performance = FirebasePerformance.instance;
    } catch (e) {
      debugPrint('Failed to get Performance instance: $e');
    }
    
    try {
      analytics = FirebaseAnalytics.instance;
    } catch (e) {
      debugPrint('Failed to get Analytics instance: $e');
    }
    
    try {
      crashlytics = FirebaseCrashlytics.instance;
    } catch (e) {
      debugPrint('Failed to get Crashlytics instance: $e');
    }
  }

  // Mark initialization as complete
  _isInitializationComplete = true;

  runApp(
    ProviderScope(
      overrides: [
        if (sharedPreferences != null)
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        if (performance != null)
          firebasePerformanceProvider.overrideWithValue(performance),
        if (analytics != null)
          firebaseAnalyticsProvider.overrideWithValue(analytics),
        if (crashlytics != null)
          firebaseCrashlyticsProvider.overrideWithValue(crashlytics),
        if (notificationService != null)
          notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: ErrorBoundary(
        onError: (error, stackTrace) {
          // Log to Crashlytics
          if (crashlytics != null) {
            crashlytics.recordError(
              error,
              stackTrace,
              reason: 'Uncaught error in widget tree',
              fatal: false,
            );
          }
          
          // Log to ErrorLoggingService
          ErrorLoggingService.logGeneralError(
            error,
            stackTrace: stackTrace,
            context: 'Uncaught error in widget tree',
            screen: 'App Root',
            operation: 'Widget Build',
          );
        },
        errorBuilder: (error, stackTrace) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar', 'SA'),
            supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'حدث خطأ غير متوقع',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'نعتذر عن الإزعاج. يرجى إعادة تشغيل التطبيق.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Restart the app by re-running main
                          // Note: This is a simple restart mechanism
                          // For production, consider using restart_app package
                          main();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة تشغيل التطبيق'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wait for initialization to complete before rendering the app
    if (!_isInitializationComplete) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'نبض - Nabd',
      debugShowCheckedModeBanner: false,

      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeProvider), // Dynamic theme from provider
      themeAnimationDuration:
          Duration.zero, // Disable global theme animation to prevent crash
      // RTL Support
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
