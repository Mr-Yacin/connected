import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:social_connect_app/core/theme/app_theme.dart';
import 'package:social_connect_app/core/theme/theme_provider.dart';
import 'package:social_connect_app/core/navigation/app_router.dart';
import 'package:social_connect_app/services/firebase_service.dart';
import 'package:social_connect_app/services/performance_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseService.initialize();

  // Initialize Firebase Performance Monitoring
  final performance = FirebasePerformance.instance;
  await performance.setPerformanceCollectionEnabled(true);

  // Initialize Firebase Analytics
  final analytics = FirebaseAnalytics.instance;
  await analytics.setAnalyticsCollectionEnabled(true);

  runApp(
    ProviderScope(
      overrides: [
        firebasePerformanceProvider.overrideWithValue(performance),
        firebaseAnalyticsProvider.overrideWithValue(analytics),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = AppRouter.createRouter();

    return MaterialApp.router(
      routerConfig: router,
      title: 'نبض - Nabd',
      debugShowCheckedModeBanner: false,

      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeProvider), // Dynamic theme from provider
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
