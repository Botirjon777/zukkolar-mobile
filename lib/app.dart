import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/i18n/messages.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_background.dart';
import 'core/widgets/app_button.dart';
import 'core/widgets/logo.dart';
import 'features/auth/auth.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/shell/app_shell.dart';

/// Routes mirror the web app's paths (`/login`, `/dashboard`, `/learn`, …) so links can be shared later.
final routerProvider = Provider<GoRouter>((ref) {
  final authChanged = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => authChanged.value++);
  ref.onDispose(authChanged.dispose);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: authChanged,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final path = state.matchedLocation;
      // Checking the saved session (or it failed, e.g. offline) → the launch screen.
      if (auth.isLoading || auth.hasError) {
        return path == '/launch' ? null : '/launch';
      }

      final atAuth = path == '/login' || path == '/register';
      if (auth.value == null) return atAuth ? null : '/login';
      return atAuth || path == '/launch' ? '/dashboard' : null;
    },
    routes: [
      GoRoute(path: '/launch', builder: (_, _) => const LaunchScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (_, state) =>
            RegisterScreen(referralCode: state.uri.queryParameters['ref']),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          for (final tab in AppShell.tabs)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/${tab.key}',
                  builder: (_, _) =>
                      ComingSoonScreen(title: t('nav.${tab.key}')),
                ),
              ],
            ),
        ],
      ),
    ],
  );
});

class ZukkolarApp extends ConsumerWidget {
  const ZukkolarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Zukkolar',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) =>
          AppBackground(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Shown while the saved session is checked; offers a retry when the server can't be reached.
class LaunchScreen extends ConsumerWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final failed = auth.hasError && !auth.isLoading;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LogoFull(width: 176),
              const SizedBox(height: 32),
              if (failed) ...[
                Text(
                  t('mobile.networkError'),
                  textAlign: TextAlign.center,
                  style: AppText.sm.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: t('common.retry'),
                  expand: false,
                  onPressed: () => ref.invalidate(authControllerProvider),
                ),
              ] else
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.brand,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
