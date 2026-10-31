import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/token_storage.dart';
import '../domain/app_user.dart';

/// Accès à l'API d'authentification.
class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  Future<AppUser> login({required String email, required String password}) async {
    final res = await _dio.post('/auth/login',
        data: {'email': email, 'password': password});
    await _saveTokens(res.data);
    return AppUser.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required Gender gender,
    required UserRole role,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'password': password,
      'gender': gender == Gender.homme ? 'HOMME' : 'FEMME',
      'role': role == UserRole.provider ? 'PROVIDER' : 'CLIENT',
    });
    await _saveTokens(res.data);
    return AppUser.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> me() async {
    final res = await _dio.get('/me');
    return AppUser.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final refresh = await _storage.refreshToken();
    if (refresh != null) {
      try {
        await _dio.post('/auth/logout', data: {'refreshToken': refresh});
      } catch (_) {
        // On efface les jetons quoi qu'il arrive.
      }
    }
    await _storage.clear();
  }

  Future<void> _saveTokens(dynamic data) async {
    await _storage.save(
      access: data['accessToken'] as String,
      refresh: data['refreshToken'] as String,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider));
});
