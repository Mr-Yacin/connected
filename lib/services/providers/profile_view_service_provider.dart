import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../profile_view_service.dart';

/// Provider for ProfileViewService
final profileViewServiceProvider = Provider<ProfileViewService>((ref) {
  return ProfileViewService();
});
