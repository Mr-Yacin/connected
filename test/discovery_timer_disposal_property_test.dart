// Feature: performance-optimization, Property 19: Timer cleanup on provider disposal
// Validates: Requirements 5.4

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_connect_app/features/discovery/presentation/providers/discovery_provider.dart';
import 'package:social_connect_app/features/discovery/data/repositories/firestore_discovery_repository.dart';
import 'package:social_connect_app/features/discovery/data/services/viewed_users_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([FirestoreDiscoveryRepository, ViewedUsersService])
import 'discovery_timer_disposal_property_test.mocks.dart';

void main() {
  group('Property 19: Timer cleanup on provider disposal', () {
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

    test('disposing provider with active timer should cancel the timer', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Start cooldown
      await notifier.shuffleWithCooldown();

      // Verify timer is active
      var state = container.read(discoveryProvider);
      expect(state.canShuffle, false);
      expect(state.cooldownSeconds, 3);

      // Dispose container (which should dispose the notifier and cancel timer)
      container.dispose();

      // Wait to ensure timer would have fired if not cancelled
      await Future.delayed(const Duration(milliseconds: 1500));

      // No exceptions should be thrown - timer was properly cancelled
      // If timer wasn't cancelled, it would try to update disposed state
    });

    test('disposing provider during cooldown should not cause errors', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Start cooldown
      await notifier.shuffleWithCooldown();

      // Dispose immediately during active cooldown
      expect(() => container.dispose(), returnsNormally);

      // Wait to ensure no delayed errors
      await Future.delayed(const Duration(milliseconds: 500));
    });

    test('multiple dispose calls should be safe', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Start cooldown
      await notifier.shuffleWithCooldown();

      // First dispose
      container.dispose();

      // Second dispose should not throw
      expect(() => container.dispose(), returnsNormally);
    });

    test('disposing provider before cooldown starts should be safe', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Dispose without starting cooldown
      expect(() => container.dispose(), returnsNormally);
    });

    test('disposing provider after cooldown completion should be safe', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Start cooldown
      await notifier.shuffleWithCooldown();

      // Wait for completion
      await Future.delayed(const Duration(milliseconds: 3500));

      // Dispose after completion
      expect(() => container.dispose(), returnsNormally);
    });

    test('timer should not update state after disposal', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Track state updates
      int updateCount = 0;
      container.listen(
        discoveryProvider,
        (previous, next) {
          updateCount++;
        },
      );

      // Start cooldown
      await notifier.shuffleWithCooldown();
      
      // Wait a bit for some updates
      await Future.delayed(const Duration(milliseconds: 500));
      
      final updatesBeforeDispose = updateCount;

      // Dispose
      container.dispose();

      // Wait for what would be more timer ticks
      await Future.delayed(const Duration(milliseconds: 2000));

      // No new updates should have occurred after disposal
      expect(updateCount, updatesBeforeDispose);
    });
  });
}
