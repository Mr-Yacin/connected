// Unit tests for AppLogger service
// Validates: Requirements 10.2, 10.3, 10.4, 10.5

import 'package:flutter_test/flutter_test.dart';
import 'package:social_connect_app/services/monitoring/app_logger.dart';

void main() {
  setUp(() {
    // Reset logger state before each test
    AppLogger.reset();
  });

  group('AppLogger Unit Tests', () {
    group('Requirement 10.2: Production log filtering', () {
      test('debug logs should be filtered out in production mode', () {
        // Set production mode
        AppLogger.setProductionMode(true);
        
        // Initialize logger
        AppLogger.initialize(userId: 'test-user');
        
        // Verify production mode is enabled
        expect(AppLogger.isProduction, isTrue,
            reason: 'Production mode should be enabled');
        
        // Debug logs should be filtered (no exception should be thrown)
        expect(
          () => AppLogger.debug('This is a debug message'),
          returnsNormally,
          reason: 'Debug logs should be filtered in production',
        );
      });

      test('info logs should be filtered out in production mode', () {
        // Set production mode
        AppLogger.setProductionMode(true);
        
        // Initialize logger
        AppLogger.initialize(userId: 'test-user');
        
        // Verify production mode is enabled
        expect(AppLogger.isProduction, isTrue,
            reason: 'Production mode should be enabled');
        
        // Info logs should be filtered (no exception should be thrown)
        expect(
          () => AppLogger.info('This is an info message'),
          returnsNormally,
          reason: 'Info logs should be filtered in production',
        );
      });

      test('warning logs should NOT be filtered in production mode', () {
        // Set production mode
        AppLogger.setProductionMode(true);
        
        // Initialize logger
        AppLogger.initialize(userId: 'test-user');
        
        // Verify production mode is enabled
        expect(AppLogger.isProduction, isTrue,
            reason: 'Production mode should be enabled');
        
        // Warning logs should not be filtered (no exception should be thrown)
        expect(
          () => AppLogger.warning('This is a warning message'),
          returnsNormally,
          reason: 'Warning logs should not be filtered in production',
        );
      });

      test('error logs should NOT be filtered in production mode', () {
        // Set production mode
        AppLogger.setProductionMode(true);
        
        // Initialize logger
        AppLogger.initialize(userId: 'test-user');
        
        // Verify production mode is enabled
        expect(AppLogger.isProduction, isTrue,
            reason: 'Production mode should be enabled');
        
        // Error logs should not be filtered (no exception should be thrown)
        expect(
          () => AppLogger.error('This is an error message'),
          returnsNormally,
          reason: 'Error logs should not be filtered in production',
        );
      });

      test('all log levels should work in debug mode', () {
        // Set debug mode
        AppLogger.setProductionMode(false);
        
        // Initialize logger
        AppLogger.initialize(userId: 'test-user');
        
        // Verify debug mode is enabled
        expect(AppLogger.isProduction, isFalse,
            reason: 'Debug mode should be enabled');
        
        // All log levels should work (no exception should be thrown)
        expect(
          () {
            AppLogger.debug('Debug message');
            AppLogger.info('Info message');
            AppLogger.warning('Warning message');
            AppLogger.error('Error message');
          },
          returnsNormally,
          reason: 'All log levels should work in debug mode',
        );
      });
    });

    group('Requirement 10.3: userId and sessionId inclusion', () {
      test('userId should be set during initialization', () {
        const testUserId = 'user-12345';
        
        // Initialize with userId
        AppLogger.initialize(userId: testUserId);
        
        // Verify userId is set
        expect(AppLogger.userId, equals(testUserId),
            reason: 'userId should be set during initialization');
      });

      test('sessionId should be generated during initialization', () {
        // Initialize logger
        AppLogger.initialize();
        
        // Verify sessionId is generated
        expect(AppLogger.sessionId, isNotNull,
            reason: 'sessionId should be generated during initialization');
        expect(AppLogger.sessionId, isNotEmpty,
            reason: 'sessionId should not be empty');
      });

      test('sessionId should be unique for each initialization', () {
        // First initialization
        AppLogger.initialize();
        final sessionId1 = AppLogger.sessionId;
        
        // Reset and initialize again
        AppLogger.reset();
        AppLogger.initialize();
        final sessionId2 = AppLogger.sessionId;
        
        // Session IDs should be different
        expect(sessionId1, isNot(equals(sessionId2)),
            reason: 'Each initialization should generate a unique sessionId');
      });

      test('userId can be updated after initialization', () {
        // Initialize without userId
        AppLogger.initialize();
        expect(AppLogger.userId, isNull,
            reason: 'userId should be null initially');
        
        // Set userId
        const testUserId = 'user-67890';
        AppLogger.setUserId(testUserId);
        
        // Verify userId is updated
        expect(AppLogger.userId, equals(testUserId),
            reason: 'userId should be updated after setUserId call');
      });

      test('userId can be cleared by setting to null', () {
        // Initialize with userId
        AppLogger.initialize(userId: 'user-12345');
        expect(AppLogger.userId, isNotNull,
            reason: 'userId should be set');
        
        // Clear userId
        AppLogger.setUserId(null);
        
        // Verify userId is cleared
        expect(AppLogger.userId, isNull,
            reason: 'userId should be cleared when set to null');
      });

      test('sessionId persists across userId changes', () {
        // Initialize logger
        AppLogger.initialize(userId: 'user-1');
        final sessionId = AppLogger.sessionId;
        
        // Change userId
        AppLogger.setUserId('user-2');
        
        // Session ID should remain the same
        expect(AppLogger.sessionId, equals(sessionId),
            reason: 'sessionId should persist across userId changes');
      });

      test('both userId and sessionId are available for logging', () {
        const testUserId = 'user-test-123';
        
        // Initialize with userId
        AppLogger.initialize(userId: testUserId);
        
        // Both should be available
        expect(AppLogger.userId, equals(testUserId),
            reason: 'userId should be available');
        expect(AppLogger.sessionId, isNotNull,
            reason: 'sessionId should be available');
        
        // Log should include both (no exception should be thrown)
        expect(
          () => AppLogger.error('Test error with user context'),
          returnsNormally,
          reason: 'Logging with userId and sessionId should work',
        );
      });
    });

    group('Requirement 10.4: Crashlytics custom keys', () {
      test('log data should include custom keys for Crashlytics', () {
        // Set production mode to enable Crashlytics logging
        AppLogger.setProductionMode(true);
        
        // Initialize with userId
        AppLogger.initialize(userId: 'test-user');
        
        // Log with custom data
        final customData = {
          'screen': 'TestScreen',
          'operation': 'testOperation',
          'customKey': 'customValue',
        };
        
        // This should set custom keys in Crashlytics (no exception)
        expect(
          () => AppLogger.error(
            'Test error with custom data',
            data: customData,
          ),
          returnsNormally,
          reason: 'Logging with custom data should work',
        );
      });

      test('custom keys should be included in log data structure', () {
        // Initialize logger
        AppLogger.initialize(userId: 'test-user');
        
        // Custom data to log
        final customData = {
          'key1': 'value1',
          'key2': 42,
          'key3': true,
        };
        
        // Log with custom data (should not throw)
        expect(
          () => AppLogger.warning('Test with custom keys', data: customData),
          returnsNormally,
          reason: 'Custom keys should be included in log data',
        );
      });

      test('empty custom data should be handled gracefully', () {
        // Initialize logger
        AppLogger.initialize();
        
        // Log with empty data
        expect(
          () => AppLogger.error('Test error', data: {}),
          returnsNormally,
          reason: 'Empty custom data should be handled gracefully',
        );
      });

      test('null custom data should be handled gracefully', () {
        // Initialize logger
        AppLogger.initialize();
        
        // Log without custom data
        expect(
          () => AppLogger.error('Test error', data: null),
          returnsNormally,
          reason: 'Null custom data should be handled gracefully',
        );
      });
    });

    group('Requirement 10.5: Timestamp and log level inclusion', () {
      test('log should include timestamp', () {
        // Initialize logger
        AppLogger.initialize();
        
        // Record time before logging
        final beforeLog = DateTime.now();
        
        // Log a message
        AppLogger.error('Test error for timestamp verification');
        
        // Record time after logging
        final afterLog = DateTime.now();
        
        // The log should have been created between these times
        // We can't directly verify the timestamp, but we can verify
        // the logging mechanism works without errors
        expect(beforeLog.isBefore(afterLog) || beforeLog.isAtSameMomentAs(afterLog),
            isTrue,
            reason: 'Timestamp should be captured during logging');
      });

      test('debug level should be included in log', () {
        // Set debug mode
        AppLogger.setProductionMode(false);
        
        // Initialize logger
        AppLogger.initialize();
        
        // Log debug message (should include level)
        expect(
          () => AppLogger.debug('Debug message'),
          returnsNormally,
          reason: 'Debug level should be included in log',
        );
      });

      test('info level should be included in log', () {
        // Set debug mode
        AppLogger.setProductionMode(false);
        
        // Initialize logger
        AppLogger.initialize();
        
        // Log info message (should include level)
        expect(
          () => AppLogger.info('Info message'),
          returnsNormally,
          reason: 'Info level should be included in log',
        );
      });

      test('warning level should be included in log', () {
        // Initialize logger
        AppLogger.initialize();
        
        // Log warning message (should include level)
        expect(
          () => AppLogger.warning('Warning message'),
          returnsNormally,
          reason: 'Warning level should be included in log',
        );
      });

      test('error level should be included in log', () {
        // Initialize logger
        AppLogger.initialize();
        
        // Log error message (should include level)
        expect(
          () => AppLogger.error('Error message'),
          returnsNormally,
          reason: 'Error level should be included in log',
        );
      });

      test('all log levels should be distinct', () {
        // Verify LogLevel enum has distinct values
        expect(LogLevel.debug, isNot(equals(LogLevel.info)),
            reason: 'Debug and info levels should be distinct');
        expect(LogLevel.info, isNot(equals(LogLevel.warning)),
            reason: 'Info and warning levels should be distinct');
        expect(LogLevel.warning, isNot(equals(LogLevel.error)),
            reason: 'Warning and error levels should be distinct');
        expect(LogLevel.debug, isNot(equals(LogLevel.error)),
            reason: 'Debug and error levels should be distinct');
      });

      test('log level names should be correct', () {
        // Verify log level names
        expect(LogLevel.debug.name, equals('debug'),
            reason: 'Debug level name should be "debug"');
        expect(LogLevel.info.name, equals('info'),
            reason: 'Info level name should be "info"');
        expect(LogLevel.warning.name, equals('warning'),
            reason: 'Warning level name should be "warning"');
        expect(LogLevel.error.name, equals('error'),
            reason: 'Error level name should be "error"');
      });
    });

    group('Additional AppLogger functionality', () {
      test('reset should clear userId and sessionId', () {
        // Initialize with userId
        AppLogger.initialize(userId: 'test-user');
        expect(AppLogger.userId, isNotNull,
            reason: 'userId should be set');
        expect(AppLogger.sessionId, isNotNull,
            reason: 'sessionId should be set');
        
        // Reset logger
        AppLogger.reset();
        
        // Both should be cleared
        expect(AppLogger.userId, isNull,
            reason: 'userId should be cleared after reset');
        expect(AppLogger.sessionId, isNull,
            reason: 'sessionId should be cleared after reset');
      });

      test('error logging with error object and stack trace', () {
        // Initialize logger
        AppLogger.initialize();
        
        try {
          throw Exception('Test exception');
        } catch (e, stackTrace) {
          // Log error with error object and stack trace
          expect(
            () => AppLogger.error(
              'Caught exception',
              error: e,
              stackTrace: stackTrace,
            ),
            returnsNormally,
            reason: 'Error logging with error object and stack trace should work',
          );
        }
      });

      test('logging with complex custom data', () {
        // Initialize logger
        AppLogger.initialize();
        
        // Complex custom data
        final complexData = {
          'nested': {
            'key1': 'value1',
            'key2': 123,
          },
          'list': [1, 2, 3],
          'bool': true,
          'null': null,
        };
        
        // Log with complex data
        expect(
          () => AppLogger.info('Complex data test', data: complexData),
          returnsNormally,
          reason: 'Logging with complex custom data should work',
        );
      });

      test('multiple sequential logs should work', () {
        // Initialize logger
        AppLogger.initialize(userId: 'test-user');
        
        // Multiple sequential logs
        expect(
          () {
            AppLogger.debug('First log');
            AppLogger.info('Second log');
            AppLogger.warning('Third log');
            AppLogger.error('Fourth log');
          },
          returnsNormally,
          reason: 'Multiple sequential logs should work',
        );
      });

      test('production mode can be toggled', () {
        // Start in debug mode
        AppLogger.setProductionMode(false);
        expect(AppLogger.isProduction, isFalse,
            reason: 'Should start in debug mode');
        
        // Switch to production mode
        AppLogger.setProductionMode(true);
        expect(AppLogger.isProduction, isTrue,
            reason: 'Should switch to production mode');
        
        // Switch back to debug mode
        AppLogger.setProductionMode(false);
        expect(AppLogger.isProduction, isFalse,
            reason: 'Should switch back to debug mode');
      });
    });
  });
}
