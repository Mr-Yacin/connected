import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_connect_app/features/stories/utils/story_time_formatter.dart';
import 'package:social_connect_app/features/stories/presentation/widgets/common/story_profile_avatar.dart';
import 'package:social_connect_app/features/stories/presentation/widgets/common/story_stats_row.dart';
import 'package:social_connect_app/features/stories/presentation/widgets/story_insights_dialog.dart';
import 'package:social_connect_app/core/models/story.dart';
import 'package:social_connect_app/core/models/enums.dart';

/// Integration tests for shared story utilities
/// Tests that shared utilities work correctly in multiple contexts
/// **Validates: Requirements 1.5**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shared Utilities Integration Tests - Requirements 1.5', () {
    
    // ========================================================================
    // StoryTimeFormatter Tests
    // ========================================================================
    
    group('StoryTimeFormatter in multiple contexts', () {
      test('formats time correctly for "now" (less than 1 minute)', () {
        final now = DateTime.now();
        final result = StoryTimeFormatter.getTimeAgo(now);
        expect(result, equals('الآن'));
      });

      test('formats time correctly for minutes ago', () {
        final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
        final result = StoryTimeFormatter.getTimeAgo(fiveMinutesAgo);
        expect(result, equals('منذ 5د'));
      });

      test('formats time correctly for hours ago', () {
        final threeHoursAgo = DateTime.now().subtract(const Duration(hours: 3));
        final result = StoryTimeFormatter.getTimeAgo(threeHoursAgo);
        expect(result, equals('منذ 3س'));
      });

      test('formats time correctly for days ago', () {
        final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
        final result = StoryTimeFormatter.getTimeAgo(twoDaysAgo);
        expect(result, equals('منذ 2ي'));
      });

      test('handles edge case: exactly 1 minute ago', () {
        final oneMinuteAgo = DateTime.now().subtract(const Duration(minutes: 1));
        final result = StoryTimeFormatter.getTimeAgo(oneMinuteAgo);
        expect(result, equals('منذ 1د'));
      });

      test('handles edge case: exactly 1 hour ago', () {
        final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
        final result = StoryTimeFormatter.getTimeAgo(oneHourAgo);
        expect(result, equals('منذ 1س'));
      });

      test('handles edge case: exactly 24 hours ago', () {
        final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));
        final result = StoryTimeFormatter.getTimeAgo(oneDayAgo);
        expect(result, equals('منذ 1ي'));
      });

      test('works in story card context', () {
        // Simulate usage in story card widget
        final storyTimestamp = DateTime.now().subtract(const Duration(hours: 2));
        final formattedTime = StoryTimeFormatter.getTimeAgo(storyTimestamp);
        
        expect(formattedTime, equals('منذ 2س'));
        expect(formattedTime, isA<String>());
        expect(formattedTime.isNotEmpty, isTrue);
      });

      test('works in story viewer context', () {
        // Simulate usage in story viewer screen
        final storyTimestamp = DateTime.now().subtract(const Duration(minutes: 30));
        final formattedTime = StoryTimeFormatter.getTimeAgo(storyTimestamp);
        
        expect(formattedTime, equals('منذ 30د'));
      });

      test('works in multi-user story view context', () {
        // Simulate usage in multi-user story view
        final timestamps = [
          DateTime.now().subtract(const Duration(minutes: 5)),
          DateTime.now().subtract(const Duration(hours: 1)),
          DateTime.now().subtract(const Duration(days: 1)),
        ];
        
        final formattedTimes = timestamps.map((t) => StoryTimeFormatter.getTimeAgo(t)).toList();
        
        expect(formattedTimes[0], equals('منذ 5د'));
        expect(formattedTimes[1], equals('منذ 1س'));
        expect(formattedTimes[2], equals('منذ 1ي'));
      });
    });

    // ========================================================================
    // StoryProfileAvatar Tests
    // ========================================================================
    
    group('StoryProfileAvatar in multiple contexts', () {
      testWidgets('renders with default parameters', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StoryProfileAvatar(
                profileImageUrl: 'https://example.com/avatar.jpg',
              ),
            ),
          ),
        );

        expect(find.byType(StoryProfileAvatar), findsOneWidget);
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('renders with null profile image URL', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StoryProfileAvatar(
                profileImageUrl: null,
              ),
            ),
          ),
        );

        expect(find.byType(StoryProfileAvatar), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
      });

      testWidgets('renders with custom size', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StoryProfileAvatar(
                profileImageUrl: 'https://example.com/avatar.jpg',
                size: 60,
              ),
            ),
          ),
        );

        final avatar = tester.widget<StoryProfileAvatar>(find.byType(StoryProfileAvatar));
        expect(avatar.size, equals(60));
      });

      testWidgets('renders with custom border width', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StoryProfileAvatar(
                profileImageUrl: 'https://example.com/avatar.jpg',
                borderWidth: 3,
              ),
            ),
          ),
        );

        final avatar = tester.widget<StoryProfileAvatar>(find.byType(StoryProfileAvatar));
        expect(avatar.borderWidth, equals(3));
      });

      testWidgets('renders without shadow when showShadow is false', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StoryProfileAvatar(
                profileImageUrl: 'https://example.com/avatar.jpg',
                showShadow: false,
              ),
            ),
          ),
        );

        final avatar = tester.widget<StoryProfileAvatar>(find.byType(StoryProfileAvatar));
        expect(avatar.showShadow, isFalse);
      });

      testWidgets('works in story card context', (WidgetTester tester) async {
        // Simulate usage in story card widget
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  StoryProfileAvatar(
                    profileImageUrl: 'https://example.com/user1.jpg',
                    size: 40,
                  ),
                  SizedBox(height: 8),
                  Text('User Story'),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(StoryProfileAvatar), findsOneWidget);
        expect(find.text('User Story'), findsOneWidget);
      });

      testWidgets('works in story viewer context', (WidgetTester tester) async {
        // Simulate usage in story viewer screen
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  StoryProfileAvatar(
                    profileImageUrl: 'https://example.com/user1.jpg',
                    size: 32,
                    borderWidth: 1,
                  ),
                  SizedBox(width: 8),
                  Text('Username'),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(StoryProfileAvatar), findsOneWidget);
        expect(find.text('Username'), findsOneWidget);
      });

      testWidgets('works in multi-user story view context', (WidgetTester tester) async {
        // Simulate usage with multiple avatars
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  StoryProfileAvatar(
                    profileImageUrl: 'https://example.com/user1.jpg',
                    size: 40,
                  ),
                  SizedBox(width: 8),
                  StoryProfileAvatar(
                    profileImageUrl: 'https://example.com/user2.jpg',
                    size: 40,
                  ),
                  SizedBox(width: 8),
                  StoryProfileAvatar(
                    profileImageUrl: null,
                    size: 40,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(StoryProfileAvatar), findsNWidgets(3));
      });
    });

    // ========================================================================
    // StoryStatsRow Tests
    // ========================================================================
    
    group('StoryStatsRow in multiple contexts', () {
      testWidgets('renders with default icon mode', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StoryStatsRow(
                viewCount: 10,
                likeCount: 5,
                replyCount: 2,
              ),
            ),
          ),
        );

        expect(find.byType(StoryStatsRow), findsOneWidget);
        expect(find.byIcon(Icons.visibility), findsOneWidget);
        expect(find.byIcon(Icons.favorite), findsOneWidget);
        expect(find.byIcon(Icons.message), findsOneWidget);
        expect(find.text('10'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('renders with text labels mode', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StoryStatsRow.withLabels(
                viewCount: 10,
                likeCount: 5,
                replyCount: 2,
              ),
            ),
          ),
        );

        expect(find.byType(StoryStatsRow), findsOneWidget);
        expect(find.textContaining('مشاهدة'), findsOneWidget);
        expect(find.textContaining('إعجاب'), findsOneWidget);
        expect(find.textContaining('رد'), findsOneWidget);
      });

      testWidgets('hides zero replies when hideZeroReplies is true', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StoryStatsRow(
                viewCount: 10,
                likeCount: 5,
                replyCount: 0,
                hideZeroReplies: true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.visibility), findsOneWidget);
        expect(find.byIcon(Icons.favorite), findsOneWidget);
        expect(find.byIcon(Icons.message), findsNothing);
      });

      testWidgets('shows zero replies when hideZeroReplies is false', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StoryStatsRow(
                viewCount: 10,
                likeCount: 5,
                replyCount: 0,
                hideZeroReplies: false,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.message), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('renders with custom colors', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StoryStatsRow(
                viewCount: 10,
                likeCount: 5,
                replyCount: 2,
                color: Colors.blue,
              ),
            ),
          ),
        );

        final statsRow = tester.widget<StoryStatsRow>(find.byType(StoryStatsRow));
        expect(statsRow.color, equals(Colors.blue));
      });

      testWidgets('works in story card context', (WidgetTester tester) async {
        // Simulate usage in story card widget
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Story Title'),
                  SizedBox(height: 8),
                  StoryStatsRow(
                    viewCount: 100,
                    likeCount: 25,
                    replyCount: 5,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(StoryStatsRow), findsOneWidget);
        expect(find.text('100'), findsOneWidget);
        expect(find.text('25'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('works in story viewer overlay context', (WidgetTester tester) async {
        // Simulate usage in story viewer overlay
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Container(color: Colors.black),
                  const Positioned(
                    bottom: 20,
                    left: 20,
                    child: StoryStatsRow(
                      viewCount: 50,
                      likeCount: 10,
                      replyCount: 3,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(StoryStatsRow), findsOneWidget);
      });

      testWidgets('works in insights summary context', (WidgetTester tester) async {
        // Simulate usage in insights/summary view
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: StoryStatsRow.withLabels(
                    viewCount: 200,
                    likeCount: 50,
                    replyCount: 10,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(StoryStatsRow), findsOneWidget);
        expect(find.textContaining('200'), findsOneWidget);
      });

      test('formatStatsText extension works correctly', () {
        final formattedText = StoryStatsText.formatStatsText(
          viewCount: 10,
          likeCount: 5,
          replyCount: 2,
        );

        expect(formattedText, equals('10 مشاهدة • 5 إعجاب • 2 رد'));
      });
    });

    // ========================================================================
    // Story Insights Dialog Tests
    // ========================================================================
    
    group('Story insights dialog in multiple contexts', () {
      late Story testStory;

      setUp(() {
        testStory = Story(
          id: 'test-story-1',
          userId: 'user-1',
          mediaUrl: 'https://example.com/story.jpg',
          type: StoryType.image,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          expiresAt: DateTime.now().add(const Duration(hours: 22)),
          viewerIds: ['viewer1', 'viewer2', 'viewer3'],
          likedBy: ['liker1', 'liker2'],
          replyCount: 5,
        );
      });

      testWidgets('dialog displays all story statistics', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showStoryInsightsDialog(
                        context: context,
                        story: testStory,
                      );
                    },
                    child: const Text('Show Insights'),
                  );
                },
              ),
            ),
          ),
        );

        // Tap button to show dialog
        await tester.tap(find.text('Show Insights'));
        await tester.pumpAndSettle();

        // Verify dialog is displayed
        expect(find.byType(StoryInsightsDialog), findsOneWidget);
        expect(find.text('إحصائيات القصة'), findsOneWidget);
        
        // Verify statistics are displayed
        expect(find.text('المشاهدات'), findsOneWidget);
        expect(find.text('3'), findsOneWidget); // viewerIds.length
        
        expect(find.text('الإعجابات'), findsOneWidget);
        expect(find.text('2'), findsOneWidget); // likedBy.length
        
        expect(find.text('الردود'), findsOneWidget);
        expect(find.text('5'), findsOneWidget); // replyCount
        
        expect(find.text('تنتهي في'), findsOneWidget);
      });

      testWidgets('dialog can be closed', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showStoryInsightsDialog(
                        context: context,
                        story: testStory,
                      );
                    },
                    child: const Text('Show Insights'),
                  );
                },
              ),
            ),
          ),
        );

        // Show dialog
        await tester.tap(find.text('Show Insights'));
        await tester.pumpAndSettle();

        expect(find.byType(StoryInsightsDialog), findsOneWidget);

        // Close dialog
        await tester.tap(find.text('إغلاق'));
        await tester.pumpAndSettle();

        expect(find.byType(StoryInsightsDialog), findsNothing);
      });

      testWidgets('dialog shows correct time remaining', (WidgetTester tester) async {
        final storyExpiringSoon = Story(
          id: 'test-story-2',
          userId: 'user-1',
          mediaUrl: 'https://example.com/story.jpg',
          type: StoryType.image,
          createdAt: DateTime.now().subtract(const Duration(hours: 23)),
          expiresAt: DateTime.now().add(const Duration(minutes: 45)),
          viewerIds: [],
          likedBy: [],
          replyCount: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showStoryInsightsDialog(
                        context: context,
                        story: storyExpiringSoon,
                      );
                    },
                    child: const Text('Show Insights'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Insights'));
        await tester.pumpAndSettle();

        // Verify time remaining is displayed
        expect(find.text('تنتهي في'), findsOneWidget);
        expect(find.textContaining('دقيقة'), findsOneWidget);
      });

      testWidgets('dialog shows expired status for expired stories', (WidgetTester tester) async {
        final expiredStory = Story(
          id: 'test-story-3',
          userId: 'user-1',
          mediaUrl: 'https://example.com/story.jpg',
          type: StoryType.image,
          createdAt: DateTime.now().subtract(const Duration(hours: 25)),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
          viewerIds: [],
          likedBy: [],
          replyCount: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showStoryInsightsDialog(
                        context: context,
                        story: expiredStory,
                      );
                    },
                    child: const Text('Show Insights'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Insights'));
        await tester.pumpAndSettle();

        // Verify expired status is shown
        expect(find.text('منتهية'), findsOneWidget);
      });

      testWidgets('works in story card context', (WidgetTester tester) async {
        // Simulate usage from story card widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Card(
                    child: Column(
                      children: [
                        const Text('My Story'),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            showStoryInsightsDialog(
                              context: context,
                              story: testStory,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();

        expect(find.byType(StoryInsightsDialog), findsOneWidget);
      });

      testWidgets('works in story viewer context', (WidgetTester tester) async {
        // Simulate usage from story viewer screen
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Stack(
                    children: [
                      Container(color: Colors.black),
                      Positioned(
                        top: 40,
                        right: 20,
                        child: IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onPressed: () {
                            showStoryInsightsDialog(
                              context: context,
                              story: testStory,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(find.byType(StoryInsightsDialog), findsOneWidget);
      });

      testWidgets('works in profile stories context', (WidgetTester tester) async {
        // Simulate usage from profile stories grid
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return GridView.count(
                    crossAxisCount: 3,
                    children: [
                      GestureDetector(
                        onLongPress: () {
                          showStoryInsightsDialog(
                            context: context,
                            story: testStory,
                          );
                        },
                        child: Container(
                          color: Colors.grey,
                          child: const Center(child: Text('Story')),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        await tester.longPress(find.text('Story'));
        await tester.pumpAndSettle();

        expect(find.byType(StoryInsightsDialog), findsOneWidget);
      });
    });

    // ========================================================================
    // Integration Tests: Multiple Utilities Together
    // ========================================================================
    
    group('Multiple utilities working together', () {
      testWidgets('StoryProfileAvatar + StoryStatsRow + StoryTimeFormatter', 
          (WidgetTester tester) async {
        final storyTimestamp = DateTime.now().subtract(const Duration(hours: 3));
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Row(
                    children: [
                      const StoryProfileAvatar(
                        profileImageUrl: 'https://example.com/user.jpg',
                        size: 40,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Username'),
                          Text(StoryTimeFormatter.getTimeAgo(storyTimestamp)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const StoryStatsRow(
                    viewCount: 50,
                    likeCount: 10,
                    replyCount: 3,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(StoryProfileAvatar), findsOneWidget);
        expect(find.byType(StoryStatsRow), findsOneWidget);
        expect(find.text('منذ 3س'), findsOneWidget);
      });

      testWidgets('All utilities in story card layout', (WidgetTester tester) async {
        final storyTimestamp = DateTime.now().subtract(const Duration(minutes: 30));
        final testStory = Story(
          id: 'test-story',
          userId: 'user-1',
          mediaUrl: 'https://example.com/story.jpg',
          type: StoryType.image,
          createdAt: storyTimestamp,
          expiresAt: DateTime.now().add(const Duration(hours: 23, minutes: 30)),
          viewerIds: ['v1', 'v2'],
          likedBy: ['l1'],
          replyCount: 1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const StoryProfileAvatar(
                                profileImageUrl: null, // Use null to avoid network loading
                                size: 40,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Test User'),
                                  Text(
                                    StoryTimeFormatter.getTimeAgo(storyTimestamp),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.info_outline),
                                onPressed: () {
                                  showStoryInsightsDialog(
                                    context: context,
                                    story: testStory,
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const StoryStatsRow(
                            viewCount: 2,
                            likeCount: 1,
                            replyCount: 1,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pump();

        // Verify all utilities are present
        expect(find.byType(StoryProfileAvatar), findsOneWidget);
        expect(find.byType(StoryStatsRow), findsOneWidget);
        expect(find.text('منذ 30د'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);

        // Test insights dialog integration
        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();

        expect(find.byType(StoryInsightsDialog), findsOneWidget);
        expect(find.text('إحصائيات القصة'), findsOneWidget);
      });
    });
  });
}
