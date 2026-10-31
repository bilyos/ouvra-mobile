// Fil de demandes : le client montre son problème (photo, vocal, texte),
// les prestataires du métier autour de lui envoient un devis.

enum RequestStatus { open, assigned, expired, cancelled }

enum RequestTiming { now, thisWeek, flexible }

enum QuoteStatus { sent, withdrawn, accepted, declined, expired }

enum PriceKind { fixed, from, afterVisit }

extension RequestTimingApi on RequestTiming {
  String get api => switch (this) {
        RequestTiming.now => 'NOW',
        RequestTiming.thisWeek => 'THIS_WEEK',
        RequestTiming.flexible => 'FLEXIBLE',
      };

  String get label => switch (this) {
        RequestTiming.now => 'Maintenant',
        RequestTiming.thisWeek => 'Cette semaine',
        RequestTiming.flexible => 'Pas pressé',
      };

  String get hint => switch (this) {
        RequestTiming.now => 'Visible 2 heures, jusqu\'à 20 km',
        _ => 'Visible 3 jours, jusqu\'à 10 km',
      };
}

extension PriceKindApi on PriceKind {
  String get api => switch (this) {
        PriceKind.fixed => 'FIXED',
        PriceKind.from => 'FROM',
        PriceKind.afterVisit => 'AFTER_VISIT',
      };

  String get label => switch (this) {
        PriceKind.fixed => 'Prix ferme',
        PriceKind.from => 'À partir de',
        PriceKind.afterVisit => 'Après visite',
      };

  String get hint => switch (this) {
        PriceKind.fixed => 'Ce prix ne bougera pas.',
        PriceKind.from => 'Prix de départ, ajusté sur place selon le travail.',
        PriceKind.afterVisit =>
          'Estimation : vous fixerez le prix final après avoir vu le problème.',
      };
}

RequestStatus _requestStatus(String? s) => switch (s) {
      'ASSIGNED' => RequestStatus.assigned,
      'EXPIRED' => RequestStatus.expired,
      'CANCELLED' => RequestStatus.cancelled,
      _ => RequestStatus.open,
    };

RequestTiming _timing(String? s) => switch (s) {
      'NOW' => RequestTiming.now,
      'FLEXIBLE' => RequestTiming.flexible,
      _ => RequestTiming.thisWeek,
    };

QuoteStatus _quoteStatus(String? s) => switch (s) {
      'WITHDRAWN' => QuoteStatus.withdrawn,
      'ACCEPTED' => QuoteStatus.accepted,
      'DECLINED' => QuoteStatus.declined,
      'EXPIRED' => QuoteStatus.expired,
      _ => QuoteStatus.sent,
    };

PriceKind _priceKind(String? s) => switch (s) {
      'FROM' => PriceKind.from,
      'AFTER_VISIT' => PriceKind.afterVisit,
      _ => PriceKind.fixed,
    };

DateTime _date(dynamic v) =>
    DateTime.tryParse(v?.toString() ?? '')?.toLocal() ?? DateTime.now();

double? _double(dynamic v) => v == null ? null : (v as num).toDouble();

/// Une photo jointe à la demande.
class RequestPhoto {
  const RequestPhoto({required this.url, this.thumbnailUrl});

  final String url;
  final String? thumbnailUrl;

  factory RequestPhoto.fromJson(Map<String, dynamic> json) => RequestPhoto(
        url: json['url'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String?,
      );
}

class JobRequest {
  const JobRequest({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.voiceUrl,
    required this.voiceSeconds,
    required this.photos,
    required this.city,
    required this.quarter,
    required this.distanceKm,
    required this.timing,
    required this.budgetMax,
    required this.status,
    required this.quoteCount,
    required this.maxQuotes,
    required this.expiresAt,
    required this.createdAt,
    required this.clientName,
    required this.clientAvatarUrl,
    required this.mine,
    required this.address,
    required this.bookingId,
    required this.myQuote,
  });

  final String id;
  final String categoryId;
  final String title;
  final String? description;
  final String? voiceUrl;
  final int? voiceSeconds;
  final List<RequestPhoto> photos;
  final String city;
  final String? quarter;

