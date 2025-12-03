import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/report.dart';
import '../../domain/repositories/moderation_repository.dart';
import '../../data/repositories/firestore_moderation_repository.dart';
import '../../data/services/block_service.dart';

/// Provider for ModerationRepository
final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return FirestoreModerationRepository();
});

/// Provider for BlockService
final blockServiceProvider = Provider<BlockService>((ref) {
  final repository = ref.watch(moderationRepositoryProvider);
  return BlockService(moderationRepository: repository);
});

/// State notifier for moderation operations
class ModerationNotifier extends StateNotifier<AsyncValue<void>> {
  final ModerationRepository _repository;
  final BlockService _blockService;

  ModerationNotifier(this._repository, this._blockService)
      : super(const AsyncValue.data(null));

  /// Block a user
  Future<void> blockUser(String userId, String blockedUserId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.blockUser(userId, blockedUserId);
    });
  }

  /// Unblock a user
  Future<void> unblockUser(String userId, String blockedUserId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.unblockUser(userId, blockedUserId);
    });
  }

  /// Report content
  Future<void> reportContent(Report report) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.reportContent(report);
    });
  }

  /// Check if a user is blocked
  Future<bool> isBlocked(String userId, String targetUserId) async {
    return await _blockService.isBlocked(userId, targetUserId);
  }

  /// Check if access should be prevented
  Future<bool> preventAccess(String userId1, String userId2) async {
    return await _blockService.preventAccess(userId1, userId2);
  }
}

/// Provider for ModerationNotifier
final moderationProvider =
    StateNotifierProvider<ModerationNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(moderationRepositoryProvider);
  final blockService = ref.watch(blockServiceProvider);
  return ModerationNotifier(repository, blockService);
});

/// Provider for blocked users list
final blockedUsersProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  final repository = ref.watch(moderationRepositoryProvider);
  return await repository.getBlockedUsers(userId);
});

/// Provider for pending reports (for moderators)
final pendingReportsProvider = FutureProvider<List<Report>>((ref) async {
  final repository = ref.watch(moderationRepositoryProvider);
  return await repository.getPendingReports();
});
