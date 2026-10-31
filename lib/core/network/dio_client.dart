import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'token_storage.dart';

/// Fournit un [Dio] configuré : base URL API, ajout automatique du Bearer,
/// et rafraîchissement transparent du jeton sur 401.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);

  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.apiUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    contentType: 'application/json',
  ));

  // Dio dédié au refresh (sans intercepteur, pour éviter les boucles).
  final refreshDio = Dio(BaseOptions(
    baseUrl: ApiConfig.apiUrl,
    contentType: 'application/json',
  ));

  dio.interceptors.add(QueuedInterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.accessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      final status = error.response?.statusCode;
      final path = error.requestOptions.path;
      final isAuthCall = path.contains('/auth/');
      final alreadyRetried = error.requestOptions.extra['retried'] == true;

      if (status == 401 && !isAuthCall && !alreadyRetried) {
        final refresh = await storage.refreshToken();
        if (refresh != null) {
          try {
            final resp = await refreshDio.post('/auth/refresh',
                data: {'refreshToken': refresh});
            final newAccess = resp.data['accessToken'] as String;
            final newRefresh = resp.data['refreshToken'] as String;
            await storage.save(access: newAccess, refresh: newRefresh);

            final req = error.requestOptions;
            req.extra['retried'] = true;
            req.headers['Authorization'] = 'Bearer $newAccess';
            final cloned = await dio.fetch(req);
            return handler.resolve(cloned);
          } catch (_) {
            await storage.clear();
          }
        } else {
          await storage.clear();
        }
      }
      handler.next(error);
    },
  ));

  return dio;
});
