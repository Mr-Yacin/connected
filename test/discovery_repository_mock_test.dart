import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:social_connect_app/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:social_connect_app/core/models/user_profile.dart';
import 'package:social_connect_app/core/models/discovery_filters.dart';

// Generate mock using Mockito
@GenerateMocks([DiscoveryRepository])
import 'discovery_repository_mock_test.mocks.dart';

/// **Validates: Requirements 5.4, 5.5**
/// 
/// This test suite validates that:
/// 1. The DiscoveryRepository interface can be mocked for testing
/// 2. Tests can run without Firebase dependencies
/// 3. The interface supports dependency injection patterns
void main() {
  group('DiscoveryRepository Mock Tests', () {
    late MockDiscoveryRepository mockRepository;

    setUp(() {
      mockRepository = MockDiscoveryRepository();
    });

    group('Interface Mocking', () {
      test('should successfully mock getRandomUser method', () async {
        // Arrange
        final testUser = UserProfile(
          id: 'test-user-1',
          phoneNumber: '+1234567890',
          name: 'Test User',
          age: 25,
          country: 'US',
          gender: 'male',
          isActive: true,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        final filters = DiscoveryFilters(
          country: 'US',
          minAge: 20,
          maxAge: 30,
        );

        when(mockRepository.getRandomUser('current-user-id', filters))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await mockRepository.getRandomUser('current-user-id', filters);

        // Assert
        expect(result, equals(testUser));
        verify(mockRepository.getRandomUser('current-user-id', filters)).called(1);
      });

      test('should successfully mock getRandomUser returning null', () async {
        // Arrange
        final filters = DiscoveryFilters(
          country: 'XX',
          minAge: 100,
          maxAge: 120,
        );

        when(mockRepository.getRandomUser('current-user-id', filters))
            .thenAnswer((_) async => null);

        // Act
        final result = await mockRepository.getRandomUser('current-user-id', filters);

        // Assert
        expect(result, isNull);
        verify(mockRepository.getRandomUser('current-user-id', filters)).called(1);
      });

      test('should successfully mock getFilteredUsers method', () async {
        // Arrange
        final testUsers = [
          UserProfile(
            id: 'user-1',
            phoneNumber: '+1111111111',
            name: 'User One',
            age: 25,
            country: 'US',
            gender: 'male',
            isActive: true,
            createdAt: DateTime.now(),
            lastActive: DateTime.now(),
          ),
          UserProfile(
            id: 'user-2',
            phoneNumber: '+2222222222',
            name: 'User Two',
            age: 28,
            country: 'US',
            gender: 'female',
            isActive: true,
            createdAt: DateTime.now(),
            lastActive: DateTime.now(),
          ),
        ];

        final filters = DiscoveryFilters(country: 'US');

        when(mockRepository.getFilteredUsers('current-user-id', filters))
            .thenAnswer((_) async => testUsers);

        // Act
        final result = await mockRepository.getFilteredUsers('current-user-id', filters);

        // Assert
        expect(result, equals(testUsers));
        expect(result.length, equals(2));
        verify(mockRepository.getFilteredUsers('current-user-id', filters)).called(1);
      });

      test('should successfully mock getFilteredUsersPaginated method', () async {
        // Arrange
        final testUsers = [
          UserProfile(
            id: 'user-1',
            phoneNumber: '+1111111111',
            name: 'User One',
            age: 25,
            country: 'US',
            gender: 'male',
            isActive: true,
            createdAt: DateTime.now(),
            lastActive: DateTime.now(),
          ),
        ];

        final filters = DiscoveryFilters(
          country: 'US',
          pageSize: 20,
        );

        final paginatedResult = PaginatedUsers(
          users: testUsers,
          hasMore: true,
          updatedFilters: filters,
        );

        when(mockRepository.getFilteredUsersPaginated('current-user-id', filters))
            .thenAnswer((_) async => paginatedResult);

        // Act
        final result = await mockRepository.getFilteredUsersPaginated('current-user-id', filters);

        // Assert
        expect(result.users, equals(testUsers));
        expect(result.hasMore, isTrue);
        expect(result.updatedFilters, equals(filters));
        verify(mockRepository.getFilteredUsersPaginated('current-user-id', filters)).called(1);
      });
    });

    group('No Firebase Dependencies', () {
      test('should run without Firebase when using mocked repository', () async {
        // Arrange
        final filters = DiscoveryFilters(country: 'US');
        final testUser = UserProfile(
          id: 'test-user',
          phoneNumber: '+1234567890',
          name: 'Test User',
          age: 25,
          country: 'US',
          isActive: true,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        when(mockRepository.getRandomUser('current-user-id', filters))
            .thenAnswer((_) async => testUser);

        // Act - This should work without Firebase initialization
        final result = await mockRepository.getRandomUser('current-user-id', filters);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('test-user'));
        // No Firebase calls were made - test runs in isolation
      });

      test('should handle multiple sequential calls without Firebase', () async {
        // Arrange
        final filters = DiscoveryFilters(country: 'US');
        final users = List.generate(
          5,
          (i) => UserProfile(
            id: 'user-$i',
            phoneNumber: '+123456789$i',
            name: 'User $i',
            age: 20 + i,
            country: 'US',
            isActive: true,
            createdAt: DateTime.now(),
            lastActive: DateTime.now(),
          ),
        );

        when(mockRepository.getFilteredUsers('current-user-id', filters))
            .thenAnswer((_) async => users);

        // Act - Multiple calls without Firebase
        final result1 = await mockRepository.getFilteredUsers('current-user-id', filters);
        final result2 = await mockRepository.getFilteredUsers('current-user-id', filters);

        // Assert
        expect(result1.length, equals(5));
        expect(result2.length, equals(5));
        verify(mockRepository.getFilteredUsers('current-user-id', filters)).called(2);
      });
    });

    group('Dependency Injection Support', () {
      test('should support interface-based dependency injection', () {
        // Arrange - Create a service that depends on DiscoveryRepository interface
        final service = TestDiscoveryService(mockRepository);

        final filters = DiscoveryFilters(country: 'US');
        final testUser = UserProfile(
          id: 'test-user',
          phoneNumber: '+1234567890',
          name: 'Test User',
          age: 25,
          country: 'US',
          isActive: true,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        when(mockRepository.getRandomUser('current-user-id', filters))
            .thenAnswer((_) async => testUser);

        // Act
        final result = service.findRandomUser('current-user-id', filters);

        // Assert
        expect(result, completes);
        verify(mockRepository.getRandomUser('current-user-id', filters)).called(1);
      });

      test('should allow swapping implementations via interface', () async {
        // Arrange - Create two different mock implementations
        final mockRepo1 = MockDiscoveryRepository();
        final mockRepo2 = MockDiscoveryRepository();

        final filters = DiscoveryFilters(country: 'US');
        final user1 = UserProfile(
          id: 'user-from-repo-1',
          phoneNumber: '+1111111111',
          name: 'User 1',
          age: 25,
          country: 'US',
          isActive: true,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );
        final user2 = UserProfile(
          id: 'user-from-repo-2',
          phoneNumber: '+2222222222',
          name: 'User 2',
          age: 30,
          country: 'US',
          isActive: true,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        when(mockRepo1.getRandomUser('current-user-id', filters))
            .thenAnswer((_) async => user1);
        when(mockRepo2.getRandomUser('current-user-id', filters))
            .thenAnswer((_) async => user2);

        // Act - Use different implementations
        final service1 = TestDiscoveryService(mockRepo1);
        final service2 = TestDiscoveryService(mockRepo2);

        final result1 = await service1.findRandomUser('current-user-id', filters);
        final result2 = await service2.findRandomUser('current-user-id', filters);

        // Assert - Different implementations return different results
        expect(result1?.id, equals('user-from-repo-1'));
        expect(result2?.id, equals('user-from-repo-2'));
      });
    });

    group('Error Handling with Mocks', () {
      test('should mock error scenarios without Firebase', () async {
        // Arrange
        final filters = DiscoveryFilters(country: 'US');

        when(mockRepository.getRandomUser('current-user-id', filters))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => mockRepository.getRandomUser('current-user-id', filters),
          throwsException,
        );
      });

      test('should verify error handling logic without Firebase', () async {
        // Arrange
        final filters = DiscoveryFilters(country: 'US');

        when(mockRepository.getFilteredUsersPaginated('current-user-id', filters))
            .thenThrow(Exception('Service unavailable'));

        // Act & Assert
        try {
          await mockRepository.getFilteredUsersPaginated('current-user-id', filters);
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e, isA<Exception>());
          expect(e.toString(), contains('Service unavailable'));
        }

        verify(mockRepository.getFilteredUsersPaginated('current-user-id', filters)).called(1);
      });
    });

    group('Filter Variations', () {
      test('should mock repository with different filter combinations', () async {
        // Arrange
        final filters1 = DiscoveryFilters(
          country: 'US',
          gender: 'male',
          minAge: 20,
          maxAge: 30,
        );

        final filters2 = DiscoveryFilters(
          country: 'UK',
          gender: 'female',
          minAge: 25,
          maxAge: 35,
        );

        final user1 = UserProfile(
          id: 'us-male-user',
          phoneNumber: '+1111111111',
          name: 'US Male',
          age: 25,
          country: 'US',
          gender: 'male',
          isActive: true,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        final user2 = UserProfile(
          id: 'uk-female-user',
          phoneNumber: '+2222222222',
          name: 'UK Female',
          age: 30,
          country: 'UK',
          gender: 'female',
          isActive: true,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        when(mockRepository.getRandomUser('current-user-id', filters1))
            .thenAnswer((_) async => user1);
        when(mockRepository.getRandomUser('current-user-id', filters2))
            .thenAnswer((_) async => user2);

        // Act
        final result1 = await mockRepository.getRandomUser('current-user-id', filters1);
        final result2 = await mockRepository.getRandomUser('current-user-id', filters2);

        // Assert
        expect(result1?.country, equals('US'));
        expect(result1?.gender, equals('male'));
        expect(result2?.country, equals('UK'));
        expect(result2?.gender, equals('female'));
      });
    });
  });
}

/// Test service that depends on DiscoveryRepository interface
/// This demonstrates dependency injection pattern
class TestDiscoveryService {
  final DiscoveryRepository repository;

  TestDiscoveryService(this.repository);

  Future<UserProfile?> findRandomUser(String userId, DiscoveryFilters filters) {
    return repository.getRandomUser(userId, filters);
  }

  Future<List<UserProfile>> findFilteredUsers(String userId, DiscoveryFilters filters) {
    return repository.getFilteredUsers(userId, filters);
  }

  Future<PaginatedUsers> findPaginatedUsers(String userId, DiscoveryFilters filters) {
    return repository.getFilteredUsersPaginated(userId, filters);
  }
}
