import 'package:flutter/material.dart';

/// نبض (Nabd) - Brand Colors
/// Desert Sunset Color Palette - Arabic-Inspired Theme
class AppColors {
  // ====================
  // PRIMARY BRAND COLORS - ألوان العلامة التجارية
  // ====================

  /// Sunrise Orange - برتقالي الغروب (Primary Brand Color)
  static const Color primary = Color(0xFFE67E22);

  /// Royal Purple - بنفسجي ملكي (Secondary Brand Color)
  static const Color secondary = Color(0xFF9B59B6);

  /// Golden Hour - ذهبي (Accent Brand Color)
  static const Color accent = Color(0xFFF39C12);

  // ====================
  // BRAND COLOR VARIATIONS - تدرجات ألوان العلامة
  // ====================

  /// Deep Orange - برتقالي داكن (Darker shade for contrast)
  static const Color primaryDark = Color(0xFFD35400);

  /// Soft Purple - بنفسجي فاتح (Lighter purple for highlights)
  static const Color secondaryLight = Color(0xFFAF7AC5);

  /// Pale Gold - ذهبي فاتح (Light accent)
  static const Color accentLight = Color(0xFFF8C471);

  // ====================
  // BACKGROUND COLORS - ألوان الخلفية
  // ====================

  /// Light Mode Background
  static const Color lightBackground = Color(0xFFF8F9FA);

  /// Dark Mode Background - Almost Black
  static const Color darkBackground = Color(0xFF0F0F0F);

  // ====================
  // SURFACE COLORS - ألوان الأسطح
  // ====================

  /// Light Surface
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Dark Surface - Cards and elevated components
  static const Color darkSurface = Color(0xFF1A1A1A);

  /// Dark Card - More elevated surface
  static const Color darkCard = Color(0xFF252525);

  // ====================
  // TEXT COLORS - ألوان النصوص
  // ====================

  /// Primary Text (Light Mode)
  static const Color textPrimary = Color(0xFF212121);

  /// Secondary Text (Light Mode)
  static const Color textSecondary = Color(0xFF757575);

  /// Primary Text (Dark Mode)
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  /// Secondary Text (Dark Mode)
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  /// Hint Text (Dark Mode)
  static const Color textHintDark = Color(0xFF6B6B6B);

  // ====================
  // STATUS COLORS - ألوان الحالة
  // ====================

  /// Success - Green
  static const Color success = Color(0xFF27AE60);

  /// Error - Red
  static const Color error = Color(0xFFE74C3C);

  /// Warning - Amber
  static const Color warning = Color(0xFFF39C12);

  /// Info - Blue
  static const Color info = Color(0xFF3498DB);

  /// Online Status - Emerald
  static const Color online = Color(0xFF10B981);

  /// Offline Status - Gray
  static const Color offline = Color(0xFF6B7280);

  // ====================
  // UI ELEMENTS - عناصر الواجهة
  // ====================

  /// Divider (Light Mode)
  static const Color divider = Color(0xFFE0E0E0);

  /// Divider (Dark Mode)
  static const Color dividerDark = Color(0xFF404040);

  /// Border (Dark Mode)
  static const Color borderDark = Color(0xFF2A2A2A);

  /// Shimmer Base (Dark Mode)
  static const Color shimmerBase = Color(0xFF1A1A1A);

  /// Shimmer Highlight (Dark Mode)
  static const Color shimmerHighlight = Color(0xFF2A2A2A);

  // ====================
  // GRADIENTS - التدرجات
  // ====================

  /// Primary Brand Gradient - التدرج الأساسي
  /// Orange → Purple → Gold
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE67E22), // Sunrise Orange
      Color(0xFF9B59B6), // Royal Purple
      Color(0xFFF39C12), // Golden Hour
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Accent Gradient - تدرج مساعد
  /// Deep Orange → Soft Purple
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFD35400), // Deep Orange
      Color(0xFFAF7AC5), // Soft Purple
    ],
  );

  /// Subtle Gradient - تدرج خفيف
  /// Gold → Orange
  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF39C12), // Golden Hour
      Color(0xFFE67E22), // Sunrise Orange
    ],
  );

  /// Card Gradient (Dark Mode) - تدرج البطاقات
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF252525)],
  );

  // ====================
  // SHADOW COLORS - ألوان الظلال
  // ====================

  /// Warm Shadow for brand elements
  static const Color shadowWarm = Color(0x33E67E22);

  /// Purple Glow for accents
  static const Color glowPurple = Color(0x449B59B6);

  /// Gold Glow for highlights
  static const Color glowGold = Color(0x44F39C12);
}
