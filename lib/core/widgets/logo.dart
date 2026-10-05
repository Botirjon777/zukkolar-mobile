import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Emblem only (book, brain, pencil, cap).
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/logo-mark-192.webp',
    width: size,
    height: size,
    filterQuality: FilterQuality.medium,
    excludeFromSemantics: true,
  );
}

/// Emblem + name in the brand gradient.
class Logo extends StatelessWidget {
  const Logo({super.key, this.name = 'Zukkolar'});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LogoMark(),
        const SizedBox(width: 8),
        GradientText(name, style: AppText.heading(AppText.xl, tight: true)),
      ],
    );
  }
}

/// The full logo (emblem with the ZUKKOLAR wordmark).
class LogoFull extends StatelessWidget {
  const LogoFull({super.key, this.width = 144});

  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/logo-full-320.webp',
    width: width,
    semanticLabel: 'Zukkolar',
  );
}

/// `text-grad-brand`: text filled with a gradient.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient = AppGradients.brand,
  });

  final String text;
  final TextStyle style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          gradient.createShader(Offset.zero & bounds.size),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}
