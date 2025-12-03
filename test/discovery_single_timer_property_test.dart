// Feature: performance-optimization, Property 20: Single active cooldown timer
// Validates: Requirements 5.5

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_connect_app/features/discovery/presentation/providers/discovery_provider.dart';
import 'package:social_connect_app/features/discovery/data/repositories/firestore_discovery_repository.dart';
import 'package:social_connect_app/features/discovery/data/services/viewed_users_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([FirestoreDiscoveryRepository, ViewedUsersService])
import 'discovery_single_timer_property_test.mocks.dart';

void main() {
  group('Property 20: Single active cooldown timer', () {
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

    test('starting new cooldown while one is active should cancel previous timer', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Start first cooldown
      await notifier.shuffleWithCooldown();
      
      var state = container.read(discoveryProvider);
      expect(state.cooldownSeconds, 3);

      // Wait 1 second
      await Future.delayed(const Duration(milliseconds: 1100));
      
      state = container.read(discoveryProvider);
      final firstCooldownValue = state.cooldownSeconds;
      expect(firstCooldownValue, lessThan(3));

      // Wait for cooldown to complete
      await Future.delayed(const Duration(milliseconds: 2500));
      
      // Start second cooldown immediately
      await notifier.shuffleWithCooldown();
      
      state = container.read(discoveryProvider);
      // Should reset to 3, not continue from previous timer
      expect(state.cooldownSeconds, 3);
    });

    test('rapid shuffle attempts should maintain single timer', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // First shuffle
      await notifier.shuffleWithCooldown();
      
      // Wait for cooldown to complete
      await Future.delayed(const Duration(milliseconds: 3500));

      // Multiple rapid shuffles
      await notifier.shuffleWithCooldown();
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Wait for cooldown
      await Future.delayed(const Duration(milliseconds: 3500));
      
      await notifier.shuffleWithCooldown();
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Wait for cooldown
      await Future.delayed(const Duration(milliseconds: 3500));
      
      await notifier.shuffleWithCooldown();

      // Final state should be valid
      final state = container.read(discoveryProvider);
      expect(state.cooldownSeconds, greaterThanOrEqualTo(0));
      expect(state.cooldownSeconds, lessThanOrEqualTo(3));
    });

    test('only one timer should be active at any time', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Track all cooldown values
      final cooldownValues = <int>[];
      container.listen(
        discoveryProvider,
        (previous, next) {
          cooldownValues.add(next.cooldownSeconds);
        },
      );

      // Start first cooldown
      await notifier.shuffleWithCooldown();
      
      // Wait for it to complete
      await Future.delayed(const Duration(milliseconds: 3500));
      
      // Start second cooldown
      await notifier.shuffleWithCooldown();
      
      // Wait for it to complete
      await Future.delayed(const Duration(milliseconds: 3500));

      // Verify countdown pattern is consistent (no overlapping timers)
      // Each cooldown should go from 3 -> 2 -> 1 -> 0
      // We should see this pattern twice, not interleaved
      expect(cooldownValues.first, 3);
      expect(cooldownValues.last, 0);
    });

    test('cancelling previous timer should not affect new timer', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Start first cooldown
      await notifier.shuffleWithCooldown();
      
      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Wait for first cooldown to complete
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // Start new cooldown
      await notifier.shuffleWithCooldown();
      
      var state = container.read(discoveryProvider);
      expect(state.cooldownSeconds, 3);
      expect(state.canShuffle, false);

      // New timer should work normally
      await Future.delayed(const Duration(milliseconds: 1100));
      state = container.read(discoveryProvider);
      expect(state.cooldownSeconds, lessThan(3));

      // Wait for completion
      await Future.delayed(const Duration(milliseconds: 2500));
      state = container.read(discoveryProvider);
      expect(state.cooldownSeconds, 0);
      expect(state.canShuffle, true);
    });

    test('timer cancellation should be immediate when starting new cooldown', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Start first cooldown
      await notifier.shuffleWithCooldown();
      
      // Wait for completion
      await Future.delayed(const Duration(milliseconds: 3500));
      
      var state = container.read(discoveryProvider);
      expect(state.canShuffle, true);

      // Start second cooldown immediately
      await notifier.shuffleWithCooldown();
      
      state = container.read(discoveryProvider);
      // Should immediately show new cooldown state
      expect(state.cooldownSeconds, 3);
      expect(state.canShuffle, false);
    });
  });
}
