import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle location detection and country identification
class LocationService {
  /// Request location permission from the user
  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    try {
      final status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      return false;
    }
  }

  /// Get the country name from the current position
  /// Returns null if unable to determine
  Future<String?> getCurrentCountry() async {
    try {
      // Check if location service is enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permission
      final hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      // Get country from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return placemark.country;
      }

      return null;
    } catch (e) {
      // Return null on any error
      return null;
    }
  }

  /// Get a list of common countries for manual selection
  static List<String> getCountryList() {
    return [
      'الجزائر', // Algeria
      'البحرين', // Bahrain
      'مصر', // Egypt
      'العراق', // Iraq
      'الأردن', // Jordan
      'الكويت', // Kuwait
      'لبنان', // Lebanon
      'ليبيا', // Libya
      'موريتانيا', // Mauritania
      'المغرب', // Morocco
      'عُمان', // Oman
      'فلسطين', // Palestine
      'قطر', // Qatar
      'السعودية', // Saudi Arabia
      'السودان', // Sudan
      'سوريا', // Syria
      'تونس', // Tunisia
      'الإمارات', // UAE
      'اليمن', // Yemen
      'أخرى', // Other
    ]..sort();
  }

  /// Convert English country name to Arabic (basic mapping)
  static String? convertCountryToArabic(String? englishCountry) {
    if (englishCountry == null) return null;

    final countryMap = {
      'Algeria': 'الجزائر',
      'Bahrain': 'البحرين',
      'Egypt': 'مصر',
      'Iraq': 'العراق',
      'Jordan': 'الأردن',
      'Kuwait': 'الكويت',
      'Lebanon': 'لبنان',
      'Libya': 'ليبيا',
      'Mauritania': 'موريتانيا',
      'Morocco': 'المغرب',
      'Oman': 'عُمان',
      'Palestine': 'فلسطين',
      'Qatar': 'قطر',
      'Saudi Arabia': 'السعودية',
      'Sudan': 'السودان',
      'Syria': 'سوريا',
      'Tunisia': 'تونس',
      'United Arab Emirates': 'الإمارات',
      'Yemen': 'اليمن',
    };

    return countryMap[englishCountry] ?? englishCountry;
  }
}
