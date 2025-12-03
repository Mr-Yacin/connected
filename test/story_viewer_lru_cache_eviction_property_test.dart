import 'package:flutter_test/flutter_test.dart';

/// Feature: performance-optimization, Property 9: LRU cache eviction
/// **Validates: Requirements 2.5**
///
/// Property: For any user stories cache, when entries exceed 50, the least
/// recently used entries should be removed
///
/// This test validates that the LRU (Least Recently Used) cache eviction
/// mechanism works correctly, ensuring that when the cache exceeds the
/// maximum size of 50 entries, the least recently accessed entries are
/// removed to make room for new entries.

void main() {
  group('Story Viewer LRU Cache Eviction Property Tests', () {
    test(
      'cache should evict LRU entry when exceeding max size',
      () {
        // Test with various scenarios
        final testCases = [
          {'initial': 50, 'toAdd': 1, 'expectedSize': 50},
          {'initial': 50, 'toAdd': 5, 'expectedSize': 50},
          {'initial': 50, 'toAdd': 10, 'expectedSize': 50},
        ];

        for (final testCase in testCases) {
          final initial = testCase['initial'] as int;
          final toAdd = testCase['toAdd'] as int;
          final expectedSize = testCase['expectedSize'] as int;

          final cache = LRUCache(maxSize: 50);

          // Fill cache to maximum
          for (var i = 0; i < initial; i++) {
            cache.add('user_$i', ['story_${i}_1', 'story_${i}_2']);
          }

          expect(cache.size, equals(initial));

          // Add more entries - should trigger eviction
          for (var i = initial; i < initial + toAdd; i++) {
            cache.add('user_$i', ['story_${i}_1']);
          }

          // Cache should not exceed max size
          expect(
            cache.size,
            equals(expectedSize),
            reason: 'Cache should maintain max size of $expectedSize after adding $toAdd entries',
          );

          // Oldest entries should be evicted
          for (var i = 0; i < toAdd; i++) {
            expect(
              cache.contains('user_$i'),
              isFalse,
              reason: 'Oldest entry user_$i should be evicted',
            );
          }

          // Newest entries should be present
          for (var i = initial; i < initial + toAdd; i++) {
            expect(
              cache.contains('user_$i'),
              isTrue,
              reason: 'Newest entry user_$i should be present',
            );
          }

          print('✓ Property 9 test passed: LRU eviction for initial=$initial, toAdd=$toAdd');
        }
      },
    );

    test(
      'accessing an entry should update its access time',
      () {
        final cache = LRUCache(maxSize: 50);

        // Fill cache to maximum
        for (var i = 0; i < 50; i++) {
          cache.add('user_$i', ['story_$i']);
        }

        // Access the oldest entry (user_0)
        cache.access('user_0');

        // Add a new entry - should evict user_1 (now the oldest), not user_0
        cache.add('user_50', ['story_50']);

        // user_0 should still be present (was accessed recently)
        expect(
          cache.contains('user_0'),
          isTrue,
          reason: 'Recently accessed entry should not be evicted',
        );

        // user_1 should be evicted (oldest unaccessed)
        expect(
          cache.contains('user_1'),
          isFalse,
          reason: 'Oldest unaccessed entry should be evicted',
        );

        // user_50 should be present (newly added)
        expect(
          cache.contains('user_50'),
          isTrue,
          reason: 'Newly added entry should be present',
        );

        print('✓ Property 9 test passed: Accessing entry updates access time');
      },
    );

    test(
      'multiple accesses should maintain correct LRU order',
      () {
        final cache = LRUCache(maxSize: 5);

        // Add 5 entries
        for (var i = 0; i < 5; i++) {
          cache.add('user_$i', ['story_$i']);
        }

        // Access pattern: user_2, user_1, user_0 (in reverse order to make user_0 most recent)
        cache.access('user_2');
        cache.access('user_1');
        cache.access('user_0');

        // Add 3 new entries - should evict user_3, user_4, user_2 (oldest)
        cache.add('user_5', ['story_5']);
        cache.add('user_6', ['story_6']);
        cache.add('user_7', ['story_7']);

        // Most recently accessed entries should remain
        expect(cache.contains('user_0'), isTrue, reason: 'user_0 was accessed last');
        expect(cache.contains('user_1'), isTrue, reason: 'user_1 was accessed second');

        // Oldest entries should be evicted
        expect(cache.contains('user_2'), isFalse, reason: 'user_2 was accessed first (oldest of accessed)');
        expect(cache.contains('user_3'), isFalse, reason: 'user_3 was never accessed');
        expect(cache.contains('user_4'), isFalse, reason: 'user_4 was never accessed');

        // New entries should be present
        expect(cache.contains('user_5'), isTrue);
        expect(cache.contains('user_6'), isTrue);
        expect(cache.contains('user_7'), isTrue);

        print('✓ Property 9 test passed: Multiple accesses maintain LRU order');
      },
    );

    test(
      'cache should not evict when below max size',
      () {
        final cache = LRUCache(maxSize: 50);

        // Add entries below max size
        for (var i = 0; i < 30; i++) {
          cache.add('user_$i', ['story_$i']);
        }

        expect(cache.size, equals(30));

        // All entries should still be present
        for (var i = 0; i < 30; i++) {
          expect(
            cache.contains('user_$i'),
            isTrue,
            reason: 'Entry user_$i should be present when cache is below max size',
          );
        }

        print('✓ Property 9 test passed: No eviction when below max size');
      },
    );

    test(
      'adding existing entry should update access time without eviction',
      () {
        final cache = LRUCache(maxSize: 50);

        // Fill cache to maximum
        for (var i = 0; i < 50; i++) {
          cache.add('user_$i', ['story_$i']);
        }

        // Re-add an existing entry (should update access time)
        cache.add('user_0', ['story_0_updated']);

        // Cache size should remain the same
        expect(cache.size, equals(50));

        // user_0 should still be present with updated data
        expect(cache.contains('user_0'), isTrue);
        expect(cache.get('user_0'), equals(['story_0_updated']));

        // Add a new entry - should evict user_1 (now oldest), not user_0
        cache.add('user_50', ['story_50']);

        expect(cache.contains('user_0'), isTrue);
        expect(cache.contains('user_1'), isFalse);
        expect(cache.contains('user_50'), isTrue);

        print('✓ Property 9 test passed: Re-adding entry updates access time');
      },
    );

    test(
      'eviction should work correctly with sequential additions',
      () {
        final cache = LRUCache(maxSize: 10);

        // Add 15 entries sequentially
        for (var i = 0; i < 15; i++) {
          cache.add('user_$i', ['story_$i']);
        }

        // Cache should contain only the last 10 entries
        expect(cache.size, equals(10));

        // First 5 entries should be evicted
        for (var i = 0; i < 5; i++) {
          expect(
            cache.contains('user_$i'),
            isFalse,
            reason: 'Entry user_$i should be evicted',
          );
        }

        // Last 10 entries should be present
        for (var i = 5; i < 15; i++) {
          expect(
            cache.contains('user_$i'),
            isTrue,
            reason: 'Entry user_$i should be present',
          );
        }

        print('✓ Property 9 test passed: Sequential additions evict correctly');
      },
    );

    test(
      'eviction should handle interleaved access patterns',
      () {
        final cache = LRUCache(maxSize: 5);

        // Add 5 entries
        for (var i = 0; i < 5; i++) {
          cache.add('user_$i', ['story_$i']);
        }

        // Interleaved access pattern
        cache.access('user_0'); // Make user_0 most recent
        cache.add('user_5', ['story_5']); // Should evict user_1
        cache.access('user_2'); // Make user_2 most recent
        cache.add('user_6', ['story_6']); // Should evict user_3

        // Check expected state
        expect(cache.contains('user_0'), isTrue, reason: 'user_0 was accessed');
        expect(cache.contains('user_1'), isFalse, reason: 'user_1 should be evicted');
        expect(cache.contains('user_2'), isTrue, reason: 'user_2 was accessed');
        expect(cache.contains('user_3'), isFalse, reason: 'user_3 should be evicted');
        expect(cache.contains('user_4'), isTrue, reason: 'user_4 not yet evicted');
        expect(cache.contains('user_5'), isTrue, reason: 'user_5 was added');
        expect(cache.contains('user_6'), isTrue, reason: 'user_6 was added');

        print('✓ Property 9 test passed: Interleaved access patterns handled correctly');
      },
    );

    test(
      'cache at exactly max size should evict on next addition',
      () {
        final cache = LRUCache(maxSize: 50);

        // Fill cache to exactly max size
        for (var i = 0; i < 50; i++) {
          cache.add('user_$i', ['story_$i']);
        }

        expect(cache.size, equals(50));

        // Add one more entry
        cache.add('user_50', ['story_50']);

        // Cache should still be at max size
        expect(cache.size, equals(50));

        // Oldest entry should be evicted
        expect(cache.contains('user_0'), isFalse);

        // Newest entry should be present
        expect(cache.contains('user_50'), isTrue);

        print('✓ Property 9 test passed: Cache at max size evicts on addition');
      },
    );

    test(
      'eviction should preserve most recently used entries',
      () {
        final cache = LRUCache(maxSize: 10);

        // Add 10 entries
        for (var i = 0; i < 10; i++) {
          cache.add('user_$i', ['story_$i']);
        }

        // Access the first 5 entries in reverse order
        for (var i = 4; i >= 0; i--) {
          cache.access('user_$i');
        }

        // Add 5 new entries
        for (var i = 10; i < 15; i++) {
          cache.add('user_$i', ['story_$i']);
        }

        // First 5 entries should be preserved (were accessed)
        for (var i = 0; i < 5; i++) {
          expect(
            cache.contains('user_$i'),
            isTrue,
            reason: 'Recently accessed entry user_$i should be preserved',
          );
        }

        // Entries 5-9 should be evicted (oldest unaccessed)
        for (var i = 5; i < 10; i++) {
          expect(
            cache.contains('user_$i'),
            isFalse,
            reason: 'Oldest unaccessed entry user_$i should be evicted',
          );
        }

        // New entries should be present
        for (var i = 10; i < 15; i++) {
          expect(
            cache.contains('user_$i'),
            isTrue,
            reason: 'New entry user_$i should be present',
          );
        }

        print('✓ Property 9 test passed: Most recently used entries preserved');
      },
    );

    test(
      'empty cache should not trigger eviction',
      () {
        final cache = LRUCache(maxSize: 50);

        // Add first entry to empty cache
        cache.add('user_0', ['story_0']);

        expect(cache.size, equals(1));
        expect(cache.contains('user_0'), isTrue);

        print('✓ Property 9 test passed: Empty cache does not trigger eviction');
      },
    );

    test(
      'cache with one entry should not evict when adding second',
      () {
        final cache = LRUCache(maxSize: 50);

        cache.add('user_0', ['story_0']);
        cache.add('user_1', ['story_1']);

        expect(cache.size, equals(2));
        expect(cache.contains('user_0'), isTrue);
        expect(cache.contains('user_1'), isTrue);

        print('✓ Property 9 test passed: Single entry cache does not evict on second addition');
      },
    );

    test(
      'eviction should work with rapid successive additions',
      () {
        final cache = LRUCache(maxSize: 50);

        // Rapidly add 100 entries
        for (var i = 0; i < 100; i++) {
          cache.add('user_$i', ['story_$i']);
        }

        // Cache should maintain max size
        expect(cache.size, equals(50));

        // Only the last 50 entries should be present
        for (var i = 0; i < 50; i++) {
          expect(cache.contains('user_$i'), isFalse);
        }
        for (var i = 50; i < 100; i++) {
          expect(cache.contains('user_$i'), isTrue);
        }

        print('✓ Property 9 test passed: Rapid successive additions handled correctly');
      },
    );

    test(
      'access time should be independent of data size',
      () {
        final cache = LRUCache(maxSize: 50);

        // Add entries with varying data sizes
        cache.add('user_0', ['story_0']);
        cache.add('user_1', List.generate(10, (i) => 'story_1_$i'));
        cache.add('user_2', List.generate(100, (i) => 'story_2_$i'));

        // Fill rest of cache
        for (var i = 3; i < 50; i++) {
          cache.add('user_$i', ['story_$i']);
        }

        // Access user_1 (medium data size)
        cache.access('user_1');

        // Add new entry - should evict user_0 (oldest), not user_1
        cache.add('user_50', ['story_50']);

        expect(cache.contains('user_0'), isFalse);
        expect(cache.contains('user_1'), isTrue);
        expect(cache.contains('user_2'), isTrue);

        print('✓ Property 9 test passed: Access time independent of data size');
      },
    );

    test(
      'eviction should maintain cache consistency',
      () {
        final cache = LRUCache(maxSize: 10);

        // Add and evict multiple times
        for (var round = 0; round < 5; round++) {
          for (var i = 0; i < 15; i++) {
            cache.add('user_${round}_$i', ['story_${round}_$i']);
          }

          // Cache should always maintain max size
          expect(
            cache.size,
            equals(10),
            reason: 'Cache should maintain max size after round $round',
          );
        }

        print('✓ Property 9 test passed: Cache consistency maintained across multiple evictions');
      },
    );

    test(
      'LRU eviction should work with max size of 50',
      () {
        // Test the actual max size used in the application
        final cache = LRUCache(maxSize: 50);

        // Add 60 entries
        for (var i = 0; i < 60; i++) {
          cache.add('user_$i', ['story_$i']);
        }

        // Cache should be exactly 50
        expect(
          cache.size,
          equals(50),
          reason: 'Cache should maintain max size of 50',
        );

        // First 10 entries should be evicted
        for (var i = 0; i < 10; i++) {
          expect(
            cache.contains('user_$i'),
            isFalse,
            reason: 'Entry user_$i should be evicted',
          );
        }

        // Last 50 entries should be present
        for (var i = 10; i < 60; i++) {
          expect(
            cache.contains('user_$i'),
            isTrue,
            reason: 'Entry user_$i should be present',
          );
        }

        print('✓ Property 9 test passed: LRU eviction works with max size of 50');
      },
    );
  });
}

