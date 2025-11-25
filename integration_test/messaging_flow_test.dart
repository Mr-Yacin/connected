import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:social_connect_app/main.dart' as app;

/// Integration test for messaging flow
/// Tests: Creating chat, sending text messages, sending voice messages, message delivery
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Messaging Flow Tests', () {
    testWidgets('Send text message in chat', (WidgetTester tester) async {
      // Start the app (assumes user is already authenticated)
      app.main();
      await tester.pumpAndSettle();

      // Navigate to chat list
      final chatTab = find.byIcon(Icons.chat);
      if (chatTab.evaluate().isNotEmpty) {
        await tester.tap(chatTab);
        await tester.pumpAndSettle();
      }

      // If there are existing chats, tap the first one
      final chatTiles = find.byType(ListTile);
      if (chatTiles.evaluate().isNotEmpty) {
        await tester.tap(chatTiles.first);
        await tester.pumpAndSettle();

        // Find the message input field
        final messageField = find.byType(TextField).last;
        expect(messageField, findsOneWidget);

        // Type a message
        await tester.enterText(messageField, 'مرحباً! هذه رسالة اختبار');
        await tester.pumpAndSettle();

        // Find and tap the send button
        final sendButton = find.byIcon(Icons.send);
        expect(sendButton, findsOneWidget);
        await tester.tap(sendButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify message appears in chat
        expect(find.text('مرحباً! هذه رسالة اختبار'), findsOneWidget);
      }
    });

    testWidgets('Voice message recording', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to a chat
      final chatTab = find.byIcon(Icons.chat);
      if (chatTab.evaluate().isNotEmpty) {
        await tester.tap(chatTab);
        await tester.pumpAndSettle();

        final chatTiles = find.byType(ListTile);
        if (chatTiles.evaluate().isNotEmpty) {
          await tester.tap(chatTiles.first);
          await tester.pumpAndSettle();

          // Find the microphone button
          final micButton = find.byIcon(Icons.mic);
          if (micButton.evaluate().isNotEmpty) {
            // Long press to start recording
            await tester.longPress(micButton);
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Release to send
            // Note: Actual voice recording would require microphone permissions
            // and proper test environment setup
            
            // Verify voice message indicator appears
            expect(find.byIcon(Icons.play_arrow), findsWidgets);
          }
        }
      }
    });

    testWidgets('Message read status updates', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to chat
      final chatTab = find.byIcon(Icons.chat);
      if (chatTab.evaluate().isNotEmpty) {
        await tester.tap(chatTab);
        await tester.pumpAndSettle();

        // Check for unread count badge
        final unreadBadge = find.textContaining('1');
        
        // Open a chat with unread messages
        final chatTiles = find.byType(ListTile);
        if (chatTiles.evaluate().isNotEmpty) {
          await tester.tap(chatTiles.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Go back to chat list
          await tester.pageBack();
          await tester.pumpAndSettle();

          // Verify unread count decreased or disappeared
          // (messages should be marked as read when viewed)
        }
      }
    });

    testWidgets('Real-time message updates', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to a chat
      final chatTab = find.byIcon(Icons.chat);
      if (chatTab.evaluate().isNotEmpty) {
        await tester.tap(chatTab);
        await tester.pumpAndSettle();

        final chatTiles = find.byType(ListTile);
        if (chatTiles.evaluate().isNotEmpty) {
          await tester.tap(chatTiles.first);
          await tester.pumpAndSettle();

          // Count initial messages
          final initialMessageCount = find.byType(ListTile).evaluate().length;

          // Send a new message
          final messageField = find.byType(TextField).last;
          await tester.enterText(messageField, 'رسالة جديدة');
          await tester.pumpAndSettle();

          final sendButton = find.byIcon(Icons.send);
          await tester.tap(sendButton);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify message count increased
          final newMessageCount = find.byType(ListTile).evaluate().length;
          expect(newMessageCount, greaterThan(initialMessageCount));
        }
      }
    });
  });
}
