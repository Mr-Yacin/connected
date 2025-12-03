import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/models/discovery_filters.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../../data/repositories/firestore_discovery_repository.dart';
import '../../data/services/viewed_users_service.dart';
import '../../../../services/monitoring/error_logging_service.dart';

/// Provider for DiscoveryRepository
final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return FirestoreDiscoveryRepository();
});

/// Provider for ViewedUsersService
final viewedUsersServiceProvider = Provider<ViewedUsersService>((ref) {
  return ViewedUsersService();
});

/// State for discovery operations
class DiscoveryState {
  final UserProfile? currentUser;
  final List<UserProfile> discoveredUsers;
  final DiscoveryFilters filters;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final Set<String> viewedUserIds;
  final DateTime? lastShuffleTime;
  final bool canShuffle;
  final int cooldownSeconds;

  DiscoveryState({
    this.currentUser,
    this.discoveredUsers = const [],
    DiscoveryFilters? filters,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.viewedUserIds = const {},
    this.lastShuffleTime,
    this.canShuffle = true,
    this.cooldownSeconds = 0,
  }) : filters = filters ?? DiscoveryFilters();

  DiscoveryState copyWith({
    UserProfile? currentUser,
    List<UserProfile>? discoveredUsers,
    DiscoveryFilters? filters,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    Set<String>? viewedUserIds,
    DateTime? lastShuffleTime,
    bool? canShuffle,
    int? cooldownSeconds,
  }) {
    return DiscoveryState(
      currentUser: currentUser ?? this.currentUser,
      discoveredUsers: discoveredUsers ?? this.discoveredUsers,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      viewedUserIds: viewedUserIds ?? this.viewedUserIds,
      lastShuffleTime: lastShuffleTime ?? this.lastShuffleTime,
      canShuffle: canShuffle ?? this.canShuffle,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
    );
  }
}

/// Discovery provider for managing discovery state
class DiscoveryNotifier extends StateNotifier<DiscoveryState> {
  final DiscoveryRepository _repository;
  final ViewedUsersService _viewedUsersService;
  String? _currentUserId;
  Timer? _cooldownTimer;

  DiscoveryNotifier(this._repository, this._viewedUsersService) : super(DiscoveryState()) {
    _initViewedUsers();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    super.dispose();
  }

  /// Initialize viewed users from storage
  Future<void> _initViewedUsers() async {
    final viewedUsers = await _viewedUsersService.getViewedUsers();
    state = state.copyWith(viewedUserIds: viewedUsers);
  }

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
      // Reload viewed users from storage
      final viewedUsers = await _viewedUsersService.getViewedUsers();
      
      // Add viewed users to filters
      final updatedFilters = state.filters.copyWith(
        excludedUserIds: [
          ...state.filters.excludedUserIds,
          ...viewedUsers,
        ],
      );

      final user = await _repository.getRandomUser(_currentUserId!, updatedFilters);
      
