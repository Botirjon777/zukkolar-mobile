import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

/// A failed API call. The backend answers errors as `{ "error": "<key>", "fieldErrors": { "<field>": "<key>" } }`
/// where the keys are the same i18n keys the web forms use (e.g. `auth.errors.<key>`).
class ApiException implements Exception {
  const ApiException({this.status, this.error, this.fieldErrors = const {}});

  /// HTTP status, or null when the request never reached the server.
  final int? status;
  final String? error;
  final Map<String, String> fieldErrors;

  bool get isNetwork => status == null;
  bool get isUnauthorized => status == 401;

  @override
  String toString() => 'ApiException($status, $error, $fieldErrors)';
}

/// Where the session token lives between launches (Keychain / Keystore).
class TokenStore {
  TokenStore([this._storage = const FlutterSecureStorage()]);

  static const _key = 'session_token';
  final FlutterSecureStorage _storage;
  String? _cached;

  Future<String?> read() async => _cached ??= await _storage.read(key: _key);

  Future<void> write(String token) async {
    _cached = token;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _key);
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

class ApiClient {
  ApiClient(this._tokens, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: '${AppConfig.apiBaseUrl}/api/v1',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Accept': 'application/json'},
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokens.read();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
      ),
    );
  }

  final TokenStore _tokens;
  final Dio _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) => _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? body,
  ]) => _send(() => _dio.post<dynamic>(path, data: body ?? const {}));

  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final data = (await request()).data;
      return data is Map<String, dynamic> ? data : const {};
    } on DioException catch (e) {
      final data = e.response?.data;
      final body = data is Map<String, dynamic>
          ? data
          : const <String, dynamic>{};
      throw ApiException(
        status: e.response?.statusCode,
        error: body['error'] as String?,
        fieldErrors: {
          for (final entry
              in (body['fieldErrors'] as Map<String, dynamic>? ?? const {})
                  .entries)
            entry.key: '${entry.value}',
        },
      );
    }
  }
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(tokenStoreProvider)),
);
