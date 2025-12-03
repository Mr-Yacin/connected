// Feature: performance-optimization, Property 18: Cooldown completion cleanup
// Validates: Requirements 5.3

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_connect_app/features/discovery/presentation/providers/discovery_provider.dart';
import 'package:social_connect_app/features/discovery/data/repositories/firestore_discovery_repository.dart';
import 'package:social_connect_app/features/discovery/data/services/viewed_users_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([FirestoreDiscoveryRepository, ViewedUsersService])
import 'discovery_cooldown_completion_property_test.mocks.dart';

void main() {
  group('Property 18: Cooldown completion cleanup', () {
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

    test('when cooldown reaches zero, timer should be cancelled and shuffle enabled', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Start cooldown
      await notifier.shuffleWithCooldown();

      // Initial state
      var state = container.read(discoveryProvider);
      expect(state.canShuffle, false);
      expect(state.cooldownSeconds, 3);

      // Wait for cooldown to complete
      await Future.delayed(const Duration(milliseconds: 3500));

      // Final state should have shuffle enabled and countdown at 0
      state = container.read(discoveryProvider);
      expect(state.canShuffle, true);
      expect(state.cooldownSeconds, 0);
    });

    test('after cooldown completion, shuffle should be immediately available', () async {
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
      expect(container.read(discoveryProvider).canShuffle, false);

      // Wait for cooldown to complete
      await Future.delayed(const Duration(milliseconds: 3500));

      // Should be able to shuffle again
      var state = container.read(discoveryProvider);
      expect(state.canShuffle, true);
      
      // Second shuffle should work without error
      await notifier.shuffleWithCooldown();
      state = container.read(discoveryProvider);
      expect(state.canShuffle, false);
      expect(state.cooldownSeconds, 3);
    });

    test('cooldown completion should transition from disabled to enabled state', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Track canShuffle state changes
      final canShuffleStates = <bool>[];
      container.listen(
        discoveryProvider,
        (previous, next) {
          if (previous?.canShuffle != next.canShuffle) {
            canShuffleStates.add(next.canShuffle);
          }
        },
      );

      // Start cooldown
      await notifier.shuffleWithCooldown();

      // Wait for completion
      await Future.delayed(const Duration(milliseconds: 3500));

      // Should have transitioned from false to true
      expect(canShuffleStates, contains(false));
      expect(canShuffleStates, contains(true));
      expect(canShuffleStates.last, true);
    });

    test('cooldown completion should set countdown to exactly zero', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Start cooldown
      await notifier.shuffleWithCooldown();

      // Wait for completion
      await Future.delayed(const Duration(milliseconds: 3500));

      // Countdown should be exactly 0, not negative
      final state = container.read(discoveryProvider);
      expect(state.cooldownSeconds, 0);
    });

    test('timer should stop updating after cooldown completion', () async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(mockRepository),
          viewedUsersServiceProvider.overrideWithValue(mockViewedUsersService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(discoveryProvider.notifier);
      notifier.setCurrentUserId('test-user-id');

      // Start cooldown
      await notifier.shuffleWithCooldown();

      // Wait for completion
      await Future.delayed(const Duration(milliseconds: 3500));

      // Get state after completion
      final stateAfterCompletion = container.read(discoveryProvider);
      expect(stateAfterCompletion.cooldownSeconds, 0);

      // Wait additional time
      await Future.delayed(const Duration(milliseconds: 2000));

      // State should remain at 0, not go negative
      final stateLater = container.read(discoveryProvider);
      expect(stateLater.cooldownSeconds, 0);
      expect(stateLater.canShuffle, true);
    });
  });
}
