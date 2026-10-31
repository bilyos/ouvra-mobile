// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$providerProfileControllerHash() =>
    r'e94b8799563232edbd35ef44e1313591a26746eb';

/// Détient le profil prestataire de l'utilisateur courant (null tant qu'il
/// n'est pas prestataire). Rempli à l'inscription prestataire.
///
/// Copied from [ProviderProfileController].
@ProviderFor(ProviderProfileController)
final providerProfileControllerProvider =
    AutoDisposeNotifierProvider<
      ProviderProfileController,
      ProviderProfile?
    >.internal(
      ProviderProfileController.new,
      name: r'providerProfileControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$providerProfileControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProviderProfileController = AutoDisposeNotifier<ProviderProfile?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