  /// Vue prestataire : distance arrondie au demi-kilomètre.
  final double? distanceKm;
  final RequestTiming timing;
  final int? budgetMax;
  final RequestStatus status;
  final int quoteCount;
  final int maxQuotes;
  final DateTime expiresAt;
  final DateTime createdAt;

  /// Prénom et initiale : « Aurélien T. ».
  final String clientName;
  final String? clientAvatarUrl;
  final bool mine;

  /// Visible par l'auteur seulement.
  final String? address;
  final String? bookingId;

  /// Vue prestataire : son devis sur cette demande.
  final Quote? myQuote;

  String get place =>
      quarter == null || quarter!.isEmpty ? city : '$quarter, $city';

  bool get isOpen => status == RequestStatus.open;

  /// Plus de place pour un nouveau devis.
  bool get isFull => quoteCount >= maxQuotes;

  factory JobRequest.fromJson(Map<String, dynamic> json) => JobRequest(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        voiceUrl: json['voiceUrl'] as String?,
        voiceSeconds: (json['voiceSeconds'] as num?)?.toInt(),
        photos: ((json['media'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .where((m) => m['kind'] == 'PHOTO')
            .map(RequestPhoto.fromJson)
            .toList(),
        city: json['city'] as String? ?? '',
        quarter: json['quarter'] as String?,
        distanceKm: _double(json['distanceKm']),
        timing: _timing(json['timing'] as String?),
        budgetMax: (json['budgetMax'] as num?)?.toInt(),
        status: _requestStatus(json['status'] as String?),
        quoteCount: (json['quoteCount'] as num?)?.toInt() ?? 0,
        maxQuotes: (json['maxQuotes'] as num?)?.toInt() ?? 5,
        expiresAt: _date(json['expiresAt']),
        createdAt: _date(json['createdAt']),
        clientName: json['clientName'] as String? ?? 'Client',
        clientAvatarUrl: json['clientAvatarUrl'] as String?,
        mine: json['mine'] as bool? ?? false,
        address: json['address'] as String?,
        bookingId: json['bookingId'] as String?,
        myQuote: json['myQuote'] == null
            ? null
            : Quote.fromJson(json['myQuote'] as Map<String, dynamic>),
      );
}

class Quote {
  const Quote({
    required this.id,
    required this.requestId,
    required this.providerId,
    required this.providerName,
    required this.providerAvatarUrl,
    required this.providerTitle,
    required this.ratingAvg,
    required this.reviewCount,
    required this.distanceKm,
    required this.price,
    required this.priceKind,
    required this.message,
    required this.availableAt,
    required this.status,
    required this.createdAt,
    required this.request,
  });

  final String id;
  final String requestId;
  final String providerId;
  final String providerName;
  final String? providerAvatarUrl;
  final String providerTitle;
  final double ratingAvg;
  final int reviewCount;
  final double? distanceKm;
  final int price;
  final PriceKind priceKind;
  final String? message;
  final DateTime availableAt;
  final QuoteStatus status;
  final DateTime createdAt;

  /// Liste « Mes devis » du prestataire : la demande chiffrée.
  final JobRequest? request;

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        id: json['id'] as String,
        requestId: json['requestId'] as String? ?? '',
        providerId: json['providerId'] as String? ?? '',
        providerName: json['providerName'] as String? ?? 'Prestataire',
        providerAvatarUrl: json['providerAvatarUrl'] as String?,
        providerTitle: json['providerTitle'] as String? ?? '',
        ratingAvg: _double(json['ratingAvg']) ?? 0,
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        distanceKm: _double(json['distanceKm']),
        price: (json['price'] as num?)?.toInt() ?? 0,
        priceKind: _priceKind(json['priceKind'] as String?),
        message: json['message'] as String?,
        availableAt: _date(json['availableAt']),
        status: _quoteStatus(json['status'] as String?),
        createdAt: _date(json['createdAt']),
        request: json['request'] == null
            ? null
            : JobRequest.fromJson(json['request'] as Map<String, dynamic>),
      );
}
