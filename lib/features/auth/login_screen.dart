import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/i18n/messages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_field.dart';
import 'auth.dart';
import 'auth_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _pending = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pending) return;
    final identifier = _identifier.text.trim();
    final password = _password.text;
    // Same checks as loginSchema on the server, so an empty form doesn't need a round trip.
    final missing = {
      if (identifier.isEmpty) 'identifier': 'required',
      if (password.isEmpty) 'password': 'required',
    };
    if (missing.isNotEmpty) {
      setState(() {
        _error = null;
        _fieldErrors = missing;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _pending = true;
      _error = null;
      _fieldErrors = const {};
    });
    try {
      // On success the router sees the signed-in user and moves to the dashboard.
      await ref
          .read(authControllerProvider.notifier)
          .login(identifier: identifier, password: password);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _pending = false;
        _error = authErrorText(e);
        _fieldErrors = e.fieldErrors;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: t('auth.loginTitle'),
      subtitle: t('auth.loginSubtitle'),
      children: [
        if (_error != null) ...[FormAlert(_error!), const SizedBox(height: 16)],
        AppField(
          label: t('auth.identifier'),
          controller: _identifier,
          autofillHints: const [AutofillHints.username],
          keyboardType: TextInputType.emailAddress,
          error: authFieldError(_fieldErrors, 'identifier'),
        ),
        const SizedBox(height: 16),
        AppField(
          label: t('auth.password'),
          controller: _password,
          obscure: true,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          error: authFieldError(_fieldErrors, 'password'),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: _pending ? t('auth.pending') : t('auth.submitLogin'),
          onPressed: _pending ? null : _submit,
        ),
        const SizedBox(height: 20),
        Text(
          t('auth.forgotPassword'),
          style: AppText.xs.copyWith(color: AppColors.muted, height: 1.625),
        ),
        const SizedBox(height: 20),
        AuthSwitchLink(
          text: t('auth.noAccount'),
          link: t('auth.submitRegister'),
          onTap: () => context.go('/register'),
        ),
      ],
    );
  }
}
