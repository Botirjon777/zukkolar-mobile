import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The page background from `globals.css` (`body`): --background with two soft glows at the top corners,
/// fixed while content scrolls.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: const _BackgroundPainter(), child: child);
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);
    // radial-gradient(900px 500px at 100% -10%, brand-2 10%, transparent 70%)
    _glow(canvas, Offset(size.width, -0.1 * size.height), 900, 500, AppColors.brand2);
    // radial-gradient(800px 500px at -10% 0%, brand 10%, transparent 70%)
    _glow(canvas, Offset(-0.1 * size.width, 0), 800, 500, AppColors.brand);
  }

  void _glow(Canvas canvas, Offset center, double rx, double ry, Color color) {
    final shader = RadialGradient(
      colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0)],
      stops: const [0, 0.7],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: rx));
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(1, ry / rx)
      ..drawCircle(Offset.zero, rx, Paint()..shader = shader)
      ..restore();
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => false;
}
