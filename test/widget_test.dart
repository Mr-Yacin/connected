import 'package:flutter_test/flutter_test.dart';
import 'package:social_connect_app/core/models/user_profile.dart';
import 'package:social_connect_app/core/models/message.dart';
import 'package:social_connect_app/core/models/story.dart';
import 'package:social_connect_app/core/models/report.dart';
import 'package:social_connect_app/core/models/discovery_filters.dart';
import 'package:social_connect_app/core/models/enums.dart';

void main() {
  group('Data Models Tests', () {
    test('UserProfile toJson and fromJson should work correctly', () {
      final profile = UserProfile(
        id: 'test-id',
        phoneNumber: '+1234567890',
        name: 'Test User',
        age: 25,
        country: 'Saudi Arabia',
        dialect: 'Najdi',
        profileImageUrl: 'https://example.com/image.jpg',
        isImageBlurred: false,
        anonymousLink: 'https://example.com/anon/123',
        createdAt: DateTime(2024, 1, 1),
        lastActive: DateTime(2024, 1, 2),
      );

      final json = profile.toJson();
      final fromJson = UserProfile.fromJson(json);

      expect(fromJson.id, equals(profile.id));
      expect(fromJson.phoneNumber, equals(profile.phoneNumber));
      expect(fromJson.name, equals(profile.name));
      expect(fromJson.age, equals(profile.age));
    });

    test('Message toJson and fromJson should work correctly', () {
      final message = Message(
        id: 'msg-1',
        chatId: 'chat-1',
        senderId: 'user-1',
        receiverId: 'user-2',
        type: MessageType.text,
        content: 'Hello',
        timestamp: DateTime(2024, 1, 1),
        isRead: false,
      );

      final json = message.toJson();
      final fromJson = Message.fromJson(json);

      expect(fromJson.id, equals(message.id));
      expect(fromJson.chatId, equals(message.chatId));
      expect(fromJson.type, equals(message.type));
      expect(fromJson.content, equals(message.content));
    });

    test('Story toJson and fromJson should work correctly', () {
      final story = Story(
        id: 'story-1',
        userId: 'user-1',
        mediaUrl: 'https://example.com/story.jpg',
        type: StoryType.image,
        createdAt: DateTime(2024, 1, 1),
        expiresAt: DateTime(2024, 1, 2),
        viewerIds: ['user-2', 'user-3'],
      );

      final json = story.toJson();
      final fromJson = Story.fromJson(json);

      expect(fromJson.id, equals(story.id));
      expect(fromJson.userId, equals(story.userId));
      expect(fromJson.type, equals(story.type));
      expect(fromJson.viewerIds.length, equals(2));
    });

    test('Report toJson and fromJson should work correctly', () {
      final report = Report(
        id: 'report-1',
        reporterId: 'user-1',
        reportedUserId: 'user-2',
        reportedContentId: 'content-1',
        type: ReportType.user,
        reason: 'Inappropriate behavior',
        status: ReportStatus.pending,
        createdAt: DateTime(2024, 1, 1),
      );

      final json = report.toJson();
      final fromJson = Report.fromJson(json);

      expect(fromJson.id, equals(report.id));
      expect(fromJson.reporterId, equals(report.reporterId));
      expect(fromJson.type, equals(report.type));
      expect(fromJson.status, equals(report.status));
    });

    test('DiscoveryFilters toJson should work correctly', () {
      final filters = DiscoveryFilters(
        country: 'Saudi Arabia',
        dialect: 'Najdi',
        minAge: 18,
        maxAge: 30,
        excludedUserIds: ['user-1', 'user-2'],
      );

      final json = filters.toJson();

      expect(json['country'], equals('Saudi Arabia'));
      expect(json['dialect'], equals('Najdi'));
      expect(json['minAge'], equals(18));
      expect(json['maxAge'], equals(30));
    });

    test('Story isExpired should return correct value', () {
      final expiredStory = Story(
        id: 'story-1',
        userId: 'user-1',
        mediaUrl: 'https://example.com/story.jpg',
        type: StoryType.image,
        createdAt: DateTime(2024, 1, 1),
        expiresAt: DateTime(2024, 1, 1, 1), // 1 hour after creation
        viewerIds: [],
      );

      final activeStory = Story(
        id: 'story-2',
        userId: 'user-1',
        mediaUrl: 'https://example.com/story2.jpg',
        type: StoryType.image,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 23)),
        viewerIds: [],
      );

      expect(expiredStory.isExpired, isTrue);
      expect(activeStory.isExpired, isFalse);
    });
  });
}
