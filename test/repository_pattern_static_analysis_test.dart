// Feature: code-quality-improvements, Task 13.1: Static analysis for repository patterns
// Validates: Requirements 3.1, 5.1, 5.3

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('Static Analysis: Repository Pattern Compliance', () {
    test('all Firestore repositories should extend BaseFirestoreRepository', () {
      // Get the lib directory path
      final projectRoot = Directory.current;
      final libDir = Directory(path.join(projectRoot.path, 'lib'));

      expect(libDir.existsSync(), isTrue,
          reason: 'lib directory should exist');

      // Find all repository implementation files (Firestore repositories)
      final repositoryFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) =>
              file.path.endsWith('.dart') &&
              file.path.contains('repositories') &&
              file.path.contains('firestore_') &&
              !file.path.contains('base_firestore_repository.dart'))
          .toList();

      expect(repositoryFiles.isNotEmpty, isTrue,
          reason: 'Should find Firestore repository files');

      // Track repositories that don't extend BaseFirestoreRepository
      final nonCompliantRepos = <String>[];

      for (final file in repositoryFiles) {
        final relativePath = path.relative(file.path, from: projectRoot.path);
        final content = file.readAsStringSync();

        // Check if the file contains a class definition
        final classMatch = RegExp(r'class\s+(\w+)\s+').firstMatch(content);
        if (classMatch == null) continue;

        final className = classMatch.group(1)!;

        // Check if it extends BaseFirestoreRepository
        final extendsBase = content.contains('extends BaseFirestoreRepository');

        if (!extendsBase) {
          nonCompliantRepos.add('$relativePath (class: $className)');
        }
      }

      // Build detailed error message if non-compliant repositories found
      if (nonCompliantRepos.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln(
            '\nFound ${nonCompliantRepos.length} Firestore repository(ies) that do not extend BaseFirestoreRepository:');
        buffer.writeln();

        for (final repo in nonCompliantRepos) {
          buffer.writeln('  - $repo');
        }

        buffer.writeln();
        buffer.writeln('All Firestore repositories must extend BaseFirestoreRepository to ensure:');
        buffer.writeln('  - Consistent error handling');
        buffer.writeln('  - Standardized logging');
        buffer.writeln('  - Arabic error messages');
        buffer.writeln('  - Proper exception wrapping');

        fail(buffer.toString());
      }

      // Test passes if all repositories extend BaseFirestoreRepository
      expect(nonCompliantRepos.isEmpty, isTrue,
          reason: 'All Firestore repositories should extend BaseFirestoreRepository');
    });

    test('all repositories should have corresponding interfaces', () {
      final projectRoot = Directory.current;
      final libDir = Directory(path.join(projectRoot.path, 'lib'));

      // Find all repository implementation files
      final implementationFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) =>
              file.path.endsWith('.dart') &&
              file.path.contains(path.join('data', 'repositories')) &&
              !file.path.contains('base_firestore_repository.dart'))
          .toList();

      expect(implementationFiles.isNotEmpty, isTrue,
          reason: 'Should find repository implementation files');

      // Track repositories without interfaces
      final reposWithoutInterfaces = <String>[];

      for (final file in implementationFiles) {
        final relativePath = path.relative(file.path, from: projectRoot.path);
        final content = file.readAsStringSync();

        // Extract class name
        final classMatch = RegExp(r'class\s+(\w+)\s+').firstMatch(content);
        if (classMatch == null) continue;

        final className = classMatch.group(1)!;

        // Check if it implements an interface
        final implementsInterface = content.contains('implements');

        if (!implementsInterface) {
          reposWithoutInterfaces.add('$relativePath (class: $className)');
        }
      }

      // Build detailed error message if repositories without interfaces found
      if (reposWithoutInterfaces.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln(
            '\nFound ${reposWithoutInterfaces.length} repository(ies) without interfaces:');
        buffer.writeln();

        for (final repo in reposWithoutInterfaces) {
          buffer.writeln('  - $repo');
        }

        buffer.writeln();
        buffer.writeln('All repositories must have corresponding interfaces to enable:');
        buffer.writeln('  - Dependency injection');
        buffer.writeln('  - Easy mocking for tests');
        buffer.writeln('  - Loose coupling');
        buffer.writeln('  - Multiple implementations');

        fail(buffer.toString());
      }

      // Test passes if all repositories have interfaces
      expect(reposWithoutInterfaces.isEmpty, isTrue,
          reason: 'All repositories should have corresponding interfaces');
    });

    test('repository interfaces should exist in domain layer', () {
      final projectRoot = Directory.current;
      final libDir = Directory(path.join(projectRoot.path, 'lib'));

      // Find all repository implementation files
      final implementationFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) =>
              file.path.endsWith('.dart') &&
              file.path.contains(path.join('data', 'repositories')) &&
              !file.path.contains('base_firestore_repository.dart'))
          .toList();

      // Track missing interface files
      final missingInterfaces = <String>[];

      for (final file in implementationFiles) {
        final relativePath = path.relative(file.path, from: projectRoot.path);
        final content = file.readAsStringSync();

        // Extract class name and interface name
        final classMatch = RegExp(r'class\s+(\w+)\s+').firstMatch(content);
        if (classMatch == null) continue;

        final className = classMatch.group(1)!;

        // Extract interface name from implements clause
        final implementsMatch =
            RegExp(r'implements\s+(\w+)').firstMatch(content);
        if (implementsMatch == null) continue;

        final interfaceName = implementsMatch.group(1)!;

        // Construct expected interface file path
        // Convert from data/repositories to domain/repositories
        var expectedInterfacePath = file.path.replaceAll(
          path.join('data', 'repositories'),
          path.join('domain', 'repositories'),
        );
        
        // Remove firestore_ or firebase_ prefix from filename
        final fileName = path.basename(expectedInterfacePath);
        final dirName = path.dirname(expectedInterfacePath);
        final cleanFileName = fileName
            .replaceFirst('firestore_', '')
            .replaceFirst('firebase_', '');
        expectedInterfacePath = path.join(dirName, cleanFileName);

        final interfaceFile = File(expectedInterfacePath);

        if (!interfaceFile.existsSync()) {
          missingInterfaces.add(
              '$relativePath (class: $className, interface: $interfaceName, expected: ${path.relative(expectedInterfacePath, from: projectRoot.path)})');
        }
      }

      // Build detailed error message if missing interfaces found
      if (missingInterfaces.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln(
            '\nFound ${missingInterfaces.length} repository(ies) with missing interface files:');
        buffer.writeln();

        for (final missing in missingInterfaces) {
          buffer.writeln('  - $missing');
        }

        buffer.writeln();
        buffer.writeln('Repository interfaces should be placed in the domain layer:');
        buffer.writeln('  - Implementation: lib/features/*/data/repositories/');
        buffer.writeln('  - Interface: lib/features/*/domain/repositories/');

        fail(buffer.toString());
      }

      // Test passes if all interface files exist
      expect(missingInterfaces.isEmpty, isTrue,
          reason: 'All repository interfaces should exist in domain layer');
    });

    test('providers should use interface types, not concrete implementations',
        () {
      final projectRoot = Directory.current;
      final libDir = Directory(path.join(projectRoot.path, 'lib'));

      // Find all provider files
      final providerFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) =>
              file.path.endsWith('_provider.dart') &&
              file.path.contains('presentation'))
          .toList();

      expect(providerFiles.isNotEmpty, isTrue,
          reason: 'Should find provider files');

      // Track providers using concrete repository types
      final providersWithConcreteTypes = <String>[];

      for (final file in providerFiles) {
        final relativePath = path.relative(file.path, from: projectRoot.path);
        final content = file.readAsStringSync();

        // Look for repository provider definitions
        final providerMatches = RegExp(
          r'Provider<(\w+)>\s*\(\s*\(ref\)\s*\{[^}]*return\s+(\w+)\(',
          multiLine: true,
        ).allMatches(content);

        for (final match in providerMatches) {
          final returnType = match.group(1)!;
          final concreteClass = match.group(2)!;

          // Check if provider returns concrete Firestore implementation
          // but declares interface type
          if (concreteClass.startsWith('Firestore') &&
              concreteClass.contains('Repository')) {
            // This is good - using concrete implementation
            // Now check if the type is also concrete (bad) or interface (good)
            if (returnType.startsWith('Firestore')) {
              providersWithConcreteTypes.add(
                  '$relativePath: Provider<$returnType> should use interface type instead');
            }
          }
        }
      }

      // Build detailed error message if providers with concrete types found
      if (providersWithConcreteTypes.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln(
            '\nFound ${providersWithConcreteTypes.length} provider(s) using concrete repository types:');
        buffer.writeln();

        for (final provider in providersWithConcreteTypes) {
          buffer.writeln('  - $provider');
        }

        buffer.writeln();
        buffer.writeln('Providers should use interface types for repositories:');
        buffer.writeln('  - BAD:  Provider<FirestoreStoryRepository>');
        buffer.writeln('  - GOOD: Provider<StoryRepository>');
        buffer.writeln();
        buffer.writeln('This enables:');
        buffer.writeln('  - Easy mocking in tests');
        buffer.writeln('  - Dependency injection');
        buffer.writeln('  - Swapping implementations');

        fail(buffer.toString());
      }

      // Test passes if all providers use interface types
      expect(providersWithConcreteTypes.isEmpty, isTrue,
          reason: 'Providers should use interface types for repositories');
    });

    test('repository implementations should use handleFirestoreOperation', () {
      final projectRoot = Directory.current;
      final libDir = Directory(path.join(projectRoot.path, 'lib'));

      // Find all Firestore repository implementation files
      final repositoryFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) =>
              file.path.endsWith('.dart') &&
              file.path.contains('repositories') &&
              file.path.contains('firestore_') &&
              !file.path.contains('base_firestore_repository.dart'))
          .toList();

      // Track repositories not using handleFirestoreOperation
      final reposNotUsingHelper = <String>[];

      for (final file in repositoryFiles) {
        final relativePath = path.relative(file.path, from: projectRoot.path);
        final content = file.readAsStringSync();

        // Check if repository extends BaseFirestoreRepository
        if (!content.contains('extends BaseFirestoreRepository')) {
          continue; // Skip if not extending base (will be caught by other test)
        }

        // Count method definitions (excluding constructors and getters)
        final methodMatches = RegExp(
          r'@override\s+(?:Future<[^>]+>|Stream<[^>]+>)\s+\w+\s*\(',
          multiLine: true,
        ).allMatches(content);

        final methodCount = methodMatches.length;

        // Count usage of handleFirestoreOperation or handleFirestoreVoidOperation
        final handleOperationCount = RegExp(
          r'handleFirestore(?:Void)?Operation\s*\(',
          multiLine: true,
        ).allMatches(content).length;

        // If there are methods but no usage of helper methods, flag it
        // Allow some methods to not use helpers (like streams with try-catch)
        if (methodCount > 0 && handleOperationCount == 0) {
          reposNotUsingHelper.add(
              '$relativePath (methods: $methodCount, using helpers: $handleOperationCount)');
        }
      }

      // Build detailed error message if repositories not using helpers found
      if (reposNotUsingHelper.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln(
            '\nFound ${reposNotUsingHelper.length} repository(ies) not using handleFirestoreOperation:');
        buffer.writeln();

        for (final repo in reposNotUsingHelper) {
          buffer.writeln('  - $repo');
        }

        buffer.writeln();
        buffer.writeln('Repositories extending BaseFirestoreRepository should use:');
        buffer.writeln('  - handleFirestoreOperation<T>() for operations returning values');
        buffer.writeln('  - handleFirestoreVoidOperation() for operations returning void');
        buffer.writeln();
        buffer.writeln('This ensures:');
        buffer.writeln('  - Consistent error handling');
        buffer.writeln('  - Standardized logging');
        buffer.writeln('  - Arabic error messages');

        fail(buffer.toString());
      }

      // Test passes if repositories use helper methods
      expect(reposNotUsingHelper.isEmpty, isTrue,
          reason: 'Repositories should use handleFirestoreOperation methods');
    });

    test('repository pattern documentation should exist', () {
      final projectRoot = Directory.current;

      // Check for repository pattern documentation
      final docsFiles = [
        'docs/guides/REPOSITORY_PATTERN_GUIDE.md',
        'docs/references/REPOSITORY_PATTERN_QUICK_REFERENCE.md',
      ];

      final missingDocs = <String>[];

      for (final docPath in docsFiles) {
        final docFile = File(path.join(projectRoot.path, docPath));
        if (!docFile.existsSync()) {
          missingDocs.add(docPath);
        }
      }

      // Build error message if documentation is missing
      if (missingDocs.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln('\nMissing repository pattern documentation:');
        buffer.writeln();

        for (final doc in missingDocs) {
          buffer.writeln('  - $doc');
        }

        buffer.writeln();
        buffer.writeln('Repository pattern should be documented for developers');

        fail(buffer.toString());
      }

      // Test passes if documentation exists
      expect(missingDocs.isEmpty, isTrue,
          reason: 'Repository pattern documentation should exist');
    });

    test('BaseFirestoreRepository should provide required helper methods', () {
      final projectRoot = Directory.current;
      final baseRepoFile = File(path.join(
        projectRoot.path,
        'lib/core/data/base_firestore_repository.dart',
      ));

      expect(baseRepoFile.existsSync(), isTrue,
          reason: 'BaseFirestoreRepository should exist');

      final content = baseRepoFile.readAsStringSync();

      // Check for required methods
      final requiredMethods = [
        'handleFirestoreOperation',
        'handleFirestoreVoidOperation',
        'mapQuerySnapshot',
        'mapDocumentSnapshot',
      ];

      final missingMethods = <String>[];

      for (final method in requiredMethods) {
        if (!content.contains(method)) {
          missingMethods.add(method);
        }
      }

      // Build error message if methods are missing
      if (missingMethods.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln('\nBaseFirestoreRepository is missing required methods:');
        buffer.writeln();

        for (final method in missingMethods) {
          buffer.writeln('  - $method');
        }

        fail(buffer.toString());
      }

      // Test passes if all required methods exist
      expect(missingMethods.isEmpty, isTrue,
          reason: 'BaseFirestoreRepository should provide all required helper methods');
    });

    test('repository pattern compliance summary', () {
      // This test provides a summary of the repository pattern compliance
      final projectRoot = Directory.current;
      final libDir = Directory(path.join(projectRoot.path, 'lib'));

      // Count repositories
      final implementationFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) =>
              file.path.endsWith('.dart') &&
              file.path.contains(path.join('data', 'repositories')) &&
              !file.path.contains('base_firestore_repository.dart'))
          .toList();

      final interfaceFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) =>
              file.path.endsWith('.dart') &&
              file.path.contains(path.join('domain', 'repositories')))
          .toList();

      // Count Firestore repositories
      final firestoreRepos = implementationFiles
          .where((file) => file.path.contains('firestore_'))
          .length;

      // This test always passes but provides useful information
      expect(implementationFiles.length, greaterThan(0),
          reason: 'Should have repository implementations');
      expect(interfaceFiles.length, greaterThan(0),
          reason: 'Should have repository interfaces');
      expect(firestoreRepos, greaterThan(0),
          reason: 'Should have Firestore repositories');

      // Print summary (visible in test output)
      // ignore: avoid_print
      print('\n=== Repository Pattern Compliance Summary ===');
      // ignore: avoid_print
      print('Total repository implementations: ${implementationFiles.length}');
      // ignore: avoid_print
      print('Total repository interfaces: ${interfaceFiles.length}');
      // ignore: avoid_print
      print('Firestore repositories: $firestoreRepos');
      // ignore: avoid_print
      print('==========================================\n');
    });
  });
}
