import 'package:flutter_test/flutter_test.dart';
import 'package:zukkolar/core/i18n/messages.dart';
import 'package:zukkolar/features/auth/login_screen.dart';
import 'package:zukkolar/features/auth/register_screen.dart';
import 'package:zukkolar/features/shell/app_shell.dart';
import 'helpers.dart';

void main() {
  setUpAll(loadAppAssets);

  test('strings come from the web app\'s messages file', () {
    expect(t('auth.submitLogin'), 'Kirish');
    expect(t('nav.levelXp', {'level': 3, 'xp': 120}), '3-daraja · 120 XP');
    expect(t('no.such.key'), 'no.such.key');
  });

  testWidgets('signed out → login; empty form shows the required errors', (tester) async {
    await pumpApp(tester);
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.text(t('auth.submitLogin')));
    await tester.pump();
    expect(find.text(t('auth.errors.required')), findsNWidgets(2));
  });

  testWidgets('login ↔ register links', (tester) async {
    await pumpApp(tester);
    await tapRegisterLink(tester);
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    await tester.ensureVisible(find.text(t('auth.submitRegister')));
    await tester.tap(find.text(t('auth.submitRegister')));
    await tester.pump();
    expect(find.text(t('auth.errors.genderRequired')), findsOneWidget);
    expect(find.text(t('auth.errors.passwordTooShort')), findsOneWidget);
  });

  testWidgets('signed in → shell with the five tabs; logging out returns to login', (tester) async {
    await pumpApp(tester, user: testUser);
    expect(find.byType(AppShell), findsOneWidget);
    for (final tab in AppShell.tabs) {
      expect(find.text(t('nav.${tab.key}')), findsWidgets);
    }

    await tester.tap(find.text(t('nav.learn')));
    await tester.pumpAndSettle();
    expect(find.text(t('mobile.comingSoon')), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(t('nav.profileMenu')));
    await tester.pumpAndSettle();
    // The menu's own row, then the button of the question it asks.
    await tester.tap(find.text(t('nav.logout')));
    await tester.pumpAndSettle();
    expect(find.text(t('nav.logoutConfirmTitle')), findsOneWidget);
    await tester.tap(find.text(t('nav.logout')).last);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