      if (user == null) {
        state = state.copyWith(
          currentUser: null,
          isLoading: false,
          error: 'لا يوجد مستخدمين متاحين بهذه الفلاتر',
        );
      } else {
        // Add to viewed users
        await _viewedUsersService.addViewedUser(user.id);
        final updatedViewedUsers = {...state.viewedUserIds, user.id};

        state = state.copyWith(
          currentUser: user,
          isLoading: false,
          viewedUserIds: updatedViewedUsers,
        );
      }
    } on AppException catch (e) {
      // Log AppException (already logged in repository)
      state = state.copyWith(error: e.message, isLoading: false);
    } catch (e, stackTrace) {
      // Log unexpected errors with full context
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get random user',
        screen: 'ShuffleScreen',
        operation: 'getRandomUser',
      );
      
      // Report critical errors to Crashlytics
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Unexpected error in getRandomUser',
        fatal: false,
      );
      
      state = state.copyWith(error: 'حدث خطأ غير متوقع', isLoading: false);
    }
  }

  /// Shuffle with cooldown (3 seconds)
  Future<void> shuffleWithCooldown() async {
    if (!_canShuffle()) {
      final remaining = _getRemainingSeconds();
      state = state.copyWith(
        error: 'يرجى الانتظار $remaining ثانية',
        cooldownSeconds: remaining,
      );
      return;
    }

    // Update last shuffle time
    state = state.copyWith(
      lastShuffleTime: DateTime.now(),
      canShuffle: false,
      cooldownSeconds: 3,
    );

    // Start cooldown countdown
    _startCooldownCountdown();

    // Get random user
    await getRandomUser();
  }

  /// Check if shuffle is available (3+ seconds passed)
  bool _canShuffle() {
    if (state.lastShuffleTime == null) return true;
    final now = DateTime.now();
    final diff = now.difference(state.lastShuffleTime!);
    return diff.inSeconds >= 3;
  }

  /// Get remaining cooldown seconds
  int _getRemainingSeconds() {
    if (state.lastShuffleTime == null) return 0;
    final now = DateTime.now();
    final diff = now.difference(state.lastShuffleTime!);
    final remaining = 3 - diff.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Start cooldown countdown
  void _startCooldownCountdown() {
    // Cancel existing timer before starting new one
    _cooldownTimer?.cancel();
    
    // Use Timer.periodic instead of recursive Future.delayed
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _getRemainingSeconds();
      
      if (remaining > 0) {
        state = state.copyWith(cooldownSeconds: remaining);
      } else {
        state = state.copyWith(
          canShuffle: true,
          cooldownSeconds: 0,
        );
        timer.cancel();
        _cooldownTimer = null;
      }
    });
  }

  /// Get filtered users (deprecated - use getFilteredUsersPaginated)
  @Deprecated('Use loadUsers or loadMoreUsers for pagination support')
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

  /// Load initial users with pagination
  Future<void> loadUsers() async {
    if (_currentUserId == null) {
      state = state.copyWith(error: 'يجب تسجيل الدخول أولاً');
      return;
    }

    // Reset pagination
    final resetFilters = state.filters.copyWith(clearLastDocument: true);
    state = state.copyWith(
      isLoading: true, 
      error: null,
      filters: resetFilters,
      discoveredUsers: [],
    );
    
    try {
      final result = await _repository.getFilteredUsersPaginated(_currentUserId!, state.filters);
      state = state.copyWith(
        discoveredUsers: result.users,
        filters: result.updatedFilters,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } on AppException catch (e) {
      // Log AppException (already logged in repository)
      state = state.copyWith(error: e.message, isLoading: false);
    } catch (e, stackTrace) {
      // Log unexpected errors with full context
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to load users',
        screen: 'ShuffleScreen',
        operation: 'loadUsers',
      );
      
      // Report critical errors to Crashlytics
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Unexpected error in loadUsers',
        fatal: false,
      );
      
      state = state.copyWith(error: 'حدث خطأ غير متوقع', isLoading: false);
    }
  }

  /// Load more users (pagination)
  Future<void> loadMoreUsers() async {
    if (_currentUserId == null) {
      state = state.copyWith(error: 'يجب تسجيل الدخول أولاً');
      return;
    }

    // Don't load if already loading or no more items
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, error: null);
    
    try {
      final result = await _repository.getFilteredUsersPaginated(_currentUserId!, state.filters);
      
      // Append new users to existing list
      final updatedUsers = [...state.discoveredUsers, ...result.users];
      
      state = state.copyWith(
        discoveredUsers: updatedUsers,
        filters: result.updatedFilters,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } on AppException catch (e) {
      // Log AppException (already logged in repository)
      state = state.copyWith(error: e.message, isLoadingMore: false);
    } catch (e, stackTrace) {
      // Log unexpected errors with full context
      ErrorLoggingService.logGeneralError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to load more users',
        screen: 'ShuffleScreen',
        operation: 'loadMoreUsers',
      );
      
      // Report critical errors to Crashlytics
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Unexpected error in loadMoreUsers',
        fatal: false,
      );
      
      state = state.copyWith(error: 'حدث خطأ غير متوقع', isLoadingMore: false);
    }
  }

  /// Update filters
  void updateFilters(DiscoveryFilters filters) {
    // Clear pagination when filters change
    final resetFilters = filters.copyWith(clearLastDocument: true);
    state = state.copyWith(
      filters: resetFilters,
      discoveredUsers: [],
      hasMore: true,
    );
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
        clearLastDocument: true,
      );
      state = state.copyWith(
        currentUser: null,
        filters: updatedFilters,
      );
    }
  }

  /// Reset filters
  void resetFilters() {
    state = state.copyWith(
      filters: DiscoveryFilters(),
      discoveredUsers: [],
      hasMore: true,
    );
  }
}

/// Provider for DiscoveryNotifier
final discoveryProvider = StateNotifierProvider<DiscoveryNotifier, DiscoveryState>((ref) {
  final repository = ref.watch(discoveryRepositoryProvider);
  final viewedUsersService = ref.watch(viewedUsersServiceProvider);
  return DiscoveryNotifier(repository, viewedUsersService);
});
