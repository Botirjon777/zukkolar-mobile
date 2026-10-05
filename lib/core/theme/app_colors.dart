import 'package:flutter/painting.dart';

/// Brand tokens — the same values as `:root` in the web app's `globals.css`.
abstract final class AppColors {
  static const background = Color(0xFFF6F5FB);
  static const foreground = Color(0xFF14122B);
  static const surface = Color(0xFFFFFFFF);
  static const muted = Color(0xFF6B6883);
  static const border = Color(0xFFE7E4F2);
  static const brand = Color(0xFF6D4AFF);
  static const brand2 = Color(0xFFD946EF);
  static const brandForeground = Color(0xFFFFFFFF);
  static const xp = Color(0xFFF59E0B);
  static const streak = Color(0xFFFF6A2B);
  static const success = Color(0xFF12B76A);
  static const danger = Color(0xFFE5484D);

  /// Backdrop behind dialogs and drawers: `rgb(15 10 40 / 0.45)`.
  static const scrim = Color(0x730F0A28);
}

/// `--grad-*` from `globals.css` (all are `linear-gradient(135deg, a 0%, b 100%)`).
abstract final class AppGradients {
  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand, AppColors.brand2],
  );
  static const xp = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
  );
  static const streak = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFB923C), Color(0xFFEF4444)],
  );
  static const iq = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22D3EE), Color(0xFF6366F1)],
  );
  static const success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF059669)],
  );
  static const gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
  );
  static const silver = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF1F5F9), Color(0xFF94A3B8)],
  );
  static const bronze = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFED7AA), Color(0xFFC2410C)],
  );
  static const dark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1B4B), Color(0xFF3B0764)],
  );
}

/// Tailwind's box shadows, tinted like `shadow-lg shadow-brand/25`.
abstract final class AppShadows {
  static List<BoxShadow> lg(Color color) => [
    BoxShadow(
      color: color,
      offset: const Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: color,
      offset: const Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> xl(Color color) => [
    BoxShadow(
      color: color,
      offset: const Offset(0, 20),
      blurRadius: 25,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: color,
      offset: const Offset(0, 8),
      blurRadius: 10,
      spreadRadius: -6,
    ),
  ];
}
