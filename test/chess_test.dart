import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zukkolar/core/i18n/messages.dart';
import 'package:zukkolar/features/chess/chess_board.dart';
import 'package:zukkolar/features/chess/chess_game_screen.dart';
import 'package:zukkolar/features/chess/chess_lobby_screen.dart';
import 'package:zukkolar/features/chess/rules.dart';
import 'helpers.dart';

void main() {
  setUpAll(loadAppAssets);

  group('rules', () {
    test('rebuilds a game from its moves, with notation', () {
      final position = Position.replay(['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'g8f6', 'e1g1']);
      expect(position.san, ['e4', 'e5', 'Nf3', 'Nc6', 'Bc4', 'Nf6', 'O-O']);
      expect(position.turn, 'b');
      expect(position.pieceAt('g1'), 'wK');
      expect(position.pieceAt('e2'), isNull);
      expect(position.kingSquare, 'e8');
    });

    test('knows where a piece may go, promotions and checks included', () {
      final start = Position.replay([]);
      expect(start.legalMoves.where((m) => m.from == 'e2').map((m) => m.to), ['e3', 'e4']);

      final promoting = Position.replay(['e2e4', 'd7d5', 'e4d5', 'c7c6', 'd5c6', 'a7a6', 'c6b7', 'a6a5']);
      final options = promoting.legalMoves.where((m) => m.from == 'b7' && m.to == 'a8').toList();
      expect(options.map((m) => m.uci).toSet(), {'b7a8q', 'b7a8r', 'b7a8b', 'b7a8n'});
      expect(options.every((m) => m.isCapture), isTrue);

      // Fool's mate: Black's queen gives mate on h4.
      final mated = Position.replay(['f2f3', 'e7e5', 'g2g4', 'd8h4']);
      expect(mated.inCheck, isTrue);
      expect(mated.legalMoves, isEmpty);
    });

    test('draws the board from a8 to h1; a1 is dark', () {
      expect(allSquares.first, 'a8');
      expect(allSquares.last, 'h1');
      expect(isDarkSquare('a1'), isTrue);
      expect(isDarkSquare('h1'), isFalse);
    });
  });

  testWidgets('profile menu → chess → a game: move, the bot answers, give up', (tester) async {
    final server = FakeChessApi();
    await pumpApp(tester, user: testUser, chess: server);

    await tester.tap(find.bySemanticsLabel(t('nav.profileMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t('nav.chess')));
    await tester.pumpAndSettle();
    expect(find.byType(ChessLobbyScreen), findsOneWidget);
    expect(find.text('800'), findsOneWidget);
    // The paid bot is locked for this user: one row of colour buttons, one lock.
    expect(find.text(t('chessBots.colors.w')), findsOneWidget);
    expect(find.text(t('chessBots.locked')), findsOneWidget);

    await tester.tap(find.text(t('chessBots.colors.w')));
    await tester.pumpAndSettle();
    expect(find.byType(ChessGameScreen), findsOneWidget);
    expect(find.text(t('chessBots.game.yourTurn')), findsOneWidget);

    // e2 → e4; the bot is "thinking", then its move is on the board.
    await tester.tap(find.bySemanticsLabel('e2, wP'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('e4'));
    await tester.pump();
    expect(find.text(t('chessBots.game.thinking', {'bot': t('chessBots.bots.quyon.name')})), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(server.current!.moves.length, 2);
    expect(find.text('e4'), findsOneWidget);
    expect(find.text(t('chessBots.game.yourTurn')), findsOneWidget);

    // A tap on a square the piece can't reach only clears the selection.
    await tester.tap(find.bySemanticsLabel('d2, wP'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('d6'));
    await tester.pump();
    expect(server.current!.moves.length, 2);

    // One own move so far → leaving is offered, not a rated loss.
    await tester.ensureVisible(find.text(t('chessBots.game.leave')));
    await tester.tap(find.text(t('chessBots.game.leave')));
    await tester.pumpAndSettle();
    expect(find.text(t('chessBots.game.leaveTitle')), findsOneWidget);
    await tester.tap(find.text(t('chessBots.game.leave')).last);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text(t('chessBots.game.end.LOST')), findsOneWidget);
    expect(find.textContaining('(-20)'), findsOneWidget);
    expect(find.byType(ChessBoard), findsOneWidget);

    // Back in the lobby the rating and the result are there.
    await tester.tap(find.text(t('chessBots.game.toBots')));
    await tester.pumpAndSettle();
    expect(find.byType(ChessLobbyScreen), findsOneWidget);
    expect(find.text('780'), findsOneWidget);
    // The results are below the bots: scroll down to them.
    await tester.scrollUntilVisible(find.text(t('chessBots.results.LOST')), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text(t('chessBots.results.LOST')), findsOneWidget);
  });
}
