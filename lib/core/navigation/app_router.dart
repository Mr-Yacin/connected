import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../features/auth/presentation/screens/phone_input_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/stories/presentation/screens/story_creation_screen.dart';
import '../../features/moderation/presentation/screens/blocked_users_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

/// Application router using go_router
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: GoRouterRefreshStream(
        FirebaseAuth.instance.authStateChanges(),
      ),

      // Auth guard - redirect to login if not authenticated
      redirect: (context, state) {
        final user = FirebaseAuth.instance.currentUser;
        final isAuthRoute = state.matchedLocation.startsWith('/auth');

        // If user is not logged in and trying to access protected route
        if (user == null && !isAuthRoute) {
          return '/auth/phone';
        }

        // If user is logged in and trying to access auth routes
        if (user != null && isAuthRoute) {
          return '/';
        }

        return null; // No redirect needed
      },

      routes: [
        // Auth routes
        GoRoute(
          path: '/auth/phone',
          builder: (context, state) => const PhoneInputScreen(),
        ),
        GoRoute(
          path: '/auth/otp',
          builder: (context, state) => const OtpVerificationScreen(),
        ),

        // Main app routes
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
          routes: [
            // Chat routes
            GoRoute(
              path: 'chat/:chatId',
              builder: (context, state) {
                final chatId = state.pathParameters['chatId']!;
                final currentUserId =
                    state.uri.queryParameters['currentUserId'] ??
                    FirebaseAuth.instance.currentUser?.uid ??
                    '';
                final otherUserId =
                    state.uri.queryParameters['otherUserId'] ?? '';
                final otherUserName =
                    state.uri.queryParameters['otherUserName'];
                final otherUserImageUrl =
                    state.uri.queryParameters['otherUserImageUrl'];

                return ChatScreen(
                  chatId: chatId,
                  currentUserId: currentUserId,
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  otherUserImageUrl: otherUserImageUrl,
                );
              },
            ),

            // Profile routes
            GoRoute(
              path: 'profile/:userId',
              builder: (context, state) {
                final userId = state.pathParameters['userId'];
                return ProfileScreen(viewedUserId: userId);
              },
            ),

            // Anonymous profile deep link
            GoRoute(
              path: 'profile/link/:anonymousLink',
              builder: (context, state) {
                final anonymousLink = state.pathParameters['anonymousLink']!;
                // The ProfileScreen will need to handle loading by anonymous link
                return ProfileScreen(viewedUserId: anonymousLink);
              },
            ),

            // Story routes
            GoRoute(
              path: 'story/create',
              builder: (context, state) {
                final userId = state.uri.queryParameters['userId'] ?? '';
                return StoryCreationScreen(userId: userId);
              },
            ),

            // Settings routes
            GoRoute(
              path: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),

            // Moderation routes
            GoRoute(
              path: 'blocked-users',
              builder: (context, state) => const BlockedUsersScreen(),
            ),
          ],
        ),
      ],

      // Error handling
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'خطأ في التنقل',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.toString() ?? 'صفحة غير موجودة',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
