import 'package:flutter/material.dart';

/// Camera filter model with color transformation parameters
class CameraFilter {
  final String id;
  final String name;
  final ColorFilter colorFilter;
  final String? iconAsset;

  const CameraFilter({
    required this.id,
    required this.name,
    required this.colorFilter,
    this.iconAsset,
  });

  /// Creates a color filter from a matrix
  static ColorFilter createFilter(List<double> matrix) {
    return ColorFilter.matrix(matrix);
  }

  /// Creates a filter with adjustable intensity
  ColorFilter withIntensity(double intensity) {
    if (id == 'none' || intensity == 1.0) {
      return colorFilter;
    }

    // Blend the filter with identity matrix based on intensity
    final matrix = _getMatrix(colorFilter);
    final identityMatrix = [
      1, 0, 0, 0, 0, // Red
      0, 1, 0, 0, 0, // Green
      0, 0, 1, 0, 0, // Blue
      0, 0, 0, 1, 0, // Alpha
    ];

    // Interpolate between identity and filter matrix
    final blendedMatrix = List<double>.generate(20, (i) {
      return identityMatrix[i] + (matrix[i] - identityMatrix[i]) * intensity;
    });

    return createFilter(blendedMatrix);
  }

  /// Extract matrix from ColorFilter
  List<double> _getMatrix(ColorFilter filter) {
    // For now, store original matrix in allFilters
    // This is a simplified approach
    return [
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  /// No filter (original)
  static CameraFilter get none => CameraFilter(
        id: 'none',
        name: 'Normal',
        colorFilter: createFilter([
          1, 0, 0, 0, 0, // Red
          0, 1, 0, 0, 0, // Green
          0, 0, 1, 0, 0, // Blue
          0, 0, 0, 1, 0, // Alpha
        ]),
      );

  /// Warm Glow - Golden hour vibes
  static CameraFilter get warmGlow => CameraFilter(
        id: 'warm_glow',
        name: 'Warm Glow',
        colorFilter: createFilter([
          1.2, 0, 0, 0, 10, // Red boost
          0, 1.0, 0, 0, 5, // Green slight boost
          0, 0, 0.8, 0, -10, // Blue reduce
          0, 0, 0, 1, 0, // Alpha
        ]),
      );

  /// Cool Blue - Fresh and clean
  static CameraFilter get coolBlue => CameraFilter(
        id: 'cool_blue',
        name: 'Cool Blue',
        colorFilter: createFilter([
          0.9, 0, 0, 0, -5, // Red reduce
          0, 1.0, 0, 0, 0, // Green normal
          0, 0, 1.2, 0, 15, // Blue boost
          0, 0, 0, 1, 0, // Alpha
        ]),
      );

  /// Vintage Film - Classic 35mm look
  static CameraFilter get vintageFilm => CameraFilter(
        id: 'vintage_film',
        name: 'Vintage',
        colorFilter: createFilter([
          1.1, 0.05, 0, 0, 0, // Red with slight cross
          0.05, 1.0, 0.05, 0, 0, // Green with cross
          0, 0.05, 0.9, 0, 0, // Blue reduced with cross
          0, 0, 0, 1, 0, // Alpha
        ]),
      );

  /// Dramatic - High contrast art
  static CameraFilter get dramatic => CameraFilter(
        id: 'dramatic',
        name: 'Dramatic',
        colorFilter: createFilter([
          1.5, 0, 0, 0, -20, // Red high contrast
          0, 1.5, 0, 0, -20, // Green high contrast
          0, 0, 1.5, 0, -20, // Blue high contrast
          0, 0, 0, 1, 0, // Alpha
        ]),
      );

  /// Soft Dream - Romantic pastels
  static CameraFilter get softDream => CameraFilter(
        id: 'soft_dream',
        name: 'Soft Dream',
        colorFilter: createFilter([
          0.9, 0, 0, 0, 20, // Red soften
          0, 0.95, 0, 0, 15, // Green soften
          0, 0, 1.0, 0, 10, // Blue slight
          0, 0, 0, 0.95, 0, // Alpha slight transparency
        ]),
      );

  /// Vibrant - Enhanced colors
  static CameraFilter get vibrant => CameraFilter(
        id: 'vibrant',
        name: 'Vibrant',
        colorFilter: createFilter([
          1.3, 0, 0, 0, 0, // Red boost
          0, 1.3, 0, 0, 0, // Green boost
          0, 0, 1.3, 0, 0, // Blue boost
          0, 0, 0, 1, 0, // Alpha
        ]),
      );

  /// Noir - B&W with style
  static CameraFilter get noir => CameraFilter(
        id: 'noir',
        name: 'Noir',
        colorFilter: createFilter([
          0.3, 0.59, 0.11, 0, 0, // Red from all
          0.3, 0.59, 0.11, 0, 0, // Green from all
          0.3, 0.59, 0.11, 0, 0, // Blue from all
          0, 0, 0, 1, 0, // Alpha
        ]),
      );

  /// Sunset - Warm orange tones
  static CameraFilter get sunset => CameraFilter(
        id: 'sunset',
        name: 'Sunset',
        colorFilter: createFilter([
          1.3, 0, 0, 0, 20, // Red boost
          0, 1.0, 0, 0, 10, // Green moderate
          0, 0, 0.7, 0, -20, // Blue reduce
          0, 0, 0, 1, 0, // Alpha
        ]),
      );

  /// Party - Fun celebratory feel
  static CameraFilter get party => CameraFilter(
        id: 'party',
        name: 'Party',
        colorFilter: createFilter([
          1.2, 0.1, 0, 0, 10, // Red with cross
          0, 1.3, 0.1, 0, 10, // Green boost
          0.1, 0, 1.2, 0, 10, // Blue with cross
          0, 0, 0, 1, 0, // Alpha
        ]),
      );

  /// Get all available filters
  static List<CameraFilter> get allFilters => [
        none,
        warmGlow,
        coolBlue,
        vintageFilm,
        dramatic,
        softDream,
        vibrant,
        noir,
        sunset,
        party,
      ];
}
