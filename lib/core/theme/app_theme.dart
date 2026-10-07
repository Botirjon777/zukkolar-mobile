import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Font families bundled in `assets/fonts` — the web app's `font-sans`, `font-display`, `font-mono`.
abstract final class AppFonts {
  static const sans = 'Onest';
  static const display = 'Unbounded';
  static const mono = 'JetBrainsMono';
}

/// Tailwind's type scale (size / line height), so screens can be ported class by class.
abstract final class AppText {
  static const _base = TextStyle(fontFamily: AppFonts.sans, color: AppColors.foreground);

  /// `text-[10px]` / `text-[11px]` — badges and tab labels.
  static final tiny = _base.copyWith(fontSize: 10, height: 1.2);
  static final tab = _base.copyWith(fontSize: 11, height: 16.5 / 11);
  static final xs = _base.copyWith(fontSize: 12, height: 16 / 12);
  static final sm = _base.copyWith(fontSize: 14, height: 20 / 14);
  static final base = _base.copyWith(fontSize: 16, height: 24 / 16);
  static final lg = _base.copyWith(fontSize: 18, height: 28 / 18);
  static final xl = _base.copyWith(fontSize: 20, height: 28 / 20);
  static final xl2 = _base.copyWith(fontSize: 24, height: 32 / 24);
  static final xl3 = _base.copyWith(fontSize: 30, height: 36 / 30);

  /// `h1`–`h3`: display font, `letter-spacing: -0.01em`. Pass `tight: true` for `tracking-tight`.
  static TextStyle heading(TextStyle size, {FontWeight weight = FontWeight.w700, bool tight = false}) =>
      size.copyWith(fontFamily: AppFonts.display, fontWeight: weight, letterSpacing: (size.fontSize ?? 16) * (tight ? -0.025 : -0.01));
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.brand).copyWith(
    primary: AppColors.brand,
    onPrimary: AppColors.brandForeground,
    secondary: AppColors.brand2,
    surface: AppColors.surface,
    onSurface: AppColors.foreground,
    error: AppColors.danger,
    outline: AppColors.border,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppFonts.sans,
    // The page background is painted by AppBackground (two soft brand glows over --background).
    scaffoldBackgroundColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textTheme: TextTheme(bodyLarge: AppText.base, bodyMedium: AppText.sm, bodySmall: AppText.xs),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.brand,
      selectionColor: AppColors.brand.withValues(alpha: 0.2),
      selectionHandleColor: AppColors.brand,
    ),
  );
}
