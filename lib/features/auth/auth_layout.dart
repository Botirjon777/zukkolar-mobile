import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/i18n/messages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/logo.dart';

/// The frame around login / register (`(auth)/layout.tsx`): logo, then the form in a white card.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 80,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 384),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Logo(),
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.xl(
                            AppColors.brand.withValues(alpha: 0.05),
                          ),
                        ),
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppText.heading(
                                  AppText.xl2,
                                  tight: true,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: AppText.sm.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ...children,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "No account? Sign up" under a form: muted text followed by a brand-coloured link.
class AuthSwitchLink extends StatefulWidget {
  const AuthSwitchLink({
    super.key,
    required this.text,
    required this.link,
    required this.onTap,
  });

  final String text;
  final String link;
  final VoidCallback onTap;

  @override
  State<AuthSwitchLink> createState() => _AuthSwitchLinkState();
}

class _AuthSwitchLinkState extends State<AuthSwitchLink> {
  late final _recognizer = TapGestureRecognizer()..onTap = () => widget.onTap();

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text.rich(
        TextSpan(
          text: '${widget.text} ',
          children: [
            TextSpan(
              text: widget.link,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.brand,
              ),
              recognizer: _recognizer,
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: AppText.sm.copyWith(color: AppColors.muted),
      ),
    );
  }
}

/// The message for a failed auth call: the server's key under `auth.errors`, or a connection problem.
String? authErrorText(ApiException e) {
  if (e.isNetwork) return t('mobile.networkError');
  if (e.error != null) return t('auth.errors.${e.error}');
  return e.fieldErrors.isEmpty ? t('mobile.serverError') : null;
}

String? authFieldError(Map<String, String> fieldErrors, String field) {
  final key = fieldErrors[field];
  return key == null ? null : t('auth.errors.$key');
}
