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
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('shots/login.png'),
    );
    await tester.tap(find.text(t('auth.submitLogin')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('shots/login_errors.png'),
    );
  });

  testWidgets('register', (tester) async {
    await pumpApp(tester);
    await tapRegisterLink(tester);
    await tester.pumpAndSettle();
    await precache(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('shots/register.png'),
    );
  });

  testWidgets('shell', (tester) async {
    await pumpApp(tester, user: testUser);
    await precache(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('shots/shell.png'),
    );
    await tester.tap(find.bySemanticsLabel(t('nav.profileMenu')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('shots/logout.png'),
    );
  });
}
