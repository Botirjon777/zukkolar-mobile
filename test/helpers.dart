import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zukkolar/app.dart';
import 'package:zukkolar/core/i18n/messages.dart';
import 'package:zukkolar/core/theme/app_colors.dart';
import 'package:zukkolar/core/widgets/avatar.dart';
import 'package:zukkolar/features/auth/auth.dart';
import 'package:zukkolar/features/chess/chess_api.dart';
import 'package:zukkolar/features/chess/rules.dart';

/// Real fonts (text, icons) and real strings, so tests see what users see.
Future<void> loadAppAssets() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    for (final font in (family['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
  await Messages.load();
  // Avatars come from the backend; tests draw one the web app's generator produced.
  final svg = File('test/fixtures/avatar-adventurer.svg').readAsStringSync();
  Avatar.debugLoader = (_) => SvgStringLoader(svg);
}

/// Auth state without a backend: starts as [user] (null = signed out).
class FakeAuthController extends AuthController {
  FakeAuthController(this.user);

  final User? user;

  @override
  Future<User?> build() async => user;

  @override
  Future<void> logout() async => state = const AsyncData(null);
}

const testUser = User(id: 'u1', username: 'ali', avatarSeed: 'ali', level: 3, xp: 120, plan: 'FREE', gender: 'MALE');

/// The whole app on an iPhone-sized screen.
Future<void> pumpApp(WidgetTester tester, {User? user, FakeChessApi? chess}) async {
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => FakeAuthController(user)), chessApiProvider.overrideWithValue(chess ?? FakeChessApi())],
      child: const ZukkolarApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Taps the "sign up" link under the login form — the last words of a centred line of rich text.
Future<void> tapRegisterLink(WidgetTester tester) async {
  final line = find.textContaining(t('auth.noAccount'), findRichText: true);
  await tester.ensureVisible(line);
  await tester.tapAt(tester.getBottomRight(line) - const Offset(24, 8));
}

/// The chess server in memory: one game at a time, and a bot that always plays its first legal move.
class FakeChessApi implements ChessApi {
  static const bots = [
    ChessBot(key: 'quyon', emoji: 'Q', gradient: AppGradients.success, elo: 800, paid: false, xp: 10),
    ChessBot(key: 'ajdar', emoji: 'A', gradient: AppGradients.dark, elo: 2850, paid: true, xp: 60, locked: true),
  ];

  ChessGame? current;
  int elo = 800;
  final List<RecentGame> recent = [];

  @override
  Future<ChessLobby> lobby() async => ChessLobby(
    elo: elo,
    games: recent.length,
    bots: bots,
    recent: recent,
    activeId: current?.isOver == false ? current!.id : null,
    activeBot: current?.isOver == false ? current!.bot : null,
  );

  @override
  Future<String> start(String bot, String color) async {
    current = ChessGame(id: 'g${recent.length + 1}', bot: bot, color: color == 'random' ? 'w' : color, moves: const [], status: 'ACTIVE', elo: elo);
    return current!.id;
  }

  @override
  Future<ChessGame> game(String id) async => current!;

  @override
  Future<({ChessGame game, bool botFailed})> move(String id, String move) async {
    current = current!.withMove(move);
    return botMove(id);
  }

  @override
  Future<({ChessGame game, bool botFailed})> botMove(String id) async {
    final reply = Position.replay(current!.moves).legalMoves.first.uci;
    current = current!.withMove(reply);
    return (game: current!, botFailed: false);
  }

  @override
  Future<({ChessGame game, bool botFailed})> resign(String id) async {
    elo -= 20;
    final g = current!;
    current = ChessGame(id: g.id, bot: g.bot, color: g.color, moves: g.moves, status: 'LOST', endReason: 'resign', elo: elo, eloChange: -20);
    recent.insert(0, RecentGame(id: g.id, bot: g.bot, status: 'LOST', eloChange: -20, finishedAt: DateTime.utc(2026, 10, 6, 12)));
    return (game: current!, botFailed: false);
  }
}
