/// Rôle actif de l'utilisateur. Un compte peut basculer entre les deux
/// (transformation de compte — cf. paramètres).
enum UserRole { client, provider }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
        UserRole.client => 'Client',
        UserRole.provider => 'Prestataire',
      };
}

/// Sexe de l'utilisateur.
enum Gender { homme, femme }

extension GenderLabel on Gender {
  String get label => switch (this) {
        Gender.homme => 'Homme',
        Gender.femme => 'Femme',
      };
}

/// Utilisateur de l'application.
class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    this.email,
    this.gender,
    this.avatarUrl,
    this.city,
    this.isProviderEnabled = false,
  });

  final String id;
  final String fullName;
  final String phone;
  final UserRole role;
  final String? email;
  final Gender? gender;
  final String? avatarUrl;
  final String? city;

  /// True si l'utilisateur a déjà créé un profil prestataire (peut basculer).
  final bool isProviderEnabled;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final first = (json['firstName'] as String?) ?? '';
    final last = (json['lastName'] as String?) ?? '';
    return AppUser(
      id: json['id'].toString(),
      fullName: '$first $last'.trim(),
      phone: (json['phone'] as String?) ?? '',
      email: json['email'] as String?,
      gender: switch (json['gender']) {
        'HOMME' => Gender.homme,
        'FEMME' => Gender.femme,
        _ => null,
      },
      role: json['role'] == 'PROVIDER' ? UserRole.provider : UserRole.client,
      city: json['city'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isProviderEnabled: (json['providerEnabled'] as bool?) ?? false,
    );
  }

  AppUser copyWith({UserRole? role, bool? isProviderEnabled}) => AppUser(
        id: id,
        fullName: fullName,
        phone: phone,
        role: role ?? this.role,
        email: email,
        gender: gender,
        avatarUrl: avatarUrl,
        city: city,
        isProviderEnabled: isProviderEnabled ?? this.isProviderEnabled,
      );
}
