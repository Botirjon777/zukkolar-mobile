import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/api/api_client.dart';
import '../../core/i18n/messages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/dialogs.dart';
import '../auth/auth.dart';
import 'chess_api.dart';
import 'chess_board.dart';
import 'chess_lobby_screen.dart';
import 'rules.dart';

/// The bot never answers faster than this — an instant reply doesn't feel like an opponent.
const _minThink = Duration(milliseconds: 600);

/// A game against a bot (`(focus)/chess/[id]`, `bot-game.tsx`). The board follows the rules by itself so a move
/// shows at once; the server checks it again, saves it and answers with the bot's move.
class ChessGameScreen extends ConsumerStatefulWidget {
  const ChessGameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<ChessGameScreen> createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends ConsumerState<ChessGameScreen> {
  ChessGame? _game;
  ChessBot? _bot;
  bool _loadFailed = false;

  /// Waiting for the server (the bot is "thinking").
  bool _waiting = false;

  /// The engine didn't answer: the bot still owes a move.
  bool _failed = false;
  String? _selected;
  ({String from, String to})? _promoting;
  bool _starting = false;

  /// The game was still going when it was opened — its end is then announced by scrolling to the result.
  bool _openedActive = false;
  final _resultKey = GlobalKey();

  ChessApi get _api => ref.read(chessApiProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final (game, lobby) = await (_api.game(widget.gameId), ref.read(chessLobbyProvider.future)).wait;
      if (!mounted) return;
      setState(() {
        _game = game;
        _bot = lobby.bot(game.bot) ?? ChessBot(key: game.bot, emoji: '♞', gradient: AppGradients.dark, elo: 0, paid: false, xp: 0);
        _openedActive = !game.isOver;
      });
      _askBotIfItsTurn();
    } on Object {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  /// Runs a request with the bot "thinking"; on failure the board goes back to [fallback].
  Future<void> _send(Future<({ChessGame game, bool botFailed})> Function() request, ChessGame fallback) async {
    setState(() => _waiting = true);
    final started = DateTime.now();
    ({ChessGame game, bool botFailed})? result;
    ApiException? problem;
    try {
      result = await request();
    } on ApiException catch (e) {
      problem = e;
    }
    final left = _minThink - DateTime.now().difference(started);
    if (left > Duration.zero) await Future<void>.delayed(left);
    if (!mounted) return;

    if (result == null) {
      setState(() {
        _waiting = false;
        _game = fallback;
        // No answer at all: the move may or may not have been saved — the retry asks the server.
        _failed = problem!.isNetwork;
      });
      showToast(context, problem!.isNetwork ? t('mobile.networkError') : t('chessBots.errors.${problem.error ?? 'generic'}'), error: true);
      if (problem.isNetwork) return;
      // Whatever the server holds is the truth.
      final fresh = await _api.game(widget.gameId).then<ChessGame?>((g) => g).catchError((_) => null);
      if (mounted && fresh != null) setState(() => _game = fresh);
      return;
    }

    final over = result.game.isOver;
    setState(() {
      _waiting = false;
      _game = result!.game;
      _failed = result.botFailed;
    });
    if (over) {
      HapticFeedback.mediumImpact();
      _showResult();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _askBotIfItsTurn() {
    final game = _game;
    if (game == null || game.isOver || _waiting) return;
    if (Position.replay(game.moves).turn == game.color) return;
    _send(() => _api.botMove(game.id), game);
  }

  void _commit(LegalMove move) {
    final game = _game!;
    HapticFeedback.selectionClick();
    setState(() {
      _selected = null;
      _promoting = null;
      // Shown at once; the server's answer replaces it.
      _game = game.withMove(move.uci);
    });
    _send(() => _api.move(game.id, move.uci), game);
  }

  void _onSquare(String square, Position position) {
    final game = _game!;
    final selected = _selected;
    if (selected != null && selected != square) {
      final options = position.legalMoves.where((m) => m.from == selected && m.to == square).toList();
      if (options.isNotEmpty) {
        if (options.any((m) => m.promotion != null)) {
          setState(() => _promoting = (from: selected, to: square));
        } else {
          _commit(options.first);
        }
        return;
      }
    }
    // Another piece of one's own → select it; anything else clears the selection.
    final own = position.pieceAt(square)?.startsWith(game.color) ?? false;
    setState(() => _selected = own && square != selected ? square : null);
  }

  void _showResult() {
    if (!_openedActive) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _resultKey.currentContext;
      if (target != null) Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 400), curve: Curves.easeOut, alignment: 0.1);
    });
  }

