import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/data/mock_providers.dart';
import '../../providers/domain/service_provider.dart';

part 'search_controller.g.dart';

/// Texte de recherche courant.
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';
  void update(String value) => state = value;
}

/// Résultats de recherche filtrés sur nom / métier / ville / catégorie.
@riverpod
List<ServiceProvider> searchResults(Ref ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return kMockProviders;
  return kMockProviders.where((p) {
    return p.name.toLowerCase().contains(query) ||
        p.profession.toLowerCase().contains(query) ||
        p.city.toLowerCase().contains(query) ||
        p.categoryId.toLowerCase().contains(query);
  }).toList();
}
