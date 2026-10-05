import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/i18n/messages.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_field.dart';
import 'auth.dart';
import 'auth_layout.dart';
import 'gender_picker.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.referralCode});

  /// From an invite link (`/register?ref=K7M2QX`).
  final String? referralCode;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _phone = TextEditingController(text: '+998 ');
  final _username = TextEditingController();
  final _password = TextEditingController();
  late final _ref = TextEditingController(text: widget.referralCode);
  String? _gender;

  /// Username the avatar previews are drawn for — updated a moment after typing stops.
  String _seed = 'zukkolar';
  Timer? _seedTimer;

  bool _pending = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _seedTimer?.cancel();
    _phone.dispose();
    _username.dispose();
    _password.dispose();
    _ref.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _seedTimer?.cancel();
    _seedTimer = Timer(const Duration(milliseconds: 400), () {
      final seed = value.trim().toLowerCase();
      if (mounted) setState(() => _seed = seed.isEmpty ? 'zukkolar' : seed);
    });
  }

  /// The checks of registerSchema that need no server (the phone number itself is validated there).
  Map<String, String> _validate() {
    final username = _username.text.trim().toLowerCase();
    final password = _password.text;
    return {
      if (_gender == null) 'gender': 'genderRequired',
      if (_phone.text.trim().isEmpty) 'phone': 'required',
      if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username))
        'username': 'usernameFormat',
      if (password.length < 8)
        'password': 'passwordTooShort'
      else if (password.length > 128)
        'password': 'passwordTooLong',
    };
  }

  Future<void> _submit() async {
    if (_pending) return;
    final invalid = _validate();
    if (invalid.isNotEmpty) {
      setState(() {
        _error = null;
        _fieldErrors = invalid;
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
      await ref
          .read(authControllerProvider.notifier)
          .register(
            gender: _gender!,
            phone: _phone.text,
            username: _username.text,
            password: _password.text,
            ref: _ref.text,
          );
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
      title: t('auth.registerTitle'),
      subtitle: t('auth.registerSubtitle'),
      children: [
        if (_error != null) ...[FormAlert(_error!), const SizedBox(height: 16)],
        GenderPicker(
          seed: _seed,
          value: _gender,
          onChanged: (gender) => setState(() => _gender = gender),
          label: t('auth.gender'),
          hint: t('auth.genderHint'),
          error: authFieldError(_fieldErrors, 'gender'),
        ),
        const SizedBox(height: 16),
        AppField(
          label: t('auth.phone'),
          controller: _phone,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          placeholder: t('auth.phonePlaceholder'),
          error: authFieldError(_fieldErrors, 'phone'),
        ),
        const SizedBox(height: 16),
        AppField(
          label: t('auth.username'),
          controller: _username,
          autofillHints: const [AutofillHints.newUsername],
          hint: t('auth.usernameHint'),
          onChanged: _onUsernameChanged,
          error: authFieldError(_fieldErrors, 'username'),
        ),
        const SizedBox(height: 16),
        AppField(
          label: t('auth.password'),
          controller: _password,
          obscure: true,
          autofillHints: const [AutofillHints.newPassword],
          hint: t('auth.passwordHint'),
          error: authFieldError(_fieldErrors, 'password'),
        ),
        const SizedBox(height: 16),
        AppField(
          label: t('auth.referral'),
          controller: _ref,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          hint: t('auth.referralHint'),
          error: authFieldError(_fieldErrors, 'ref'),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: _pending ? t('auth.pending') : t('auth.submitRegister'),
          onPressed: _pending ? null : _submit,
        ),
        const SizedBox(height: 20),
        AuthSwitchLink(
          text: t('auth.haveAccount'),
          link: t('auth.submitLogin'),
          onTap: () => context.go('/login'),
        ),
      ],
    );
  }
}
