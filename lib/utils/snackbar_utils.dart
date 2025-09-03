import 'package:flutter/material.dart';
import '../config/theme.dart';

class SnackBarUtils {
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: AppTheme.successGreen,
      icon: Icons.check_circle,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: AppTheme.errorColor,
      icon: Icons.error,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: AppTheme.warningAmber,
      icon: Icons.warning,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
      duration: duration,
    );
  }

  static void showFavoriteAdded(BuildContext context) {
    _showSnackBar(
      context,
      'Added to favorites',
      backgroundColor: AppTheme.successGreen,
      icon: Icons.favorite,
      duration: const Duration(seconds: 2),
    );
  }

  static void showFavoriteRemoved(BuildContext context) {
    _showSnackBar(
      context,
      'Removed from favorites',
      backgroundColor: Colors.red,
      icon: Icons.favorite_border,
      duration: const Duration(seconds: 2),
    );
  }

  static void showEntryDeleted(BuildContext context) {
    _showSnackBar(
      context,
      'Journal entry deleted',
      backgroundColor: Colors.red,
      icon: Icons.delete,
      duration: const Duration(seconds: 2),
    );
  }

  static void showEntrySaved(BuildContext context) {
    _showSnackBar(
      context,
      'Journal entry saved successfully!',
      backgroundColor: AppTheme.successGreen,
      icon: Icons.save,
      duration: const Duration(seconds: 2),
    );
  }

  static void showTitleUpdated(BuildContext context) {
    _showSnackBar(
      context,
      'Title updated successfully',
      backgroundColor: AppTheme.successGreen,
      icon: Icons.edit,
      duration: const Duration(seconds: 2),
    );
  }

  static void showNotesSaved(BuildContext context) {
    _showSnackBar(
      context,
      'Notes saved successfully',
      backgroundColor: AppTheme.successGreen,
      icon: Icons.notes,
      duration: const Duration(seconds: 2),
    );
  }

  static void showNotesAutoSaved(BuildContext context) {
    _showSnackBar(
      context,
      'Notes saved automatically',
      backgroundColor: AppTheme.successGreen,
      icon: Icons.auto_awesome,
      duration: const Duration(seconds: 1),
    );
  }

  static void _showSnackBar(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        duration: duration,
      ),
    );
  }
}
