import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';

/// The signed-in user, as `/api/v1/me` and the auth endpoints return it.
class User {
  const User({
    required this.id,
    required this.username,
    required this.avatarSeed,
    required this.level,
    required this.xp,
    required this.plan,
    this.avatarStyle,
    this.gender,
    this.planExpiresAt,
    this.mustChangePassword = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    username: json['username'] as String,
    avatarSeed: json['avatarSeed'] as String,
    avatarStyle: json['avatarStyle'] as String?,
    gender: json['gender'] as String?,
    level: (json['level'] as num).toInt(),
    xp: (json['xp'] as num).toInt(),
    plan: json['plan'] as String? ?? 'FREE',
    planExpiresAt: json['planExpiresAt'] == null
        ? null
        : DateTime.parse(json['planExpiresAt'] as String),
    mustChangePassword: json['mustChangePassword'] as bool? ?? false,
  );

  final String id;
  final String username;
  final String avatarSeed;
  final String? avatarStyle;

  /// `MALE` / `FEMALE`, or null for accounts created before the question was asked.
  final String? gender;
  final int level;
  final int xp;

  /// Effective plan: `FREE`, `PRO` or `DIAMOND`.
  final String plan;
  final DateTime? planExpiresAt;
  final bool mustChangePassword;
}

/// Who is signed in: null when nobody is. Loading while the saved session is checked at launch.
class AuthController extends AsyncNotifier<User?> {
  ApiClient get _api => ref.read(apiClientProvider);
  TokenStore get _tokens => ref.read(tokenStoreProvider);

  @override
  Future<User?> build() async {
    if (await _tokens.read() == null) return null;
    try {
      return User.fromJson(
        (await _api.get('/me'))['user'] as Map<String, dynamic>,
      );
    } on ApiException catch (e) {
      // Revoked, expired or blocked → back to the login screen. Anything else (offline…) is shown with a retry.
      if (!e.isUnauthorized) rethrow;
      await _tokens.clear();
      return null;
    }
  }

  /// Throws [ApiException] with the same error keys as the web form (`auth.errors.*`).
  Future<void> login({required String identifier, required String password}) =>
      _signIn('/auth/login', {'identifier': identifier, 'password': password});

  Future<void> register({
    required String gender,
    required String phone,
    required String username,
    required String password,
    String ref = '',
  }) => _signIn('/auth/register', {
    'gender': gender,
    'phone': phone,
    'username': username,
    'password': password,
    'ref': ref,
  });

  Future<void> _signIn(String path, Map<String, dynamic> body) async {
    final data = await _api.post(path, body);
    await _tokens.write(data['token'] as String);
    state = AsyncData(User.fromJson(data['user'] as Map<String, dynamic>));
  }

  Future<void> logout() async {
    // Revoking on the server is best effort: the device forgets the token either way.
    try {
      await _api.post('/auth/logout');
    } on ApiException {
      // ignore
    }
    await _tokens.clear();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
);
