import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/models/discovery_filters.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../data/repositories/firestore_discovery_repository.dart';

/// Provider for DiscoveryRepository
final discoveryRepositoryProvider = Provider<FirestoreDiscoveryRepository>((ref) {
  return FirestoreDiscoveryRepository();
});

/// State for discovery operations
class DiscoveryState {
  final UserProfile? currentUser;
  final List<UserProfile> discoveredUsers;
  final DiscoveryFilters filters;
  final bool isLoading;
  final String? error;

  DiscoveryState({
    this.currentUser,
    this.discoveredUsers = const [],
    DiscoveryFilters? filters,
    this.isLoading = false,
    this.error,
  }) : filters = filters ?? DiscoveryFilters();

  DiscoveryState copyWith({
    UserProfile? currentUser,
    List<UserProfile>? discoveredUsers,
    DiscoveryFilters? filters,
    bool? isLoading,
    String? error,
  }) {
    return DiscoveryState(
      currentUser: currentUser ?? this.currentUser,
      discoveredUsers: discoveredUsers ?? this.discoveredUsers,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Discovery provider for managing discovery state
class DiscoveryNotifier extends StateNotifier<DiscoveryState> {
  final FirestoreDiscoveryRepository _repository;
  String? _currentUserId;

  DiscoveryNotifier(this._repository) : super(DiscoveryState());

  /// Set current user ID
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  /// Get a random user based on current filters
  Future<void> getRandomUser() async {
    if (_currentUserId == null) {
      state = state.copyWith(error: 'يجب تسجيل الدخول أولاً');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _repository.getRandomUser(_currentUserId!, state.filters);
      
      if (user == null) {
        state = state.copyWith(
          currentUser: null,
          isLoading: false,
          error: 'لا يوجد مستخدمين متاحين بهذه الفلاتر',
        );
      } else {
        state = state.copyWith(
          currentUser: user,
          isLoading: false,
        );
      }
    } on AppException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: 'حدث خطأ غير متوقع', isLoading: false);
    }
  }

  /// Get filtered users
  Future<void> getFilteredUsers() async {
    if (_currentUserId == null) {
      state = state.copyWith(error: 'يجب تسجيل الدخول أولاً');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final users = await _repository.getFilteredUsers(_currentUserId!, state.filters);
      state = state.copyWith(
        discoveredUsers: users,
        isLoading: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: 'حدث خطأ غير متوقع', isLoading: false);
    }
  }

  /// Update filters
  void updateFilters(DiscoveryFilters filters) {
    state = state.copyWith(filters: filters);
  }

  /// Clear current user (skip)
  void skipCurrentUser() {
    if (state.currentUser != null) {
      // Add current user to excluded list
      final updatedFilters = state.filters.copyWith(
        excludedUserIds: [
          ...state.filters.excludedUserIds,
          state.currentUser!.id,
        ],
      );
      state = state.copyWith(
        currentUser: null,
        filters: updatedFilters,
      );
    }
  }

  /// Reset filters
  void resetFilters() {
    state = state.copyWith(filters: DiscoveryFilters());
  }
}

/// Provider for DiscoveryNotifier
final discoveryProvider = StateNotifierProvider<DiscoveryNotifier, DiscoveryState>((ref) {
  final repository = ref.watch(discoveryRepositoryProvider);
  return DiscoveryNotifier(repository);
});
