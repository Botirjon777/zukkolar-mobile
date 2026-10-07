import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/i18n/messages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/dialogs.dart';
import '../auth/auth.dart';

/// "1 234 567" — thousands apart, like the web's groupDigits.
String groupDigits(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');

/// The panel the avatar in the top bar opens from the right (`profile-menu.tsx`, the web's `dialog.drawer`).
/// It lists the screens the app has so far; the rest join as they are ported.
Future<void> showProfileMenu(BuildContext context, User user) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: t('nav.close'),
    barrierColor: AppColors.scrim,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => _ProfileMenu(user: user),
    transitionBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: const Cubic(0.2, 0.8, 0.2, 1))),
      child: child,
    ),
  );
}

class _ProfileMenu extends ConsumerWidget {
  const _ProfileMenu({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;

    Future<void> open(String path) async {
      Navigator.pop(context);
      await GoRouter.of(context).push(path);
    }

    Future<void> logout() async {
      final confirmed = await showConfirmDialog(context, title: t('nav.logoutConfirmTitle'), text: t('nav.logoutConfirmText'), confirmLabel: t('nav.logout'));
      if (!confirmed || !context.mounted) return;
      Navigator.pop(context);
      await ref.read(authControllerProvider.notifier).logout();
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: AppColors.surface,
        child: Container(
          // min(20rem, 86vw)
          width: width * 0.86 < 320 ? width * 0.86 : 320,
          height: double.infinity,
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Semantics(
                      button: true,
                      label: t('nav.close'),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.pop(context),
                        child: const SizedBox(width: 40, height: 40, child: Icon(LucideIcons.x, size: 20, color: AppColors.muted)),
                      ),
                    ),
                  ),
                ),
                Avatar(
                  seed: user.avatarSeed,
                  style: user.avatarStyle,
                  gender: user.gender,
                  size: 80,
                  ringWidth: 4,
                  ringColor: AppColors.brand.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 12),
                Text(user.username, style: AppText.heading(AppText.lg)),
                const SizedBox(height: 4),
                Text(t('nav.levelXp', {'level': user.level, 'xp': groupDigits(user.xp)}), style: AppText.sm.copyWith(color: AppColors.muted)),
                const SizedBox(height: 20),
                const Divider(height: 1, thickness: 1, color: AppColors.border),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [_MenuItem(icon: LucideIcons.chessKnight, color: AppColors.brand, label: t('nav.chess'), onTap: () => open('/chess'))],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _MenuItem(
                    icon: LucideIcons.logOut,
                    color: AppColors.danger,
                    label: t('nav.logout'),
                    textColor: AppColors.danger,
                    chevron: false,
                    onTap: logout,
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

/// A row of the menu: `flex items-center gap-3 rounded-xl px-3 py-3 font-semibold`.
class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.color, required this.label, required this.onTap, this.textColor, this.chevron = true});

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppText.base.copyWith(fontWeight: FontWeight.w600, color: textColor),
                ),
              ),
              if (chevron) const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
