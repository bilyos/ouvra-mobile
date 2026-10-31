import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/service_provider.dart';

/// Accès à l'API des prestataires (recherche + détail).
class ProviderRepository {
  ProviderRepository(this._dio);

  final Dio _dio;

  Future<List<ServiceProvider>> search({
    String? category,
    String? query,
    String sort = 'proximity',
    double? lat,
    double? lng,
    double? radius,
  }) async {
    final params = <String, dynamic>{'sort': sort, 'size': 50};
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();
    if (lat != null) params['lat'] = lat;
    if (lng != null) params['lng'] = lng;
    if (radius != null) params['radius'] = radius;

    final res = await _dio.get('/providers', queryParameters: params);
    final content = (res.data['content'] as List?) ?? const [];
    return content
        .map((e) => ServiceProvider.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ServiceProvider> detail(String id, {double? lat, double? lng}) async {
    final params = <String, dynamic>{};
    if (lat != null) params['lat'] = lat;
    if (lng != null) params['lng'] = lng;

    final res = await _dio.get('/providers/$id', queryParameters: params);
    return ServiceProvider.fromJson(res.data as Map<String, dynamic>);
  }
}

final providerRepositoryProvider = Provider<ProviderRepository>((ref) {
  return ProviderRepository(ref.watch(dioProvider));
});

/// Paramètres de recherche (clé de famille — égalité structurelle des records).
typedef ProviderQuery = ({String? category, String? query, String sort});

/// Liste de prestataires selon des critères.
final providerSearchProvider = FutureProvider.autoDispose
    .family<List<ServiceProvider>, ProviderQuery>((ref, q) async {
  return ref
      .watch(providerRepositoryProvider)
      .search(category: q.category, query: q.query, sort: q.sort);
});

/// Détail d'un prestataire par id.
final providerDetailProvider = FutureProvider.autoDispose
    .family<ServiceProvider, String>((ref, id) async {
  return ref.watch(providerRepositoryProvider).detail(id);
});
