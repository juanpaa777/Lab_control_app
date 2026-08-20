import 'package:flutter/material.dart';
import 'package:lab_control_app/config/theme/app_theme.dart';

enum CustomSnackbarType { success, error, info }

class CustomSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    CustomSnackbarType type = CustomSnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color bgColor;
    IconData iconData;

    switch (type) {
      case CustomSnackbarType.success:
        bgColor = AppTheme.available;
        iconData = Icons.check_circle_rounded;
        break;
      case CustomSnackbarType.error:
        bgColor = AppTheme.unavailable;
        iconData = Icons.error_outline_rounded;
        break;
      case CustomSnackbarType.info:
        bgColor = AppTheme.textPrimary;
        iconData = Icons.info_outline_rounded;
        break;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: Colors.white, size: 20),
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
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: duration,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, type: CustomSnackbarType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, type: CustomSnackbarType.error);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message: message, type: CustomSnackbarType.info);
  }
}
