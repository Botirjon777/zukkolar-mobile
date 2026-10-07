import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/api/api_client.dart';
import '../../core/i18n/messages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/dialogs.dart';
import 'chess_api.dart';

/// A bot's face: its animal on its colour.
class BotAvatar extends StatelessWidget {
  const BotAvatar({super.key, required this.bot, this.size = 56});

  final ChessBot bot;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(gradient: bot.gradient, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.lg(Colors.black.withValues(alpha: 0.1))),
      child: ExcludeSemantics(
        child: Text(bot.emoji, style: TextStyle(fontSize: size * 0.54, height: 1.1)),
      ),
    );
  }
}

/// The dot that stands for a colour: white or black.
class ColorDot extends StatelessWidget {
  const ColorDot(this.color, {super.key, this.size = 14});

  final String color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color == 'w' ? Colors.white : const Color(0xFF222222),
      border: Border.all(color: Colors.black.withValues(alpha: 0.3)),
    ),
  );
}

String botName(String key) => Messages.instance.has('chessBots.bots.$key.name') ? t('chessBots.bots.$key.name') : key;

/// "6-oktabr", in Tashkent time (UTC+5).
String shortDate(DateTime at) {
  final day = at.toUtc().add(const Duration(hours: 5));
  return t('time.date', {'day': day.day, 'month': t('time.months.${day.month - 1}')});
}

/// Chess against the bots (`(app)/chess/page.tsx`): the rating, the opponents, the open game, the last results.
class ChessLobbyScreen extends ConsumerStatefulWidget {
  const ChessLobbyScreen({super.key});

  @override
  ConsumerState<ChessLobbyScreen> createState() => _ChessLobbyScreenState();
}

class _ChessLobbyScreenState extends ConsumerState<ChessLobbyScreen> {
  /// The bot a game is being started against.
  String? _starting;

  Future<void> _open(String gameId) async {
    await context.push('/chess/$gameId');
    // Back from a game: the rating, the results and the open game may all have changed.
    ref.invalidate(chessLobbyProvider);
  }

  Future<void> _start(ChessBot bot, String color) async {
    if (_starting != null) return;
    setState(() => _starting = bot.key);
    try {
      final id = await ref.read(chessApiProvider).start(bot.key, color);
      if (mounted) await _open(id);
    } on ApiException catch (e) {
      if (!mounted) return;
      showToast(context, e.isNetwork ? t('mobile.networkError') : t('chessBots.errors.${e.error ?? 'generic'}'), error: true);
      ref.invalidate(chessLobbyProvider);
    } finally {
      if (mounted) setState(() => _starting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lobby = ref.watch(chessLobbyProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () => ref.refresh(chessLobbyProvider.future),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(context).bottom),
            children: [
              const BackLink(),
              const SizedBox(height: 12),
              Text(t('chessBots.title'), style: AppText.heading(AppText.xl2, tight: true)),
              const SizedBox(height: 6),
              Text(t('chessBots.subtitle'), style: AppText.base.copyWith(color: AppColors.muted)),
              const SizedBox(height: 24),
              ...lobby.when(
                skipLoadingOnRefresh: true,
                loading: () => [
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.brand)),
                    ),
                  ),
                ],
                error: (error, _) => [
                  Text(
                    error is ApiException && !error.isNetwork ? t('mobile.serverError') : t('mobile.networkError'),
                    style: AppText.sm.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  AppButton(label: t('common.retry'), expand: false, onPressed: () => ref.invalidate(chessLobbyProvider)),
                ],
                data: _content,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(ChessLobby lobby) {
    final hasOpenGame = lobby.activeId != null;
    return [
      _RatingCard(lobby: lobby),
      if (hasOpenGame) ...[
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('chessBots.continue.title'), style: AppText.base.copyWith(fontWeight: FontWeight.w700)),
              Text(t('chessBots.continue.text', {'bot': botName(lobby.activeBot!)}), style: AppText.sm.copyWith(color: AppColors.muted)),
              const SizedBox(height: 12),
              AppButton(label: t('chessBots.continue.cta'), icon: LucideIcons.arrowRight, onPressed: () => _open(lobby.activeId!)),
            ],
          ),
        ),
      ],
      const SizedBox(height: 24),
      Text(t('chessBots.chooseBot'), style: AppText.heading(AppText.sm)),
      const SizedBox(height: 12),
      for (final bot in lobby.bots) ...[
        _BotCard(bot: bot, disabled: hasOpenGame || _starting != null, onStart: (color) => _start(bot, color)),
        const SizedBox(height: 12),
      ],
      if (hasOpenGame) Text(t('chessBots.finishFirst'), style: AppText.sm.copyWith(color: AppColors.muted)),
      if (lobby.recent.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(t('chessBots.recent'), style: AppText.heading(AppText.sm)),
        const SizedBox(height: 12),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (final (index, game) in lobby.recent.indexed) ...[
                if (index > 0) const Divider(height: 1, thickness: 1, color: AppColors.border),
                _RecentRow(game: game, bot: lobby.bot(game.bot), onTap: () => _open(game.id)),
              ],
            ],
          ),
        ),
      ],
    ];
  }
}

