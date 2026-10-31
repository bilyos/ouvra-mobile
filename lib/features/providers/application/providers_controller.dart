import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/mock_providers.dart';
import '../domain/service_provider.dart';

part 'providers_controller.g.dart';

/// Critère de tri de la liste des prestataires.
enum ProviderSort { proximity, rating, price }

extension ProviderSortLabel on ProviderSort {
  String get label => switch (this) {
        ProviderSort.proximity => 'Proximité',
        ProviderSort.rating => 'Note',
        ProviderSort.price => 'Prix',
      };
}

/// Rayon de recherche disponible (en km). `null` = illimité.
const List<int?> kDistanceFilters = [1, 5, 10, 20, null];

/// Tri actif.
@riverpod
class ProviderSortState extends _$ProviderSortState {
  @override
  ProviderSort build() => ProviderSort.proximity;
  void set(ProviderSort sort) => state = sort;
}

/// Filtre distance actif (km).
@riverpod
class DistanceFilter extends _$DistanceFilter {
  @override
  int? build() => null;
  void set(int? km) => state = km;
}

/// Catégorie sélectionnée sur le home. `null` = toutes.
@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  String? build() => null;
  void toggle(String id) => state = state == id ? null : id;
}

/// Liste dérivée : prestataires filtrés (catégorie + distance) puis triés.
@riverpod
List<ServiceProvider> filteredProviders(Ref ref) {
  final sort = ref.watch(providerSortStateProvider);
  final maxKm = ref.watch(distanceFilterProvider);
  final category = ref.watch(selectedCategoryProvider);

  final list = kMockProviders.where((p) {
    if (category != null && p.categoryId != category) return false;
    if (maxKm != null && p.distanceKm > maxKm) return false;
    return true;
  }).toList();

  list.sort((a, b) => switch (sort) {
        ProviderSort.proximity => a.distanceKm.compareTo(b.distanceKm),
        ProviderSort.rating => b.rating.compareTo(a.rating),
        ProviderSort.price => a.startingPrice.compareTo(b.startingPrice),
      });
  return list;
}

/// Récupère un prestataire par id (pour l'écran détail).
@riverpod
ServiceProvider? providerById(Ref ref, String id) {
  for (final p in kMockProviders) {
    if (p.id == id) return p;
  }
  return null;
}
