import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/provider_profile.dart';

part 'provider_profile_controller.g.dart';

/// Détient le profil prestataire de l'utilisateur courant (null tant qu'il
/// n'est pas prestataire). Rempli à l'inscription prestataire.
@riverpod
class ProviderProfileController extends _$ProviderProfileController {
  @override
  ProviderProfile? build() => null;

  void save(ProviderProfile profile) => state = profile;

  void clear() => state = null;
}
