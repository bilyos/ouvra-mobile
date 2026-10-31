/// Avis client sur un prestataire.
class Review {
  const Review({
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.daysAgo,
  });

  final String authorName;
  final double rating;
  final String comment;
  final int daysAgo;

  factory Review.fromJson(Map<String, dynamic> json) {
    final created = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final days = created == null ? 0 : DateTime.now().difference(created).inDays;
    return Review(
      authorName: (json['authorName'] as String?) ?? 'Client',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      comment: (json['comment'] as String?) ?? '',
      daysAgo: days,
    );
  }
}

/// Prestataire affiché dans la marketplace (card façon Fiverr + proximité Uber).
class ServiceProvider {
  const ServiceProvider({
    required this.id,
    required this.name,
    required this.profession,
    required this.categoryId,
    required this.avatarUrl,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.startingPrice,
    required this.city,
    required this.bio,
    this.isOnline = false,
    this.isAvailable = true,
    this.portfolio = const [],
    this.reviews = const [],
  });

  final String id;
  final String name;
  final String profession;
  final String categoryId;
  final String avatarUrl;
  final double rating;
  final int reviewCount;
  final double distanceKm;

  /// Prix de départ estimé, en FCFA.
  final int startingPrice;
  final String city;
  final String bio;
  final bool isOnline;
  final bool isAvailable;
  final List<String> portfolio;
  final List<Review> reviews;

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'].toString(),
      name: (json['name'] as String?) ?? '',
      profession: (json['profession'] as String?) ?? '',
      categoryId: (json['categoryId'] as String?) ?? '',
      avatarUrl: (json['avatarUrl'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      startingPrice: (json['startingPrice'] as num?)?.toInt() ?? 0,
      city: (json['city'] as String?) ?? '',
      bio: (json['description'] as String?) ?? '',
      isOnline: (json['online'] as bool?) ?? false,
      isAvailable: (json['available'] as bool?) ?? true,
      portfolio:
          (json['portfolio'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      reviews: (json['reviews'] as List?)
              ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
