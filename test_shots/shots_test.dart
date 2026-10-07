import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zukkolar/core/i18n/messages.dart';
import '../test/helpers.dart';

// Renders the screens to test_shots/shots/*.png for a visual check against the web app:
//   flutter test test_shots --update-goldens
void main() {
  setUpAll(loadAppAssets);

  Future<void> precache(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets('login', (tester) async {
    await pumpApp(tester);
    await precache(tester);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/login.png'));
    await tester.tap(find.text(t('auth.submitLogin')));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/login_errors.png'));
  });

  testWidgets('register', (tester) async {
    await pumpApp(tester);
    await tapRegisterLink(tester);
    await tester.pumpAndSettle();
    await precache(tester);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/register.png'));
  });

  testWidgets('shell and profile menu', (tester) async {
    await pumpApp(tester, user: testUser);
    await precache(tester);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/shell.png'));
    await tester.tap(find.bySemanticsLabel(t('nav.profileMenu')));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/profile_menu.png'));
  });

  testWidgets('chess', (tester) async {
    await pumpApp(tester, user: testUser);
    await tester.tap(find.bySemanticsLabel(t('nav.profileMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t('nav.chess')));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/chess_lobby.png'));

    await tester.tap(find.text(t('chessBots.colors.w')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('e2, wP'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/chess_selected.png'));
    await tester.tap(find.bySemanticsLabel('e4'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('g1, wN'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('f3'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/chess_game.png'));

    await tester.ensureVisible(find.text(t('chessBots.game.resign')));
    await tester.tap(find.text(t('chessBots.game.resign')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t('chessBots.game.resign')).last);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/chess_result.png'));
  });
}
