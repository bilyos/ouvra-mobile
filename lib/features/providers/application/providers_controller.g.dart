// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredProvidersHash() => r'71596354160c2e0c88e767b5d2c13934a2d4beb0';

/// Liste dérivée : prestataires filtrés (catégorie + distance) puis triés.
///
/// Copied from [filteredProviders].
@ProviderFor(filteredProviders)
final filteredProvidersProvider =
    AutoDisposeProvider<List<ServiceProvider>>.internal(
      filteredProviders,
      name: r'filteredProvidersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$filteredProvidersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredProvidersRef = AutoDisposeProviderRef<List<ServiceProvider>>;
String _$providerByIdHash() => r'7b5c51ca2006e5ac81b8ac253299cdd5ab8932fb';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Récupère un prestataire par id (pour l'écran détail).
///
/// Copied from [providerById].
@ProviderFor(providerById)
const providerByIdProvider = ProviderByIdFamily();

/// Récupère un prestataire par id (pour l'écran détail).
///
/// Copied from [providerById].
class ProviderByIdFamily extends Family<ServiceProvider?> {
  /// Récupère un prestataire par id (pour l'écran détail).
  ///
  /// Copied from [providerById].
  const ProviderByIdFamily();

  /// Récupère un prestataire par id (pour l'écran détail).
  ///
  /// Copied from [providerById].
  ProviderByIdProvider call(String id) {
    return ProviderByIdProvider(id);
  }

  @override
  ProviderByIdProvider getProviderOverride(
    covariant ProviderByIdProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'providerByIdProvider';
}

/// Récupère un prestataire par id (pour l'écran détail).
///
/// Copied from [providerById].
class ProviderByIdProvider extends AutoDisposeProvider<ServiceProvider?> {
  /// Récupère un prestataire par id (pour l'écran détail).
  ///
  /// Copied from [providerById].
  ProviderByIdProvider(String id)
    : this._internal(
        (ref) => providerById(ref as ProviderByIdRef, id),
        from: providerByIdProvider,
        name: r'providerByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$providerByIdHash,
        dependencies: ProviderByIdFamily._dependencies,
        allTransitiveDependencies:
            ProviderByIdFamily._allTransitiveDependencies,
        id: id,
      );

  ProviderByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    ServiceProvider? Function(ProviderByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProviderByIdProvider._internal(
        (ref) => create(ref as ProviderByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<ServiceProvider?> createElement() {
    return _ProviderByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProviderByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProviderByIdRef on AutoDisposeProviderRef<ServiceProvider?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _ProviderByIdProviderElement
    extends AutoDisposeProviderElement<ServiceProvider?>
    with ProviderByIdRef {
  _ProviderByIdProviderElement(super.provider);

  @override
  String get id => (origin as ProviderByIdProvider).id;
}

String _$providerSortStateHash() => r'e748eeef24907244db95e1544028913b8d5036da';

/// Tri actif.
///
/// Copied from [ProviderSortState].
@ProviderFor(ProviderSortState)
final providerSortStateProvider =
    AutoDisposeNotifierProvider<ProviderSortState, ProviderSort>.internal(
      ProviderSortState.new,
      name: r'providerSortStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$providerSortStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProviderSortState = AutoDisposeNotifier<ProviderSort>;
String _$distanceFilterHash() => r'380c60bba7a82e0068a2ad94f883ba8d7522742e';

/// Filtre distance actif (km).
///
/// Copied from [DistanceFilter].
@ProviderFor(DistanceFilter)
final distanceFilterProvider =
    AutoDisposeNotifierProvider<DistanceFilter, int?>.internal(
      DistanceFilter.new,
      name: r'distanceFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$distanceFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DistanceFilter = AutoDisposeNotifier<int?>;
String _$selectedCategoryHash() => r'5b9637543e7ee06b61089e9631f289530ec66316';

/// Catégorie sélectionnée sur le home. `null` = toutes.
///
/// Copied from [SelectedCategory].
@ProviderFor(SelectedCategory)
final selectedCategoryProvider =
    AutoDisposeNotifierProvider<SelectedCategory, String?>.internal(
      SelectedCategory.new,
      name: r'selectedCategoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedCategoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedCategory = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
