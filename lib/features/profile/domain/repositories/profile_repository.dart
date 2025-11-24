import 'dart:io';
import '../../../../core/models/user_profile.dart';

/// Repository interface for profile operations
abstract class ProfileRepository {
  /// Get user profile by ID
  Future<UserProfile> getProfile(String userId);
  
  /// Update user profile
  Future<void> updateProfile(UserProfile profile);
  
  /// Upload profile image and return the URL
  Future<String> uploadProfileImage(String userId, File image);
  
  /// Generate a unique anonymous link for the user
  Future<String> generateAnonymousLink(String userId);
}