  Future<void> _resign(bool rated) async {
    final confirmed = await showConfirmDialog(
      context,
      title: t(rated ? 'chessBots.game.resignTitle' : 'chessBots.game.leaveTitle'),
      text: t(rated ? 'chessBots.game.resignText' : 'chessBots.game.leaveText'),
      confirmLabel: t(rated ? 'chessBots.game.resign' : 'chessBots.game.leave'),
    );
    if (!confirmed || !mounted) return;
    final game = _game!;
    await _send(() => _api.resign(game.id), game);
  }

  Future<void> _again() async {
    setState(() => _starting = true);
    try {
      final id = await _api.start(_game!.bot, 'random');
      if (mounted) context.pushReplacement('/chess/$id');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _starting = false);
      showToast(context, e.isNetwork ? t('mobile.networkError') : t('chessBots.errors.${e.error ?? 'generic'}'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    return Scaffold(
      body: SafeArea(
        child: game == null
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BackLink(label: t('chessBots.game.back')),
                    const Spacer(),
                    Center(
                      child: _loadFailed
                          ? AppButton(label: t('common.retry'), expand: false, onPressed: _load)
                          : const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.brand)),
                    ),
                    const Spacer(),
                  ],
                ),
              )
            : _body(game, _bot!),
      ),
    );
  }

  Widget _body(ChessGame game, ChessBot bot) {
    final user = ref.watch(authControllerProvider).value;
    final position = Position.replay(game.moves);
    final over = game.isOver;
    final myTurn = !over && position.turn == game.color;
    final name = botName(bot.key);

    final last = game.moves.lastOrNull;
    final tints = <String, SquareTint>{
      if (last != null) ...{last.substring(0, 2): SquareTint.last, last.substring(2, 4): SquareTint.last},
      if (position.inCheck && position.kingSquare != null) position.kingSquare!: SquareTint.check,
      ?_selected: SquareTint.selected,
    };
    final targets = <String, bool>{
      if (_selected != null)
        for (final move in position.legalMoves.where((m) => m.from == _selected)) move.to: move.isCapture,
    };
    final ownMoves = (game.moves.length + (game.color == 'w' ? 1 : 0)) ~/ 2;
    final rated = ownMoves >= 2;
    final playable = myTurn && !_waiting && _promoting == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BackLink(label: t('chessBots.game.back')),
              const SizedBox(height: 12),
              // The bot, above the board
              _PlayerRow(
                avatar: BotAvatar(bot: bot, size: 44),
                color: game.color == 'w' ? 'b' : 'w',
                name: name,
                elo: bot.elo,
                trailing: _waiting && !over
                    ? Text(
                        t('chessBots.game.thinking', {'bot': name}),
                        style: AppText.sm.copyWith(fontWeight: FontWeight.w600, color: AppColors.muted),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Stack(
                children: [
                  ChessBoard(
                    position: position,
                    flip: game.color == 'b',
                    tints: tints,
                    targets: targets,
                    onTap: playable ? (square) => _onSquare(square, position) : null,
                  ),
                  if (_promoting != null)
                    PromotionPicker(
                      side: game.color,
                      title: t('chess.promote'),
                      onPick: (piece) {
                        final move = position.legalMoves.where((m) => m.from == _promoting!.from && m.to == _promoting!.to && m.promotion == piece).firstOrNull;
                        if (move != null) _commit(move);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // The player, below the board
              _PlayerRow(
                avatar: user == null
                    ? const SizedBox(width: 44, height: 44)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Avatar(seed: user.avatarSeed, style: user.avatarStyle, gender: user.gender, size: 44),
                      ),
                color: game.color,
                name: user?.username ?? t('chessBots.game.you'),
                elo: game.elo,
                trailing: myTurn && !_waiting
                    ? Text(
                        t('chessBots.game.yourTurn'),
                        style: AppText.sm.copyWith(fontWeight: FontWeight.w600, color: AppColors.brand),
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              if (_failed && !over) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(t('chessBots.game.failed', {'bot': name}), style: AppText.sm.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        label: t('chessBots.game.retry'),
                        icon: LucideIcons.rotateCcw,
                        variant: AppButtonVariant.secondary,
                        expand: false,
                        onPressed: () {
                          setState(() => _failed = false);
                          _load();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (over) ...[_result(game), const SizedBox(height: 16)],
              _MoveList(san: position.san),
              if (!over) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    label: t(rated ? 'chessBots.game.resign' : 'chessBots.game.leave'),
                    icon: LucideIcons.flag,
                    variant: AppButtonVariant.danger,
                    expand: false,
                    onPressed: _waiting ? null : () => _resign(rated),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _result(ChessGame game) {
    final change = game.eloChange;
    final (background, color) = change == null || change == 0
        ? (AppColors.background, AppColors.muted)
        : change > 0
        ? (AppColors.success.withValues(alpha: 0.1), AppColors.success)
        : (AppColors.danger.withValues(alpha: 0.1), AppColors.danger);
    Widget chip(Color background, Widget child) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: child,
    );
    final bold = AppText.sm.copyWith(fontWeight: FontWeight.w700);

    return Container(
      key: _resultKey,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(t('chessBots.game.end.${game.status}'), textAlign: TextAlign.center, style: AppText.heading(AppText.xl)),
          if (game.endReason != null && game.status != 'ABORTED') ...[
            const SizedBox(height: 12),
            Text(
              t('chessBots.game.reasons.${game.endReason}'),
              textAlign: TextAlign.center,
              style: AppText.sm.copyWith(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              chip(
                background,
                Text(
                  change == null ? t('chessBots.game.notRated') : '${t('chessBots.game.rating', {'elo': game.elo})} (${change > 0 ? '+' : ''}$change)',
                  style: bold.copyWith(color: color),
                ),
              ),
              if (game.xpAwarded > 0)
                chip(
                  AppColors.xp.withValues(alpha: 0.1),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.zap, size: 16, color: AppColors.xp),
                      const SizedBox(width: 4),
                      Text(t('chessBots.game.xp', {'xp': game.xpAwarded}), style: bold.copyWith(color: AppColors.xp)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(label: t('chessBots.game.again'), onPressed: _starting ? null : _again),
          const SizedBox(height: 8),
          AppButton(
            label: t('chessBots.game.toBots'),
            variant: AppButtonVariant.secondary,
            onPressed: () => context.canPop() ? context.pop() : context.go('/chess'),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.avatar, required this.color, required this.name, required this.elo, this.trailing});

  final Widget avatar;
  final String color;
  final String name;
  final int elo;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        avatar,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ColorDot(color, size: 12),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.base.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              Text(
                t('chessBots.eloShort', {'elo': elo}),
                style: AppText.xs.copyWith(fontWeight: FontWeight.w500, color: AppColors.muted),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class _MoveList extends StatelessWidget {
  const _MoveList({required this.san});

  final List<String> san;

  @override
  Widget build(BuildContext context) {
    final mono = AppText.sm.copyWith(fontFamily: AppFonts.mono, fontWeight: FontWeight.w600);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('chessBots.game.moves'), style: AppText.heading(AppText.sm)),
          const SizedBox(height: 8),
          if (san.isEmpty)
            Text(t('chessBots.game.noMoves'), style: AppText.sm.copyWith(color: AppColors.muted))
          else
            for (var i = 0; i < san.length; i += 2)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text('${i ~/ 2 + 1}.', style: AppText.sm.copyWith(color: AppColors.muted)),
                    ),
                    Expanded(child: Text(san[i], style: mono)),
                    Expanded(child: Text(i + 1 < san.length ? san[i + 1] : '', style: mono)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
