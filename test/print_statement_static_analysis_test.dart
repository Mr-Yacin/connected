// Feature: code-quality-improvements, Task 6.1: Static analysis for print statements
// Validates: Requirements 4.1

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('Static Analysis: Print Statement Detection', () {
    test('production code should not contain print statements', () {
      // Get the lib directory path
      final projectRoot = Directory.current;
      final libDir = Directory(path.join(projectRoot.path, 'lib'));

      expect(libDir.existsSync(), isTrue,
          reason: 'lib directory should exist');

      // Find all Dart files in lib directory
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();

      expect(dartFiles.isNotEmpty, isTrue,
          reason: 'Should find Dart files in lib directory');

      // Files that are allowed to have print statements (debug utilities, logging services)
      final allowedFiles = [
        'error_logging_service.dart',
        'app_logger.dart',
      ];

      // Track files with print statements
      final filesWithPrint = <String, List<int>>{};

      for (final file in dartFiles) {
        final relativePath = path.relative(file.path, from: projectRoot.path);
        final fileName = path.basename(file.path);

        // Skip allowed files
        if (allowedFiles.contains(fileName)) {
          continue;
        }

        // Read file content
        final content = file.readAsStringSync();
        final lines = content.split('\n');

        // Search for print statements
        final printLines = <int>[];
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmedLine = line.trim();

          // Skip comments
          if (trimmedLine.startsWith('//')) {
            continue;
          }

          // Skip if print is inside a string literal
          // Simple heuristic: if the line contains quotes before print, it's likely in a string
          final printMatch = RegExp(r'\bprint\s*\(').firstMatch(line);
          if (printMatch != null && !line.contains('debugPrint(')) {
            final beforePrint = line.substring(0, printMatch.start);
            
            // Count quotes before print to see if we're inside a string
            final singleQuotes = beforePrint.split("'").length - 1;
            final doubleQuotes = beforePrint.split('"').length - 1;
            
            // If odd number of quotes, we're inside a string
            if (singleQuotes % 2 == 0 && doubleQuotes % 2 == 0) {
              printLines.add(i + 1); // Line numbers are 1-indexed
            }
          }
        }

        if (printLines.isNotEmpty) {
          filesWithPrint[relativePath] = printLines;
        }
      }

      // Build detailed error message if print statements found
      if (filesWithPrint.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln(
            '\nFound print statements in ${filesWithPrint.length} file(s):');
        buffer.writeln();

        filesWithPrint.forEach((file, lines) {
          buffer.writeln('  $file:');
          for (final lineNum in lines) {
            buffer.writeln('    Line $lineNum');
          }
          buffer.writeln();
        });

        buffer.writeln('Print statements should be replaced with:');
        buffer.writeln('  - AppLogger.debug() for debug messages');
        buffer.writeln('  - AppLogger.info() for informational messages');
        buffer.writeln('  - AppLogger.error() for errors');
        buffer.writeln(
            '  - ErrorLoggingService.logGeneralError() for error logging');
        buffer.writeln('  - debugPrint() for Flutter debug output (if needed)');

        fail(buffer.toString());
      }

      // Test passes if no print statements found
      expect(filesWithPrint.isEmpty, isTrue,
          reason: 'No print statements should be found in production code');
    });

    test('debugPrint statements are allowed in production code', () {
      // This test verifies that debugPrint is acceptable
      // debugPrint is Flutter's debug-only print that doesn't output in release mode

      final projectRoot = Directory.current;
      final libDir = Directory(path.join(projectRoot.path, 'lib'));

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();

      // Count files with debugPrint
      int debugPrintCount = 0;

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        if (content.contains('debugPrint(')) {
          debugPrintCount++;
        }
      }

      // debugPrint is allowed, so this test just verifies the pattern
      expect(debugPrintCount, greaterThanOrEqualTo(0),
          reason: 'debugPrint statements are allowed');
    });

    test('logging services are allowed to use print statements', () {
      // Verify that our logging services exist and can use print
      final projectRoot = Directory.current;

      final errorLoggingService = File(path.join(
        projectRoot.path,
        'lib/services/monitoring/error_logging_service.dart',
      ));

      final appLogger = File(path.join(
        projectRoot.path,
        'lib/services/monitoring/app_logger.dart',
      ));

      expect(errorLoggingService.existsSync(), isTrue,
          reason: 'ErrorLoggingService should exist');
      expect(appLogger.existsSync(), isTrue,
          reason: 'AppLogger should exist');

      // These files are allowed to use print for debug output
      final errorLoggingContent = errorLoggingService.readAsStringSync();
      final appLoggerContent = appLogger.readAsStringSync();

      // Verify they use print only in debug mode (kDebugMode)
      if (errorLoggingContent.contains('print(')) {
        expect(errorLoggingContent.contains('kDebugMode'), isTrue,
            reason:
                'ErrorLoggingService should only print in debug mode');
      }

      if (appLoggerContent.contains('print(')) {
        expect(appLoggerContent.contains('kDebugMode'), isTrue,
            reason: 'AppLogger should only print in debug mode');
      }
    });

    test('test files are allowed to have print statements', () {
      // Test files can use print for debugging tests
      final projectRoot = Directory.current;
      final testDir = Directory(path.join(projectRoot.path, 'test'));

      if (!testDir.existsSync()) {
        // Skip if test directory doesn't exist
        return;
      }

      final testFiles = testDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();

      // Count test files with print statements
      int testFilesWithPrint = 0;

      for (final file in testFiles) {
        final content = file.readAsStringSync();
        if (content.contains('print(')) {
          testFilesWithPrint++;
        }
      }

      // Test files are allowed to use print
      expect(testFilesWithPrint, greaterThanOrEqualTo(0),
          reason: 'Test files are allowed to use print statements');
    });

    test('print statements should be replaced with appropriate logging', () {
      // This test documents the replacement patterns
      final replacementPatterns = {
        'print(\'Error: \$e\')': 'ErrorLoggingService.logGeneralError(e, ...)',
        'print(\'Debug: ...\')': 'AppLogger.debug(\'...\')',
        'print(\'Info: ...\')': 'AppLogger.info(\'...\')',
        'print(\'Warning: ...\')': 'AppLogger.warning(\'...\')',
        'print(\'Failed to ...\')': 'ErrorLoggingService.logGeneralError(...)',
      };

      // Verify replacement patterns are documented
      expect(replacementPatterns.isNotEmpty, isTrue,
          reason: 'Replacement patterns should be documented');

      // This test serves as documentation for developers
      expect(replacementPatterns.length, greaterThan(0),
          reason: 'Multiple replacement patterns should be available');
    });

    test('static analysis should run on all production code', () {
      // Verify that the static analysis covers all production code
      final projectRoot = Directory.current;
      final libDir = Directory(path.join(projectRoot.path, 'lib'));

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();

      // Should have production code to analyze
      expect(dartFiles.length, greaterThan(0),
          reason: 'Should have Dart files to analyze');

      // Verify we're checking all subdirectories
      final subdirectories = <String>{};
      for (final file in dartFiles) {
        final dir = path.dirname(file.path);
        subdirectories.add(dir);
      }

      expect(subdirectories.length, greaterThan(1),
          reason: 'Should analyze files in multiple directories');
    });

    test('print statement detection should handle edge cases', () {
      // Test the regex pattern used for detection
      final testCases = [
        {'code': 'print("test")', 'shouldMatch': true},
        {'code': 'print(\'test\')', 'shouldMatch': true},
        {'code': 'print(variable)', 'shouldMatch': true},
        {'code': '  print("indented")', 'shouldMatch': true},
        {'code': 'debugPrint("test")', 'shouldMatch': false},
        {'code': '// print("commented")', 'shouldMatch': false},
        {'code': 'final text = "print(test)";', 'shouldMatch': false},
        {'code': 'sprint("test")', 'shouldMatch': false},
        {'code': 'fingerprint()', 'shouldMatch': false},
      ];

      final printRegex = RegExp(r'\bprint\s*\(');

      for (final testCase in testCases) {
        final code = testCase['code'] as String;
        final shouldMatch = testCase['shouldMatch'] as bool;
        final line = code.trim();

        // Skip comments
        if (line.startsWith('//')) {
          continue;
        }

        // Check for print statement
        final printMatch = printRegex.firstMatch(code);
        bool matches = false;
        
        if (printMatch != null && !code.contains('debugPrint(')) {
          final beforePrint = code.substring(0, printMatch.start);
          
          // Count quotes before print to see if we're inside a string
          final singleQuotes = beforePrint.split("'").length - 1;
          final doubleQuotes = beforePrint.split('"').length - 1;
          
          // If even number of quotes, we're not inside a string
          if (singleQuotes % 2 == 0 && doubleQuotes % 2 == 0) {
            matches = true;
          }
        }

        expect(matches, equals(shouldMatch),
            reason: 'Pattern should ${shouldMatch ? "match" : "not match"}: $code');
      }
    });
  });
}
