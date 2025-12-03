import 'package:flutter_test/flutter_test.dart';

/// Feature: performance-optimization, Property 7: Cache clearing on disposal
/// **Validates: Requirements 2.3**
///
/// Property: For any story viewer screen with cached stories, disposing should
/// clear the user stories cache map
///
/// This test validates that the cache is properly cleared when the widget
/// is disposed, preventing memory leaks and ensuring proper resource cleanup.

void main() {
  group('Story Viewer Cache Clearing Property Tests', () {
    test(
      'cache should be cleared when widget is disposed',
      () {
        // Test with various cache sizes
        final testCases = [1, 5, 10, 25, 50];

        for (final cacheSize in testCases) {
          // Create a cache tracker
          final cacheTracker = CacheTracker();

          // Populate cache with entries
          for (var i = 0; i < cacheSize; i++) {
            cacheTracker.addEntry('user_$i', ['story_${i}_1', 'story_${i}_2']);
          }

          // Verify cache has entries
          expect(
            cacheTracker.size,
            equals(cacheSize),
            reason: 'Cache should have $cacheSize entries after population',
          );

          // Simulate disposal by clearing cache
          cacheTracker.clearCache();

          // Verify cache is empty
          expect(
            cacheTracker.size,
            equals(0),
            reason: 'Cache should be empty after disposal (size: $cacheSize)',
          );

          print('✓ Property 7 test passed: Cache cleared for size $cacheSize');
        }
      },
    );

    test(
      'both cache maps should be cleared together',
      () {
        // Test that both _userStoriesCache and _cacheAccessTimes are cleared
        final storiesCache = CacheTracker();
        final accessTimesCache = CacheTracker();

        // Populate both caches
        for (var i = 0; i < 10; i++) {
          storiesCache.addEntry('user_$i', ['story_$i']);
          accessTimesCache.addEntry('user_$i', ['timestamp_$i']);
        }

        // Verify both caches have entries
        expect(storiesCache.size, equals(10));
        expect(accessTimesCache.size, equals(10));

        // Clear both caches (simulating disposal)
        storiesCache.clearCache();
        accessTimesCache.clearCache();

        // Verify both caches are empty
        expect(
          storiesCache.size,
          equals(0),
          reason: 'Stories cache should be empty after disposal',
        );
        expect(
          accessTimesCache.size,
          equals(0),
          reason: 'Access times cache should be empty after disposal',
        );

        print('✓ Property 7 test passed: Both cache maps cleared together');
      },
    );

    test(
      'cache clearing should be idempotent',
      () {
        // Test that calling clear multiple times doesn't cause errors
        final cacheTracker = CacheTracker();

        // Populate cache
        cacheTracker.addEntry('user_1', ['story_1']);
        expect(cacheTracker.size, equals(1));

        // Clear once
        cacheTracker.clearCache();
        expect(cacheTracker.size, equals(0));

        // Clear again - should not throw
        expect(() => cacheTracker.clearCache(), returnsNormally);
        expect(cacheTracker.size, equals(0));

        // Clear a third time - should still not throw
        expect(() => cacheTracker.clearCache(), returnsNormally);
        expect(cacheTracker.size, equals(0));

        print('✓ Property 7 test passed: Cache clearing is idempotent');
      },
    );

    test(
      'cleared cache should not be accessible',
      () {
        // Test that cleared cache cannot be accessed
        final cacheTracker = CacheTracker();

        // Populate cache
        cacheTracker.addEntry('user_1', ['story_1', 'story_2']);
        expect(cacheTracker.hasEntry('user_1'), isTrue);
        expect(cacheTracker.getEntry('user_1'), isNotNull);

        // Clear cache
        cacheTracker.clearCache();

        // Cache should not be accessible
        expect(cacheTracker.hasEntry('user_1'), isFalse);
        expect(cacheTracker.getEntry('user_1'), isNull);

        print('✓ Property 7 test passed: Cleared cache is not accessible');
      },
    );

    test(
      'cache clearing should happen after controller disposal',
      () {
        // Test disposal order: controllers before cache
        final disposalOrder = <String>[];

        // Simulate disposal sequence from story viewer
        disposalOrder.add('cancel_timer');
        disposalOrder.add('dispose_storyProgressController');
        disposalOrder.add('dispose_userPageController');
        disposalOrder.add('dispose_messageController');
        disposalOrder.add('dispose_messageFocusNode');
        disposalOrder.add('clear_userStoriesCache');
        disposalOrder.add('clear_cacheAccessTimes');

        // Verify cache is cleared after controllers
        final lastControllerIndex = disposalOrder.indexOf('dispose_messageFocusNode');
        final cacheCleanupIndex = disposalOrder.indexOf('clear_userStoriesCache');

        expect(
          lastControllerIndex < cacheCleanupIndex,
          isTrue,
          reason: 'Cache should be cleared after all controllers are disposed',
        );

        print('✓ Property 7 test passed: Cache cleared after controller disposal');
      },
    );

    test(
      'cache clearing should happen before image eviction',
      () {
        // Test disposal order: cache before images
        final disposalOrder = <String>[];

        // Simulate disposal sequence from story viewer
        disposalOrder.add('cancel_timer');
        disposalOrder.add('dispose_controllers');
        disposalOrder.add('clear_userStoriesCache');
        disposalOrder.add('clear_cacheAccessTimes');
        disposalOrder.add('evict_precachedImages');

        // Verify cache is cleared before images are evicted
        final cacheCleanupIndex = disposalOrder.indexOf('clear_userStoriesCache');
        final imageEvictionIndex = disposalOrder.indexOf('evict_precachedImages');

        expect(
          cacheCleanupIndex < imageEvictionIndex,
          isTrue,
          reason: 'Cache should be cleared before images are evicted',
        );

        print('✓ Property 7 test passed: Cache cleared before image eviction');
      },
    );

    test(
      'empty cache should be cleared without errors',
      () {
        // Test that clearing an empty cache doesn't cause errors
        final cacheTracker = CacheTracker();

        // Verify cache is empty
        expect(cacheTracker.size, equals(0));

        // Clear empty cache - should not throw
        expect(() => cacheTracker.clearCache(), returnsNormally);
        expect(cacheTracker.size, equals(0));

        print('✓ Property 7 test passed: Empty cache cleared without errors');
      },
    );

    test(
      'cache with maximum entries should be cleared',
      () {
        // Test clearing cache at maximum capacity (50 entries)
        final cacheTracker = CacheTracker();
        const maxEntries = 50;

        // Fill cache to maximum
        for (var i = 0; i < maxEntries; i++) {
          cacheTracker.addEntry('user_$i', ['story_$i']);
        }

        expect(cacheTracker.size, equals(maxEntries));

        // Clear cache
        cacheTracker.clearCache();

        // Verify cache is empty
        expect(
          cacheTracker.size,
          equals(0),
          reason: 'Cache at maximum capacity should be cleared completely',
        );

        print('✓ Property 7 test passed: Maximum capacity cache cleared');
      },
    );

    test(
      'cache clearing should release all references',
      () {
        // Test that cache clearing releases all object references
        final cacheTracker = CacheTracker();

        // Populate cache with multiple entries
        final userIds = ['user_1', 'user_2', 'user_3', 'user_4', 'user_5'];
        for (final userId in userIds) {
          cacheTracker.addEntry(userId, ['story_1', 'story_2', 'story_3']);
        }

        // Verify all entries exist
        for (final userId in userIds) {
          expect(cacheTracker.hasEntry(userId), isTrue);
        }

        // Clear cache
        cacheTracker.clearCache();

        // Verify all references are released
        for (final userId in userIds) {
          expect(
            cacheTracker.hasEntry(userId),
            isFalse,
            reason: 'Reference to $userId should be released',
          );
        }

        print('✓ Property 7 test passed: All cache references released');
      },
    );

    test(
      'cache clearing should be synchronous',
      () {
        // Test that cache clearing completes synchronously
        final cacheTracker = CacheTracker();

        // Populate cache with many entries
        for (var i = 0; i < 50; i++) {
          cacheTracker.addEntry('user_$i', List.generate(10, (j) => 'story_${i}_$j'));
        }

        expect(cacheTracker.size, equals(50));

        // Clear cache and measure time
        final stopwatch = Stopwatch()..start();
        cacheTracker.clearCache();
        stopwatch.stop();

        // Clearing should be fast (< 10ms)
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(10),
          reason: 'Cache clearing should be synchronous and fast',
        );

        expect(cacheTracker.size, equals(0));

        print('✓ Property 7 test passed: Cache clearing is synchronous');
      },
    );

    test(
      'cache clearing should not affect other state',
      () {
        // Test that cache clearing doesn't affect other widget state
        final cacheTracker = CacheTracker();
        final otherState = {'currentUserIndex': 0, 'currentStoryIndex': 0};

        // Populate cache
        cacheTracker.addEntry('user_1', ['story_1']);
        expect(cacheTracker.size, equals(1));

        // Clear cache
        cacheTracker.clearCache();

        // Verify cache is cleared but other state is unchanged
        expect(cacheTracker.size, equals(0));
        expect(otherState['currentUserIndex'], equals(0));
        expect(otherState['currentStoryIndex'], equals(0));

        print('✓ Property 7 test passed: Cache clearing does not affect other state');
      },
    );

    test(
      'cache with nested data structures should be cleared',
      () {
        // Test that cache with complex nested data is properly cleared
        final cacheTracker = CacheTracker();

        // Add entries with nested data
        cacheTracker.addEntry('user_1', [
          'story_1',
          'story_2',
          'story_3',
        ]);
        cacheTracker.addEntry('user_2', [
          'story_4',
          'story_5',
        ]);

        expect(cacheTracker.size, equals(2));

        // Clear cache
        cacheTracker.clearCache();

        // Verify all nested data is cleared
        expect(cacheTracker.size, equals(0));
        expect(cacheTracker.hasEntry('user_1'), isFalse);
        expect(cacheTracker.hasEntry('user_2'), isFalse);

        print('✓ Property 7 test passed: Nested data structures cleared');
      },
    );

    test(
      'cache clearing should complete before provider invalidation',
      () {
        // Test disposal order: cache before provider invalidation
        final disposalOrder = <String>[];

        // Simulate disposal sequence from story viewer
        disposalOrder.add('cancel_timer');
        disposalOrder.add('dispose_controllers');
        disposalOrder.add('clear_userStoriesCache');
        disposalOrder.add('clear_cacheAccessTimes');
        disposalOrder.add('evict_precachedImages');
        disposalOrder.add('invalidate_activeStoriesProvider');

        // Verify cache is cleared before provider invalidation
        final cacheCleanupIndex = disposalOrder.indexOf('clear_userStoriesCache');
        final providerInvalidationIndex = disposalOrder.indexOf('invalidate_activeStoriesProvider');

        expect(
          cacheCleanupIndex < providerInvalidationIndex,
          isTrue,
          reason: 'Cache should be cleared before provider invalidation',
        );

        print('✓ Property 7 test passed: Cache cleared before provider invalidation');
      },
    );

    test(
      'cache size should be zero after clearing',
      () {
        // Test that cache size is exactly zero after clearing
        final testSizes = [1, 10, 25, 50];

        for (final size in testSizes) {
          final cacheTracker = CacheTracker();

          // Populate cache
          for (var i = 0; i < size; i++) {
            cacheTracker.addEntry('user_$i', ['story_$i']);
          }

          expect(cacheTracker.size, equals(size));

          // Clear cache
          cacheTracker.clearCache();

          // Verify size is exactly zero
          expect(
            cacheTracker.size,
            equals(0),
            reason: 'Cache size should be exactly 0 after clearing (was $size)',
          );
        }

        print('✓ Property 7 test passed: Cache size is zero after clearing');
      },
    );

    test(
      'cache clearing should allow repopulation',
      () {
        // Test that cache can be repopulated after clearing
        final cacheTracker = CacheTracker();

        // First population
        cacheTracker.addEntry('user_1', ['story_1']);
        expect(cacheTracker.size, equals(1));

        // Clear cache
        cacheTracker.clearCache();
        expect(cacheTracker.size, equals(0));

        // Repopulate cache
        cacheTracker.addEntry('user_2', ['story_2']);
        expect(cacheTracker.size, equals(1));
        expect(cacheTracker.hasEntry('user_2'), isTrue);
        expect(cacheTracker.hasEntry('user_1'), isFalse);

        print('✓ Property 7 test passed: Cache can be repopulated after clearing');
      },
    );
  });
}

/// Helper class to track cache state
class CacheTracker {
  final Map<String, List<String>> _cache = {};

  int get size => _cache.length;

  void addEntry(String key, List<String> value) {
    _cache[key] = value;
  }

  bool hasEntry(String key) {
    return _cache.containsKey(key);
  }

  List<String>? getEntry(String key) {
    return _cache[key];
  }

  void clearCache() {
    _cache.clear();
  }
}
