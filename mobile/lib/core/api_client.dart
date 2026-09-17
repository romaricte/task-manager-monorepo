import 'package:dio/dio.dart';

import 'token_storage.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.validationErrors});

  final String message;
  final int? statusCode;
  final Map<String, String>? validationErrors;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this._tokenStorage, {String? baseUrl})
    : dio = Dio(
        BaseOptions(
          baseUrl:
              baseUrl ??
              const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: 'http://10.0.2.2:8080',
              ),
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
          sendTimeout: const Duration(seconds: 12),
          headers: const {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/api/auth/')) {
            await _tokenStorage.clear();
          }
          handler.next(error);
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  final Dio dio;

  ApiException mapError(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final data = error.response?.data;
      final validationErrors = <String, String>{};
      if (data is Map<String, dynamic>) {
        final rawErrors = data['validationErrors'];
        if (rawErrors is Map) {
          for (final entry in rawErrors.entries) {
            if (entry.value != null) {
              validationErrors[entry.key.toString()] = entry.value.toString();
            }
          }
        }
      }

      final message = data is Map<String, dynamic> && data['message'] is String
          ? data['message'] as String
          : switch (error.type) {
              DioExceptionType.connectionTimeout ||
              DioExceptionType.sendTimeout ||
              DioExceptionType.receiveTimeout =>
                'Le serveur met trop de temps à répondre.',
              DioExceptionType.connectionError =>
                'Impossible de joindre l’API. Vérifiez votre connexion.',
              _ => 'Une erreur inattendue est survenue.',
            };

      return ApiException(
        message,
        statusCode: error.response?.statusCode,
        validationErrors: validationErrors.isEmpty ? null : validationErrors,
      );
    }
    return const ApiException('Une erreur inattendue est survenue.');
  }
}
