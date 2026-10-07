import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'rules.dart';

/// Why a square is tinted (the web board's colours).
enum SquareTint { last, selected, check }

const _light = Color(0xFFF0D9B5);
const _dark = Color(0xFFB58863);
const _green = Color(0xFF14551E);

/// A chess board (`chess-board.tsx`). With [onTap] it is playable: the screen decides what a tap means.
class ChessBoard extends StatelessWidget {
  const ChessBoard({super.key, required this.position, this.flip = false, this.tints = const {}, this.targets = const {}, this.onTap});

  final Position position;

  /// Seen from Black's side.
  final bool flip;
  final Map<String, SquareTint> tints;

  /// Squares the selected piece can go to; `true` = it captures there.
  final Map<String, bool> targets;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final order = flip ? allSquares.reversed.toList() : allSquares;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.lg(Colors.black.withValues(alpha: 0.1))),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        ),
        child: GridView.count(
          crossAxisCount: 8,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: [for (final (at, square) in order.indexed) _square(at, square)],
        ),
      ),
    );
  }

  Widget _square(int at, String square) {
    final dark = isDarkSquare(square);
    final piece = position.pieceAt(square);
    final tint = tints[square];
    final label = AppText.tiny.copyWith(fontWeight: FontWeight.w700, color: dark ? _light : _dark);

    return Semantics(
      label: piece == null ? square : '$square, $piece',
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null ? null : () => onTap!(square),
        child: ColoredBox(
          color: dark ? _dark : _light,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (tint == SquareTint.check)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(colors: [Color(0xFFFF0000), Color(0xFFE70000), Color(0x00A90000)], stops: [0, 0.25, 0.85]),
                  ),
                )
              else if (tint != null)
                ColoredBox(color: tint == SquareTint.last ? const Color(0x739BC700) : _green.withValues(alpha: 0.5)),
              // Coordinates: ranks down the left edge, files along the bottom (the square already says its name aloud).
              if (at % 8 == 0)
                Positioned(
                  left: 2,
                  top: 0,
                  child: ExcludeSemantics(child: Text(square[1], style: label)),
                ),
              if (at >= 56)
                Positioned(
                  right: 2,
                  bottom: 0,
                  child: ExcludeSemantics(child: Text(square[0], style: label)),
                ),
              if (piece != null) SvgPicture.asset('assets/chess/pieces/$piece.svg'),
              if (targets.containsKey(square))
                targets[square]!
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _green.withValues(alpha: 0.45), width: 5),
                        ),
                      )
                    : FractionallySizedBox(
                        widthFactor: 0.3,
                        heightFactor: 0.3,
                        child: DecoratedBox(
                          decoration: BoxDecoration(shape: BoxShape.circle, color: _green.withValues(alpha: 0.45)),
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Over the board when a pawn reaches the last rank: which piece should it become?
class PromotionPicker extends StatelessWidget {
  const PromotionPicker({super.key, required this.side, required this.title, required this.onPick});

  /// "w" or "b".
  final String side;
  final String title;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppText.sm.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final piece in const ['q', 'r', 'b', 'n'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => onPick(piece),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _light,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border, width: 2),
                          ),
                          child: SvgPicture.asset('assets/chess/pieces/$side${piece.toUpperCase()}.svg'),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
