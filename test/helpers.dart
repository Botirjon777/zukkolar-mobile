import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zukkolar/app.dart';
import 'package:zukkolar/core/i18n/messages.dart';
import 'package:zukkolar/core/widgets/avatar.dart';
import 'package:zukkolar/features/auth/auth.dart';

/// Real fonts (text, icons) and real strings, so tests see what users see.
Future<void> loadAppAssets() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest =
      jsonDecode(await rootBundle.loadString('FontManifest.json'))
          as List<dynamic>;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    for (final font
        in (family['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
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

const testUser = User(
  id: 'u1',
  username: 'ali',
  avatarSeed: 'ali',
  level: 3,
  xp: 120,
  plan: 'FREE',
  gender: 'MALE',
);

/// The whole app on an iPhone-sized screen.
Future<void> pumpApp(WidgetTester tester, {User? user}) async {
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => FakeAuthController(user)),
      ],
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
