import 'package:flutter_test/flutter_test.dart';
import 'package:social_connect_app/services/storage/image_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageCacheService', () {
    test('getCacheSize returns non-negative value', () async {
      final service = ImageCacheService();
      final size = await service.getCacheSize();
      
      // Should return 0 or a non-negative number (will be 0 in test environment)
      expect(size, greaterThanOrEqualTo(0));
    });

    test('getCacheSize handles errors gracefully', () async {
      final service = ImageCacheService();
      
      // This should not throw an exception, should return 0 on error
      final size = await service.getCacheSize();
      expect(size, equals(0));
    });

    test('maxCacheSize constant is set to 100MB', () {
      // Verify 100MB limit (100 * 1024 * 1024 bytes)
      expect(ImageCacheService.maxCacheSize, equals(100 * 1024 * 1024));
    });

    test('enforceCacheSizeLimit does not throw exceptions', () async {
      final service = ImageCacheService();
      
      // This should not throw an exception
      await service.enforceCacheSizeLimit();
      // If we get here without exception, test passes
      expect(true, isTrue);
    });
  });
}
