import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_provider.dart';

/// Provider specifically for the CURRENT logged-in user's profile
/// This is separate from viewedProfileProvider to avoid state conflicts
final currentUserProfileProvider = StateNotifierProvider<CurrentUserProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  final blurService = ref.watch(imageBlurServiceProvider);
  return CurrentUserProfileNotifier(repository, blurService, ref);
});

class CurrentUserProfileNotifier extends ProfileNotifier {
  CurrentUserProfileNotifier(super.repository, super.blurService, super.ref);

  /// Load the current user's profile automatically
  Future<void> loadCurrentUserProfile() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      state = state.copyWith(error: 'No user logged in', isLoading: false);
      return;
    }
    await loadProfile(currentUserId);
  }
}
