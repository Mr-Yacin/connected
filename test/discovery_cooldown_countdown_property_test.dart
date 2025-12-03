// Feature: performance-optimization, Property 17: Cooldown countdown updates
// Validates: Requirements 5.2

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_connect_app/features/discovery/presentation/providers/discovery_provider.dart';
import 'package:social_connect_app/features/discovery/data/repositories/firestore_discovery_repository.dart';
import 'package:social_connect_app/features/discovery/data/services/viewed_users_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([FirestoreDiscoveryRepository, ViewedUsersService])
import 'discovery_cooldown_countdown_property_test.mocks.dart';

void main() {
  group('Property 17: Cooldown countdown updates', () {
    late MockFirestoreDiscoveryRepository mockRepository;
    late MockViewedUsersService mockViewedUsersService;

    setUp(() {
      mockRepository = MockFirestoreDiscoveryRepository();
      mockViewedUsersService = MockViewedUsersService();
      
      // Setup default mocks
      when(mockViewedUsersService.getViewedUsers())
          .thenAnswer((_) async => <String>{});
      when(mockRepository.getRandomUser(any, any))
          .thenAnswer((_) async => null);
    });

    test('cooldown countdown should update state with remaining seconds each second', () async {
      // Create provider container with mocked dependencies
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Start cooldown by calling shuffleWithCooldown
      await notifier.shuffleWithCooldown();

      // Initial state should have cooldown at 3 seconds
      var state = container.read(discoveryProvider);
      expect(state.cooldownSeconds, 3);
      expect(state.canShuffle, false);

      // Wait 1 second and check countdown
      await Future.delayed(const Duration(milliseconds: 1100));
      state = container.read(discoveryProvider);
      expect(state.cooldownSeconds, lessThanOrEqualTo(2));
      expect(state.cooldownSeconds, greaterThanOrEqualTo(1));

      // Wait another second
      await Future.delayed(const Duration(milliseconds: 1100));
      state = container.read(discoveryProvider);
      expect(state.cooldownSeconds, lessThanOrEqualTo(1));
      expect(state.cooldownSeconds, greaterThanOrEqualTo(0));

      // Wait for completion
      await Future.delayed(const Duration(milliseconds: 1100));
      state = container.read(discoveryProvider);
      expect(state.cooldownSeconds, 0);
    });

    test('cooldown countdown should update every second for full duration', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Track state changes
      final stateChanges = <int>[];
      container.listen(
        discoveryProvider,
        (previous, next) {
          stateChanges.add(next.cooldownSeconds);
        },
      );

      // Start cooldown
      await notifier.shuffleWithCooldown();

      // Wait for full cooldown duration plus buffer
      await Future.delayed(const Duration(milliseconds: 3500));

      // Should have multiple state updates (at least 3: initial 3, 2, 1, 0)
      expect(stateChanges.length, greaterThanOrEqualTo(3));
      
      // Should end at 0
      expect(stateChanges.last, 0);
    });

    test('cooldown countdown should be monotonically decreasing', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Track state changes
      final stateChanges = <int>[];
      container.listen(
        discoveryProvider,
        (previous, next) {
          stateChanges.add(next.cooldownSeconds);
        },
      );

      // Start cooldown
      await notifier.shuffleWithCooldown();

      // Wait for full cooldown
      await Future.delayed(const Duration(milliseconds: 3500));

      // Verify countdown is monotonically decreasing
      for (int i = 1; i < stateChanges.length; i++) {
        expect(
          stateChanges[i],
          lessThanOrEqualTo(stateChanges[i - 1]),
          reason: 'Countdown should never increase',
        );
      }
    });
  });
}
