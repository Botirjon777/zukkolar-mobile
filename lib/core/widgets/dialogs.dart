import 'package:flutter/material.dart';
import '../i18n/messages.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// The web's small centred confirm box (`dialog.modal`, `ConfirmButton`). True when confirmed.
Future<bool> showConfirmDialog(BuildContext context, {required String title, String? text, required String confirmLabel}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (context) => Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 352),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.heading(AppText.lg)),
              if (text != null) ...[const SizedBox(height: 8), Text(text, style: AppText.sm.copyWith(color: AppColors.muted))],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(label: t('common.cancel'), variant: AppButtonVariant.secondary, onPressed: () => Navigator.pop(context, false)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(label: confirmLabel, variant: AppButtonVariant.danger, onPressed: () => Navigator.pop(context, true)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return confirmed ?? false;
}

/// A short message at the bottom of the screen (the web's toast).
void showToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.danger : AppColors.foreground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          message,
          style: AppText.sm.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
}
