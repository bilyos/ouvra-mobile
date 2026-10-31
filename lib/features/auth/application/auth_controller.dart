import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';
import '../domain/app_user.dart';

part 'auth_controller.g.dart';

/// État d'authentification. `null` = déconnecté.
/// Gardé en vie : sinon l'utilisateur est oublié entre deux écrans.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  AppUser? build() => null;

  bool get isLoggedIn => state != null;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required Gender gender,
    required UserRole role,
  }) async {
    state = await ref.read(authRepositoryProvider).register(
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          email: email,
          password: password,
          gender: gender,
          role: role,
        );
  }

  /// Tente de restaurer la session depuis le jeton stocké. Renvoie `true` si
  /// l'utilisateur est reconnecté.
  Future<bool> tryRestoreSession() async {
    try {
      state = await ref.read(authRepositoryProvider).me();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Rafraîchit le profil courant depuis l'API (après une modification).
  Future<void> refreshMe() async {
    try {
      state = await ref.read(authRepositoryProvider).me();
    } catch (_) {
      // ignore
    }
  }

  /// Bascule locale du rôle actif (le vrai passage prestataire se fait via
  /// l'API become-provider).
  void setRole(UserRole role) {
    final user = state;
    if (user == null) return;
    state = user.copyWith(
      role: role,
      isProviderEnabled: user.isProviderEnabled || role == UserRole.provider,
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = null;
  }
}
