import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config.dart';
import '../theme/app_colors.dart';

/// A user's avatar. The web app draws these with DiceBear (`lib/avatar.ts`, with its own per-gender rules),
/// so the app asks the backend for the same SVG instead of re-implementing the generator.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.seed,
    this.style,
    this.gender,
    this.size = 40,
    this.ringColor,
    this.ringWidth = 0,
  });

  final String seed;
  final String? style;
  final String? gender;
  final double size;
  final Color? ringColor;
  final double ringWidth;

  /// Tests swap the network for a bundled SVG.
  @visibleForTesting
  static BytesLoader Function(String url)? debugLoader;

  static String url(String seed, {String? style, String? gender}) {
    final query = Uri(
      queryParameters: {'seed': seed, 'style': ?style, 'gender': ?gender},
    ).query;
    return '${AppConfig.apiBaseUrl}/api/v1/avatar?$query';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
      ),
      foregroundDecoration: ringWidth > 0
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ringColor ?? AppColors.border,
                width: ringWidth,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            )
          : null,
      child: SvgPicture(
        (debugLoader ?? SvgNetworkLoader.new)(
          url(seed, style: style, gender: gender),
        ),
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => const SizedBox.shrink(),
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
