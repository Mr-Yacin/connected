import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../monitoring/app_logger.dart';

/// Provider for ProfileViewService
final profileViewServiceProvider = Provider<ProfileViewService>((ref) {
  return ProfileViewService();
});

/// Service for tracking profile views
class ProfileViewService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Cache to prevent duplicate views in the same session
  final Set<String> _viewedProfilesCache = {};

  ProfileViewService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Record a profile view
  /// 
  /// This will:
  /// 1. Check if user is viewing their own profile (skip)
  /// 2. Check if already viewed in this session (skip)
  /// 3. Create a profile_views document
  /// 4. Trigger Firebase Function to send notification (if enabled)
  Future<void> recordProfileView(String profileUserId) async {
    try {
      final currentUser = _auth.currentUser;
      
      // Don't record if not authenticated
      if (currentUser == null) {
        AppLogger.debug('User not authenticated, skipping profile view');
        return;
      }

      final viewerId = currentUser.uid;

      // Don't record if viewing own profile
      if (viewerId == profileUserId) {
        AppLogger.debug('Viewing own profile, skipping profile view');
        return;
      }

      // Check cache to prevent duplicate views in same session
      final cacheKey = '${viewerId}_$profileUserId';
      if (_viewedProfilesCache.contains(cacheKey)) {
        AppLogger.debug('Profile already viewed in this session, skipping');
        return;
      }

      // Record the view
      await _firestore.collection('profile_views').add({
        'viewerId': viewerId,
        'profileUserId': profileUserId,
        'viewedAt': FieldValue.serverTimestamp(),
      });

      // Add to cache
      _viewedProfilesCache.add(cacheKey);

      AppLogger.info('Profile view recorded: $profileUserId by $viewerId');
    } catch (e) {
      // Silent fail - profile views are not critical
      AppLogger.debug('Failed to record profile view: $e');
    }
  }

  /// Get profile views for a user
  /// Returns list of viewer user IDs
  Future<List<String>> getProfileViews(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('profile_views')
          .where('profileUserId', isEqualTo: userId)
          .orderBy('viewedAt', descending: true)
          .limit(50) // Last 50 views
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['viewerId'] as String)
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get profile views: $e');
      return [];
    }
  }

  /// Get profile view count for a user
  Future<int> getProfileViewCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('profile_views')
          .where('profileUserId', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Failed to get profile view count: $e');
      return 0;
    }
  }

  /// Clear the viewed profiles cache
  /// Call this when user logs out or session ends
  void clearCache() {
    _viewedProfilesCache.clear();
    AppLogger.debug('Profile views cache cleared');
  }
}

