import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost, danger, success }

/// The web app's `Button` (`components/ui/button.tsx`): 44 px tall, rounded-xl, text-sm semibold.
class AppButton extends StatefulWidget {
  const AppButton({super.key, required this.label, required this.onPressed, this.variant = AppButtonVariant.primary, this.icon, this.expand = true});

  final String label;

  /// Null disables the button (60 % opacity, like `disabled:opacity-60`).
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final (decoration, color) = _style(widget.variant, _pressed);

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: Opacity(
          opacity: enabled ? 1 : 0.6,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            // active:translate-y-px
            transform: Matrix4.translationValues(0, _pressed ? 1 : 0, 0),
            decoration: decoration,
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[Icon(widget.icon, size: 16, color: color), const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sm.copyWith(fontWeight: FontWeight.w600, color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static (BoxDecoration, Color) _style(AppButtonVariant variant, bool pressed) {
    final radius = BorderRadius.circular(12);
    switch (variant) {
      case AppButtonVariant.primary:
        return (
          BoxDecoration(
            gradient: AppGradients.brand,
            borderRadius: radius,
            boxShadow: AppShadows.lg(AppColors.brand.withValues(alpha: pressed ? 0.3 : 0.25)),
          ),
          AppColors.brandForeground,
        );
      case AppButtonVariant.success:
        return (
          BoxDecoration(gradient: AppGradients.success, borderRadius: radius, boxShadow: AppShadows.lg(AppColors.success.withValues(alpha: 0.25))),
          Colors.white,
        );
      case AppButtonVariant.secondary:
        return (
          BoxDecoration(
            color: pressed ? AppColors.background : AppColors.surface,
            borderRadius: radius,
            border: Border.all(color: pressed ? AppColors.brand.withValues(alpha: 0.4) : AppColors.border),
          ),
          AppColors.foreground,
        );
      case AppButtonVariant.ghost:
        return (BoxDecoration(color: pressed ? AppColors.surface : null, borderRadius: radius), pressed ? AppColors.foreground : AppColors.muted);
      case AppButtonVariant.danger:
        return (
          BoxDecoration(
            color: pressed ? AppColors.danger.withValues(alpha: 0.1) : null,
            borderRadius: radius,
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
          ),
          AppColors.danger,
        );
    }
  }
}
