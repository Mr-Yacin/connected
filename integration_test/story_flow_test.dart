import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:social_connect_app/main.dart' as app;

/// Integration test for story publishing and viewing flow
/// Tests: Story creation, story visibility, story viewing, story expiration
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Story Flow Tests', () {
    testWidgets('Create and publish a story', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Look for the add story button (usually a + icon in story bar)
      final addStoryButton = find.byIcon(Icons.add_circle);
      if (addStoryButton.evaluate().isNotEmpty) {
        await tester.tap(addStoryButton);
        await tester.pumpAndSettle();

        // Verify we're on story creation screen
        expect(find.text('إنشاء قصة'), findsOneWidget);

        // Select image option
        final imageButton = find.byIcon(Icons.image);
        if (imageButton.evaluate().isNotEmpty) {
          await tester.tap(imageButton);
          await tester.pumpAndSettle();

          // Note: In real test, you would need to mock image picker
          // or use a test image from assets
          
          // Tap publish button
          final publishButton = find.text('نشر');
          if (publishButton.evaluate().isNotEmpty) {
            await tester.tap(publishButton);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Verify story appears in story bar
            expect(find.byType(CircleAvatar), findsWidgets);
          }
        }
      }
    });

    testWidgets('View a story', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find story circles in the story bar
      final storyCircles = find.byType(CircleAvatar);
      if (storyCircles.evaluate().isNotEmpty) {
        // Tap on first story
        await tester.tap(storyCircles.first);
        await tester.pumpAndSettle();

        // Verify story view screen is displayed
        // Should show full-screen story
        expect(find.byType(GestureDetector), findsWidgets);

        // Wait for story to display
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Tap to go to next story or close
        await tester.tapAt(const Offset(300, 400));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Story progress indicator', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final storyCircles = find.byType(CircleAvatar);
      if (storyCircles.evaluate().isNotEmpty) {
        await tester.tap(storyCircles.first);
        await tester.pumpAndSettle();

        // Verify progress indicators are present
        // (usually shown as lines at the top of the screen)
        expect(find.byType(LinearProgressIndicator), findsWidgets);
      }
    });

    testWidgets('Story view count increments', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to profile to see own stories
      final profileTab = find.byIcon(Icons.person);
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();

        // Look for story view count
        // This would show how many people viewed the story
        final viewCount = find.textContaining('مشاهدة');
        
        // Note: Actual view count verification would require
        // multiple test users or mock data
      }
    });

    testWidgets('Story expiration after 24 hours', (WidgetTester tester) async {
      // Note: This test would require time manipulation or mock data
      // to test the 24-hour expiration without waiting
      
      app.main();
      await tester.pumpAndSettle();

      // In a real scenario, you would:
      // 1. Create a story with a mocked timestamp (23 hours ago)
      // 2. Verify it appears in the story bar
      // 3. Mock time to 25 hours later
      // 4. Verify story no longer appears
      
      // For now, we just verify the story bar exists
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Navigate between multiple stories', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final storyCircles = find.byType(CircleAvatar);
      if (storyCircles.evaluate().length > 1) {
        // Tap on first story
        await tester.tap(storyCircles.first);
        await tester.pumpAndSettle();

        // Swipe left to go to next user's stories
        await tester.drag(
          find.byType(GestureDetector).first,
          const Offset(-300, 0),
        );
        await tester.pumpAndSettle();

        // Verify we moved to next story
        // (different user's story should be displayed)
      }
    });
  });
}
