import 'dart:typed_data';

/// Profil prestataire renseigné par l'utilisateur devenu prestataire.
class ProviderProfile {
  const ProviderProfile({
    required this.categoryId,
    required this.title,
    required this.description,
    required this.startingPrice,
    required this.city,
    required this.availability,
    this.photos = const [],
  });

  /// Catégorie de service (id de [ServiceCategory]).
  final String categoryId;

  /// Intitulé du métier (ex. « Plombier certifié »).
  final String title;

  /// Description + modalités (déplacement, tarifs, conditions…).
  final String description;

  final int startingPrice;
  final String city;

  /// Disponibilité (ex. « Lun–Sam, 8h–18h »).
  final String availability;

  /// Photos de réalisations (octets bruts, cross-platform y compris web).
  final List<Uint8List> photos;

  ProviderProfile copyWith({List<Uint8List>? photos}) => ProviderProfile(
        categoryId: categoryId,
        title: title,
        description: description,
        startingPrice: startingPrice,
        city: city,
        availability: availability,
        photos: photos ?? this.photos,
      );
}
