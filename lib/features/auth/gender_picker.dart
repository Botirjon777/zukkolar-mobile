import 'package:flutter/material.dart';
import '../../core/i18n/messages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/avatar.dart';

/// Two big cards with an avatar preview for each gender (`gender-picker.tsx`).
class GenderPicker extends StatelessWidget {
  const GenderPicker({
    super.key,
    required this.seed,
    required this.value,
    required this.onChanged,
    required this.label,
    this.hint,
    this.error,
  });

  /// Drives the preview; the backend picks the style a new account with this username would get.
  final String seed;

  /// `MALE`, `FEMALE` or null.
  final String? value;
  final ValueChanged<String> onChanged;
  final String label;
  final String? hint;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.sm.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _card('MALE', t('auth.male'))),
            const SizedBox(width: 12),
            Expanded(child: _card('FEMALE', t('auth.female'))),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error!, style: AppText.sm.copyWith(color: AppColors.danger)),
        ] else if (hint != null) ...[
          const SizedBox(height: 6),
          Text(hint!, style: AppText.xs.copyWith(color: AppColors.muted)),
        ],
      ],
    );
  }

  Widget _card(String gender, String text) {
    final active = value == gender;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: active,
      child: GestureDetector(
        onTap: () => onChanged(gender),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active
                ? Color.alphaBlend(
                    AppColors.brand.withValues(alpha: 0.05),
                    AppColors.surface,
                  )
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? AppColors.brand : AppColors.border,
              width: 2,
            ),
            boxShadow: active
                ? AppShadows.lg(AppColors.brand.withValues(alpha: 0.1))
                : null,
          ),
          child: Column(
            children: [
              Avatar(
                key: ValueKey('$seed|$gender'),
                seed: seed,
                gender: gender,
                size: 64,
              ),
              const SizedBox(height: 8),
              Text(
                text,
                textAlign: TextAlign.center,
                style: AppText.sm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.brand : AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
