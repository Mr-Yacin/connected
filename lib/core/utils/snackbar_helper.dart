import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Centralized snackbar helper with type-specific methods
/// Provides consistent snackbar styling across the app
class SnackbarHelper {
  SnackbarHelper._();

  /// Show a success snackbar
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_rounded,
      iconColor: Colors.white,
      duration: duration,
      action: action,
    );
  }

  /// Show an error snackbar
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message,
      backgroundColor: AppColors.error,
      icon: Icons.error_rounded,
      iconColor: Colors.white,
      duration: duration,
      action: action,
    );
  }

  /// Show a warning snackbar
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_rounded,
      iconColor: Colors.white,
      duration: duration,
      action: action,
    );
  }

  /// Show an info snackbar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message,
      backgroundColor: AppColors.info,
      icon: Icons.info_rounded,
      iconColor: Colors.white,
      duration: duration,
      action: action,
    );
  }

  /// Show a neutral/default snackbar (uses theme styling)
  static void showMessage(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
      ),
    );
  }

  /// Base method for showing snackbars with custom styling
  static void _showSnackbar(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: action,
      ),
    );
  }
}