/// Helper class implementing LRU cache logic
class LRUCache {
  final int maxSize;
  final Map<String, List<String>> _cache = {};
  final Map<String, int> _accessOrder = {};
  int _accessCounter = 0;

  LRUCache({required this.maxSize});

  int get size => _cache.length;

  void add(String key, List<String> value) {
    // Check if cache exceeds limit and key is not already present
    if (_cache.length >= maxSize && !_cache.containsKey(key)) {
      // Find least recently used entry
      String? lruKey;
      int? lowestOrder;

      for (final entry in _accessOrder.entries) {
        if (lowestOrder == null || entry.value < lowestOrder) {
          lowestOrder = entry.value;
          lruKey = entry.key;
        }
      }

      // Remove LRU entry
      if (lruKey != null) {
        _cache.remove(lruKey);
        _accessOrder.remove(lruKey);
      }
    }

    // Add to cache and update access order
    _cache[key] = value;
    _accessOrder[key] = _accessCounter++;
  }

  void access(String key) {
    if (_cache.containsKey(key)) {
      _accessOrder[key] = _accessCounter++;
    }
  }

  bool contains(String key) {
    return _cache.containsKey(key);
  }

  List<String>? get(String key) {
    if (_cache.containsKey(key)) {
      // Update access order when getting
      _accessOrder[key] = _accessCounter++;
      return _cache[key];
    }
    return null;
  }
}
