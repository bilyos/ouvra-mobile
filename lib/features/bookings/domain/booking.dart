/// Statut d'une réservation (côté API : `BookingStatus`).
enum BookingStatus { pending, accepted, rejected, inProgress, completed, cancelled }

/// Où en est l'argent (côté API : `EscrowStatus`).
enum EscrowStatus { none, held, released, refunded, disputed }

/// Moyens de paiement acceptés.
enum PaymentMethod { orangeMoney, mtnMomo, card }

extension PaymentMethodApi on PaymentMethod {
  String get api => switch (this) {
        PaymentMethod.orangeMoney => 'ORANGE_MONEY',
        PaymentMethod.mtnMomo => 'MTN_MOMO',
        PaymentMethod.card => 'CARD',
      };

  String get label => switch (this) {
        PaymentMethod.orangeMoney => 'Orange Money',
        PaymentMethod.mtnMomo => 'MTN Mobile Money',
        PaymentMethod.card => 'Carte bancaire',
      };
}

BookingStatus _status(String? s) => switch (s) {
      'ACCEPTED' => BookingStatus.accepted,
      'REJECTED' => BookingStatus.rejected,
      'IN_PROGRESS' => BookingStatus.inProgress,
      'COMPLETED' => BookingStatus.completed,
      'CANCELLED' => BookingStatus.cancelled,
      _ => BookingStatus.pending,
    };

EscrowStatus _escrow(String? s) => switch (s) {
      'HELD' => EscrowStatus.held,
      'RELEASED' => EscrowStatus.released,
      'REFUNDED' => EscrowStatus.refunded,
      'DISPUTED' => EscrowStatus.disputed,
      _ => EscrowStatus.none,
    };

DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

/// Réservation d'un prestataire par un client.
class Booking {
  const Booking({
    required this.id,
    required this.clientName,
    required this.providerId,
    required this.providerName,
    required this.providerProfession,
    required this.providerAvatarUrl,
    required this.title,
    required this.description,
    required this.scheduledAt,
    required this.address,
    required this.price,
    required this.status,
    required this.escrow,
    required this.paid,
    required this.urgent,
    required this.createdAt,
    this.cancelReason,
    this.completionCode,
    this.completedAt,
    this.releaseAt,
    this.disputeReason,
    this.acceptedAt,
    this.onTheWayAt,
  });

  final String id;
  final String clientName;
  final String? providerId;
  final String? providerName;
  final String? providerProfession;
  final String? providerAvatarUrl;
  final String title;
  final String description;
  final DateTime? scheduledAt;
  final String address;
  final int price;
  final BookingStatus status;
  final EscrowStatus escrow;
  final bool paid;
  final bool urgent;
  final DateTime createdAt;
  final String? cancelReason;

  /// Code à remettre au prestataire en fin de travail (visible du client seul).
  final String? completionCode;
  final DateTime? completedAt;

  /// Versement automatique prévu (travail déclaré terminé sans code).
  final DateTime? releaseAt;
  final String? disputeReason;
  final DateTime? acceptedAt;
  final DateTime? onTheWayAt;

  /// Réservation encore vivante (ni terminée, ni annulée, ni refusée).
  bool get isOpen =>
      status == BookingStatus.pending ||
      status == BookingStatus.accepted ||
      status == BookingStatus.inProgress;

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'].toString(),
        clientName: (j['clientName'] as String?) ?? '',
        providerId: j['providerId']?.toString(),
        providerName: j['providerName'] as String?,
        providerProfession: j['providerProfession'] as String?,
        providerAvatarUrl: j['providerAvatarUrl'] as String?,
        title: (j['title'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        scheduledAt: _date(j['scheduledAt']),
        address: (j['address'] as String?) ?? '',
        price: (j['price'] as num?)?.toInt() ?? 0,
        status: _status(j['status'] as String?),
        escrow: _escrow(j['escrowStatus'] as String?),
        paid: (j['paid'] as bool?) ?? false,
        urgent: (j['urgent'] as bool?) ?? false,
        createdAt: _date(j['createdAt']) ?? DateTime.now(),
        cancelReason: j['cancelReason'] as String?,
        completionCode: j['completionCode'] as String?,
        completedAt: _date(j['completedAt']),
        releaseAt: _date(j['releaseAt']),
        disputeReason: j['disputeReason'] as String?,
        acceptedAt: _date(j['acceptedAt']),
        onTheWayAt: _date(j['onTheWayAt']),
      );
}

/// Paiement initié sur une réservation.
class Payment {
  const Payment({
    required this.id,
    required this.amount,
    required this.commissionAmount,
    required this.providerAmount,
    required this.status,
  });

  final String id;
  final int amount;
  final int commissionAmount;
  final int providerAmount;
  final String status;

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'].toString(),
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        commissionAmount: (j['commissionAmount'] as num?)?.toInt() ?? 0,
        providerAmount: (j['providerAmount'] as num?)?.toInt() ?? 0,
        status: (j['status'] as String?) ?? '',
      );
}

/// Créneau proposé par le planning d'un prestataire.
class Slot {
  const Slot(this.start, this.free);
  final DateTime start;
  final bool free;
}

class DaySlots {
  const DaySlots(this.date, this.slots);
  final DateTime date;
  final List<Slot> slots;
}

class SlotsInfo {
  const SlotsInfo({required this.hasSchedule, required this.days});
  final bool hasSchedule;
  final List<DaySlots> days;

  factory SlotsInfo.fromJson(Map<String, dynamic> j) => SlotsInfo(
        hasSchedule: (j['hasSchedule'] as bool?) ?? false,
        days: ((j['days'] as List?) ?? const [])
            .map((d) => DaySlots(
                  DateTime.parse(d['date'].toString()),
                  ((d['slots'] as List?) ?? const [])
                      .map((s) => Slot(
                            DateTime.parse(s['start'].toString()).toLocal(),
                            (s['free'] as bool?) ?? false,
                          ))
                      .toList(),
                ))
            .toList(),
      );
}
