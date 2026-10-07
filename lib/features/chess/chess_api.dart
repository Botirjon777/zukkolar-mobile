import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';

/// A bot as the lobby shows it (`/api/v1/chess`). Its name and description are text: `chessBots.bots.<key>`.
class ChessBot {
  const ChessBot({
    required this.key,
    required this.emoji,
    required this.gradient,
    required this.elo,
    required this.paid,
    required this.xp,
    this.locked = false,
    this.wins = 0,
    this.played = 0,
  });

  factory ChessBot.fromJson(Map<String, dynamic> json) => ChessBot(
    key: json['key'] as String,
    emoji: json['emoji'] as String,
    gradient: _gradients[json['gradient']] ?? AppGradients.brand,
    elo: (json['elo'] as num).toInt(),
    paid: json['paid'] as bool? ?? false,
    xp: (json['xp'] as num).toInt(),
    locked: json['locked'] as bool? ?? false,
    wins: (json['wins'] as num?)?.toInt() ?? 0,
    played: (json['played'] as num?)?.toInt() ?? 0,
  );

  /// The web names its gradients by their Tailwind utility.
  static const _gradients = <String, Gradient>{
    'bg-grad-brand': AppGradients.brand,
    'bg-grad-xp': AppGradients.xp,
    'bg-grad-streak': AppGradients.streak,
    'bg-grad-iq': AppGradients.iq,
    'bg-grad-success': AppGradients.success,
    'bg-grad-gold': AppGradients.gold,
    'bg-grad-silver': AppGradients.silver,
    'bg-grad-bronze': AppGradients.bronze,
    'bg-grad-dark': AppGradients.dark,
  };

  final String key;
  final String emoji;
  final Gradient gradient;
  final int elo;

  /// Needs Pro or Diamond; [locked] when the user doesn't have it.
  final bool paid;
  final bool locked;

  /// XP for a win.
  final int xp;
  final int wins;
  final int played;
}

class RecentGame {
  const RecentGame({required this.id, required this.bot, required this.status, required this.finishedAt, this.eloChange});

  factory RecentGame.fromJson(Map<String, dynamic> json) => RecentGame(
    id: json['id'] as String,
    bot: json['bot'] as String,
    status: json['status'] as String,
    eloChange: (json['eloChange'] as num?)?.toInt(),
    finishedAt: DateTime.parse(json['finishedAt'] as String),
  );

  final String id;
  final String bot;
  final String status;
  final int? eloChange;
  final DateTime finishedAt;
}

class ChessLobby {
  const ChessLobby({required this.elo, required this.games, required this.bots, required this.recent, this.activeId, this.activeBot});

  factory ChessLobby.fromJson(Map<String, dynamic> json) {
    final active = json['active'] as Map<String, dynamic>?;
    return ChessLobby(
      elo: (json['elo'] as num).toInt(),
      games: (json['games'] as num).toInt(),
      bots: [for (final bot in json['bots'] as List<dynamic>) ChessBot.fromJson(bot as Map<String, dynamic>)],
      recent: [for (final game in json['recent'] as List<dynamic>) RecentGame.fromJson(game as Map<String, dynamic>)],
      activeId: active?['id'] as String?,
      activeBot: active?['bot'] as String?,
    );
  }

  /// The user's rating and how many rated games stand behind it.
  final int elo;
  final int games;
  final List<ChessBot> bots;
  final List<RecentGame> recent;

  /// The unfinished game, if any.
  final String? activeId;
  final String? activeBot;

  ChessBot? bot(String key) => bots.where((b) => b.key == key).firstOrNull;
}

/// A game as the server holds it.
class ChessGame {
  const ChessGame({
    required this.id,
    required this.bot,
    required this.color,
    required this.moves,
    required this.status,
    required this.elo,
    this.endReason,
    this.eloChange,
    this.xpAwarded = 0,
  });

  factory ChessGame.fromJson(Map<String, dynamic> json) => ChessGame(
    id: json['id'] as String,
    bot: json['bot'] as String,
    color: json['color'] as String,
    moves: [for (final move in json['moves'] as List<dynamic>) move as String],
    status: json['status'] as String,
    endReason: json['endReason'] as String?,
    elo: (json['elo'] as num).toInt(),
    eloChange: (json['eloChange'] as num?)?.toInt(),
    xpAwarded: (json['xpAwarded'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String bot;

  /// The player's colour: "w" or "b".
  final String color;

  /// Every move from the starting position ("e2e4").
  final List<String> moves;

  /// ACTIVE, WON, LOST, DRAWN or ABORTED — from the player's side.
  final String status;
  final String? endReason;

  /// The player's rating now, and how this game moved it (null: still playing, or not rated).
  final int elo;
  final int? eloChange;
  final int xpAwarded;

  bool get isOver => status != 'ACTIVE';

  ChessGame withMove(String move) => ChessGame(
    id: id,
    bot: bot,
    color: color,
    moves: [...moves, move],
    status: status,
    endReason: endReason,
    elo: elo,
    eloChange: eloChange,
    xpAwarded: xpAwarded,
  );
}

/// Calls of `/api/v1/chess`. Failures are [ApiException]s whose `error` is a key under `chessBots.errors`.
class ChessApi {
  ChessApi(this._api);

  final ApiClient _api;

  Future<ChessLobby> lobby() async => ChessLobby.fromJson(await _api.get('/chess'));

  /// Starts a game and returns its id. When one is unfinished the [ApiException] carries no id — ask [lobby].
  Future<String> start(String bot, String color) async => (await _api.post('/chess/games', {'bot': bot, 'color': color}))['gameId'] as String;

  Future<ChessGame> game(String id) async => ChessGame.fromJson((await _api.get('/chess/games/$id'))['game'] as Map<String, dynamic>);

  /// The player's move; the answer carries the bot's reply. `botFailed`: the engine gave none — ask [botMove].
  Future<({ChessGame game, bool botFailed})> move(String id, String move) => _moved(_api.post('/chess/games/$id/move', {'move': move}));

  Future<({ChessGame game, bool botFailed})> botMove(String id) => _moved(_api.post('/chess/games/$id/bot-move'));

  Future<({ChessGame game, bool botFailed})> resign(String id) => _moved(_api.post('/chess/games/$id/resign'));

  Future<({ChessGame game, bool botFailed})> _moved(Future<Map<String, dynamic>> request) async {
    final data = await request;
    return (game: ChessGame.fromJson(data['game'] as Map<String, dynamic>), botFailed: data['botFailed'] as bool? ?? false);
  }
}

final chessApiProvider = Provider<ChessApi>((ref) => ChessApi(ref.watch(apiClientProvider)));

/// The lobby; invalidate to load it again (after a game, on pull to refresh).
final chessLobbyProvider = FutureProvider.autoDispose<ChessLobby>((ref) => ref.watch(chessApiProvider).lobby());