/// "← Back" at the top of a screen opened over the tabs.
class BackLink extends StatelessWidget {
  const BackLink({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.arrowLeft, size: 16, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                label ?? t('chat.back'),
                style: AppText.sm.copyWith(fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.lobby});

  final ChessLobby lobby;

  @override
  Widget build(BuildContext context) {
    final soft = Colors.white.withValues(alpha: 0.7);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.dark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.lg(AppColors.brand.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(LucideIcons.chessKnight, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('chessBots.elo'),
                  style: AppText.sm.copyWith(fontWeight: FontWeight.w500, color: soft),
                ),
                Text('${lobby.elo}', style: AppText.heading(AppText.xl3).copyWith(color: Colors.white)),
                Text(lobby.games > 0 ? t('chessBots.gamesPlayed', {'count': lobby.games}) : t('chessBots.noGames'), style: AppText.sm.copyWith(color: soft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotCard extends StatelessWidget {
  const _BotCard({required this.bot, required this.disabled, required this.onStart});

  final ChessBot bot;
  final bool disabled;
  final ValueChanged<String> onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BotAvatar(bot: bot),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(botName(bot.key), style: AppText.heading(AppText.lg))),
                        if (bot.paid) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(gradient: AppGradients.gold, borderRadius: BorderRadius.circular(999)),
                            child: Text(
                              t('chessBots.paidBadge'),
                              style: AppText.tab.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF7C2D12)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      t('chessBots.eloShort', {'elo': bot.elo}),
                      style: AppText.sm.copyWith(fontWeight: FontWeight.w600, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(t('chessBots.bots.${bot.key}.text'), style: AppText.sm.copyWith(color: AppColors.muted)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.zap, size: 14, color: AppColors.xp),
                  const SizedBox(width: 4),
                  Text(
                    t('chessBots.xpWin', {'xp': bot.xp}),
                    style: AppText.xs.copyWith(fontWeight: FontWeight.w600, color: AppColors.xp),
                  ),
                ],
              ),
              if (bot.played > 0)
                Text(
                  t('chessBots.record', {'wins': bot.wins, 'played': bot.played}),
                  style: AppText.xs.copyWith(fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (bot.locked)
            Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.lock, size: 16, color: AppColors.muted),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      t('chessBots.locked'),
                      style: AppText.sm.copyWith(fontWeight: FontWeight.w600, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            )
          else
            Semantics(
              label: t('chessBots.playAs'),
              child: Row(
                children: [
                  for (final (index, color) in const ['w', 'random', 'b'].indexed) ...[
                    if (index > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _ColorButton(color: color, onTap: disabled ? null : () => onStart(color)),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "White", "Random", "Black" under a bot — pressing one starts the game. 44 px tall: a comfortable tap target.
class _ColorButton extends StatelessWidget {
  const _ColorButton({required this.color, required this.onTap});

  final String color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.6 : 1,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (color == 'random') const Icon(LucideIcons.shuffle, size: 16, color: AppColors.muted) else ColorDot(color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    t('chessBots.colors.$color'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sm.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.game, required this.bot, required this.onTap});

  final RecentGame game;
  final ChessBot? bot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (background, color) = switch (game.status) {
      'WON' => (AppColors.success.withValues(alpha: 0.1), AppColors.success),
      'LOST' => (AppColors.danger.withValues(alpha: 0.1), AppColors.danger),
      _ => (AppColors.background, AppColors.muted),
    };
    final change = game.eloChange;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (bot != null) ...[BotAvatar(bot: bot!, size: 40), const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(botName(game.bot), style: AppText.base.copyWith(fontWeight: FontWeight.w600)),
                  Text(shortDate(game.finishedAt), style: AppText.sm.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
            if (change != null) ...[
              Text(
                '${change > 0 ? '+' : ''}$change',
                style: AppText.sm.copyWith(fontWeight: FontWeight.w700, color: AppColors.muted),
              ),
              const SizedBox(width: 12),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
              child: Text(
                t('chessBots.results.${game.status}'),
                style: AppText.xs.copyWith(fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
