import '../domain/service_provider.dart';

/// Prestataires mockés (villes camerounaises). Remplacé par l'API + géoloc.
const List<ServiceProvider> kMockProviders = [
  ServiceProvider(
    id: 'p1',
    name: 'Jean-Paul Mbarga',
    profession: 'Plombier certifié',
    categoryId: 'plomberie',
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
    rating: 4.9,
    reviewCount: 128,
    distanceKm: 1.2,
    startingPrice: 5000,
    city: 'Yaoundé, Bastos',
    bio: "Plombier avec 8 ans d'expérience. Fuites, installations, dépannage "
        "d'urgence 7j/7. Devis gratuit avant intervention.",
    isOnline: true,
    portfolio: [
      'https://picsum.photos/seed/plomb1/400',
      'https://picsum.photos/seed/plomb2/400',
      'https://picsum.photos/seed/plomb3/400',
    ],
    reviews: [
      Review(authorName: 'Aline T.', rating: 5, comment: 'Rapide et propre, je recommande !', daysAgo: 2),
      Review(authorName: 'Boris K.', rating: 4.5, comment: 'Bon travail, prix correct.', daysAgo: 9),
    ],
  ),
  ServiceProvider(
    id: 'p2',
    name: 'Christelle Ngo',
    profession: 'Coiffeuse à domicile',
    categoryId: 'coiffure',
    avatarUrl: 'https://i.pravatar.cc/150?img=45',
    rating: 4.8,
    reviewCount: 96,
    distanceKm: 2.5,
    startingPrice: 3000,
    city: 'Douala, Akwa',
    bio: 'Coiffure femme et enfant à domicile. Tresses, tissage, soins. '
        'Déplacement dans tout Douala.',
    isOnline: true,
    portfolio: [
      'https://picsum.photos/seed/coif1/400',
      'https://picsum.photos/seed/coif2/400',
    ],
    reviews: [
      Review(authorName: 'Marie N.', rating: 5, comment: 'Super douce avec les enfants.', daysAgo: 1),
    ],
  ),
  ServiceProvider(
    id: 'p3',
    name: 'Samuel Etoa',
    profession: 'Électricien bâtiment',
    categoryId: 'electricite',
    avatarUrl: 'https://i.pravatar.cc/150?img=33',
    rating: 4.7,
    reviewCount: 74,
    distanceKm: 3.8,
    startingPrice: 7000,
    city: 'Yaoundé, Mvan',
    bio: 'Installations électriques, tableaux, câblage, mise aux normes. '
        'Intervention rapide et sécurisée.',
    isAvailable: true,
    portfolio: ['https://picsum.photos/seed/elec1/400'],
    reviews: [
      Review(authorName: 'Paul E.', rating: 4.5, comment: 'Sérieux et ponctuel.', daysAgo: 5),
    ],
  ),
  ServiceProvider(
    id: 'p4',
    name: 'Fatima Bello',
    profession: 'Aide-ménagère',
    categoryId: 'menage',
    avatarUrl: 'https://i.pravatar.cc/150?img=20',
    rating: 4.9,
    reviewCount: 210,
    distanceKm: 0.8,
    startingPrice: 2500,
    city: 'Douala, Bonapriso',
    bio: 'Ménage, repassage, entretien maison. Ponctuelle et méticuleuse. '
        'Disponible en semaine et week-end.',
    isOnline: false,
    portfolio: [],
    reviews: [
      Review(authorName: 'Sandra M.', rating: 5, comment: 'Impeccable, maison nickel.', daysAgo: 3),
    ],
  ),
  ServiceProvider(
    id: 'p5',
    name: 'Rodrigue Fotso',
    profession: 'Technicien réparation',
    categoryId: 'reparation',
    avatarUrl: 'https://i.pravatar.cc/150?img=51',
    rating: 4.6,
    reviewCount: 58,
    distanceKm: 5.1,
    startingPrice: 4000,
    city: 'Bafoussam, Centre',
    bio: 'Réparation électroménager : frigo, machine à laver, climatiseur. '
        'Diagnostic offert.',
    isAvailable: false,
    portfolio: ['https://picsum.photos/seed/rep1/400', 'https://picsum.photos/seed/rep2/400'],
    reviews: [],
  ),
  ServiceProvider(
    id: 'p6',
    name: 'Aïcha Njoya',
    profession: 'Couturière styliste',
    categoryId: 'couture',
    avatarUrl: 'https://i.pravatar.cc/150?img=26',
    rating: 5.0,
    reviewCount: 143,
    distanceKm: 4.3,
    startingPrice: 6000,
    city: 'Yaoundé, Mokolo',
    bio: 'Couture sur mesure, retouches, tenues traditionnelles et modernes. '
        'Finitions soignées.',
    isOnline: true,
    portfolio: [
      'https://picsum.photos/seed/cout1/400',
      'https://picsum.photos/seed/cout2/400',
      'https://picsum.photos/seed/cout3/400',
    ],
    reviews: [
      Review(authorName: 'Grace L.', rating: 5, comment: 'Une vraie artiste, robe magnifique !', daysAgo: 4),
    ],
  ),
];
