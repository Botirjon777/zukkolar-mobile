import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/i18n/messages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/logo.dart';
import '../auth/auth.dart';
import 'profile_menu.dart';

/// The signed-in frame (`(app)/layout.tsx`, phone layout): top bar, page, bottom tab bar.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Same five as the web's mobile tab bar; the rest is reached from the top bar and the profile menu.
  static const tabs = [
    (key: 'dashboard', icon: LucideIcons.house),
    (key: 'learn', icon: LucideIcons.bookOpen),
    (key: 'practice', icon: LucideIcons.dumbbell),
    (key: 'leaderboard', icon: LucideIcons.trophy),
    (key: 'friends', icon: LucideIcons.users),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final insets = MediaQuery.paddingOf(context);

    return Scaffold(
      body: Column(
        children: [
          _Frosted(
            color: AppColors.background.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.7))),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, insets.top + 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(onTap: () => navigationShell.goBranch(0, initialLocation: true), child: const Logo()),
                  const Spacer(),
                  _TopBarButton(icon: LucideIcons.messageCircle, label: t('nav.chat'), onTap: () {}),
                  const SizedBox(width: 8),
                  _TopBarButton(icon: LucideIcons.bell, label: t('nav.notifications'), onTap: () {}),
                  const SizedBox(width: 8),
                  if (user != null)
                    Semantics(
                      button: true,
                      label: t('nav.profileMenu'),
                      child: GestureDetector(
                        onTap: () => showProfileMenu(context, user),
                        child: Avatar(seed: user.avatarSeed, style: user.avatarStyle, gender: user.gender, ringWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(child: navigationShell),
          _Frosted(
            color: AppColors.surface.withValues(alpha: 0.95),
            border: const Border(top: BorderSide(color: AppColors.border)),
            child: Padding(
              padding: EdgeInsets.only(bottom: insets.bottom),
              child: Row(
                children: [
                  for (final (index, tab) in tabs.indexed)
                    Expanded(
                      child: _TabItem(
                        icon: tab.icon,
                        label: t('nav.${tab.key}'),
                        active: navigationShell.currentIndex == index,
                        onTap: () => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A bar with the page blurred behind it (`bg-…/80 backdrop-blur`).
class _Frosted extends StatelessWidget {
  const _Frosted({required this.color, required this.border, required this.child});

  final Color color;
  final Border border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, border: border),
          child: child,
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  const _TopBarButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 20, color: AppColors.muted),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.icon, required this.label, required this.active, required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brand : AppColors.muted;
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.tab.copyWith(fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stand-in for a tab whose screen isn't ported yet.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.heading(AppText.xl2, tight: true)),
          const SizedBox(height: 6),
          Text(t('mobile.comingSoon'), style: AppText.sm.copyWith(color: AppColors.muted)),
        ],
      ),
    );
  }
}
